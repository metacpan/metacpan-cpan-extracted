use strict;
package ObjStore;
use Carp;
use vars
    qw($VERSION @ISA @EXPORT @EXPORT_OK @EXPORT_FAIL %EXPORT_TAGS 
       %sizeof $INITIALIZED $RUN_TIME $OS_CACHE_DIR %FEATURE),
    qw($SAFE_EXCEPTIONS $REGRESS @UNLOADED),                        # exceptional
    qw($CLIENT_NAME $CACHE_SIZE $TRANSACTION_PRIORITY),             # tied
    qw($DEFAULT_OPEN_MODE),                                         # simulated
    qw(%SCHEMA $EXCEPTION %CLASSLOAD $CLASSLOAD $CLASS_AUTO_LOAD);  # private

$VERSION = '1.59';

$OS_CACHE_DIR = $ENV{OS_CACHE_DIR} || '/tmp/ostore';
if (!-d $OS_CACHE_DIR) {
    mkdir $OS_CACHE_DIR, 0777 or warn "mkdir $OS_CACHE_DIR: $!";
}

require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
{
    my @x_adv = qw(&peek &blessed &reftype &os_version &translate 
		   &get_all_servers &set_default_open_mode &lock_timeout
		   &get_lock_status &is_lock_contention 
		  );
    my @x_tra = (qw(&release_name
		    &network_servers_available
		    &get_page_size &return_all_pages 
		    &abort_in_progress &get_n_databases
		    &set_stargate &DEFAULT_STARGATE),
		 # deprecated
		 qw(&set_transaction_priority &subscribe &unsubscribe
		   ));
    my @x_old = qw(&fatal_exceptions);
    my @x_priv= qw($DEFAULT_OPEN_MODE %CLASSLOAD $CLASSLOAD $EXCEPTION
		   &_PRIVATE_ROOT);

    @EXPORT      = (qw(&bless &begin));
    @EXPORT_FAIL = ('PANIC');
    @EXPORT_OK   = (@EXPORT, @x_adv, @x_tra, @x_old, @x_priv, @EXPORT_FAIL);
    %EXPORT_TAGS = (DEFAULT => [@EXPORT],
		    ADV => [@EXPORT, @x_adv],
		    ALL => [@EXPORT, @x_adv, @x_tra]);
}

'ObjStore'->bootstrap($VERSION);

for (qw(ObjStore::Server ObjStore::Database ObjStore::Root
	ObjStore::Schema ObjStore::Segment ObjStore::PathExam)) {
    no strict 'refs';
    *{$_.'::DESTROY'} = \&_typemap_any_destroy;
}

$EXCEPTION = sub {
    my $m = shift;
#    local $Carp::CarpLevel = $Carp::CarpLevel + 1;  # too ambitious
    if ($m eq 'SEGV') {
	$m = &_SEGV_reason();
	if ($m) {
	    if ($ObjStore::REGRESS) {
		my $buf = "[ObjStore::REGRESS output for '$m':\n";
		my $i = 0;
		my @a;
		while (@a = caller $i) {
		    my ($pack,$file,$line,$sub) = @a;
		    $buf .= "FRAME[$i]: $sub at $file line $line\n";
		    ++$i;
		}
		$buf.= "]\n";
		warn $buf;
	    }
	    $m = "ObjectStore: $m\t";
	} else {
	    $m = 'SEGV';  # probably not our fault?
	}
    }

    # Due to bugs in perl, confess can cause a SEGV if the signal
    # happens at the wrong time.  Even a simple die doesn't always work.
    confess $m if !$ObjStore::SAFE_EXCEPTIONS;
    die $m;
};

$SIG{SEGV} = \&$EXCEPTION
    unless defined $SIG{SEGV}; # MUST NOT BE CHANGED! XXX

eval { require Thread::Specific } or do {
    sub lock {}
    undef $@;
};

tie $CACHE_SIZE, 'ObjStore::Config::CacheSize';
tie $CLIENT_NAME, 'ObjStore::Config::ClientName';

require ObjStore::Config;

END {
#    debug(qw(bridge txn));
    warn "ObjStore: beginning global destruction\n"
	if $ObjStore::REGRESS;
    if ($INITIALIZED) {
	lock %ObjStore::Transaction::;
	my @copy = reverse @ObjStore::Transaction::Stack;
	for (@copy) { $_->abort }
	ObjStore::shutdown();
    }
    warn "ObjStore: completed global destruction\n"
	if $ObjStore::REGRESS;
}

sub initialize {
    croak "initialized twice" if $INITIALIZED; #XXX ?
    ObjStore::_initialize();
    $SCHEMA{'ObjStore'}->load($ObjStore::Config::SCHEMA_DBDIR.
			      "/osperl-".&ObjStore::Config::SCHEMA_VERSION.
			      ".adb");
    ObjStore::CORE->boot2($VERSION);  #little hackie
    ++$INITIALIZED;
}

ObjStore::initialize()
    if !$ObjStore::NoInit::INIT_DELAYED;

sub export_fail {
    shift;
    if ($_[0] eq 'PANIC') { 
	require Carp;
	Carp->import('verbose');
	ObjStore::debug(shift);
    }
    @_;
}

# keywords flying coach...
sub reftype ($);
sub blessed ($);
sub bless ($;$);

tie $TRANSACTION_PRIORITY, 'ObjStore::Transaction::Priority';
sub set_transaction_priority {
    carp "just assign to \$TRANSACTION_PRIORITY directly";
    $TRANSACTION_PRIORITY = shift;
}

sub begin {
    my $code = pop;
    croak "last argument must be CODE" if !ref $code eq 'CODE';
    my $wantarray = wantarray;
    my @result=();
    my $txn = ObjStore::Transaction->new(@_);
    my $ok=0;
    $ok = eval {
	if ($wantarray) {
	    @result = $code->();
	} elsif (defined $wantarray) {
	    $result[0] = $code->();
	} else {
	    $code->();
	}
	$txn->post_transaction(); #1
	1;
    };
    ($ok and $txn->get_type !~ m'^abort') ? $txn->commit() : $txn->abort();
    if (!defined wantarray) { () } else { wantarray ? @result : $result[0]; }
}

use vars qw(%STARGATE);
%STARGATE = (
	     HASH => sub {
		 my ($class, $sv, $seg) = @_;
		 my $pt = $class eq 'HASH' ? 'ObjStore::HV' : $class;
		 $pt->new($seg, $sv);
	     },
	     ARRAY => sub {
		 my ($class, $sv, $seg) = @_;
		 my $pt = $class eq 'ARRAY' ? 'ObjStore::AV' : $class;
		 $pt->new($seg, $sv);
	     },
	     REF => sub {
		 my ($class, $sv, $seg) = @_;
		 $sv = $$sv;
		 $sv->new_ref($seg, 'unsafe');
	     }
	    );

sub DEFAULT_STARGATE {
    my ($seg, $sv) = @_;
    my $class = ref $sv;
    my $code = $STARGATE{$class} || $STARGATE{ reftype($sv) };

    croak("ObjStore::DEFAULT_STARGATE: Don't know how to translate $sv")
	if !$code;

    $code->($class, $sv, $seg);
};
set_stargate(\&DEFAULT_STARGATE);

# the revised new standard bless, limited edition
sub bless ($;$) {
    my ($ref, $class) = @_;
    $class ||= scalar(caller);
    $ref->BLESS($class) if blessed $ref;
    $class->BLESS($ref);
}
# When CORE::GLOBAL works -
#   *CORE::GLOBAL::bless = \&bless;  XXX

#sub BLESS {
#    my ($r1,$r2);
#    if (ref $r1) { warn "$r1 leaving ".ref $r1." for a new life in $r2";  }
#    else         { warn "$r2 entering $r1"; }
#    $r1->SUPER::BLESS($r2);
#}

sub require_isa_tree {
    no strict 'refs';
    my ($class, $isa) = @_;
#    warn "require_isa_tree $class $isa";
    unless (@{"$class\::ISA"}) {
	my $file = $class;
	$file =~ s,::,/,g;
	eval { require "$file.pm" };
	die $@ if $@ && $@ !~ m"Can't locate .*? in \@INC";
    }
    for (my $x=0; $x < @$isa; $x+=2) {
	require_isa_tree($isa->[$x], $isa->[$x+1]);
    }
}

sub force_load {
    # Can the damage be undone if eventually loaded? XXX
    no strict;
    my ($class, $isa) = @_;

    return if !@$isa || @{"${class}::ISA"};

#    warn "force_load $class $isa";

    $ {"${class}::UNLOADED"} = 1;
    push @UNLOADED, $class;

    for (my $x=0; $x < @$isa; $x+=2) {
	push @{"${class}::ISA"}, $isa->[$x];
	force_load($isa->[$x], $isa->[$x+1]);
    }

#    warn "[ObjStore: marking $class as UNLOADED]\n";# if $ObjStore::REGRESS;
#    eval "package $class; ".' sub AUTOLOAD {
#Carp::croak(qq[Sorry, "$AUTOLOAD" is not loaded.  You may need to adjust \@INC in order for your database code to be automatically loaded when the database is opened.\n]);
#};';
#    die if $@;
}

$CLASS_AUTO_LOAD = 1;

sub _isa_loader {
    no strict 'refs';
    my ($bs, $base, $class) = @_;
#    Carp::cluck "_isa_loader $bs $base $class";
    if (!@{"$class\::ISA"} and $CLASS_AUTO_LOAD) {
	return $class if $class eq 'ObjStore::Database';
	my $isa;
	if (!$bs) {
	    $isa = [$base,[]];
	} else {
	    $isa = $bs->[3];
	}
	if ($class =~ m/^_fake\:\:/ and @$isa == 2) {
	    # pop fake blessing
	    ($class,$isa) = @$isa;
	}
	require_isa_tree($class, $isa);
	if (!$class->isa($base)) {
	    force_load($class, $isa);
	    while (!$class->isa($base) and @$isa) {
		# pop classes until we get a winner
		($class,$isa) = @$isa;
	    }
	    if (!$class->isa($base)) {
		# oops!  hope this works...
		return $base;
	    }
	}
    }
#    warn $class;
    $class;
};
$CLASSLOAD = \&_isa_loader;

sub disable_auto_class_loading { $CLASS_AUTO_LOAD=0 }

sub lookup {
    my ($path, $mode) = @_;
    $mode = 0 if !defined $mode;
    my $db = _lookup($path, $mode);
    if ($db && $db->is_open) {
	&ObjStore::begin(sub { $db->import_blessing(); });
	die if $@;
    }
    $db;
}

$DEFAULT_OPEN_MODE = 'update';
sub set_default_open_mode {
    my ($mode) = @_;
    croak "ObjStore::set_default_open_mode: $mode unknown"
	if $mode ne 'read' and $mode ne 'update' and $mode ne 'mvcc';
    $DEFAULT_OPEN_MODE = $mode;
}

sub open {
    my ($path, $mode, $create_mode) = @_;
    $create_mode = 0 if !defined $create_mode;
    my $db = lookup($path, $create_mode);
    if ($db) { $db->open($mode) and return $db; }
    undef;
}

sub peek {
    croak "ObjStore::peek(top)" if @_ != 1;
    require ObjStore::Peeker;
    my $pk = ObjStore::Peeker->new(to => *STDERR{IO});
    $pk->Peek($_[0]);
}

sub debug {  # autoload
    my $mask=0;
    for (@_) {
	/^off/      and last;
	/^refcnt/   and $mask |= 0x0001, next;
	/^assign/   and $mask |= 0x0002, next;
	/^bridge/   and $mask |= 0x0004, next;
	/^array/    and $mask |= 0x0008, next;
	/^hash/     and $mask |= 0x0010, next;
	/^set/      and $mask |= 0x0020, next;
	/^cursor/   and $mask |= 0x0040, next;
	/^bless/    and $mask |= 0x0080, next;
	/^root/     and $mask |= 0x0100, next;
	/^splash/   and $mask |= 0x0200, next;
	/^txn/      and $mask |= 0x0400, next;
	/^ref/      and $mask |= 0x0800, next;
	/^wrap/     and $mask |= 0x1000, next;
	/^thread/   and $mask |= 0x2000, next;
	/^index/    and $mask |= 0x4000, next;
	/^norefs/   and $mask |= 0x8000, next;
	/^decode/   and $mask |= 0x00010000, next;
	/^schema/   and $mask |= 0x00020000, next;
	/^pathexam/ and $mask |= 0x00040000, next;
	/^compare/  and $mask |= 0x00080000, next;
	/^dynacast/ and $mask |= 0x00100000, next;
	/^PANIC/    and $mask = 0xfffff, next;
	die "Snawgrev $_ tsanik brizwah dork'ni";
    }
    if ($mask) {
	Carp->import('verbose');
    }
    ++$ObjStore::REGRESS if $mask != 0;
    _debug($mask);
}

#------ ------ ------ ------
sub fatal_exceptions {
    my ($yes) = @_;
    confess "sorry, the cat's already out of the bag"
	if $yes;
}
*ObjStore::disable_class_auto_loading = \&disable_auto_class_loading; #silly me

package ObjStore::Config::CacheSize;

sub TIESCALAR {
    my $p = $ENV{OS_CACHE_SIZE} || 1024 * 1024 * 8;
    bless \$p, shift;
}

sub FETCH { ${$_[0]} }
sub STORE {
    my ($o, $new) = @_;
    ObjStore::_set_cache_size($new);
    $$o = $new;
}

package ObjStore::Config::ClientName;

sub TIESCALAR {
    my $o = $0;
    $o =~ s,^.*/,,;
    ObjStore::_set_client_name($o);
    bless \$o, shift;
}

sub FETCH { ${$_[0]} }
sub STORE {
    my ($o, $new) = @_;
    ObjStore::_set_client_name($new);
    $$o = $new;
}

package ObjStore::Transaction::Priority;

sub TIESCALAR {
    my $p = 0x8000;
    bless \$p, shift;
}

sub FETCH { ${$_[0]} }
sub STORE {
    my ($o,$new) = @_;
    ObjStore::_set_transaction_priority($new);
    $$o = $new;
}

package ObjStore::Transaction;
use vars qw(@Stack);
#for (qw(new top_level abort commit checkpoint post_transaction
#	get_current get_type),
#     # experimental
#     qw(prepare_to_commit is_prepare_to_commit_invoked
#        is_prepare_to_commit_completed)) {
#    ObjStore::_lock_method($_)
#}

# Psuedo-class to animate persistent bless..  (Kudos to Devel::Symdump :-)
#
package ObjStore::BRAHMA;
use Carp;
use vars qw(@ISA @EXPORT %CLASS_DOGTAG);
BEGIN {
    @ISA = qw(Exporter);
    @EXPORT = (qw(&_isa &_versionof &_is_evolved &stash &GLOBS
		  %CLASS_DOGTAG &_get_certified_blessing &_engineer_blessing
		  &_conjure_brahma
		 ));
}

'ObjStore::Database'->
    _register_private_root_key('BRAHMA', sub { 'ObjStore::HV'->new(shift, 30) });
sub _conjure_brahma { shift->_private_root_data('BRAHMA'); }

# persistent per-class globals
'ObjStore::Database'->
    _register_private_root_key('GLOBAL', sub { 'ObjStore::HV'->new(shift, 30) });
sub stash {
    my ($db, $class) = @_;
    if (!defined $class) {
	$class = ref $db;
	$db = $db->database_of;
    }
    my $G = $db->_private_root_data('GLOBAL');
    return if !$G;
    my $g = $G->{$class};
    if (!$g) {
	$g = $G->{$class} = 'ObjStore::HV'->new($G);
    }
    # can't bless what is essentially a symbol table...
    my %fake;
    tie %fake, 'ObjStore::HV', $g;
    \%fake;
}
sub GLOBS {
    carp "'GLOBS' has been renamed to 'stash'";
    stash(@_);
}

# classname => [
#   [0] = 0          (version)
#   [1] = classname  (must always be [1]; everything else can change)
#   [2] = dogtag
#   [3] = [@ISA]     (depth-first array-tree)
# ]
# classname => [
#   [0] = 1
#   [1] = classname
#   [2] = dogtag
#   [3] = [@ISA]
#   [4] = { map { $_ => $_\::VERSION } @ISA }
# ]

# We can elide the recursion check, since 
# If the persistent tree
# Has a LOOP, 
# We made a biggger mistake.
#                 -- Vogon Poetry, volume 3

sub isa_tree_matches {
    my ($class, $isa) = @_;
    no strict 'refs';
    my $x=0;
    for my $z (@{"$class\::ISA"}) {
	return 0 if (!$isa->[$x] or $isa->[$x] ne $z or
		     !isa_tree_matches($z, $isa->[$x+1]));
	$x+=2;
    }
    return if $isa->[$x+1];
    1;
}

sub _get_certified_blessing {  #XS? XXX
    my ($br, $o, $toclass) = @_;

    my $bs = $br->{$toclass};
    return if !$bs;

    return $bs if (ObjStore::blessed($o) ne $toclass and
		   ($CLASS_DOGTAG{$toclass} or 0) == $bs->[2]);

    # dogtag invalid; do a full check...

    return if ($bs->[0] != 1 ||
	       !isa_tree_matches($toclass, $bs->[3]));

    no strict 'refs';
    my $then = $bs->[4];
    for (my ($c,$v) = each %$then) {
	return if ($ {"$c\::VERSION"} || '') gt $v;
    }

    # looks good; fix dogtag so we short-cut next time
    $CLASS_DOGTAG{$toclass} = $bs->[2];
    # warn "ok $toclass ".$bs->[2];
    $bs;
}

sub isa2 { #recode in XS ? XXX
    my ($class, $isa) = @_;
    for (my $x=0; $x < $isa->FETCHSIZE; $x++) {
	my $z = $isa->[$x];
	if (ref $z) { return 1 if isa2($class, $z); }
	else { return 1 if $class eq $z; }
    }
    0;
}

sub _isa {
    my ($o, $class, $txn) = @_;
    return $o->SUPER::isa($class) if !ref $o;
    my $x = sub {
	my $bs = $o->_blessto_slot;
	return $o->SUPER::isa($class) if !$bs;
	return 1 if $class eq $bs->[1];
	isa2($class, $bs->[3]);
    };
    $txn? &ObjStore::begin($x) : &$x;
}

sub _versionof {
    my ($o, $class, $txn) = @_;
    return $o->SUPER::versionof($class) if !ref $o;
    my $x = sub {
	my $bs = $o->_blessto_slot;
	return $o->SUPER::versionof($class) if !$bs || !$bs->[4];
	$bs->[4]->{$class};
    };
    $txn? &ObjStore::begin($x) : &$x;
}

my $is_evolved_warn=0;
sub _is_evolved {
    local $Carp::CarpLevel = $Carp::CarpLevel+1;
    my ($o, $txn) = @_;
    carp "is_evolved might be depreciated"
	if ++$is_evolved_warn < 5;
    croak("is_evolved($o) is only meaningful on real objects") if !ref $o;
    my $x = sub {
	my $bs = $o->_blessto_slot;
	croak("is_evolved($o) only works on re-blessed objects")
	    if !$bs || !$bs->[4];
	
	no strict 'refs';
	my $then = $bs->[4];
	while (my ($c,$v) = each %$then) {
	    if (($ {"$c\::VERSION"} || '') gt $v) {
		#warn $c;
		return;
	    }
	}
	1;
    };
    $txn? &ObjStore::begin($x) : &$x;
}

# can skip the top-level class
sub isa_tree {
    my ($pkg, $depth) = @_;
    confess "ObjStore::BRAHMA::isa_tree: loop in \@$pkg\::ISA"
	if ++$depth > 100;
    my @isa;
    no strict 'refs';
    for my $z (@{"$pkg\::ISA"}) { push(@isa, $z, isa_tree($z, $depth)); }
    \@isa;
}

sub isa_versions {
    my ($pkg, $vmap, $depth) = @_;
    return $vmap if $pkg eq 'Exporter';  #apparently doesn't make sense?
    confess "ObjStore::BRAHMA::isa_versions: loop in \@$pkg\::ISA"
	if ++$depth > 100;
    no strict 'refs';
#    if (!defined $ {"$pkg\::VERSION"}) {
#	warn "\$$pkg\::VERSION must be assigned a version string!\n";
#    }
    $vmap->{$pkg} = $ {"$pkg\::VERSION"} || '0.001';
    for my $z (@{"$pkg\::ISA"}) { isa_versions($z, $vmap, $depth); }
    $vmap;
}

sub _engineer_blessing {
    my ($br, $bs, $o, $toclass, $os_class) = @_;
    if (! $bs) {
	# This warning is broken since it doesn't detect the right thing
	# when there are multiple databases.  Each database needs its own copy
	# of bless-info.
#	warn "ObjStore::BRAHMA must be notified of run-time manipulation of VERSION strings by changing \$ObjStore::RUN_TIME to be != \$CLASS_DOGTAG{$toclass}" 
#	    if ($CLASS_DOGTAG{$toclass} or 0) == $ObjStore::RUN_TIME; #majify? XXX

	$bs = $br->{$toclass} = [1,
				 $toclass,
				 $ObjStore::RUN_TIME,
				 isa_tree($toclass,0),
				 isa_versions($toclass, {}, 0)];
	$bs->const;
	$CLASS_DOGTAG{$toclass} = $bs->[2];
#	warn "fix $toclass ".$bs->[2];
    }
    $o->_blessto_slot($bs);
}

package ObjStore::Root;

for (qw(destroy get_name get_value set_value)) {
    ObjStore::_mark_method($_)
}

# 'bless' for databases is totally, completely, and utterly
# special-cased.  It's like stuffing a balloon inside itself!
#
package ObjStore::Database;
BEGIN { ObjStore::BRAHMA->import(); }
use Carp;
use vars qw($VERSION @OPEN0 @OPEN1 %_ROOT_KEYS);

$VERSION = '1.00';

for (qw(close get_host_name get_pathname get_relative_directory
	get_id get_default_segment_size size size_in_sectors time_created
	is_open is_writable set_fetch_policy set_lock_whole_segment
	get_default_segment get_segment get_all_segments get_all_roots
	create_root find_root)) {
    ObjStore::_mark_method($_)
}

@OPEN0=();
@OPEN1=();

sub database_of {
    use attrs 'method';
    $_[0];
 }
sub segment_of {
    use attrs 'method';
    $_[0]->get_default_segment;
}

sub os_class { 'ObjStore::Database' }

sub open {
    use attrs 'method';
    my ($db, $mode) = @_;
    $mode = $ObjStore::DEFAULT_OPEN_MODE if !defined $mode;
    if ($mode =~ /^\d$/) {
	if ($mode == 0)    { $mode = 'update' }
	elsif ($mode == 1) { $mode = 'read' }
	else { croak "ObjStore::open($db, $mode): mode $mode??" }
    }
    my $ok=0;
    if ($mode eq 'mvcc') { $ok = $db->_open_mvcc; }
    else { $ok = $db->_open($mode eq 'read'); }
    return 0 if !$ok;

    # Acquiring a lock here messes up the deadlock regression test
    # so we check TRANSACTION_PRIORITY first.
    if ($ObjStore::TRANSACTION_PRIORITY and $ObjStore::CLASS_AUTO_LOAD) {
	&ObjStore::begin(sub {
			     for my $x (@OPEN0) { $x->($db); }
			     $db->import_blessing();
			     for my $x (@OPEN1) { $x->($db); }
			 });
	die if $@;
    }
    1;
}

'ObjStore::Database'->_register_private_root_key('INC');

sub new {
    use attrs 'method';
    my $class = shift;
    my $db = ObjStore::open(@_);
    ObjStore::bless($db, $class) if $db;
}

use vars qw(%BLESSMAP);
sub import_blessing {
    my ($db) = @_;
    my $bs = $db->_blessto_slot;
    if ($bs) {
	# This is essentially the same as what is done for
	# ObjStore::UNIVERSAL.

	my $class = $BLESSMAP{ $bs->[1] };
	if (!$class) {
	    $class = $BLESSMAP{ $bs->[1] } =
		&ObjStore::_isa_loader($bs, 'ObjStore::Database', $bs->[1]);
	}
	# Must use CORE::bless here -- the database is _already_ blessed, yes?
	CORE::bless($db, $class);
    }
    $db;
}

'ObjStore::Database'->_register_private_root_key('database_blessed_to');
sub _blessto_slot {
    my ($db, $new) = @_;
    my $bs = $db->_private_root_data('database_blessed_to', $new);
    return if $bs && !ref $bs; #deprecated 1.19
    $bs;
}

sub isa { _isa(@_, 1); }
sub versionof { _versionof(@_, 1); }
sub is_evolved { _is_evolved(@_, 1); }

# Even though the transient blessing doesn't match, the persistent
# blessing might be correct.  We need to check before doing a super-
# slow update transaction.

# There are potentially four blessings to be aware of:
# 1. the current bless-to
# 2. the destination bless-to
# 3. the database bless-info
# 4. the per-class bless-info (in BRAHMA)

sub BLESS {
    if (ref $_[0]) {
	my ($r, $class) = @_;
	croak "Cannot bless $r into non-ObjStore::Database class '$class'"
	    if !$class->isa('ObjStore::Database');
	return $r->SUPER::BLESS($class);
    }
    my ($class, $db) = @_;
    my $need_rebless = 1;
    &ObjStore::begin(sub {
	my $br = $db->_conjure_brahma;
	return if !$br;
	my $bs = _get_certified_blessing($br, $db, $class);
	return if !$bs;
	if ($db->_blessto_slot() == $bs and $bs->[1] eq $class) {
	    # Already blessed and certified: way cool dude!
	    $need_rebless = 0;
	}
    });
    die if $@;
    no strict 'refs';
    if ($need_rebless and !$ {"$class\::UNLOADED"} and $db->is_writable) {

	&ObjStore::begin('update', sub {
		my $br = $db->_conjure_brahma;
		_engineer_blessing($br, scalar(_get_certified_blessing($br, $db, $class)), $db, $class, 'ObjStore::Database');
	    });
	die if $@;
    }
    $class->SUPER::BLESS($db);
}

sub create_segment {
    use attrs 'method';
    my ($o, $name) = @_;
    carp "$o->create_segment('name')" if @_ != 2;
    my $s = $o->database_of->_create_segment;
    $s->set_comment($name) if $name;
    $s;
}

sub gc_segments {
    my ($o) = @_;
    for my $s ($o->get_all_segments()) {
	$s->destroy if $s->is_empty();
    }
}

sub destroy {
    use attrs 'method';
    my ($o, $step) = @_;
    $step ||= 10;
    my $more;
    do {
	&ObjStore::begin('update', sub {
	    my @r = ($o->get_all_roots, $o->_PRIVATE_ROOT);
	    for (my $x=0; $x < $step and @r; $x++) { (pop @r)->destroy }
	    $more = @r;
	});
	die if $@;
    } while ($more);

    # This doesn't work if there have been protected references!  Help!  XXX
    my $empty=1;
    &ObjStore::begin('update', sub {
	for my $s ($o->get_all_segments) {
	    next if $s->get_number == 0;   #system segment?
	    if (!$s->is_empty) {
#		warn "Segment #".$s->get_number." is not empty\n";
		$empty=0;
	    }
	}
    });
    die if $@;
    if ($empty) {
	$o->_destroy;  #secret destroy method :-)
    } else {
	croak "$o->destroy: not empty (use osrm to force the issue)";
    }
}

sub root {
    use attrs 'method';
    my ($o, $roottag, $nval) = @_;
    my $root = $o->find_root($roottag);
    if (defined $nval and $o->is_writable) {

	$root ||= $o->create_root($roottag);
	if (ref $nval eq 'CODE') {
	    $root->set_value(&$nval) if !defined $root->get_value();
	} else {
	    $root->set_value($nval);
	}
    }
    $root? $root->get_value() : undef;
}

sub destroy_root {
    use attrs 'method';
    my ($o, $tag) = @_;
    my $root = $o->find_root($tag);
    $root->destroy;
}

sub _register_private_root_key {
    my ($class, $key, $mk) = @_;
    croak "$_ROOT_KEYS{$key}->{owner} has already reserved private root key '$key'"
	if $_ROOT_KEYS{$key};
    $_ROOT_KEYS{$key} = { owner => scalar(caller), $mk? (mk => $mk):() };
}

sub _private_root_data {  #XS? XXX
    my ($db, $key, $new) = @_;
#    confess "_private_root_data(@_)" if @_ != 2 && @_ != 3;
    confess "Detected attempt to subvert security check on private root key '$key'"
	if !$_ROOT_KEYS{$key};
    my $rt = $db->_PRIVATE_ROOT();
    return if !$rt;
    my $priv = $rt->get_value;
    if (!$priv) {
	my $s = $db->create_segment("_osperl_private");
	$priv = 'ObjStore::HV'->new($s, 30);
	$rt->set_value($priv);

	# Useless?  You have to have to right shared objects loaded
	# anyway just to read this stuff! XXX
	$priv->{'VERSION'} = $ObjStore::VERSION;
    }
    if ($new) {
	if (ref $new eq 'CODE') {
	    my $d = $priv->{$key};
	    if (!$d) {
		$d = $priv->{$key} = $new->($priv);
	    }
	    $d
	} else {
	    $priv->{$key} = $new;	    
	}
    } else {
	my $d = $priv->{$key};
	if (!$d and $_ROOT_KEYS{$key}->{mk} and $db->is_writable) {
	    $d = $priv->{$key} = $_ROOT_KEYS{$key}->{mk}->($priv)
	}
	$d;
    }
}

#------- ------- ------- -------
sub get_INC {
    carp "deprecated";
    shift->_private_root_data('INC', sub { [] });
}
sub sync_INC {
    carp "deprecated";
    my ($db) = @_;
    my $inc = $db->_private_root_data('INC');
    return if !$inc;
    # optimize with a hash XXX
    for (my $x=0; $x < $inc->FETCHSIZE; $x++) {
	my $dir = $inc->[$x];
	my $ok=0;
	for (@INC) { $ok=1 if $_ eq $dir }
	if (!$ok) {
#	    warn "sync_INC: adding $dir";
	    unshift @INC, $dir;
	}
    }
}

sub is_open_read_only {
    my ($db) = @_;
    warn "$db->is_open_read_only: just use $db->is_writable or $db->is_open";
    $db->is_open eq 'read' or $db->is_open eq 'mvcc';
}

sub is_open_mvcc {
    my ($db) = @_;
    carp "$db->is_open_mvcc is unnecessary; simply use is_open";
    $db->is_open eq 'mvcc';
}

$_ROOT_KEYS{Brahma} = { owner => 'ObjStore::Database' }; #deprecated 1.19

package ObjStore::Segment;
use Carp;

for (qw(get_transient_segment is_empty is_deleted return_memory
       size set_size unused_space get_number set_comment get_comment
       lock_into_cache unlock_from_cache set_fetch_policy
       set_lock_whole_segment )) {
    ObjStore::_mark_method($_);
}

sub segment_of {
    use attrs 'method';
    $_[0];
}
sub database_of {
    use attrs 'method';
    $_[0]->_database_of->import_blessing;
}

sub destroy {
    use attrs 'method';
    my ($o) = @_;
    if (!$o->is_empty()) {
	croak("$o->destroy: segment not empty (you may use osp_hack if you really need to destroy it)");
    }
    $o->_destroy;
}

#------- ------- ------- ------- -------
package ObjStore::Notification;
use Carp;

# Should work exactly like ObjStore::lookup
sub get_database {
    use attrs 'method';
    my ($n) = @_;
    my $db = $n->_get_database();
    if ($db && $db->is_open) {
	&ObjStore::begin(sub { $db->import_blessing(); });
	die if $@;
    }
    $db;
}

package ObjStore::UNIVERSAL;
use Carp;
use vars qw($VERSION @OVERLOAD);
$VERSION = '1.01';
BEGIN {
    ObjStore::BRAHMA->import();
    @OVERLOAD = ('""' => \&_pstringify,
		 'bool' => sub () {1},
		 '0+' => \&_pnumify,
		 '+' => \&_pnumify,
		 '==' => \&_peq,
		 '!=' => \&_pneq,
		 # 'nomethod' => sub { croak "overload: ".join(' ',@_); }
		);
}
use overload @OVERLOAD; # make normal XXX

for (qw(segment_of get_pointer_numbers HOLD)) {
    ObjStore::_mark_method($_)
}

sub database_of {
    use attrs 'method';
    $_[0]->_database_of->import_blessing;
}

*create_segment = \&ObjStore::Database::create_segment;

sub BLESS {
    return $_[0]->SUPER::BLESS($_[1])
	if ref $_[0];
    no strict 'refs';
    my ($class, $r) = @_;
    if (_is_persistent($r) and !$ {"$class\::UNLOADED"}) {
	# recode in XS ? XXX
	my $br = $r->database_of->_conjure_brahma;
	_engineer_blessing($br, scalar(_get_certified_blessing($br, $r, $class)), $r, $class, $r->os_class());
    }
    $class->SUPER::BLESS($r);
}

sub isa { _isa(@_, 0); }
sub versionof { _versionof(@_, 0); }
sub is_evolved { _is_evolved(@_, 0); }

#shallow copy
sub clone_to { croak($_[0]."->clone_to() unimplemented") }

# Do fancy argument parsing to make creation of unsafe references a
# very intentional endevour.  Maybe the default should be 'unsafe'? XXX
my $noise_count=3;
sub new_ref {
    use attrs 'method';
    my ($o, $seg, $safe) = @_;
    $seg = $seg->segment_of if ref $seg;
    $seg = ObjStore::Segment::get_transient_segment()
	if !defined $seg;
    my $type;
    if (!defined $safe) {
	$type = 1;
    }
    elsif ($safe eq 'safe') {
	$type=0;
	Carp::cluck "os_reference_protected is deprecated"
	    if $noise_count-- >= 0;
    }
    elsif ($safe eq 'unsafe' or $safe eq 'hard') { $type=1; }
    else { croak("$o->new_ref($safe,...): unknown type"); }
    $o->_new_ref($type, $seg);
}

sub help {
    '';     # reserved for posh & various
}

sub evolve {
    # Might be as simple as this:  bless $_[0], ref($_[0]);
    # but YOU have to code it!
    my ($o) = @_;
    $o->isa($o->os_class) or croak "$o must be an ".$o->os_class;
}

#-------- -------- --------
sub set_readonly { carp "set_readonly deprecated"; shift->const }

package ObjStore::Ref;
use vars qw($VERSION @ISA);
$VERSION = '1.00';
@ISA = qw(ObjStore::UNIVERSAL);

for (qw(dump deleted focus)) {
    ObjStore::_mark_method($_)
}

# Legal arguments:
#   dump, database
#   segment, dump, database

sub load {
    use attrs 'method';
    my $class = shift;
    my ($seg, $dump, $db);
    if (@_ == 2) {
	($dump, $db) = @_;
	$seg = ObjStore::Segment::get_transient_segment();
    } elsif (@_ == 3) {
	($seg, $dump, $db) = @_;
	$seg = ObjStore::Segment::get_transient_segment()
	    if !ref $seg && $seg eq 'transient';
    } else {
	croak("$class->load([segment], dump, database)");
    }
    &ObjStore::Ref::_load($class, $seg, $dump !~ m"\@", $dump, $db);
}

# Should work exactly like ObjStore::lookup
sub get_database {
    use attrs 'method';
    my ($r) = @_;
    my $db = $r->_get_database();
    if ($db && $db->is_open) {
	&ObjStore::begin(sub { $db->import_blessing(); });
	die if $@;
    }
    $db;
}

sub open {
    use attrs 'method';
    my ($r, $mode) = @_;
    my $db = $r->get_database;
    $db->open($mode) unless $db->is_open;
}

sub clone_to {
    my ($r, $seg, $cloner) = @_;
    $cloner->($r->focus)->new_ref($seg);
}

package ObjStore::Cursor;
use vars qw($VERSION @ISA);
$VERSION = '1.00';
@ISA = qw(ObjStore::UNIVERSAL);

for (qw(focus moveto step each at store seek pos keys)) {
    ObjStore::_mark_method($_)
}

sub count { $_[0]->focus->FETCHSIZE; }

sub clone_to {
    my ($r, $seg, $cloner) = @_;
    $cloner->($r->focus)->new_cursor($seg);
}

package ObjStore::Container;
use vars qw($VERSION @ISA);
$VERSION = '1.00';
@ISA = qw(ObjStore::UNIVERSAL);

sub new_cursor {
    use attrs 'method';
    my ($o, $seg) = @_;
    $seg = ObjStore::Segment::get_transient_segment()
	if !defined $seg || (!ref $seg and $seg eq 'transient');
    $o->_new_cursor($seg->segment_of);
}

sub clone_to {
    my ($o, $where) = @_;
    my $class = ref($o) || $o;
    $class->new($where, $o->FETCHSIZE() || 1);
}

sub count { shift->FETCHSIZE; }  #goofy XXX

package ObjStore::PathExam;

for (qw(new load_path load_args stringify keys load_target compare)) {
    ObjStore::_mark_method($_)
}

package ObjStore::AV;
use Carp;
use vars qw($VERSION @ISA %REP);
$VERSION = '1.01';
@ISA=qw(ObjStore::Container);

sub new { require ObjStore::REP; &ObjStore::REP::load_default }

sub EXTEND {}  #todo? XXX

sub map {
    my ($o, $sub) = @_;
    my @r;
    for (my $x=0; $x < $o->FETCHSIZE; $x++) { push(@r, $sub->($o->[$x])); }
    @r;
}

package ObjStore::HV;
use Carp;
use vars qw($VERSION @ISA %REP);
$VERSION = '1.01';
@ISA=qw(ObjStore::Container);

sub new { require ObjStore::REP; &ObjStore::REP::load_default }

sub TIEHASH {
    my ($class, $object) = @_;
    $object;
}

sub map {
    my ($o, $sub) = @_;
    carp "Experimental API";
    my @r;
    while (my ($k,$v) = each %$o) {
	push(@r, $sub->($v));       #pass $k too? XXX
    }
    @r;
}

#----------- ----------- ----------- ----------- ----------- -----------

# HashIndex will be a separate class; need a better name! XXX
package ObjStore::Index;
use Carp;
use vars qw($VERSION @ISA %REP);
$VERSION = '1.01';
@ISA='ObjStore::AV';

for (qw(configure add remove index_path)) {
    ObjStore::_mark_method($_)
}

sub new { require ObjStore::REP; &ObjStore::REP::load_default }

sub index_path {
    # make generic? "forward to rep_class" XXX
    my $o = $_[0];
    my $rep = $o->rep_class;
    my $m = $rep->can('index_path');
    croak "$rep does not support 'index_path' yet"
	if !$m;
    $m->(@_);
}

#----------- ----------- ----------- ----------- ----------- -----------

package ObjStore::Database::HV;
sub new { die "ObjStore::Database::HV has been renamed to ObjStore::HV::Database" }
sub BLESS {
    return $_[0]->SUPER::BLESS($_[1]) if ref $_[0];
    my ($class, $db) = @_;
    $class = 'ObjStore::HV::Database';
    $class->SUPER::BLESS($db);
}

package ObjStore::DEPRECIATED::Cursor;
use Carp;
use vars qw($VERSION);
$VERSION = '0.00';

sub seek_pole {
    my $o = shift;
    carp "$o->seek_pole: used moveto instead (renamed)";
    $o->moveto(@_);
}

sub step {
    my ($o, $delta) = @_;
    $delta == 1 or carp "$o doesn't really support step";
    $o->next;
}

#----------- ----------- ----------- ----------- ----------- -----------
package ObjStore;
$RUN_TIME = time;
die "RUN_TIME must be positive" if $RUN_TIME <= 0;

if (!defined &{"UNIVERSAL::BLESS"}) {
    eval 'sub UNIVERSAL::BLESS { ref($_[0])? () : CORE::bless($_[1],$_[0]) }';
    die if $@;
}

1;
