
package OOPS;

our $VERSION = 0.2005;
our $SCHEMA_VERSION = 1005;

require 5.008002;
require Exporter;
@EXPORT = qw(transaction getref walk_hash);
@ISA = qw(Exporter);
@EXPORT_OK = qw(transaction $transaction_maxtries $transfailrx dbiconnect dboconnect workaround27555 walk_hash);

use DBI;
use strict;
use warnings;
#use diagnostics;
use Carp qw(confess longmess verbose croak longmess);
use Scalar::Util qw(refaddr reftype blessed weaken);
use Hash::Util qw(lock_keys);
use B qw(svref_2object);
require OOPS::DBO;

#
# This is a self source filter.
#
BEGIN {
	package OOPS::SelfFilter;
	sub filter
	{
		my $more = filter_read();
		$_ = "#\n" if /debug/ || (/assertions/ && /oops/);
		return $more;
	}
	use Filter::Util::Call ;
	filter_add(bless [], __PACKAGE__)
		unless $OOPS::SelfFilter::defeat;
}

our $bigcutoff = 255;
our $cksumlength = 28;
our $demandthreshold = 500;
our $oopses = 0;
my $nopkey = 'nopkey';
our $warnings = 1;
our $transaction_tries = 0;
our $transaction_maxtries = 15;
our $transaction_failure_sleep = 0.5;
our $transaction_failure_maxsleep = 10;
our @transaction_rollback;
our $dbi_bug_workaround_count_debug = 0;
our $gc_overflow_id = 4;

# This gets updated by OOPS::DBO as backends are used
our $transfailrx = qr/^wont^match^anything^yet/;

our $id_alloc_size = 10;

my %typesymbol = (
	HASH	=> '%',
	ARRAY	=> '@',
	SCALAR	=> '$',
	REF	=> '$',
	GLOB	=> '*',
	CODE	=> '&',
	H	=> '%',
	A	=> '@',
	S	=> '$',
);

my %perltype2otype = (
	HASH => 'H',
	ARRAY => 'A',
	SCALAR => 'S',
	REF => 'S',
);

our $debug_free_tied		= 0;
our $debug_tiedvars		= 0;		# produces no output -- just verification
our $debug_oops_instances	= 0;		# track allocation / destructions of OOPS objects
our $debug_load_object		= 0;		# basic loading of objects
our $debug_load_values		= 0;		# loading of all keys & values
our $debug_load_context		= 0;		# stack trace for each load
our $debug_load_group		= 0;		# touches: load groups
our $debug_arraylen		= 0;		# touches: arraylen hash
our $debug_tie			= 0;		# when tie'ing
our $debug_untie		= 0;
our $debug_writes		= 0;		
our $debug_write_object		= 0;		# write to the object table
our $debug_blessing		= 0;		# bless operations
our $debug_memory		= 0;		# touches: memory
our $debug_memory2		= 0;		# the memory set/clear routines
our $debug_cache		= 0;		# touches: cache
our $debug_oldobject		= 0;		# touches: oldobject
our $debug_refcount		= 0;		# touches: refmore, refless or refcount
our $debug_gcgeneration		= 0;		# touches: gc generation
our $debug_touched		= 0;		# touches: touched
our $debug_commit		= 0;		# save objects
our $debug_demand_iterator	= 0;
our $debug_forcesave		= 0;
our $debug_isvirtual		= 0;
our $debug_27555		= 0;		# touches: 27555 fixup code
our $debug_27555_context	= 0;		# 27555 fixup code calling context
our $debug_save_attributes	= 0;		# near: queries to save pval
our $debug_save_attr_arraylen	= 0;		# arraylen for attribute save
our $debug_save_attr_context	= 0;		# stack trace for each attribute save
our $debug_refarray		= 0;		# array elements as references
our $debug_refalias		= 0;		# references to other values inside objects
our $debug_refobject		= 0;		# references to other objects
our $debug_reftarget		= 0;		# regarding reference target tracking
our $debug_write_object_context	= 0;		# traceback in write_object()
our $debug_write_ref		= 0;
our $debug_write_array		= 0;		# has ARRAY changed?
our $debug_normalarray		= 0;		# tied callbacks: non-virtual hash
our $debug_normalhash		= 0;
our $debug_write_hash		= 0;
our $debug_virtual_delete	= 0;
our $debug_virtual_save		= 0;
our $debug_virtual_hash		= 0;		# tied callbacks: virtual hash
our $debug_virtual_ovals	= 0;		# original values of virtual has
our $debug_hashscalar		= 0;		# scalar(%tied_hash)
our $debug_object_id		= 0;		# details of id allocation
our $debug_getobid_context	= 0;		# stack trace for new objects
our $debug_dbidelay		= 0;		# add small delay before changing transaction mode
our $debug_dbi			= 0;		# DBI debug level: 0 or 1 or 2
our @debug_traceintercept	= qw();		# Debug::TraceIntercept
our $debug_upgrade		= 0;		# debug schema upgrades
our $debug_initialize		= 0;		# debug initial queries
our $debug_setup		= 0;		# debug database initialization
our $debug_bigstuff		= 0;		# debug overflow table operations
our $debug_dbd			= 0;		# debug mysql.pm, pg.pm, etc.
our $debug_queries		= 0;		# bitfield: 1=select all (vs default==regex match), 2=print query name, 4=print query, 8=print args, 16=varients, 32=full query log
our $debug_q_regex_target	= 'query';	# query regex match on 'comment', 'query', or 'data'
our $debug_q_regex		= qr/insert/i;	# query regex matches comment or query
our $debug_tdelay		= 400;		# maximum artifical wait time (milliseconds)

select(STDOUT); $| = 1; # debug

# debug set for ref.t
$debug_27555 = $debug_write_ref = $debug_load_object = $debug_load_values = $debug_memory = $debug_commit = $debug_refalias = $debug_write_ref = 1 if 0;

my $global_destruction = 0;

our %tiedvars;

tie my %qtype, 'OOPS::debug', sub { return reftype($_[0]) };
tie my %qref, 'OOPS::debug', sub { return ref($_[0]) };
tie my %qaddr, 'OOPS::debug', sub { return refaddr($_[0]) };
tie my %qnone, 'OOPS::debug', sub { $_[0] };
tie my %qmakeref, 'OOPS::debug', sub { \$_[0] };
tie my %qval, 'OOPS::debug', sub { return defined $_[0] ? (ref($_[0]) ? "$_[0] \@ $qaddr{$_[0]}" : "'$_[0]'") : 'undef' };
tie my %qplusminus, 'OOPS::debug', sub { $_[0] >= 0 ? "+$_[0]" : $_[0] };
tie my %caller, 'OOPS::debug', sub { my $lvls = $_[0]+1; my ($p,$f,$l) = caller($lvls); my $s = (caller($lvls+1))[3]; $s =~ s/OOPS:://; $l = $f eq __FILE__ ? $l : "$f:$l";  return "$s/$l" };
tie my %qmemval, 'OOPS::debug', sub { my $v = shift; return "*$v" unless ref $v; return "*$v->[0]/$qval{$v->[1]}" };
tie my %qsym, 'OOPS::debug', sub { return $typesymbol{reftype(shift)} };

sub OOPS::debug::TIEHASH { my $p = shift; return bless shift, $p } 
sub OOPS::debug::FETCH { my $f = shift; return &$f(shift) } 

require Debug::TraceIntercept if @debug_traceintercept;
for my $dti_debug (@debug_traceintercept) {
	Debug::TraceIntercept::trace($dti_debug);
} # debug

sub new
{
	my ($pkg, %args) = @_;


	my $oops = bless {
		otype		=> {},	# object id -> H(ash)/A(rray)/S(scalar or ref)
		loadgroup	=> {},	# object id -> object loadgroup #
		loadgrouplock	=> {},	# object id -> object id
		groupset	=> {},	# group id -> object id -> 1
		cache		=> {},	# object id -> actual object
		memory		=> {},	# ref memory location -> object id
		memory2key 	=> {},	# ref mem location -> [ object id, object key ]
		new_memory	=> {},	# ref memory location -> object id
		new_memory2key 	=> {},	# ref mem location -> [ object id, object key ]
		memrefs		=> {},	# ref mem location -> ref
		memcount	=> {},	# ref mem location -> count of active references
		memsetdebug	=> {},  # where mem->object mappings were made 
		deleted		=> {},	# object id -> has been deleted
		unwatched	=> {},	# object id -> must check at save
		virtual		=> {},	# object id -> is it virtual? yes=V, no=' '
		arraylen	=> {},	# object id -> integer; array length
		reftarg		=> {},	# object id -> boolean: '0' || 'T';   Indicates if there are references to elements of this object
		aliasdest	=> {},	# object id -> hash of objectids that reference id
		oldvalue	=> {},	# object id & pkey -> original pval
		oldobject	=> {},  # object id & pkey -> original object id reference
		oldbig		=> {},	# object id & pkey -> checksum
		objtouched	=> {},	# objedt id -> bit - object may need saving
		demandwritten	=> {},	# object id -> tie control object
		demandwrite	=> {},	# object id -> write this one via tied.
		gcgeneration	=> {},  # object id -> garbage collection generation
		refdebug	=> {},	# object id -> original reference count
		objverdebug	=> {},	# object id -> object version counter
		refcount	=> {},	# object id -> reference count
		refmore		=> {},	# object id -> change in reference count (during commit()) - also serves as a todo list for saving objects
		refless		=> {},	# object id -> change in reference count (during commit()) - also serves as a todo list for saving objects
		forcesave	=> {},	# object id -> bit - for object row to be re-written  XXX redesign
		vcache		=> [],	# objects that implement a CLEAR_CACHE() method
		do_forcesave	=> 0,	# always update object row when attributes change, varies per backend
		savedone	=> {},	# during commit() - object written?
		refstowrite	=> [],	# during commit() - list of reference objects to save
		insave		=> 0,	# are we currently save()ing things?
		loaded		=> 0,   # number of objects "in memory"
		tountie		=> {},	# scalars wishing to be untied
		class		=> {},  # my original class/blessing
		queries		=> {},	# text of queries - original text
		binary_q_list	=> {},	# list of binary parametes to queries - DBD::Pg only
		debug_q		=> {},	# query comments, debugging pragmas
		commitdone	=> 0,	# have we already done a commit()?
		refcopy		=> {},	# object id & pkey -> ref to orig pval
		aliascount	=> {},	# object id & pkey -> count of \aliases
		oldalias	=> {},	# object id -> [ object id, pkey ]
		disassociated	=> {},  # object id & pkey && refs => other disconnected ref
		virtualize	=> {},	# objects to (un)virtualize
		gcspillcount	=> 0,	# number of objects spilled to the gc re-do buffer
		args		=> \%args,  		# creation arguments
		readonly	=> $args{readonly},	# commit not allowed?
	}, $pkg;

	print "# CREATE $$'s OOPS $oops\n" if $debug_oops_instances;

	my $dbo = $oops->{dbo} = OOPS->dboconnect(%args);
	$dbo->rebless($oops);

	#print "BLESSED $oops at ".__LINE__."\n" if $debug_blessing;

	#
	# object.otype:
	#
	#	H	HASH
	#	A	ARRAY
	#	S	SCALAR/REF
	#
	# object.virtual:
	#
	#	0	default
	#	V	load virtual
	#
	# attribute.ptype:
	#
	#	0	normal
	#	R	reference to an OBJECT
	#	B	Big scalar
	#
	#

	$dbo->learn_queries($dbo->initial_query_set);
	$dbo->learn_queries(<<END);
		saveobject: 3
			INSERT INTO TP_object (id, loadgroup, class, otype, virtual, reftarg, rfe, alen, refs, counter, gcgeneration)
			VALUES                (?,  ?,         ?,     ?,     ?,       ?,       '0', ?,    ?,    1,       ?)
		updateobject: 2
			UPDATE TP_object
			SET loadgroup = ?, class = ?, otype = ?, virtual = ?, reftarg = ?, alen = ?, refs = ?, gcgeneration = ?, counter = (counter + 1) % 65536
			WHERE id = ?
		objectset:
			SELECT o.* FROM TP_object AS o, TP_object AS og
			WHERE og.id = ? AND og.loadgroup = o.loadgroup
		objectinfo:
			# this has to be * so that it will work on all versions of the schema
			# SELECT loadgroup,class,otype,virtual,reftarg,alen,refs,counter,gcgeneration FROM TP_object
			SELECT * FROM TP_object
			WHERE id = ?
		objectgroupload:
			SELECT a.* FROM TP_attribute AS a, TP_object AS g
			WHERE g.loadgroup = ? AND g.id = a.id
		objectload:
			SELECT pkey, pval, ptype FROM TP_attribute
			WHERE id = ?
		objectreflist:
			SELECT pval FROM TP_attribute
			WHERE id = ? AND ptype = 'R'
		reftargobject: 1
			SELECT TP_object.id FROM TP_object, TP_attribute
			WHERE TP_attribute.pkey = ?
			AND TP_object.id = TP_attribute.id 
			AND TP_object.otype = 'S'
		reftargkey: 1 2
			SELECT TP_object.id FROM TP_object, TP_attribute
			WHERE TP_attribute.pkey = ? 
			AND TP_attribute.pval = ?
			AND TP_object.id = TP_attribute.id 
			AND TP_object.otype = 'S'
		saveattribute: 2 3
			INSERT INTO TP_attribute 
			VALUES (?, ?, ?, ?)
		loadpkey: 2
			SELECT pval, ptype FROM TP_attribute
			WHERE id = ? AND pkey = ?
		deleteattribute: 2
			DELETE FROM TP_attribute
			WHERE id = ? AND pkey = ?
		savepkey: 2 4 6 7 # show
			DELETE FROM TP_attribute
			WHERE id = ? AND pkey = ?;
			DELETE FROM TP_big
			WHERE id = ? AND pkey = ?;
			INSERT INTO TP_attribute
			VALUES (?, ?, ?, ?);
		updateattribute: 1 4
			UPDATE TP_attribute
			SET pval = ?, ptype = ?
			WHERE id = ? AND pkey = ?
		deletebig: 2 # show
			DELETE FROM TP_big
			WHERE id = ? AND pkey = ?
		predelete1: # show
			DELETE FROM TP_big WHERE id = ?
		predelete2:
			DELETE FROM TP_attribute WHERE id = ? AND ptype != 'R'
		postdeleteV:
			DELETE FROM TP_attribute
			WHERE id = ?;
		postdelete1:
			DELETE FROM TP_attribute WHERE id = ?
		postdelete2:
			DELETE FROM TP_object WHERE id = ?
		deleterange: 2
			DELETE FROM TP_attribute
			WHERE id = ? AND pkey >= ?
		deleteoverrange: 2 # show
			DELETE FROM TP_big
			WHERE id = ? AND pkey >= ?
		countkeys:
			SELECT	count(*) 
			FROM	TP_attribute
			WHERE	id = ?
END

	Time::HiRes::sleep(rand($debug_tdelay)/1000) if $debug_tdelay && $debug_dbidelay;
	$oops->{do_forcesave} = $dbo->do_forcesave;

	eval { $oops->{named_objects} = $oops->load_virtual_object(1) };
	if ($@) {
		print "Could not load object #1\n" if $debug_setup;
		my $e = $@;
		require OOPS::Setup;
		$oops->load_failure($e) || die $e;
		return new($pkg, %args);
	}

	if ($oops->{arraylen}{1} != $SCHEMA_VERSION) {
		my $schema_version = $oops->{arraylen}{1};
		die "schema version = '$schema_version'" unless $schema_version =~ /\A\d+\z/;
		if ($oops->{args}{auto_upgrade} || $ENV{OOPS_UPGRADE}) {
			$dbo->disconnect();
			require "OOPS/Upgrade/To$SCHEMA_VERSION.pm";
			no strict qw(refs);
			&{"OOPS::Upgrade::To${SCHEMA_VERSION}::upgrade"}($schema_version, %{$oops->{args}});
			return new($pkg, %args);
		} else {
			$dbo->disconnect();
			require "OOPS/OOPS$schema_version.pm"
				|| die "could not find historical version $schema_version: $@";
			no strict qw(refs);
			return &{"OOPS::OOPS${schema_version}::new"}("OOPS::OOPS$schema_version", %{$oops->{args}});
		}
	}

	$oopses++;
	print "CREATE OOPS $oops [$oopses]\n" if $debug_free_tied;
	$tiedvars{$oops} = longmess if $debug_tiedvars;
	lock_keys(%$oops);
	assertions($oops);

	return $oops if $args{no_front_end};
	return OOPS::FrontEnd->new($oops);
}

sub dbms
{
	return OOPS::DBO::dbms(@_);
}

sub dbiconnect
{
	return OOPS::DBO::dbiconnect(@_);
}

sub dboconnect
{
	return OOPS::DBO::dboconnect(@_);
}

sub errstr
{
	my $oops = shift;
	return $oops->{dbo}->errstr;
}

sub dbo
{
	my $oops = shift;
	return $oops->{dbo};
}

sub query
{
	my $oops = shift;
	return $oops->{dbo}->query(@_);
}

sub initial_setup
{
	require OOPS::Setup;
	goto &initial_setup_real;
}

sub load_object
{
	my ($oops, $objectid) = @_;
	confess unless $oops->isa('OOPS');  # XX why?
	$objectid = $oops->{named_objects}->{$objectid}
		if $objectid == 0;
	confess unless $objectid;
	confess if ref $objectid;

	print Carp::longmess("DEBUG: load_object($objectid) called") if $debug_load_context;

	if (exists $oops->{cache}{$objectid}) {
		print "*$objectid load_object is cached: $qval{$oops->{cache}{$objectid}}\n" if $debug_load_object || $debug_cache;
		return $oops->{cache}{$objectid};
	}

	print "load_object($objectid) from $caller{0}\n" if $debug_load_object && ! $debug_load_context;

	my $objectsetQ = $oops->query('objectset', execute => $objectid);

	my $atloadgroup;

	my $cache = $oops->{cache};
	my $type = $oops->{otype};

	my $refcount = $oops->{refcount};
	my $oloadgroup = $oops->{loadgroup};
	my $oclass = $oops->{class};
	my $refcopy = $oops->{refcopy};
	my $memory = $oops->{memory};
	my $memory2key = $oops->{memory2key};

#print "load_object $objectid.  Already cached: ".join(' ',keys %$cache).".\n";

	#
	# We may bail out of this early if it's a virtual object so we can't
	# add anything to $oops->{cache} yet.
	#
	my %newptype;
	my %new;
	my ($object, $loadgroup, $class, $otype, $virtual, $reftarg, $arraylen, $references, $ocounter, $gcgen);
	while (($object, $loadgroup, $class, $otype, $virtual, $reftarg, undef, $arraylen, $references, $ocounter, $gcgen) = $objectsetQ->fetchrow_array()) {
		if (exists $cache->{$object}) {
			print "skipping $otype $object $loadgroup $class -- already cached\n" if $debug_load_values || $debug_cache;
			next;
		}
		if ($virtual eq 'V') {
			if ($object == $objectid) {
				die "internal error: virtual objects should not share load groups" if $atloadgroup;
				$objectsetQ->finish();
				return $oops->load_virtual_object($objectid);
			} else {
				die "internal error: virtual objects should not be object loadgroup members";
			}
		}
		die unless $loadgroup;
		$atloadgroup = $loadgroup;
		$oops->{groupset}{$atloadgroup}{$object} = 1;
		$oops->{objverdebug}{$object} = $ocounter;
		$oops->{refdebug}{$object} = $references;
		$refcount->{$object} = $references;
		print "load *$object loadgroup:$loadgroup class:$class otype:$otype refcount:$references virtual:$virtual reftarg:$reftarg arraylen:$arraylen\n" if $debug_load_values || $debug_arraylen || $debug_refcount;
		if ($otype eq 'H') {
			$new{$object} = {};
			$cache->{$object} = {};
			print "*$object load_object cache := fresh empty hash: $qval{$cache->{$object}}\n" if $debug_cache;
		} elsif ($otype eq 'A') {
			$new{$object} = $cache->{$object} = [];
			$#{$cache->{$object}} = $arraylen-1;
			$oops->{objtouched}{$object} = 'untied array';
			print "*$object load_object cache := fresh array: $qval{$cache->{$object}}\n" if $debug_cache;
			print "in load_object, *$object is always touched 'cause it's an array\n" if $debug_touched;
		} elsif ($otype eq 'S') {
			my $x;
			$cache->{$object} = \$x;
			print "*$object load_object cache := fresh scalar: $qval{$cache->{$object}}\n" if $debug_cache;
		} else {
			confess;
		}
		$oops->{arraylen}{$object} = $arraylen;
		$oops->{reftarg}{$object} = $reftarg;
		$oops->{virtual}{$object} = $virtual;

		print "*$object loaded gcgen = $gcgen\n" if $debug_gcgeneration;
		$oops->{gcgeneration}{$object} = $gcgen;

		$type->{$object} = $otype;
		$newptype{$object} = {};
		$oloadgroup->{$object} = $loadgroup;
		print "in load_object, *$object loadgroup = $loadgroup\n" if $debug_load_group;
		$oclass->{$object} = $class;
		$oops->{loaded}++;
	}

		
	confess "object *$objectid not found in database" unless $cache->{$objectid};

	my @references;
	my ($id, $pkey, $pval, $ptype);
	if ($atloadgroup) {
		#
		# we are loading the attributes for a whole loadgroup of objects
		#
		print "load loadgroup: $atloadgroup\n" if $debug_load_values;
		my $objectgrouploadQ = $oops->query('objectgroupload', execute => $atloadgroup);
		no warnings;
		local($objectgrouploadQ->{HandleError}) = undef;
		local($objectgrouploadQ->{RaiseError}) = 0;
		use warnings;
		for (;;) {
			while(($id, $pkey, $pval, $ptype) = $objectgrouploadQ->fetchrow_array) {
				next unless exists $newptype{$id};  # need something that is set on new objects only
				#
				# $t is the type of object we're loading
				# $ptype is the type of attribute we're loading
				#
				my $t = $type->{$id};  
				print "$typesymbol{$t}$id/$pkey = '$pval' (ptype $ptype)\n" if $debug_load_values && defined $pval;
				print "$typesymbol{$t}$id/$pkey = undef (ptype $ptype)\n" if $debug_load_values && ! defined $pval;
				my $ref;
				if ($t eq 'H') {
					$new{$id}{$pkey} = $pval;
				} elsif ($t eq 'A') {
					if ($ptype eq '0') {
						$cache->{$id}[$pkey] = $pval;
						$oops->{oldvalue}{$id}{$pkey} = $pval;
					} elsif ($ptype eq 'R') {
						#
						# Even if this object is already in memory, tie it so that we
						# can track if the linkage is used.
						#
						$cache->{$id}[$pkey] = undef;
						print "TIE *${id}[$pkey] OOPS::ObjectInArray object=*$pval\n" if $debug_tie;
						tie $cache->{$id}[$pkey], 'OOPS::ObjectInArray', $id, $pkey, $pval, $oops;
						$oops->{oldobject}{$id}{$pkey} = $pval;
						print "OLDOBJECT loadobject *$id/$pkey = *$pval (in array)\n" if $debug_oldobject
					} elsif ($ptype eq 'B') {
						$cache->{$id}[$pkey] = $pval;
						print "TIE *${id}[$pkey] OOPS::BigInArray cksum=$pval\n" if $debug_tie;
						tie $cache->{$id}[$pkey], 'OOPS::BigInArray', $id, $pkey, $pval, $oops;
						$oops->{oldbig}{$id}{$pkey} = $pval;
					} else {
						confess "ptype = $ptype";
					}
					$ref = \$cache->{$id}[$pkey];
				} elsif ($t eq 'S') {
					next if $pkey eq $id; # see write_ref()
					if ($pkey eq $nopkey) {
						my $x;
						$cache->{$id} = \$x;
						print "*$object load_object cache := new fresh scalar: $qval{$cache->{$object}}\n" if $debug_cache;
						if ($ptype eq 'R') {
							print "\$*$id = *$pval -- RefObject\n" if $debug_refalias && defined($pval);
							print "TIE \$*$id OOPS::RefObject object=*$pval\n" if $debug_tie;
							tie ${$cache->{$id}}, 'OOPS::RefObject', $oops, $id, $pval;
						} elsif ($ptype eq 'B') {
							print "\$*$id = '$pval...' -- RefBig\n" if $debug_refalias && defined($pval);
							print "TIE \$*$id OOPS::RefBig val='$pval'\n" if $debug_tie;
							tie ${$cache->{$id}}, 'OOPS::RefBig', $oops, $id, $pval;
						} elsif ($ptype eq '0') {
							$oops->{objtouched}{$id} = 'untied reference';
							$oops->{oldvalue}{$id}{$nopkey} = $pval;
							$x = $pval;
							print "\$*$id = '$pval' -- no tie at all\n" if $debug_refalias && defined($pval);
							print "\$*$id = undef -- no tie at all\n" if $debug_refalias && ! defined($pval);
						} else {
							confess;
						}
#					} elsif (exists $cache->{$pkey}
#						&& ! exists $new{$pkey} 
#						&& defined $pval 
#						&& reftype($cache->{$pkey}) eq 'HASH'
#						&& (my $tied = tied(%{$cache->{$pkey}})))
#					{
#						#
#						# A reference to a tied has that's already loaded.  
#						# we need to fast-path this because we might be being called
#						# during a hash's SAVE_SELF() and the hash key may already
#						# be deleted.
#						#
#						$cache->{$id} = $tied->GETREFORIG($pval);
#						$oops->{oldalias}{$id} = [ $pkey, $pval ];
#						$oops->{aliasdest}{$pkey}{$id} = $pval;
#						$oops->{unwatched}{$id} = 1;
#						print "\$*$id load_object cache = untied reference to *$pkey/'$pval' ($qval{$cache->{$id}})\n" if $debug_refalias || $debug_cache;
					} else {
						print "\$*$id = '$pval' -- RefAlias to $pkey/'$pval'\n" if $debug_refalias && defined($pval);
						print "TIE \$*$id OOPS::RefAlias target=*$pkey/'$pval' ($qval{$cache->{$id}})\n" if $debug_tie;
						tie $cache->{$id}, 'OOPS::RefAlias', $oops, $id, $pkey, $pval;
						$oops->{aliasdest}{$pkey}{$id} = $pval;
					}
				} else {
					confess;
				}
				#
				# 
				#
				$newptype{$id}{$pkey} = $ptype
					if $ptype;
				if ($ref) {
					$refcopy->{$id}{$pkey} = $ref;
					my $m = refaddr($ref);
					print "MEMORY2KEY $m := *$id/'$pkey' in load_object\n" if $debug_memory;
					$oops->memory2key($ref, $id, $pkey);
				}
			}
			if ($objectgrouploadQ->err) {
				if ($objectgrouploadQ->errstr() =~ /fetch\(\) without execute\(\)/) {
					warn "working around DBI bug"; # debug
					$objectgrouploadQ->execute($atloadgroup) || confess $objectgrouploadQ->errstr;
					$dbi_bug_workaround_count_debug++; 
					next;
				} else {
					confess "fetch_array error ".$objectgrouploadQ->errstr;
				}
			}
			last;
		}
		# $objectgrouploadQ->finish();
	} else {
		confess "no loadgroup!";
	}

	my @cblist;
	my @reflist;
	for my $id (keys %newptype) {
#		unless ($typesymbol{$oclass->{$id}}) {
#print "WILL BLESS $id as $oclass->{$id}\n";
#			bless $cache->{$id}, $oclass->{$id};
#			print "*$id load_object BLESS $qval{$cache->{$id}} at ".__LINE__."\n"  if $debug_blessing || $debug_cache;
#		}
#		print "$typesymbol{$type->{$id}}$id is $oclass->{$id}\n" if $debug_load_values;
confess if $oclass->{$id} eq 'OOPS';
		if ($type->{$id} eq 'H') {
			print "\%$id loaded - $qval{$cache->{$id}}\n" if $debug_load_object;
			# tied hashes cannot access the underlying variable during callbacks
			print "TIE %$id OOPS::NormalHash\n" if $debug_tie;
			my $tied = tie %{$cache->{$id}}, 'OOPS::NormalHash', $new{$id}, $newptype{$id}, $oops, $id;
			$oops->memory($tied, $id);
			print "MEMORY(TIED) ".refaddr($tied)." := *$id' - tied hash, in load_object\n" if $debug_memory;
			$oops->memory($cache->{$id}, $id);
			print "MEMORY $qaddr{$cache->{$id}} := *$id - hash, in load_object\n" if $debug_memory;
		} elsif ($type->{$id} eq 'A') {
			print "\@$id loaded - $qval{$cache->{$id}}\n" if $debug_load_object;
			# tied arrays are buggy so we're not using them.
			$oops->memory($cache->{$id}, $id);
			print "MEMORY $qval{$cache->{$id}} := *$id - array, in load_object\n" if $debug_memory;
		} elsif ($type->{$id} eq 'S') {
			#
			# Do these later so that when you FETCH a RefAlias you don't deadlock.  Does
			# this really solve the problem?  What about references to references?
			#
			push(@reflist, $id);
		} else {
			confess;
		}
		print "in load_object, $typesymbol{$type->{$id}} *$id loaded, refcount (=$refcount->{$id})\n" if $debug_refcount;
#		push(@cblist, $id) 
#			if ! $typesymbol{$oclass->{$id}}
#				&& $cache->{$id}->can('postload');
	}
	for my $id (@reflist) {
		my $a = refaddr($cache->{$id});
		if (exists $memory->{$a}) {
			if ($memory->{$a} > $id) {
				$oops->memory2key($cache->{$id}, $id, $nopkey);
				$oops->memory($cache->{$id}, $id);
				print "MEMORY $a := *$id - NEW LEAD REF, in load_object\n" if $debug_memory;
				print "MEMORY2KEY $a := *$id - joining refs, in load_object\n" if $debug_memory;
			} elsif (defined $memory2key->{$a}) {
				print "MEMORY2KEY $a already exists... *$memory2key->{$a}\n" if $debug_memory;
			} else {
				$oops->memory2key($cache->{$id}, $memory->{$a}, $nopkey);
				print "MEMORY2KEY $a := *$id - REFS NOW JOINED, in load_object\n" if $debug_memory;
			}
		} else {
			$oops->memory($cache->{$id}, $id);
			print "MEMORY $qval{$cache->{$id}} := *$id - ref, in load_object\n" if $debug_memory;
		}
		# $memory->{refaddr(\$cache->{$a})} = $id;
		# print "MEMORY $qval{\$cache->{$a}} := *$id REF to CACHE\n" if $debug_memory;
	}
	for my $id (keys %newptype) {
		unless ($typesymbol{$oclass->{$id}}) {
			bless $cache->{$id}, $oclass->{$id};
			print "*$id load_object BLESS $qval{$cache->{$id}} at ".__LINE__."\n"  if $debug_blessing || $debug_cache;
		}
		print "$typesymbol{$type->{$id}}$id is $oclass->{$id}\n" if $debug_load_values;
		push(@cblist, $id) 
			if ! $typesymbol{$oclass->{$id}}
				&& $cache->{$id}->can('postload');
	}
	while (@cblist) {
		my $id = shift @cblist;
		my $obj = $cache->{$id};
		$obj->postload($id);
	}
	print "*$objectid load_object finished: $qval{$cache->{$objectid}}\n" if $debug_load_values;
	assertions($oops);
	return $cache->{$objectid};
}

sub load_virtual_object
{
	my ($oops, $objectid) = @_;

	$objectid = $oops->{named_objects}{$objectid}
		if $objectid == 0;
	confess unless $objectid;

	my $objectinfoQ = $oops->query('objectinfo', execute => $objectid) || die $oops->errstr;
	my (undef, $loadgroup, $class, $otype, $virtual, $reftarg, $reserved, $arraylen, $refs, undef, $gcgen) = $objectinfoQ->fetchrow_array();
	die "no object $objectid: ".$objectinfoQ->errstr unless $otype;
	$objectinfoQ->finish();

	my %underlying;
	my $obj = \%underlying;
	bless $obj, $class unless $typesymbol{$class};
	print "*$objectid BLESSED $obj at ".__LINE__."\n" if $debug_blessing;
	print "TIE %$objectid OOPS::DemandHash\n" if $debug_tie;
	my $tied = tie %$obj, 'OOPS::DemandHash', $oops, $objectid;
	$oops->{virtual}{$objectid} = 'V';
	$oops->{arraylen}{$objectid} = $arraylen;
	$oops->{reftarg}{$objectid} = $reftarg;
	print "new object *$objectid, arraylen = 0\n" if $debug_arraylen;
	$oops->{otype}{$objectid} = 'H';
	$oops->{class}{$objectid} = $class;
	$oops->{loadgroup}{$objectid} = $objectid;
	$oops->{cache}{$objectid} = $obj;
	$oops->{refcount}{$objectid} = $refs;
	$oops->{gcgeneration}{$objectid} = $gcgen;
	print "VH$objectid loaded gcgen = $gcgen\n" if $debug_gcgeneration;
	$oops->memory($obj, $objectid);
	$oops->memory($tied, $objectid);
	print "MEMORY $qval{$obj} := *$objectid' - in load_virtual_object\n" if $debug_memory;
	print "MEMORY(TIED) $qval{$tied} := *$objectid' - in load_virtual_object\n" if $debug_memory;
	$oops->{groupset}{$objectid}{$objectid} = 1;
	print "in load_virtual_object, V% *$objectid loaded, refcount=$refs\n" if $debug_refcount || $debug_load_object;
	assertions($oops);
	return $obj;
}

sub process_deferred_virtualize
{
	my ($oops) = @_;
	for my $obj (values %{$oops->{virtualize}}) {
		next unless defined $obj; # it's a weak reference
		my $id = $oops->get_object_id($obj);
		$oops->virtual_object($id, 1);
	}
}

sub virtual_object
{
	my ($oops, $obj, $newval) = @_;

	my $id;
	if (ref($obj)) {
		my $mem = refaddr($obj);
		$id = $oops->{memory}{$mem};
		unless ($id) {
			# defer virtualization until later
			my $old = exists $oops->{virtualize}{$mem};
			if (@_ > 2) {
				if ($newval) {
					$oops->{virtualize}{$mem} = $obj;
					weaken($oops->{virtualize}{$mem});
				} else {
					delete $oops->{virtualize}{$mem};
				}
			}
			return $old;
		}
	} else {
		$id = $obj;
	}

	croak unless $oops->{otype}{$id};

	my $old = $oops->{virtual}{$id} eq 'V';
	print "*$id - virtual_object($newval)\n" if $debug_load_group;
	if (@_ > 2) {
		if ($newval) {
			unless ($oops->{virtual}{$id} eq 'V') {
				$oops->{virtual}{$id} = 'V';

				# break apart old load group
				my $olg = $oops->{loadgroup}{$id};
				print "in virtual_object($id), must break apart '$olg'\n" if $debug_load_group;
				for my $o (keys %{$oops->{groupset}{$olg}}) {
					print "in virtual_object($id) setting new group for *$o\n" if $debug_load_group;
					print "in virtual_object, *$id forcesave\n" if $debug_forcesave;
					$oops->{loadgroup}{$o} = $o;
					$oops->{forcesave}{$o} = __LINE__;
				}
			}
		} else {
			$oops->{virtual}{$id} = '0';
		}
		$oops->{forcesave}{$id} = 
			sprintf("%d/%d/%d", __LINE__, (caller(1))[2], (caller(2))[2]); my $x = # debug
			__LINE__;
		print "in virtual_object, forcesave *$id virtual=$newval\n" if $debug_forcesave;
		print "%$id - virtual: $newval.\n" if $debug_isvirtual;
	}
	assertions($oops);
	return $old;
}

sub lock {
	my ($oops, $thing) = @_;
	croak "lock() requires a reference" unless ref($thing);
	my $mem = refaddr($thing);
	if ((my $r = $oops->{memory2key}{$mem})) {
		my ($id, $key) = @$r;
		return $oops->{dbo}->lock_attribute($id, $key);
	}
	if ((my $id = $oops->{memory}{$mem})) {
		
		return $oops->{dbo}->lock_object($id);
	}
	if ((my ($tiedaddr, $key) = tied_hash_reference($_[0]))) {
		my $id = $oops->{memory}{$tiedaddr} || $oops->{new_memory}{$tiedaddr};
		return 0 unless $id;
		return $oops->{dbo}->lock_attribute($id, $key);
	}
	return 0;
}


# clears only safe parts of the cache
sub clear_cache
{
	my ($oops) = @_;
	for my $obj (@{$oops->{vcache}}) {
		$obj->CLEAR_CACHE();
	}
}

sub transaction
{
	shift if ref $_[0] ne 'CODE';
	my ($code, @args) = @_;
	local($transaction_tries) = 1;
	my $auto_die;
	for (;;) {
		croak "next or redo inside eval" if $auto_die; # protect aginst 'next' et all inside eval
		$auto_die = 1; 
		local(@transaction_rollback) = ();
		if (wantarray) {
			my @r;
			eval { @r = (&$code(@args)); };
			return @r unless $@;
		} else {
			my $r;
			eval { $r = &$code(@args); };
			return $r unless $@;
		};
		my $error = $@;
		for my $r (@transaction_rollback) {
			&$r($error);
		}
		if ($error =~ /($transfailrx)/) {
			croak "aborting transaction -- persistent deadlock: $1"
				if $transaction_tries++ > $transaction_maxtries;
			$auto_die = 0;
			require Time::HiRes;
			import Time::HiRes qw(sleep);
			if ($transaction_failure_sleep) {
				my $base = $transaction_failure_maxsleep ** (1 / $transaction_maxtries);
				my $sleeptime = rand($transaction_failure_sleep * $base ** ($transaction_tries-1));
				printf STDERR "Sleeping %.2f seconds, restarting transaction ($transaction_tries)\n", $sleeptime;
				sleep($sleeptime);
			} else {
				print STDERR "Restarting transaction ($transaction_tries)\n" if $warnings;
			}
			redo;
		}
		print STDERR "E='$error'\n";  # debug
		croak $error;
	}
	croak "last inside eval"; # protect aginst 'next' et all inside eval
}

#
# make a reference to a tied hash key
#
sub getref(\%$)
{
	my $hash = shift;
	my $key = shift;
	my $tied = tied %$hash;
	confess unless reftype($hash) eq 'HASH';
	return \$hash->{$key} unless $tied && $tied->can('GETREF');
	print "getref getting references for '$key'\n" if $debug_27555;
	return $tied->GETREF($key);
}

sub rollback
{
	my $oops = shift;
	$oops->{dbo}->rollback();
	$oops->DESTROY();
}

sub commit
{
	my $oops = shift;
	die if $oops->{readonly};
	$oops->save;
	my $x = int(rand($debug_tdelay)); if ($debug_tdelay && $debug_dbidelay) { for (my $i = 0; $i < $x; $i++) {} }
	$oops->{dbo}->commit || die $oops->errstr;
	print "COMMIT $oops done\n" if $debug_commit;
	assertions($oops);
}


#
# There are two parts to saving state: saving the objects and 
# saving the object attributes.
# 
# Rewrite: save all attributes before saving the objects.
#
# Object records will be re-written if:
#	$oops->{refmore}{$id} 
#	$oops->{refless}{$id} 
#	$oops->{forcesave}{$id} 
#
# Contents will be re-written if:
#	$oops->{unwatched}{$id} 
#	$oops->{objtouched}{$id} 
#	$oops->{demandwrite}{$id} 
# 

sub save
{
	my ($oops) = @_;

	confess "only one commit() allowed" if $oops->{commitdone}++;

	print "COMMIT start \@ $caller{1}\n" if $debug_commit;

	confess unless $oops->isa('OOPS');
	my $savedone = $oops->{savedone} = {};
	my $forcesave = $oops->{forcesave};

	my $cache = $oops->{cache};
	my $refcount = $oops->{refcount};
	my $oloadgroup = $oops->{loadgroup};
	my $type = $oops->{otype};
	my $oclass = $oops->{class};
	my $refmore = $oops->{refmore};
	my $refless = $oops->{refless};
	my $refstowrite = $oops->{refstowrite};
	my $loadgrouplock = $oops->{loadgrouplock};
	my $virtual = $oops->{virtual};
	my $arraylen = $oops->{arraylen};
	my $reftarg = $oops->{reftarg};
	my @tied;

	local($oops->{insave}) = 1;

	$oops->process_deferred_virtualize();

	# 
	# ARRAYs are always considered 'touched' and thus
	# must be rechecked.
	#
	# HASHes that have been DESTROYed are considered 'touched'
	#
	# NEW object are always touched
	#
	for my $id (keys %{$oops->{objtouched}}) {
		print "*$id->write_object (touched: $oops->{objtouched}{$id})\n" if $debug_commit;
		$oops->write_object($id);
	}

	#
	# tied HASHes (both sorts) that have been modified insert
	# themselves into the demandwrite set.
	#
	# As a side-effect of saving tied hashes, there may be additional
	# unwatched objects to save.
	#
	for my $id (keys %{$oops->{demandwrite}}) {
		print "*$id->write_object (demandwrite)\n" if $debug_commit;
		$oops->write_object($id);
		my $tied;
		my $t = $type->{$id};
		if ($t eq 'H') {
			$tied = tied %{$cache->{$id}};
		} elsif ($t eq 'A') {
			$tied = tied @{$cache->{$id}};
		} elsif ($t eq 'S') {
			$tied = tied ${$cache->{$id}};
		} else {
			confess "type = $t.";
		}
		push(@tied, $tied);
	}

	#
	# Some objects are not tied in any way and we just have to
	# check them to make sure they haven't changed.
	#
	for my $id (keys %{$oops->{unwatched}}) {
		print "*$id->write_object (unwatched)\n" if $debug_commit;
		$oops->write_object($id);
	}

	my %classdone;
	my $firstid;
	my $updateobjectQ = $oops->query('updateobject');
	my $objectinfoQ = $oops->query('objectinfo');
	my %done;
	my $pass;

	#
	# Look at objects and make adjustments while there
	# remains %refmore, %refless or @refstowrite.
	#
	for(;;) {
		# more refstowrite may be added while looking at refmore
		while (@$refstowrite) {
			$oops->write_ref(shift @$refstowrite);
		}

		# Do additions before subtractions so that we don't have
		# any false deletes.
		my $refchange;
		if (%{$oops->{refmore}}) {
			$refchange = $oops->{refmore};
			$oops->{refmore} = {};
		} elsif (%{$oops->{refless}}) {
			$refchange = $oops->{refless};
			$oops->{refless} = {};
		} else {
			last;
		}

		print "commit, pass $pass\n" if $debug_commit && $pass++;
		for my $id (keys %$refchange) {
			while (@$refstowrite) {
				$oops->write_ref(shift @$refstowrite);
			}
			if ($refchange->{$id}) {
				#
				# The reference count for $id needs to be changed.
				#
				if (exists $cache->{$id}) {
					#
					# Object is loaded.
					#
					printf "in commit, *%d refs: old %d + change %s (=%d)\n", $id, $refcount->{$id}, $qplusminus{$refchange->{$id}}, $refcount->{$id}+ $refchange->{$id} if $debug_refcount;
					my $newobject = ($refcount->{$id} == -1);
					$refcount->{$id} += $refchange->{$id};
					if ($oops->{refless}{$id} and $refcount->{$id} + $oops->{refless}{$id} > 0) {
						$refcount->{$id} += $oops->{refless}{$id};
						delete $oops->{refless}{$id};
					}
					if ($refcount->{$id} > 0) {
						my $otype = $type->{$id} || confess;
						my $loadgroup;
						if (exists $loadgrouplock->{$id}) {
							my $locked_to = $loadgrouplock->{$id};
							if (exists $refchange->{$locked_to}) {
								# 
								# they'll be saved together
								#
								$firstid ||= $id;
								$loadgroup ||= $firstid;
							} else {
								$loadgroup = $oloadgroup->{$locked_to};
							}
						} elsif ($virtual->{$id} eq 'V') {
							$loadgroup = $id;
						} else {
							$firstid ||= $id;
							$loadgroup ||= $firstid;
						}
						$oloadgroup->{$id} = $loadgroup;
						die if $oops->{deleted}{$id};  # assertion
						print "*$id updated1 (later). loadgroup=$loadgroup, class=$qref{$cache->{$id}} otype=$otype, virtual=$virtual->{$id} reftarg=$reftarg->{$id} refcount=$refcount->{$id} arraylen=$arraylen->{$id} gcgen=$oops->{gcgeneration}{$id}\n" if $debug_load_group || $debug_isvirtual || $debug_write_object || $debug_arraylen || $debug_refcount;
						$forcesave->{$id} = __LINE__;
						$oclass->{$id} = ref($cache->{$id});
						$classdone{$id} = __LINE__;
					} elsif ($refcount->{$id} == 0) {
						print "*$id - no refereces, will delete\n" if $debug_write_object || $debug_refcount;
#print "refcount *$id = 0, deleting\n";
						$oops->delete_object($id);
						$done{$id} = __LINE__;
					} else {
						confess "refcount: $refcount->{$id}";
					}
				} else {
					#
					# Object is not loaded, fetch the refcount.
					#
					# TODO/OPTIMIZATION: this may result in extra queries.  Cache the refcounts and
					# delay the writes the same way as is done for cached objects.
					#
					$objectinfoQ->execute($id) || confess;
					my (undef, $loadgroup, $class, $otype, $ovirtual, $oreftarg, undef, $oarraylen, $refs, $counter, $gcgen) = $objectinfoQ->fetchrow_array;
					$objectinfoQ->finish();
					confess unless $class;
					printf "in commit, uncached *%d refs: old %d +change %d = (=%d)\n", $id, $refs, $refchange->{$id}, $refs+ $refchange->{$id} if $debug_refcount || $debug_write_object;
					$refcount->{$id} = $refs + $refchange->{$id};
					if ($oops->{refless}{$id} and $refcount->{$id} + $oops->{refless}{$id} > 0) {
						$refcount->{$id} += $oops->{refless}{$id};
						delete $oops->{refless}{$id};
					}
					confess if exists $cache->{$id};
					if ($refcount->{$id} > 0) {
						die if $oops->{deleted}{$id}; # assertion
						$updateobjectQ->execute($loadgroup, $class, $otype, $ovirtual || '0', $oreftarg, $oarraylen, $refcount->{$id}, $gcgen, $id);
						print "*$id updated2. loadgroup=$loadgroup, type=$class, otype=$otype, refcount=$refcount->{$id} virtual=$ovirtual reftarg=$oreftarg arraylen=$oarraylen, gcgen=$gcgen\n" if $debug_load_group || $debug_write_object || $debug_arraylen || $debug_refcount || $debug_gcgeneration;
						$done{$id} = __LINE__;
					} elsif ($refcount->{$id} == 0) {
						$oops->delete_object($id);
						$done{$id} = __LINE__;
					} else {
						confess "refcount: $refcount->{$id}";
					}
				}
			} else {
				if ($refcount->{$id} > 0) {
					printf "*$id no change in refcount, marking for forced saving\n" if $debug_refcount || $debug_write_object;
					$forcesave->{$id} = __LINE__;
				} elsif ($refcount->{$id} == 0) {
					printf "in commit, deleting unchanged unreferenced $oops->{otype}{$id}*$id (=0)\n" if $debug_refcount || $debug_write_object;
					$oops->delete_object($id);
					$done{$id} = __LINE__;
				} else {
					confess "negative refcount: *$id: $refcount->{$id}";
				}
			}
		}
	}

	#
	# We have to manually scan for objects that have 
	# re-blessed themselves as there is no way to watch
	# for that.
	#
	for my $id (keys %$cache) {
		next unless defined $cache->{$id};
		next if exists($oclass->{$id}) && ref($cache->{$id}) eq $oclass->{$id};
		next if $classdone{$id};
		printf "classchange %d: %s -> %s.\n", $id, $oclass->{$id}, ref($cache->{$id}) if $debug_commit;
		$oclass->{$id} = ref($cache->{$id});
		$forcesave->{$id} = __LINE__
			unless $forcesave->{$id};
	}

	#
	# XX PARTIAL IMPLEMENTATION:
	# For database servers that use deadlock detection (rather
	# than opportunistic locking) we could force the object rows to
	# get updated whenever an attribute is added or deleted.  This
	# allows a less strict tranaction locking default.
	# 
	#
	my $die;
	for my $id (keys %$forcesave) {
		next if $done{$id};
		my $otype = $type->{$id} || confess 
			"at line $forcesave->{$id} (from $oops->{memsetdebug}{$id})... " .  # debug
			"no type for object $id";
		my $loadgroup = $oloadgroup->{$id} || $id;
		die if $oops->{deleted}{$id}; # assertion
		print "*$id updated3. loadgroup=$loadgroup, type=".ref($cache->{$id})." otype=$otype, refcount=$refcount->{$id} virtual=$virtual->{$id} reftarg=$reftarg arraylen=$arraylen->{$id} gcgen=$oops->{gcgeneration}{$id}\n" if $debug_load_group || $debug_write_object || $debug_arraylen || $debug_refcount || $debug_gcgeneration;
		$updateobjectQ->execute($loadgroup, ref($cache->{$id}), $otype, $virtual->{$id}, $reftarg->{$id}, $arraylen->{$id}, $refcount->{$id}, $oops->{gcgeneration}{$id}, $id)
			|| confess $updateobjectQ->errstr;
		$oclass->{$id} = ref($cache->{$id});
	}

	for my $tied (@tied) {
		$tied->POST_SAVE;
	}
	$oops->{forcesave} = {};
}

#
# This saves the contents of an object.  The object
# itself is updated in save().
#
sub write_object
{
	my ($oops, $id, $sponsoring_id) = @_;
	$id = $oops->get_object_id($id, $sponsoring_id) 
		if ref $id; 

	return if $oops->{savedone}{$id}++; 

	print Carp::longmess("DEBUG: write_object(@_) called") if $debug_write_object_context;

	my $obj = $oops->{cache}{$id};
	my $type = $perltype2otype{reftype($obj)} || confess;

	my $sym = $typesymbol{$type} || '???' if $debug_write_object;
	print "$sym*$id write_object $qval{$obj}\n" if $debug_write_object;

	my $memory = $oops->{memory};

# would this help?
#	if ($oops->{class}{$id} ne ref $obj) {
#		$oops->{refcount}{$id} += 0;   # touchit
#	}

	if ($type eq 'H') {
		my $tied = tied(%$obj);
		if ($tied && $tied =~ /^OOPS/) {
			print "%*$id write_object - using SAVE_SELF $qval{$tied}\n" if $debug_write_hash;
			$tied->SAVE_SELF();
		} else {
			$oops->write_hash($obj, $id);
		}
	} elsif ($type eq 'A') {
		$oops->write_array($id);
	} elsif ($type eq 'S') {
		my $tied = tied($$obj);
		if ($tied && $tied =~ /^OOPS/) {
			print "\$*$id using SAVE_SELF $tied\n" if $debug_write_ref;
			$tied->SAVE_SELF() && push(@{$oops->{refstowrite}}, $id);
		} else {
			print "\$*$id will use write_ref later\n" if $debug_write_ref;
			if (ref $$obj) {
				my $m;
				if ($m = $memory->{refaddr($$obj)}) {
					print "lookup MEMORY($qval{$$obj}) = $m in write_object - ref\n" if $debug_memory;
					print "\$*$id is an existing object *$m\n" if $debug_write_ref;
				} else {
					print "lookup MEMORY($qval{$$obj}) = ? in write_object - ref\n" if $debug_memory;
					$m = $oops->get_object_id($$obj, $id);
					print "\$*$id is a new object *$m: $qval{$$obj}\n" if $debug_write_ref;
				}
				$oops->write_object($m, $id);
			} else {
				print "\$*$id is a ref to a scalar $qval{$$obj}\n" if $debug_write_ref;
			}
			push(@{$oops->{refstowrite}}, $id);
		}
	} else {
		confess;
	}
	print "$sym*$id done with write_object\n" if $debug_write_object;
	assertions($oops);
}

sub write_hash
{
	my ($oops, $obj, $id, $ptypes, $added) = @_;

	print Carp::longmess("DEBUG: write_hash(@_) called") if 0; # debug

	my $oldvalue = $oops->{oldvalue};
	my $oldobject = $oops->{oldobject};
	my $oldbig = $oops->{oldbig};
	my $memory = $oops->{memory};
	my $memory2key = $oops->{memory2key};
	my $new_memory = $oops->{new_memory};
	my $new_memory2key = $oops->{new_memory2key};
	my $tied = tied %{$oops->{cache}{$id}};

	confess unless ref $obj;

	my (@k) = keys %$obj;

#
# auto-virtualize.  Good idea?
#
#	if (@k > $demandthreshold && ! exists($oops->{loadvirtual}{$id})) {
#		$oops->virtual_object($id, 1)
#	} elsif (@k < $demandthreshold && exists($oops->{loadvirtual}{$id})) {
#		$oops->virtual_object($id, 0)
#	}

	for my $pkey (@k) {
		unless ($tied) {
			my $m = refaddr(\$obj->{$pkey});
			$oops->new_memory2key(\$obj->{$pkey}, $id, $pkey);
			print "NEWMEMORY2KEY ".$m." := \%*$id/'$pkey' - in write_hash\n" if $debug_memory;
		}
		{ no warnings; print "\%$id/$qval{$pkey} pondering... ($qval{$obj->{$pkey}})\n" if $debug_write_hash; }
		print "ref to \%$id/$qval{$pkey} is $qval{\$obj->{$pkey}}\n" if $debug_write_hash && $debug_refalias;
		if ($ptypes && exists $ptypes->{$pkey}) {
			print "\%$id/$pkey ...still not loaded ($ptypes->{$pkey})\n" if $debug_write_hash;
		} elsif (exists $oldvalue->{$id} && exists $oldvalue->{$id}{$pkey}) {
			no warnings;
			if ($oldvalue->{$id}{$pkey} eq $obj->{$pkey} 
				&& defined($oldvalue->{$id}{$pkey}) == defined($obj->{$pkey})
				&& ref($oldvalue->{$id}{$pkey}) eq ref($obj->{$pkey})) 
			{
				use warnings;
				print "\%$id/$pkey ...unchanged\n" if $debug_write_hash;
				print "lookup MEMORY($qval{$obj->{$pkey}}) in write_hash\n" if $debug_memory;
				$oops->write_object($memory->{refaddr($obj->{$pkey})}, $id)
					if ref $obj->{$pkey};
			} else {
				use warnings;
				{ no warnings; print "\%$id/$pkey ...changed.  old value was $oldvalue->{$id}{$pkey}\n" if $debug_write_hash; }
				$oops->update_attribute($id, $pkey, $obj->{$pkey}, undef, $oldvalue->{$id}{$pkey});
			}
		} elsif (exists $oldbig->{$id} && exists $oldbig->{$id}{$pkey}) {
			my $ock = ref($obj->{$pkey}) ? '' : bigcksum($obj->{$pkey});
			if ($oldbig->{$id}{$pkey} eq $ock) {
				print "\%$id/$pkey ...unchanged (big)\n" if $debug_write_hash;
				# this attribute is unchanged
			} else {
				print "\%$id/$pkey ...changed.  old big\n" if $debug_write_hash;
				$oops->update_attribute($id, $pkey, $obj->{$pkey}, $ock);
			}
		} elsif (exists $oldobject->{$id} && exists $oldobject->{$id}{$pkey}) {
			# this used to be an object
			print "\%$id/$pkey this used to be an object...\n" if $debug_write_hash;
			if (ref $obj->{$pkey} && $oldobject->{$id}{$pkey} == $oops->get_object_id($obj->{$pkey}, $id)) {
				# no change
				print "\%$id/$pkey same one\n" if $debug_write_hash;
				$oops->write_object($oldobject->{$id}{$pkey}, $id);
			} else {
				print "\%$id/$pkey changed to $qval{$obj->{$pkey}}\n" if $debug_write_hash;
				$oops->update_attribute($id, $pkey, $obj->{$pkey});
			}
		} elsif ($added) { 
			if (exists $added->{$pkey}) {
				# this is a new value
				{ no warnings; print "\%$id/$pkey ...added: $qval{$obj->{$pkey}}\n" if $debug_write_hash; }
				$oops->insert_attribute($id, $pkey, undef, $obj->{$pkey});
			} else {
				{ no warnings; print "\%$id/$pkey ...still original value: $qval{$obj->{$pkey}}\n" if $debug_write_hash; }
			}
		} else {
			# this is a new value
			print "\%$id/$pkey ...new value A\n" if $debug_write_hash;
			$oops->insert_attribute($id, $pkey, undef, $obj->{$pkey});
		}
	}
	if (exists $oldvalue->{$id}) {
		print "\%$id checking old values\n" if $debug_write_hash;
		for my $pkey (keys %{$oldvalue->{$id}}) {
			next if exists $obj->{$pkey};
			# this pkey has gone away
			{ no warnings; print "\%$id/$pkey delete extra old value \%$id/$pkey ($oldvalue->{$id}{$pkey})\n" if $debug_write_hash; };
			$oops->delete_attribute($id, $pkey, $oldvalue->{$id}{$pkey});
		}
	}
	if (exists $oldobject->{$id}) {
		print "\%$id checking old objects\n" if $debug_write_hash;
		for my $pkey (keys %{$oldobject->{$id}}) {
			next if exists $obj->{$pkey};
			next if exists $oldvalue->{$id} && exists $oldvalue->{$id}{$pkey};
			# this pkey has gone away
			print "\%$id/$pkey delete extra old object \%$id/$pkey ($oldvalue->{$id}{$pkey})\n" if $debug_write_hash;
			$oops->delete_attribute($id, $pkey);
		}
	}
	if (exists $oldbig->{$id}) {
		for my $pkey (keys %{$oldbig->{$id}}) {
			next if exists $obj->{$pkey};
			next if exists $oldvalue->{$id} && exists $oldvalue->{$id}{$pkey};
			print "\%$id/$pkey delete extra old big \%$id/$pkey\n" if $debug_write_hash;
			$oops->delete_attribute($id, $pkey);
		}
	}
	assertions($oops);
}

sub write_array
{
	my ($oops, $id) = @_;

	my $obj = $oops->{cache}{$id};

	my $sym = '@' if $debug_write_object || $debug_write_array;
	print "$sym$id write_object $obj\n" if $debug_write_object;

	my $oldvalue = $oops->{oldvalue};
	my $oldobject = $oops->{oldobject};
	my $oldbig = $oops->{oldbig};
	my $memory = $oops->{memory};
	my $new_memory = $oops->{new_memory};
	my $new_memory2key = $oops->{new_memory2key};

	my $tied;
	my $isnew = $oops->{refcount}{$id} == -1;


	#print "WRITE ARRAY ".__LINE__." with $#$obj\n";
	#print join('',(map { exists $obj->[$_] ? '1' : '0' } 0..$#$obj),"\n");

	#
	# XXXTODO
	# There is a nasty problem: splice, shift, pop, unshift, and push can
	# move around array elements without causing big elements to be 
	# loaded.  When it comes time to save these moved elements, we have to
	# still have access to the old values.  Doing the save in exactly the
	# right order could allow the values to be shifted in the database rather
	# than read and re-written.  
	#
	# With refcopy we should be able to handle this now!
	#
	for (my $index = 0; $index <= $#$obj; $index++) {
		my $tied;
		next unless exists $obj->[$index];
		next unless ($tied = tied $obj->[$index]) && $tied->isa('OOPS::BigInArray');
		undef $tied; # keeping copies of tied objects prevents untieing.
		my $x = defined($obj->[$index]);   # force loading (which will untie)
	}

	my $end = $#$obj;
	$end = $oops->{arraylen}{$id} -1
		if defined($oops->{arraylen}{$id}) && $oops->{arraylen}{$id} > $end;
	print "$sym$id checking 0..$end ($#$obj/$oops->{arraylen}{$id}) \n" if $debug_write_array;

	for (my $index = 0; $index <= $end; $index++) {
		if (! exists $obj->[$index]) {
			if (exists $oldvalue->{$id} && exists $oldvalue->{$id}{$index}) {
				print "$sym$id/$index ...deleting extra old value ($oldvalue->{$id}{$index})\n" if $debug_write_array;
				$oops->delete_attribute($id, $index, $oldvalue->{$id}{$index});
			} elsif (exists $oldobject->{$id} && exists $oldobject->{$id}{$index}) {
				print "$sym$id/$index ...deleting extra old object ($oldobject->{$id}{$index})\n" if $debug_write_array;
				$oops->delete_attribute($id, $index);
			} elsif (exists $oldbig->{$id} && exists $oldbig->{$id}{$index}) {
				print "$sym$id/$index ...deleting extra old big ($oldbig->{$id}{$index})\n" if $debug_write_array;
				$oops->delete_attribute($id, $index);
			} else {
				print "$sym$id/$index no value now, now value before\n" if $debug_write_array;
			}
			next;
		}
		print "$sym$id/$index pondering... ($obj->[$index])\n" if $debug_write_array;
		my $tied;
		if (($tied = tied $obj->[$index]) && $tied =~ /^OOPS::Demand/ && ! $tied->changed($index)) {
			print "\@$id/$index tied and unchanged\n" if $debug_write_array;
		} elsif (exists $oldvalue->{$id} && exists $oldvalue->{$id}{$index}) {
			no warnings;
			if ($oldvalue->{$id}{$index} eq $obj->[$index] 
				&& defined($oldvalue->{$id}{$index}) == defined($obj->[$index])
				&& ref($oldvalue->{$id}{$index}) eq ref($obj->[$index]))
			{
				use warnings;
				print "$sym$id/$index ...reference - no change\n" if $debug_write_array;
				print "lookup MEMORY($qval{$obj->[$index]}) in write_object - array\n" if $debug_memory && ref($obj->[$index]);
				$oops->write_object($memory->{refaddr($obj->[$index])}, $id)
					if ref $obj->[$index];
				next;
			} else {
				use warnings;
				# this attribute's value has changed
				print "$sym$id/$index ...changed from '$oldvalue->{$id}{$index}'\n" if $debug_write_array;
				$oops->update_attribute($id, $index, $obj->[$index], undef, $oldvalue->{$id}{$index});
			}
		} elsif (exists($oldobject->{$id}) && exists($oldobject->{$id}{$index})) {
			print "\@$id/$index this used to be an object: *$oldobject->{$id}{$index}\n" if $debug_write_array;
			if (ref $obj->[$index] && $oldobject->{$id}{$index} == $oops->get_object_id($obj->[$index], $id)) {
				print "\@$id/$index same one - no change\n" if $debug_write_array;
				$oops->write_object($oldobject->{$id}{$index}, $id);
				next;
			} else {
				print "\@$id/$index changed\n" if $debug_write_array;
				$oops->update_attribute($id, $index, $obj->[$index]);
			}
		} elsif ($bigcutoff && exists($oldbig->{$id}) && exists($oldbig->{$id}{$index})) {
			my $ock = (!ref($obj->[$index]) && defined($obj->[$index]) && length($obj->[$index]) > $bigcutoff)
				? bigcksum($obj->[$index])
				: undef;
			if ($ock && $oldbig->{$id}{$index} eq $ock) {
				print "$sym$id/$index ...big - no change\n" if $debug_write_array;
				next;
			} else {
				print "$sym$id/$index ...big changed\n" if $debug_write_array;
				$oops->update_attribute($id, $index, $obj->[$index], $ock);
			}
		} else {
			# this is a new value
			print "$sym$id/$index ...new value B\n" if $debug_write_array;
			$oops->insert_attribute($id, $index, undef, $obj->[$index]);
		}
		my $m = refaddr(\$obj->[$index]);
		$oops->new_memory2key(\$obj->[$index], $id, $index);
		print "NEWMEMORY2KEY ".$m." := \@*$id/$index - in write_object - array\n" if $debug_memory;
	}
	if (! defined($oops->{arraylen}{$id}) || $oops->{arraylen}{$id} != @$obj) {
		$oops->{arraylen}{$id} = @$obj;
		$oops->{forcesave}{$id} = __LINE__;
		print "in write_array, arraylen(\@*$id) = $oops->{arraylen}{$id}, forcesave\n" if $debug_arraylen || $debug_forcesave;
	} else {
		print "in write_array, leaving arraylen for \@*$id at $oops->{arraylen}{$id}\n" if $debug_arraylen;
	}
}

#
# References are always indirect through another
# object.  If the reference isn't indirect, then
# we pretend it is.
#
# 	ATTRIBUTE TABLE
# 	id		pkey		pvalue		ptype
#			targetid	targetkey
#
#	383		400		swarmy		0
#
#	384		384		'nopkey'	0
#	384		'nopkey'	a-value		0
#
#	385		384		'nopkey'	0
#
# Reference 383 is indirect though object 400: \%400{swarmy}
#
# Reference 384 is a ref to scalar.  It uses two rows.
#
# Reference 385	is a ref to scalar that is shared with another
# reference.
#
# The purpose of this schema is to allow queries against references
# without needing to know if the reference is to another object
# or not.
#
# Unlike other variable types, write_ref might be called multiple 
# times for the same scalar during a commit() because that scalar
# might have become disconnected.
#

sub write_ref
{
	my ($oops, $id) = @_;

	if ($oops->{deleted}{$id}) {
		print "*$id WRITE_REF - already deleted - ignoring\n" if $debug_write_ref;
		return;
	}

	my $obj = $oops->{cache}{$id};

	my $oldvalue = $oops->{oldvalue};
	my $oldobject = $oops->{oldobject};
	my $oldbig = $oops->{oldbig};
	my $memory = $oops->{memory};
	my $memory2key = $oops->{memory2key};
	my $new_memory = $oops->{new_memory};
	my $new_memory2key = $oops->{new_memory2key};
	my $oldalias = $oops->{oldalias};

	my $addr = refaddr($obj);
	my $sym;
	$sym = '$' if $debug_write_ref;

	print "\$*id WRITE_REF new value: $qval{$obj}\n" if $debug_write_ref;

	my $targetid;
	my $targetkey;
	my $targettiedmem;

	if (ref($$obj) && $addr == refaddr($$obj)) {
		# reference to self...
		($targetid, $targetkey) = ($nopkey, $obj);
	} elsif (exists $new_memory2key->{$addr} && $new_memory2key->{$addr}[0] != $id) {
		($targetid, $targetkey) = @{$new_memory2key->{$addr}};
		print "\$*$id WRITE_REF new_memory2key($qval{$obj}) says: *$targetid/$qval{$targetkey} \n" if $debug_write_ref || $debug_memory;
	} elsif (exists $memory2key->{$addr} && $memory2key->{$addr}[0] != $id) {
		($targetid, $targetkey) = @{$memory2key->{$addr}};
		no warnings;
		print "\$*$id WRITE_REF memory2key($qval{$obj}) says: *$targetid/$qval{$targetkey} \n" if $debug_write_ref || $debug_memory;
	} elsif (exists $new_memory->{$addr} && $memory->{$addr} != $id) {
		$targetid = $nopkey;
		$targetkey = $$obj;
		no warnings;
		print "\$*$id WRITE_REF new_memory($qval{$obj}) says: *$targetid/$qval{$targetkey} \n" if $debug_write_ref || $debug_memory;
	} elsif (exists $memory->{$addr} && $memory->{$addr} != $id) {
		$targetid = $nopkey;
		$targetkey = $$obj;
		print "\$*$id WRITE_REF memory($qval{$obj}) says: *$targetid/$qval{$targetkey} \n" if $debug_write_ref || $debug_memory;
	} elsif (($targettiedmem, $targetkey) = tied_hash_reference($obj)) {
		$targetid = $memory->{$targettiedmem} || $new_memory->{$targettiedmem};
		print "\$*$id WRITE_REF tied hash reference: $targetid/$qval{$targetkey}\n" if $debug_write_ref;
		no warnings;
		if (! $targetid) {
			use warnings;
			print "\$*$id WRITE_REF was disassociated, now *$nopkey/$qval{$$obj}\n" if $debug_write_ref;
			$targetkey = $$obj;
			$targetid = $nopkey;
			$oops->new_memory2key($obj, $id, $nopkey);
			print "NEWMEMORY2KEY ".$addr." = \%*$id/$nopkey - in write_ref\n" if $debug_memory;
		} elsif ($$obj ne $oops->{cache}{$targetid}{$targetkey}) {
			#
			# Must have been delete'd in the meantime and become
			# disassoicated from the cache.  Unfortunantly the refaddr()
			# for such references is unique so we must guess if they
			# should be rejoined.
			#
			# Ugh!
			#
			use warnings;
			if ($targetid && exists $oops->{disassociated}{$targetid}{$targetkey}{$$obj}) {
				print "\$*$id WRITE_REF was disassociated, joining to *$oops->{disassociated}{$targetid}{$targetkey}{$$obj}/$qval{$nopkey}\n" if $debug_write_ref;
				$targetid = $oops->{disassociated}{$targetid}{$targetkey}{$$obj};
				$targetkey = $nopkey;
			} else {
				$oops->{disassociated}{$targetid}{$targetkey}{$$obj} = $id;
				print "\$*$id WRITE_REF was disassociated, now *$nopkey/$qval{$$obj}\n" if $debug_write_ref;
				$targetkey = $$obj;
				$targetid = $nopkey;
				$oops->new_memory2key($obj, $id, $nopkey);
				print "NEWMEMORY2KEY ".$addr." = \%*$id/$nopkey - in write_ref\n" if $debug_memory;
			}
		}
	} else {
		# must be a reference to an independent scalar or object
		$targetid = $nopkey;
		$targetkey = $$obj;
		print "\$*$id WRITE_REF independent, now *$targetid/$qval{$targetkey}\n" if $debug_write_ref;
		$oops->new_memory2key($obj, $id, $nopkey);
		print "NEWMEMORY2KEY ".$addr." = \%*$id/$nopkey - in write_ref\n" if $debug_memory;
	}

	if (exists $oops->{deleted}{$targetid}) {
		print "\$*$id WRITE_REF now independent, now *$nopkey/$qval{$$obj} had been ref to $targetid/$qval{$targetkey} but *$targetid was deleted\n" if $debug_write_ref;
		$targetid = $nopkey;
		$targetkey = $$obj;
		$oops->new_memory2key($obj, $id, $nopkey);
		print "NEWMEMORY2KEY ".$addr." = \%*$id/$nopkey - in write_ref\n" if $debug_memory;
	}

	my ($oldid, $oldpkey, $oldval);
	my $ock;

	if (exists $oldalias->{$id}) {
		($oldid, $oldpkey) = @{$oldalias->{$id}};
		$oldval = $oldpkey;
		print "\$*$id WRITE_REF oldalias: *$oldid/$qval{$oldpkey} = $qval{$oldval}\n" if $debug_write_ref;
	} elsif (exists $oldvalue->{$id} && exists $oldvalue->{$id}{$nopkey}) {
		$oldid = $nopkey;
		$oldpkey = $oldvalue->{$id}{$nopkey};
		$oldval = $oldpkey;
		print "\$*$id WRITE_REF oldvalue: *$oldid/$qval{$oldpkey} = $qval{$oldval}\n" if $debug_write_ref;
	} elsif (exists $oldbig->{$id} && exists $oldbig->{$id}{$nopkey}) {
		$oldid = $nopkey;
		$oldpkey = $oldbig->{$id}{$nopkey};
		$ock = (!ref($$obj) && defined($$obj) && length($$obj) > $bigcutoff)
			? bigcksum($$obj)
			: undef;
		$targetkey = $ock if $ock && $oldbig->{$id}{$nopkey} eq $ock;
		print "\$*$id WRITE_REF oldbig: *$oldid/$qval{$oldpkey} = $qval{$oldval}\n" if $debug_write_ref;
	} elsif (exists $oldobject->{$id} && exists $oldobject->{$id}{$nopkey}) {
		$oldid = $nopkey;
		$oldpkey = $oldobject->{$id}{$nopkey};
		$oldval = $oops->{cache}{$oldpkey};
		print "\$*$id WRITE_REF oldobject: *$oldid/$qval{$oldpkey} = $qval{$oldval}\n" if $debug_write_ref;
	} else {
		print "\$*$id WRITE_REF no old value\n" if $debug_write_ref;
		$oldid = undef;
	}

	# confess if $targetid == $id && $targetkey ne $nopkey;  XXXX turn this on -- it's off for debugging

	confess unless defined $targetid;
	print "\$*$id WRITE_REF target:$targetid/$qval{$targetkey} old:$oldid/$qval{$oldpkey}\n" if $debug_write_ref && defined $oldid;
	print "\$*$id WRITE_REF target:$targetid/$qval{$targetkey} no old\n" if $debug_write_ref && ! defined $oldid;

	if ($targetid ne $nopkey && ! $oops->{reftarg}{$targetid}) {
		# this is presently irreversable 
		$oops->{reftarg}{$targetid} = 'T';
		$oops->{forcesave}{$targetid} = __LINE__;
		print "force save of *$targetid as its referended by *$id\n" if $debug_forcesave;
		print "*$targetid is now reference target (from $id)\n" if $debug_reftarget;
	}

	if (defined($oldid) && $targetid eq $oldid) {
		if (defined($targetkey) ? (defined($oldpkey) ? $targetkey eq $oldpkey : 0) : ! defined($oldpkey)) {
			# unchanged
			print "\$*$id WRITE_REF no change\n" if $debug_write_ref;
		} else {
			print "\$*$id WRITE_REF CHANGE to *$targetid/$qval{$targetkey} (oldval = $qval{$oldval})\n" if $debug_write_ref;
			if (ref($oldval)) {
				$oops->update_attribute($id, $targetid, $targetkey, $ock);
			} else {
				$oops->update_attribute($id, $targetid, $targetkey, $ock, $oldval);
			}
			delete $oops->{oldalias}{$id};
			if ($targetid ne $nopkey) {
				$oops->{oldalias}{$id} = [ $targetid, $targetkey ];
				$oops->{aliasdest}{$targetid}{$id} = $targetkey;
			}

		}
	} else {
		#
		# Normal references to other objects are:
		#
		#	id=id key=other_obj_id value=other_obj_key
		#
		# References to unconnected scalars are:
		#
		#	id=id key=nopkey value=the_scalar_value
		#
		# For references to unconnected scalars, we need an extra tuple
		# so that translated sql queries work right:
		#
		# 	id=id key=id value=nopkey 
		#

		print "\$*$id WRITE_REF DELETE $qval{$oldid}\n" if $debug_write_ref && defined $oldid;

		$oops->delete_attribute($id, $oldid)
			if defined $oldid;

		print "\$*$id WRITE_REF DELETE $qval{$id}\n" if $debug_write_ref && defined($oldid) && $oldid eq $id;

		$oops->delete_attribute($id, $id)
			if defined($oldid) && $oldid eq $nopkey;

		print "\$*$id WRITE_REF INSERT $qval{$targetid}/$qval{$targetkey}\n" if $debug_write_ref;

		$oops->insert_attribute($id, $targetid, { ref => $targetid }, $targetkey);

		print "\$*$id WRITE_REF INSERT $qval{$id}/$qval{$nopkey}\n" if $debug_write_ref && $targetid eq $nopkey;

		$oops->insert_attribute($id, $id, undef, $nopkey)
			if $targetid eq $nopkey;

		delete $oops->{oldalias}{$id};
		if ($targetid ne $nopkey) {
			$oops->{oldalias}{$id} = [ $targetid, $targetkey ];
			$oops->{aliasdest}{$targetid}{$id} = $targetkey;
		}
	}

	#
	# With references to an ARRAY element, we must ensure that the reference is in
	# the same loadgroup as the ARRAY because the element may move within the ARRAY
	# and that requires re-saving the reference which will only happen if the reference
	# happens to be in memory.
	#
	# With references to a common scalar, we must do the same.
	#
	if ($targetid ne $nopkey && reftype($oops->{cache}{$targetid}) ne 'HASH') {
		if ($oops->{loadgroup}{$targetid} eq $oops->{loadgroup}{$id} && ! exists $oops->{refmore}{$targetid} && ! exists $oops->{refless}{$targetid}) {
			# great
		} else {
			$oops->{forcesave}{$id} = __LINE__;
			$oops->{loadgrouplock}{$id} = $targetid;
			print "force \$*$id group to be loged to *$targetid\n" if $debug_load_group || $debug_forcesave;
		}
	}
}

#
# $oops->update_attribute($id, $pkey, $new_value, [ $new_checksum_value ], [ $old_value ])
#
sub update_attribute
{
	print Carp::longmess("DEBUG: update_attribute(@_) called") if 0; # debug
	my $oops = shift;
	my $id = shift;
	my $pkey = shift;
	my $oldover = exists $oops->{oldbig}{$id} && exists $oops->{oldbig}{$id}{$pkey};
	my $oldobject = exists $oops->{oldobject}{$id} && exists $oops->{oldobject}{$id}{$pkey};
	my $atval;
	my $newover;
	my $ptype = '0';
	my $overcksum = $_[1];
	my $oldvalue = $_[2];
	my %change_refs;
	#my $newptype = $_[3];
	if (defined($_[0]) && length($_[0]) > $bigcutoff) {
		$atval = $overcksum || bigcksum($_[0]);
		$newover = 1;
		$ptype = 'B';
	} elsif (ref($_[0])) {
		$atval = $oops->get_object_id($_[0], $id);
		$change_refs{$atval} += 1;
		print "*$id/$pkey update_attribute1, add CURRENT ref to *$atval (+1)\n" if $debug_refcount;
		$ptype = 'R';
	} else {
		$atval = $_[0];
	}
	if (ref($_[2])) {
		# old value was a reference
		my $oldid = $oops->get_object_id($_[2], $id);
		$change_refs{$oldid} -= 1;
		print "OLDOBJECT *$id/$pkey update_attribute2, oldobject = undef (was $oops->{oldobject}{$id}{$pkey})\n" if $debug_oldobject;
		delete $oops->{oldobject}{$id}{$pkey};
		print "*$id/$pkey update_attribute2, removed OLD ref to *$oldid (-1)\n" if $debug_refcount;
	} elsif ($oldobject) {
		my $oldid = $oops->{oldobject}{$id}{$pkey};
		$change_refs{$oldid} -= 1;
		print "OLDOBJECT *$id/$pkey update_attribute3, oldobject = undef (was $oops->{oldobject}{$id}{$pkey})\n" if $debug_oldobject;
		delete $oops->{oldobject}{$id}{$pkey};
		print "*$id/$pkey update_attribute3, removed OLD ref to *$oldid (-1)\n" if $debug_refcount;
	}
	if (ref($_[0])) {
		$oops->{oldobject}{$id}{$pkey} = $atval;
		print "OLDOBJECT *$id/$pkey update_attribute4 = *$atval\n" if $debug_oldobject;
	}

	print "*$id/$pkey - now: $qval{$atval} ($ptype)\n" if $debug_save_attributes;

	my $sym;
	$sym = $typesymbol{reftype($oops->{cache}{$id})} if $debug_writes;
	print "$sym$id/$pkey update_attribute $qval{$atval} (ptype $ptype)\n" if $debug_writes;

	$atval = '0' if defined($atval) && $atval eq '0';  # make sure it's a string

	my $updateattributeQ = $oops->query('updateattribute', execute => [ $atval, $ptype, $id, $pkey ]);
	if ($oldover && $newover) {
		$oops->update_big($id, $pkey, $_[0]);
		$oops->{oldbig}{$id}{$pkey} = $atval;
		delete $oops->{oldvalue}{$id}{$pkey}
			if exists $oops->{oldvalue}{$id} && exists $oops->{oldvalue}{$id}{$pkey};
	} elsif ($oldover) {
		my $deletebigQ = $oops->query('deletebig', execute => [ $id, $pkey ]);
		$oops->{oldvalue}{$id}{$pkey} = $atval;
	} elsif ($newover) {
		$oops->save_big($id, $pkey, $_[0]);
		$oops->{oldbig}{$id}{$pkey} = $atval;
		delete $oops->{oldvalue}{$id}{$pkey}
			if exists $oops->{oldvalue}{$id} && exists $oops->{oldvalue}{$id}{$pkey};
	} else {
		$oops->{oldvalue}{$id}{$pkey} = $atval;
	}
	$oops->{forcesave}{$id} = __LINE__
		if $oops->{do_forcesave};
	for my $i (keys %change_refs) {
		print "*$id/$pkey update_attribute refchange summary for *$i: $qplusminus{$change_refs{$i}}\n" if $debug_refcount;
		next unless $change_refs{$i};
		$oops->refchange($id, $i, $change_refs{$i});
	}
	assertions($oops);
}

sub prepare_insert_attribute
{
	my $oops	= shift;
	my $id		= shift;
	my $pkey	= shift;
	my $special_handling = shift;
	my $atval;
	my $ptype = '0';
	if (ref($_[0])) {
		$atval = $oops->get_object_id($_[0], $id);
		print "*$id/$pkey is a reference to *$atval (preparing to save)\n" if $debug_save_attr_arraylen || $debug_write_ref;
		$ptype = 'R';
		$oops->refchange($id,$atval,1);
		$oops->{oldobject}{$id}{$pkey} = $atval;
		print "OLDOBJECT *$id/$pkey prepare_insert_attribute = *$atval\n" if $debug_oldobject;
		print "in prepare_insert_attribute, ref to *$atval from *$id/$pkey is new (+1)\n" if $debug_refcount;
	} elsif (defined($_[0]) && length($_[0]) > $bigcutoff && ! ($special_handling && $special_handling->{ref} && $pkey ne $nopkey)) {
		$atval = $_[1] || bigcksum($_[0]);
		$ptype = 'B';
		$oops->{oldbig}{$id}{$pkey} = $atval;
		print "*$id/$pkey is a big value\n" if $debug_save_attr_arraylen;
		$oops->save_big($id, $pkey, $_[0]);
	} else {
		$atval = $_[0];
		$oops->{oldvalue}{$id}{$pkey} = $atval;
		print "*$id/$pkey is a normal value $qval{$atval}\n" if $debug_save_attr_arraylen;
	}
	$atval = '0' if defined($atval) && $atval eq '0';  # make sure it's a string
	assertions($oops);
	print "*$id/$pkey - new: $qval{$atval}\n" if $debug_save_attributes;
	return ($atval, $ptype);
}

# 
# We don't copy all of @_ because it may have BLOBs...
#
sub insert_attribute
{
	my ($oops, $id, $pkey, $special_handling) = @_;
	print Carp::longmess("DEBUG: insert_attribute(@_) called") if $debug_save_attr_context;
	my ($atval, $ptype) = $oops->prepare_insert_attribute($id, $pkey, $special_handling, $_[4], $_[5]);
	$atval = undef unless defined $atval;
	my $sym = $typesymbol{reftype($oops->{cache}{$id})} if $debug_writes;
	print "$sym$id/$pkey insert_attribute $qval{$atval} (ptype $ptype)\n" if $debug_writes;
	$atval = '' if defined($atval) && $atval eq '';   # why does this line help?!?
	my $saveattributeQ = $oops->query('saveattribute', execute => [ $id, $pkey, $atval, $ptype ]);
	$oops->{forcesave}{$id} = __LINE__
		if $oops->{do_forcesave};
	no warnings;
	print "*$id/$qval{$pkey} - '$atval'/$ptype inserted\n" if $debug_save_attributes;
	assertions($oops);
}

sub delete_attribute
{
	my $oops = shift;
	my $id = shift;
	my $pkey = shift;
	my $sym;
	$sym = $typesymbol{reftype($oops->{cache}{$id})} if $debug_writes;
	print "$sym$id/$pkey delete_attribute\n" if $debug_writes;
	my $oldvalue = shift;
	my $oldover = exists $oops->{oldbig}{$id} && exists $oops->{oldbig}{$id}{$pkey};
	$pkey = '0' if $pkey eq '0';  # make sure it's a string
	my $deleteattributeQ = $oops->query('deleteattribute', execute => [ $id, $pkey ]);
	if (ref($oldvalue)) {
		my $oldid = $oops->get_object_id($oldvalue, $id);
		$oops->refchange($id,$oldid,-1);
		print "OLDOBJECT *$id/$pkey delete_attribute, = undef (was $oops->{oldobject}{$id}{$pkey})\n" if $debug_oldobject;
		delete $oops->{oldobject}{$id}{$pkey};
		print "in delete_attribute, ref to *$oldid from *$id/$pkey is invalid (-1)\n" if $debug_refcount;
	} elsif (exists $oops->{oldobject}{$id} && exists $oops->{oldobject}{$id}{$pkey}) {
		$oops->refchange($id, $oops->{oldobject}{$id}{$pkey}, -1);
		print "in delete_attribute, ref to *$oops->{oldobject}{$id}{$pkey} from *$id/$pkey is dropped (-1)\n" if $debug_refcount;
		print "OLDOBJECT *$id/$pkey delete_attribute2, = undef (was $oops->{oldobject}{$id}{$pkey})\n" if $debug_oldobject;
		delete $oops->{oldobject}{$id}{$pkey};
	}
	if ($oldover) {
		my $deletebigQ = $oops->query('deletebig', execute => [ $id, $pkey ]);
		delete $oops->{oldbig}{$id}{$pkey};
	}
	print "*$id/$pkey - delete'\n" if $debug_save_attributes;
	delete $oops->{oldvalue}{$id}{$pkey}
		if exists $oops->{oldvalue}{$id} && exists $oops->{oldvalue}{$id}{$pkey};
	print "*$id/$pkey delete_attribute3, oldobject *$id/$pkey = undef (was $oops->{oldobject}{$id}{$pkey})\n" if $debug_oldobject && exists $oops->{oldobject}{$id} && exists $oops->{oldobject}{$id}{$pkey};
	delete $oops->{oldobject}{$id}{$pkey}
		if exists $oops->{oldobject}{$id} && exists $oops->{oldobject}{$id}{$pkey};
	$oops->{forcesave}{$id} = __LINE__
		if $oops->{do_forcesave};
	assertions($oops);
}

sub get_object_id
{
	my ($oops, $obj, $sponsoring_id) = @_;
	confess unless ref $oops;
	confess unless blessed $oops;
	confess unless $oops->isa('OOPS');
	my $bt = reftype($obj);
	my $mem = refaddr($obj);
	my $found = $oops->{memory}{$mem};
	print "lookup MEMORY($qval{$obj}) = $mem, memory{$mem} = $qval{$found}\n" if $debug_memory;
	return $found if $found;
	
	print Carp::longmess("DEBUG: get_object_id($obj) called ") if $debug_getobid_context;

	my $gcgen = $sponsoring_id 
		? $oops->{gcgeneration}{$sponsoring_id}
		: 0;

	my $id = $oops->{dbo}->allocate_id();

	#
	# We save the object so that we don't have to worry about INSERT vs UPDATE
	# in the rest of the code.   Perhaps we could save the UPDATE by putting
	# in better values now.
	#
	my $saveobjectQ = $oops->query('saveobject');
	$saveobjectQ->execute($id, $id, "will be".ref($obj), '?', '?', '?', 0, -9999, $gcgen) || confess $saveobjectQ->errstr;

	$id = $oops->{dbo}->post_new_object($id);

	$oops->memory($obj, $id);
	print "MEMORY $mem := $id in get_object_id\n" if $debug_memory;
	$oops->{cache}{$id} = $obj;
	print "*$id get_object_id cache := $qval{$obj}\n" if $debug_cache;
	$oops->{class}{$id} = ref $obj;
	$oops->{virtual}{$id} = '0';
	$oops->{arraylen}{$id} = 0;
	$oops->{reftarg}{$id} = '0';
	$oops->{loadgroup}{$id} = $id;
	$oops->{groupset}{$id}{$id} = 1;
	$oops->{gcgeneration}{$id} = $gcgen;
	printf "NEW *%d, gcgen = %d (from %s)\n", $id, $gcgen, ($sponsoring_id ? $sponsoring_id : "none") if $debug_gcgeneration;

	# 
	# Together these will force a save.  We don't use forcesave because 
	# forcesave is cleared at the beginning of save().
	#
	$oops->{refcount}{$id} = -1;
	$oops->{refmore}{$id} = 1;

	print "in get_object_id, *$id is new: count=-1, change=+1 (=0)\n" if $debug_refcount;
	print "$typesymbol{$bt}$id created as new object: $obj\n" if $debug_writes || $debug_write_object;
	$oops->{otype}{$id} = $perltype2otype{$bt} || confess "bt='$bt',obj=$obj";
	my $x = $obj->isa('OOPS::Aware')
		unless $typesymbol{ref($obj)};
	$obj->object_id_assigned($id)
		if $x;
#print "get_ob_id -> write $id\n";

	if ($oops->{insave}) {
		$oops->write_object($id, $sponsoring_id);
	} else {
		$oops->{objtouched}{$id} = 'new object';
	}

	$oops->{loaded}++;
	assertions($oops);
	return $id;
}

sub refchange
{
	my ($oops, $from, $to, $change) = @_;
	confess unless $to; # debug
	confess unless defined $change; # debug
	if ($change >= 0) {
		$oops->{refmore}{$to} += $change;
	} else {
		$oops->{refless}{$to} += $change;
	}
	confess unless $from;
	return if $change <= 0;
	my $gc = $oops->{gcgeneration};
	if (! $gc->{$to}) {
		#
		# New object, don't worry about it.
		#
		$gc->{$to} = $gc->{$from};

		my $fg = $gc->{$from} ? $gc->{$from} : "none";  # debug
		print "*$to new gcgen $fg from $from\n" if $debug_gcgeneration;
	} elsif ($gc->{$from} && $gc->{$from} > $gc->{$to}) {
		# 
		# We're in the middle of a GC pass.  We're adding
		# a link from something that has already been swept
		# to something that has not been swept.
		#
		# Add it to the GC special-handling table.
		#
		print "GC: special handling from $from($gc->{$from}) -> $to($gc->{$to})... adding $to to special table\n" if $debug_gcgeneration;

		my $checkQ = $oops->query('loadpkey', execute => [ $gc_overflow_id, $to ]) || confess $oops->errstr;
		unless(my ($junk1, $junk2) = $checkQ->fetchrow_array()) {
			$checkQ->finish();
			my $setQ = $oops->query('saveattribute');
			$setQ->execute(4, $to, '', '0') || confess $setQ->errstr;
			$oops->{gcspillcount}++;
		}
	}
}

sub delete_object
{
	my ($oops, $id) = @_;
	print "*$id begin delete\n" if $debug_cache;
	$oops->predelete_object($id);
	$oops->query('postdelete1', execute => $id);
	$oops->query('postdelete2', execute => $id);
	$oops->{deleted}{$id} = 1;
	print "*$id has been deleted\n" if $debug_cache;
	assertions($oops);
}

#
# Object may or may not be loaded.
# Object row is not cleared.
#
sub predelete_object
{
	my ($oops, $id) = @_;
	print Carp::longmess("DEBUG: predelete_object(@_) called") if 0; # debug
	unless (defined $oops->{reftarg}{$id}) {
		my $objectinfoQ = $oops->query('objectinfo', execute => $id);
		my (undef, $loadgroup, $class, $otype, $virtual, $reftarg, undef, $arraylen, $refs, $cntr, $gcgen) = $objectinfoQ->fetchrow_array();
		confess unless $otype;
		$objectinfoQ->finish();
		if ($oops->{reftarg}{$id} = $reftarg) {
			$oops->load_object($id);
		}
	}
	if ($oops->{reftarg}{$id}) {
		#
		# This can cause calls to write_ref later in the commit
		# process than normal -- during the reference counting stage
		#
		if ($oops->{otype}{$id} eq 'H') {
			%{$oops->{cache}{$id}} = ();
		} elsif ($oops->{otype}{$id} eq 'A') {
			@{$oops->{cache}{$id}} = ();
		} elsif ($oops->{otype}{$id} eq 'S') {
			# nada
		} else {
			confess;
		}
		print "*$id searching for references to self\n" if $debug_refalias || $debug_reftarget;
		my $reftargobjectQ = $oops->query('reftargobject', execute => $id);
		my $refid;
		my %done;
		while (($refid) = $reftargobjectQ->fetchrow_array()) {
			print "\%$id loading reference *$refid\n" if ($debug_refalias || $debug_reftarget) && ! exists $oops->{cache}{$refid};
			unless (exists $oops->{cache}{$refid}) {
				$oops->load_object($refid);
				my $x = $oops->{cache}{$refid}; # force it to untie
			}
			print "*$id writing *$refid again\n" if $debug_reftarget || $debug_refalias;
			push(@{$oops->{refstowrite}}, $refid);
			$done{$refid} = 1;
		}
		if ($oops->{aliasdest}{$id}) {
			for $refid (keys %{$oops->{aliasdest}{$id}}) {
				push(@{$oops->{refstowrite}}, $refid)
					unless $done{$refid};
			}
		}
	}
	$oops->query('predelete1', execute => $id);
	$oops->query('predelete2', execute => $id);
	my $objectreflistQ = $oops->query('objectreflist', execute => $id);
	my $objid;
	while (($objid) = $objectreflistQ->fetchrow_array) {
		$oops->refchange($id, $objid, -1);
		print "in predelete_object, $oops->{otype}{$id}*$id being deleted, no longer references $oops->{otype}{$objid}*$objid (-1)\n" if $debug_refcount;
	}
	assertions($oops);
}

sub load_big
{
	my ($oops, $id, $pkey) = @_;
	my $bigloadQ = $oops->query('bigload', execute => [ $id, $pkey ]);
	print STDERR "BIGLOAD $id, '$pkey'\n" if $debug_bigstuff;
	my ($val) = $bigloadQ->fetchrow_array();
	$bigloadQ->finish();
	confess "null big *$id/'$pkey'" if ! defined($val) || $val eq '';
	assertions($oops);
	return $val;
}

sub save_big
{
	my $oops = shift;
	my $id = shift;
	my $pkey = shift;
	print STDERR "BIGSAVE $id, '$pkey'\n" if $debug_bigstuff;
	my $savebigQ = $oops->query('savebig');
	$savebigQ->execute($id, $pkey, $_[0]) || confess;
}

sub update_big
{
	my $oops = shift;
	my $id = shift;
	my $pkey = shift;
	print STDERR "BIGUPDATE $id, '$pkey'\n" if $debug_bigstuff;
	my $updatebigQ = $oops->query('updatebig');
	$updatebigQ->execute($_[0], $id, $pkey) || confess $updatebigQ->errstr;
}

sub workaround27555
{
	my $oops = shift;
	print Carp::longmess("DEBUG: workaround27555 called") if $debug_27555_context;
	my ($tiedaddr, $key) = tied_hash_reference($_[0]);
	print "workaround27555($qaddr{\$_[0]}) no tied addr\n" if $debug_27555 && ! $tiedaddr;
	return $_[0] unless $tiedaddr;
	my $id = $oops->{memory}{$tiedaddr} || $oops->{new_memory}{$tiedaddr};
	print "workaround27555($qaddr{\$_[0]}) addr $tiedaddr does not translate to id (key=$key)\n" if $debug_27555 && ! $id;
	return $_[0] unless $id;
	my $tied = tied %{$oops->{cache}{$id}};
	confess unless $tied;
	$_[0] = $tied->GETREF($key);
	print "workaround27555($qaddr{\$_[0]}) references %*$id/'$key - replaced with GETREF\n" if $debug_27555;
	return $_[0];
}

#
# The point of this is simply to prevent the reuse of refaddr()s.
# This has a bad side effect: if nothing else already prevented it,
# this will prevent DESTROY from being called.
#
sub setmem
{
	my $oops = shift;
	my $mem = shift;
	my $a = refaddr($_[0]);
	if ($_[1]) {
		print "set \U$mem\E $qval{$_[0]} := $qmemval{$_[1]} at $caller{2}\n" if $debug_memory2;
		$oops->{memcount}{$a}++
			unless exists $oops->{$mem}{$a};
		$oops->{$mem}{$a} = $_[1];
		$oops->{memrefs}{$a} = \$_[0]
			unless $_[1] == 1 || $a == refaddr($oops);
		$oops->{memsetdebug}{$_[1]} = (caller(2))[2];
	} else {
		print "set \U$mem\E $qval{$_[0]} := undef at $caller{2}\n" if $debug_memory2;
		$oops->{memcount}{$a}--
			if exists $oops->{$mem}{$a};
		delete $oops->{$mem}{$a};
		unless ($oops->{memcount}{$a}) {
			delete $oops->{memrefs}{$a};
		}
	}
}

sub memory
{
	my $oops = shift;
	$oops->setmem('memory', @_);
}
sub new_memory
{
	my $oops = shift;
	$oops->setmem('new_memory', @_);
}
#my ($oops, $ref, $id, $pkey) = @_;
sub memory2key
{
	my $oops = shift;
	if ($_[1]) {
		$oops->setmem('memory2key', $_[0], [ $_[1], $_[2] ]);
	} else {
		$oops->setmem('memory2key', $_[0]);
	}
}
sub new_memory2key
{
	my $oops = shift;
	if ($_[1]) {
		$oops->setmem('new_memory2key', $_[0], [ $_[1], $_[2] ]);
	} else {
		$oops->setmem('new_memory2key', $_[0]);
	}
}


sub END
{
	$global_destruction = 1;
}

sub DESTROY
{
	local($main::SIG{'__DIE__'}) = \&die_from_destroy;
	print "OOPS::DESTROY called\n" if $debug_free_tied;
	my $oops = shift;
	print "# DESTROY $$'s OOPS $oops\n" if $debug_oops_instances && $oops->{dbo}->dbh;
#print STDERR "self = $oops\n";
	my $cache = $oops->{cache} || {};
	for my $id (keys %$cache) {
		my $tied;
		next unless defined $cache->{$id};
		next unless ref $cache->{$id};
		my $t = reftype($cache->{$id});
		if ($t eq 'HASH') {
			$tied = tied %{$cache->{$id}};
		} elsif ($t eq 'ARRAY') {
			$tied = tied @{$cache->{$id}};
		} elsif ($t eq 'SCALAR' || $t eq 'REF') {
			$tied = tied($cache->{$id}) || ref($cache->{$id}) ? tied ${$cache->{$id}} : undef;
		} else {
			confess "type($id) = '$t'";
		}
#print "istied($id) = $tied\n";
		next unless $tied;
		next unless $tied =~ /^OOPS/;
		print "Calling *$id->destroy $qval{$tied}\n" if $debug_free_tied;
		$tied->destroy;
	}
	if ($oops->{dbo}) {
		$oops->{dbo}->disconnect();
	}
	%$oops = ();
	$oopses--;
	assertions($oops);
	print "DESTROY OOPS $oops [$oopses]\n" if $debug_free_tied;
	delete $tiedvars{$oops} if $debug_tiedvars;
}

sub assertions
{
	my $oops = shift;
	if (0) {
		if (exists($oops->{cache}) && defined($oops->{cache})) {
			for my $id (keys %{$oops->{cache}}) {
				confess "no otype for *$id" unless exists($oops->{otype}{$id}) && defined($oops->{otype}{$id});
			}
		}
	}
	# print "okay at ".(caller(0))[2]."\n";
}

#
# functions
#

# withing DESTROY methods, die doesn't do anything
sub die_from_destroy
{
	print Carp::cluck;
	kill -9, $$;
}

sub bigcksum
{
	use Digest::MD5 qw(md5_base64);
	confess if ref $_[0];
	confess unless defined $_[0];
	my $cksum = substr($_[0], 0, $bigcutoff-$cksumlength);
	$cksum .= "(MD5:";
	$cksum .= md5_base64($_[0]);
	$cksum .= ")";
	return $cksum;
}

# 
# for references to tied hash keys, this will return
# the refaddr of the tie object and the hash key
#
sub tied_hash_reference
{
	my ($ref) = @_;
	local($@);
	local $SIG{'__DIE__'};
	return eval {
		my $magic = svref_2object($ref)->MAGIC;
		$magic = $magic->MOREMAGIC
			while lc($magic->TYPE) ne 'p';
		return (${$magic->OBJ->RV}, $magic->PTR->as_string);
	};
}

#
# Get a slice w/o reading the entire thing.
#
sub walk_hash(\%@)
{
	my $obj = shift;
	my ($stride, $key) = @_;
	die unless $stride >= 1;
	my $tied = tied(%$obj);
	if ($tied && $tied->can('WALK_HASH')) {
		return $tied->WALK_HASH(@_);
	}
	my @ret;
	for my $k (sort keys %$obj) {
		if (@_ > 1 && defined($key)) {
			next unless $k gt $key;
		}
		push(@ret, $k);
		last if @ret >= $stride;
	}
	return @ret;
}

#	-	-	-	-	-	-	-	-	-	-	- 

{
	#
	# These can only untie themselves if they can find themselves in 
	# the array!  We won't search 'cause that would probably waste a 
	# lot of time.
	#

	package OOPS::InArray;

	#sub UNTIE
	#{
	#	my $self = shift;
	#	print "\@$self->{id}"."->$self->{pkey} UNTIED\n" if $debug_untie;
	#}

	sub SAVE_SELF {1}
	sub POST_SAVE {}
	
	sub destroy
	{
		my $self = shift;
		%$self = ();
	}

	sub DESTROY
	{
		my $self = shift;
		print "DESTROY ".ref($self)." \%*$self->{id} $self\n" if $debug_free_tied || $debug_refarray;
		delete $tiedvars{$self} if $debug_tiedvars;
	}

	sub STORE
	{
		my ($self, $pval) = @_;
		print "\@$self->{id}"."->$self->{pkey} STORE '$pval'\n" if $debug_normalarray || $debug_refarray;
		$self->{changed} = 1;
		$self->{pval} = $pval;
		no warnings;
		my $a = $self->{oops}{cache}{$self->{id}};
		if ($#$a >= $self->{pkey} && tied($a->[$self->{pkey}]) eq $self) {
			untie $a->[$self->{pkey}];
		}
		$self->{oops}->assertions;
		return $pval;
	}

	sub changed
	{
		my ($self, $pkey) = @_;
		print "\@$self->{id}"."->$pkey was at $self->{pkey} and changed=$self->{changed}\n" if $debug_write_array;
		return 1 unless $pkey eq $self->{pkey};  # there's room to make this go faster
		$self->{oops}->assertions;
		return $self->{changed};
	}
}
#	-	-	-	-	-	-	-	-	-	-	- 
{
	package OOPS::ObjectInArray;

	use Scalar::Util qw(weaken);
	use Carp qw(longmess);
	our (@ISA) = ('OOPS::InArray');

	sub TIESCALAR 
	{
		my $pkg = shift;
		my ($id, $pkey, $objectid, $oops) = @_;
		my $self = {
			id		=> $id,
			pkey		=> $pkey,
			objectid	=> $objectid,
			oops		=> $oops
		};
		weaken $self->{oops};
		bless $self, $pkg;
		print "BLESSED $self at ".__LINE__."\n" if $debug_blessing;
		print "CREATE ObjectflowInArray \%$id $self\n" if $debug_free_tied || $debug_refarray;
		$tiedvars{$self} = "%$id ".longmess if $debug_tiedvars;
		$self->{oops}->assertions;
		return $self;
	}

	sub FETCH
	{
		my ($self) = shift;
		return $self->{pval} 
			if exists $self->{pval};
		print "\@$self->{id}"."->$self->{pkey} FETCH *$self->{objectid}\n" if $debug_normalarray || $debug_refarray;
		my $oops = $self->{oops};
		$self->{pval} = $oops->load_object($self->{objectid});
		$oops->workaround27555($self->{pval});
		no warnings;
		my $a = $self->{oops}{cache}{$self->{id}};
		if ($#$a >= $self->{pkey} && tied($a->[$self->{pkey}]) eq $self) {
			untie $a->[$self->{pkey}];
			$oops->workaround27555($a->[$self->{pkey}]);
		}
		$self->{oops}->assertions;
		print "\@$self->{id}"."->$self->{pkey} FETCH *$self->{objectid} returns $qval{$self->{pval}}\n" if $debug_normalarray || $debug_refarray;
		return $self->{pval};
	}
}
#	-	-	-	-	-	-	-	-	-	-	- 
{
	package OOPS::BigInArray;

	use Scalar::Util qw(weaken);
	use Carp qw(longmess);
	our (@ISA) = ('OOPS::InArray');

	sub TIESCALAR 
	{
		my $pkg = shift;
		my ($id, $pkey, $cksum, $oops) = @_;
		my $self = {
			id		=> $id,
			pkey		=> $pkey,
			cksum		=> $cksum,
			oops		=> $oops
		};
		weaken $self->{oops};
		print "CREATE BigInArray \%$id/$pkey $self\n" if $debug_free_tied || $debug_refarray;
		$tiedvars{$self} = "%$id ".longmess if $debug_tiedvars;
		$self->{oops}->assertions;
		return bless $self, $pkg;
	}

	sub FETCH
	{
		my ($self) = shift;

		return $self->{pval} 
			if exists $self->{pval};

		$self->{pval} = $self->{oops}->load_big($self->{id}, $self->{pkey});
		print "\@$self->{id}"."->$self->{pkey} FETCH '$self->{pval}'\n" if $debug_normalarray || $debug_refarray;
		no warnings;
		my $a = $self->{oops}{cache}{$self->{id}};
		if ($#$a >= $self->{pkey} && tied($a->[$self->{pkey}]) eq $self) {
			untie $a->[$self->{pkey}];
		}
		$self->{oops}->assertions;
		return $self->{pval};
	}
}
#	-	-	-	-	-	-	-	-	-	-	- 
{
	package OOPS::RefAlias;

	#
	# RefAlias handles references to elements within other objects.
	# \%foo{bar} and such.
	#

	use Scalar::Util qw(weaken refaddr reftype);
	use Carp qw(confess longmess);

	#
	# If we point into an array then there is some chance that
	# our situation has changed.  We must untie ourself and return 1
	# so that the normal reference writing code can handle it.
	#

	sub SAVE_SELF
	{
		my $self = shift;
		my ($oops, $id, $objid, $objkey) = @$self;
		return if $oops->{savedone}{$id}++; 
		return unless exists $oops->{cache}{$objid};
		return unless reftype($oops->{cache}{$objid}) eq 'ARRAY';
		print "SAVE_SELF RefAlias \%*$id $self\n" if $debug_refalias;
		$self->FETCH;
		return 1;
	}

	sub POST_SAVE {}

	sub DESTROY
	{
		my $self = shift;
		my ($oops, $id, $objid, $objkey) = @$self;
		print "DESTROY RefAlias \%*$id $self\n" if $debug_free_tied || $debug_refarray;
		delete $tiedvars{$self} if $debug_tiedvars;
	}

	sub TIESCALAR
	{
		my $pkg = shift;
		my ($oops, $id, $refobid, $refobkey) = @_;
		my $self = bless [ $oops, $id, $refobid, $refobkey ], $pkg;
		weaken $self->[0];
		print "CREATE RefAlias \%$id $self\n" if $debug_free_tied || $debug_refarray;
		$tiedvars{$self} = "%$id ".longmess if $debug_tiedvars;
		$oops->assertions;
		return $self;
	}

	sub FETCH 
	{
		my $self = shift;
		my ($oops, $id, $objid, $objkey) = @$self;
		print "\$*$id raFETCH *$objid/'$objkey' (will UNITE)\n" if $debug_refalias;
		my $tied;
		my $cache = $oops->{cache};
		my $ref;
		my $wa;
		if (! exists $cache->{$objid}) {
			print "\$*$id raFETCH loading object\n" if $debug_refalias;
			$oops->load_object($objid) || confess;
		}
		my $type = reftype($oops->{cache}{$objid});
		if ($type eq 'HASH') {
			if (($tied = tied %{$cache->{$objid}})) {
				$ref = $tied->GETREFORIG($objkey);
				print "\$*$id raFETCH tied, using *$objid->GETREFORIG($qval{$objkey}): $qval{$ref}\n" if $debug_refalias;
			} else {
				confess "untied hash reference \$$id/$objid/$objkey";
				# $ref = \$oops->{cache}{$objid}{$objkey};
			}
		} elsif ($type eq 'ARRAY') {
			if ($tied = tied @{$cache->{$objid}}) {
				confess "We don't support tied arrays yet";
			} else {
				$ref = $oops->{refcopy}{$objid}{$objkey} || confess;
				print "\$*$id raFETCH from array, using refcopy: $qval{$ref}\n" if $debug_refalias;
			}
		} else {
			confess "Refalias to '$type' isn't allowed";
		}
		untie $cache->{$id};
		$oops->{unwatched}{$id} = 1;
		$oops->{oldalias}{$id} = [ $objid, $objkey ];
		$cache->{$id} = $ref; 
		print "*$id raFETCH cache := $qval{$ref}\n" if $debug_cache;
		$oops->memory($ref, $id);
		print "MEMORY $qval{$ref} = $id in raFETCH\n" if $debug_memory;
		confess unless $ref;
		print "\$*$id raFETCH *$objid/'$objkey' returns $qval{$ref}\n" if $debug_refalias;
		return $ref;
	}

	sub STORE
	{
		confess "why could this happen?";
#		my $self = shift;
#		my $val = shift;
#		my ($oops, $id, $objid, $objkey) = @$self;
#		print "\$*$id raSTORE cache := $qval{$val} (was *$objid/$objkey)\n" if $debug_refalias || $debug_cache;
#
#		my $cache = $oops->{cache};
#		untie $cache->{$id};
#		$cache->{$id} = $val;
#
		# XXX why not unwatched or oldalias?

		#my $r = $self->FETCH();
		#$oops->{unwatched}{$id} = 1;
		#$oops->{oldalias}{$id} = [ $objid, $objkey ];
		#my $cache = $oops->{cache};
		#untie ${$cache->{$id}};
		#${$cache->{$id}} = $val;
	}

}
#	-	-	-	-	-	-	-	-	-	-	- 
{
	package OOPS::Ref;

	use Scalar::Util qw(weaken);
	use Carp qw(longmess confess);

	sub SAVE_SELF {1}

	sub POST_SAVE {}

	sub DESTROY
	{
		my $self = shift;
		my ($oops, $id, $val) = @$self;
		print "DESTROY Ref \%*$id $self\n" if $debug_free_tied || $debug_refalias;
		delete $tiedvars{$self} if $debug_tiedvars;
	}

	sub destroy {}

	sub UNTIE
	{
		my $self = shift;
		my ($oops, $id, $val) = @$self;
		print "*$id UNTIE\n" if $debug_refalias || $debug_refobject;
		$oops->{unwatched}{$id} = 1;
	}

	sub TIESCALAR
	{
		my $pkg = shift;
		my $oops = shift;
		my $self = bless [ $oops, @_ ], $pkg;
		print "CREATE $pkg *$qval{$_[0]}/$qval{$_[1]}\n" if $debug_free_tied || $debug_refalias;
		$tiedvars{$self} = "*$qval{$_[0]} ".longmess if $debug_tiedvars;
		weaken $self->[0];
		confess unless defined $oops;
		$oops->assertions;
		return $self;
	}
}
#	-	-	-	-	-	-	-	-	-	-	- 
{
	package OOPS::RefObject;

	our (@ISA) = qw(OOPS::Ref);

	sub FETCH
	{
		my $self = shift;
		my ($oops, $id, $val, $suicide) = @$self;
		if (@$self == 5) {
			print "\$*id roFETCH overriden value (shouldn't happen), returning $qval{$suicide}\n" if $debug_refobject;
			return $suicide;
		}
		untie ${$oops->{cache}{$id}};
		$oops->{oldobject}{$id}{$nopkey} = $val;
		print "OLDOBJECT *$id/$nopkey refobject = *$val (roFETCH)\n" if $debug_oldobject;
		print "\$*$id roFETCH will return *$val and attempt UNTIE\n" if $debug_refobject;
		$oops->{unwatched}{$id} = 1;
		return $oops->load_object($val);
	}

	sub STORE
	{
		my $self = shift;
		my ($oops, $id, $val, $suicide) = @$self;
		untie ${$oops->{cache}{$id}};
		print "\$*$id roSTORE $qval{$_[0]} (replacing *$val), attempt UNTIE\n" if $debug_refobject;
		unless ($oops->{oldobject}{$id}{$nopkey}) {
			print "OLDOBJECT *$id/$nopkey refobject = *$val (roSTORE)\n" if $debug_oldobject;
			$oops->{oldobject}{$id}{$nopkey} = $val;
			$oops->{unwatched}{$id} = 1;
		}
		$self->[4] = $_[0];
		${$oops->{cache}{$id}} = shift;
		untie ${$oops->{cache}{$id}};
		if (@$self == 5) {
			print "\$*id roSTORE overriden value (shouldn't happen), returning $qval{$suicide}\n" if $debug_refobject;
			return $suicide;
		}
		return $val;
	}
}
#	-	-	-	-	-	-	-	-	-	-	- 
{
	package OOPS::RefBig;

	our (@ISA) = qw(OOPS::Ref);

	sub FETCH
	{
		my $self = shift;
		my ($oops, $id, $val) = @$self;
		untie ${$oops->{cache}{$id}};
		$oops->{oldbig}{$id}{$nopkey} = $val;
		return $oops->load_big($id, $nopkey);
	}

	sub STORE
	{
		my $self = shift;
		my ($oops, $id, $val) = @$self;
		untie ${$oops->{cache}{$id}};
		$oops->{oldbig}{$id}{$nopkey} = $val;
		${$oops->{cache}{$id}} = shift;
		return $val;
	}
}
#	-	-	-	-	-	-	-	-	-	-	- 
{
	package OOPS::NormalHash;

	use Scalar::Util qw(weaken reftype refaddr);
	use Carp qw(confess longmess);

	sub SAVE_SELF
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		print "\%$id hSAVE_SELF\n" if $debug_normalhash;
		$self->LOAD_SELF_REF() if $oops->{reftarg}{$id};
		$oops->write_hash($values, $id, $ptypes, $added);
		delete $oops->{demandwrite}{$id};
		$oops->assertions;
		return 0;
	}

	sub POST_SAVE 
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		delete $vars->{during_save};
	}

	sub destroy
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		print "destroy NormalHash \%$id $self\n" if $debug_free_tied || $debug_normalhash;
		%$ptypes = ();
		%$added = ();
		%$vars = ();
		$oops->assertions if defined $oops;
	}

	#
	# could this be an UNTIE sub intead?  If so, would it get
	# called too soon?
	sub DESTROY
	{
		local($main::SIG{'__DIE__'}) = \&OOPS::die_from_destroy;
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		delete $tiedvars{$self} if $debug_tiedvars;
		return unless defined $oops; # it's a weak reference
		return unless defined $oops->{cache}; # during destruction...
		$self->preserve_ptypes;
		confess if %$ptypes;
		$oops->{oldvalue}{$id} = {}
			unless exists $oops->{oldvalue}{$id};
		my $ov = $oops->{oldvalue}{$id};
		my $oo = $oops->{oldobject}{$id};
		my $of = $oops->{oldbig}{$id};
		for my $pkey (keys %$values) {
			no warnings qw(uninitialized);
			next if exists $added->{$pkey};
			next if exists $ov->{$pkey};
			next if $oo && exists $oo->{$pkey};
			next if $of && exists $of->{$pkey};
			$ov->{$pkey} = $values->{$pkey};
		}
		confess if tied %{$oops->{cache}{$id}};
		untie(%{$oops->{cache}{$id}});   # Yes, this is required.  
		%{$oops->{cache}{$id}} = %$values;
		$oops->{objtouched}{$id} = 'destroyed';
		delete $oops->{demandwrite}{$id};
		print "in NormalHash::DESTROY, *$id is touched -- \$oops is still valid\n" if $debug_touched;
		print "DESTROY NormalHash \%*$id $self\n" if $debug_free_tied || $debug_normalhash;
		delete $tiedvars{$self} if $debug_tiedvars;
	#	print "\%$id keys = ".join(' ',keys %{$oops->{cache}{$id}})."\n";
	#	print "\%$id oldvalues = ".join(' ',keys %{$oops->{oldvalue}{$id}})."\n";
	#	print "\%$id oldobject = ".join(' ',keys %{$oops->{oldobject}{$id}})."\n";
		$oops->assertions;
	}

	#	tie %{$cache->{$id}}, 'OOPS::NormalHash', $new{$id}, $newptype{$id}, $oops, $id;

	sub TIEHASH
	{
		my $pkg = shift;
		my ($values, $ptypes, $oops, $id) = @_;
		my $self = bless [ $values, $ptypes, {}, $oops, $id, {} ], $pkg;
		weaken $self->[3];
		print "CREATE NormalHash \%$id $self\n" if $debug_free_tied || $debug_normalhash;
		$tiedvars{$self} = "%$id ".longmess if $debug_tiedvars;
		$oops->assertions;
		return $self;
	}

	sub FETCH
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		return undef unless defined $oops; # weak ref
		my $pkey = shift;
		no warnings qw(uninitialized);
		print "\%$id/$pkey begin hFETCH\n" if $debug_normalhash;
		if (exists $ptypes->{$pkey}) {
			my $ot = $ptypes->{$pkey};
			if ($ot eq 'R') {
				print "OLDOBJECT *$id/$pkey hFETCH = *$values->{$pkey}\n" if $debug_oldobject;
				$oops->{oldobject}{$id}{$pkey} = $values->{$pkey};
				$values->{$pkey} = $oops->load_object($values->{$pkey});
				$oops->workaround27555($values->{$pkey});
			} elsif ($ot eq 'B') {
				$oops->{oldbig}{$id}{$pkey} = $values->{$pkey};
				$values->{$pkey} = $oops->load_big($id, $pkey);
			} else {
				confess;
			}
			delete $ptypes->{$pkey};
		}
		print "\%$id/$pkey hFETCH = $qval{$values->{$pkey}}\n" if $debug_normalhash;
		confess if exists $ptypes->{$pkey} && tied $ptypes->{$pkey};
		$oops->assertions;
		return $values->{$pkey};
	}

	sub STORE
	{
		my $self = shift;
		my ($pkey, $pval) = @_;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		return undef unless defined $oops; # weak ref
		$oops->workaround27555($pval) if ref $pval;
		no warnings qw(uninitialized);
		if (exists $ptypes->{$pkey}) {
			my $ot = $ptypes->{$pkey};
			if ($ot eq 'R') {
				print "*$id/$pkey hSTORE *$id/$pkey = *$values->{$pkey}\n" if $debug_oldobject;
				$oops->{oldobject}{$id}{$pkey} = $values->{$pkey};
			} elsif ($ot eq 'B') {
				$oops->{oldbig}{$id}{$pkey} = $values->{$pkey};
			} else {
				confess;
			}
			print "%$id/$pkey hSTORE Oldvalue = $qval{$values->{$pkey}}\n" if $debug_normalhash;
			$oops->{oldvalue}{$id}{$pkey} = $values->{$pkey};
			delete $ptypes->{$pkey};
		} else {
			if (exists $oops->{oldvalue}{$id}{$pkey}) {
				# nada
			} elsif (exists($values->{$pkey}) && ! exists($added->{$pkey})) {
				print "%$id/$pkey hSTORE oldvalue = $qval{$values->{$pkey}}\n" if $debug_normalhash;
				$oops->{oldvalue}{$id}{$pkey} = $values->{$pkey};
			} else {
				no warnings;
				$added->{$pkey} = 1;
			}
		}
		$oops->{demandwrite}{$id} = 1;
		print "\%$id/$pkey hSTORE = $qval{$pval} ($qval{$values->{$pkey}})\n" if $debug_normalhash;
		$values->{$pkey} = $pval;
		$oops->assertions;
	}

	sub DELETE
	{
		my $self = shift;
		my $pkey = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		{ no warnings; print "\%$id/$pkey hDELETE ($values->{$pkey})\n" if $debug_normalhash; }

		no warnings qw(uninitialized);
		if (exists $values->{$pkey}) {
			if (exists $vars->{keyrefs}{$pkey}) {
				my $ref = $vars->{keyrefs}{$pkey};
				my $addr = refaddr($ref);

				unless (exists $added->{$pkey} || exists $vars->{deleted}{$pkey} || exists $vars->{alldelete}) {
					print "%*$id/'$pkey' hDELETE preserve $addr ($ref) in original_refs\n" if $debug_memory || $debug_refalias;
					confess if $vars->{original_reference}{$pkey};
					$vars->{original_reference}{$pkey} = $ref
				}

				print "%*$id/'$pkey' hDELETE MEMORY2KEY($addr) := undef ($ref)\n" if $debug_memory || $debug_refalias;
				$oops->memory2key($ref);
				delete $vars->{keyrefs}{$pkey};
			}

			if (exists $added->{$pkey}) {
				# nada
			} else {
				if (exists $ptypes->{$pkey}) {
					my $ot = $ptypes->{$pkey};
					if ($ot eq 'R') {
						print "OLDOBJECT *$id/$pkey hDELETE = *$values->{$pkey}\n" if $debug_oldobject;
						$oops->{oldobject}{$id}{$pkey} = $values->{$pkey};
					} elsif ($ot eq 'B') {
						$oops->{oldbig}{$id}{$pkey} = $values->{$pkey};
					} else {
						confess;
					}
					print "%$id/$pkey hDELETE Oldvalue = $qval{$values->{$pkey}}\n" if $debug_normalhash;
					$oops->{oldvalue}{$id}{$pkey} = $values->{$pkey};
					delete $ptypes->{$pkey};
				} elsif (! exists($oops->{oldvalue}{$id}{$pkey}) && ! exists $added->{$pkey}) {
					print "%$id/$pkey hDELETE oldvalue = $qval{$values->{$pkey}}\n" if $debug_normalhash;
					$oops->{oldvalue}{$id}{$pkey} = $values->{$pkey};
				}
				unless (exists($vars->{deleted}{$pkey}) || exists($vars->{alldelete})) {
					# first time it's deleted
					$vars->{deleted}{$pkey} = $values->{$pkey};
				}
			}
			delete $values->{$pkey};
		}
		$oops->{demandwrite}{$id} = 1;
		$oops->assertions;
	}

	sub CLEAR
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		return unless defined $oops; # weak ref
		print "\%$id hCLEAR\n" if $debug_normalhash;

		$self->preserve_ptypes;

		confess if %$ptypes;
		if ($vars->{keyrefs}) {
			for my $pkey (keys %{$vars->{keyrefs}}) {
				no warnings qw(uninitialized);
				next unless $vars->{keyrefs}{$pkey};
				my $ref = $vars->{keyrefs}{$pkey};
				my $addr = refaddr($ref);
				print "%*$id/'$pkey' hCLEAR MEMORY2KEY($addr) := undef ($ref)\n" if $debug_memory || $debug_refalias;
				$oops->memory2key($ref);

				unless (exists $added->{$pkey} || exists $vars->{deleted}{$pkey} || exists $vars->{alldelete}) {
					print "%*$id/'$pkey' hCLEAR preserve $addr ($ref) in original_refs\n" if $debug_memory || $debug_refalias;
					confess if $vars->{original_reference}{$pkey};
					$vars->{original_reference}{$pkey} = $ref
				}
			}
			delete $vars->{keyrefs};
		}
		if (exists $vars->{alldelete}) {
			%$values = ();
		} else {
			delete @{$values}{keys %$added};
			$vars->{alldelete} = $self->[0];
			$self->[0] = {};
		}
		delete $vars->{deleted};
		%$added = ();
		$oops->{demandwrite}{$id} = 1;
		$oops->assertions;
	}

	sub GETREFORIG
	{
		my $self = shift;
		my $pkey = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		no warnings qw(uninitialized);
		if (exists($vars->{alldelete}) || exists($vars->{deleted}{$pkey})) {
			$self->LOAD_SELF_REF() unless $vars->{ref_to_self_loaded};
			print "%*$id/$pkey hGETREFORIG returning cached original $qaddr{$vars->{original_reference}{$pkey}} ($vars->{original_reference}{$pkey})\n" if $debug_refalias && exists $vars->{original_reference}{$pkey};
			return $vars->{original_reference}{$pkey}
				if exists $vars->{original_reference}{$pkey};
			my $pval;
			$vars->{during_save}{oldvalue} = %{$oops->{oldvalue}{$id}};
			if (exists $oops->{oldobject}{$id}{$pkey}) {
				$pval = $oops->load_object($oops->{oldobject}{$id}{$pkey});
				$oops->workaround27555($pval);
				print "%*$id/$pkey hGETREFORIG from loadobject $oops->{oldobject}{$id}{$pkey}\n" if $debug_refalias;
			} elsif (exists $oops->{oldbig}{$id}{$pkey}) {
				$pval = $oops->load_big($id, $pkey);
				print "%*$id/$pkey hGETREFORIG from loadbig\n" if $debug_refalias;
			} elsif (exists $oops->{oldvalue}{$id}{$pkey}) {
				$pval = $oops->{oldvalue}{$id}{$pkey};
				print "%*$id/$pkey hGETREFORIG from oldvalue\n" if $debug_refalias;
			} elsif (exists $vars->{alldelete} && exists $vars->{alldelete}{$pkey}) {
				print "%*$id/$pkey hGETREFORIG from CLEARed value\n" if $debug_refalias;
			} else {
				print "%*$id/$pkey hGETREFORIG no prior value\n" if $debug_refalias;
				$pval = undef;
			}
			my $ref = \$pval;
			print "%*$id/$pkey hGETREFORIG original $qval{$pval} $qaddr{$ref} ($ref)\n" if $debug_refalias;
			$vars->{original_reference}{$pkey} = $ref;
			return $ref;
		}
		print "%*$id/$pkey hGETREFORIG returning NEW reference\n" if $debug_refalias;
		return $self->GETREF($pkey);
	}

	# 
	# This should be a normal tie method but it isn't so we depend on it's 
	# being called by workaround27555
	#
	sub GETREF
	{
		my $self = shift;
		my $pkey = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		$self->STORE($pkey, $self->FETCH($pkey));
		no warnings qw(uninitialized);
		confess unless exists $values->{$pkey};
		$self->LOAD_SELF_REF() unless $vars->{ref_to_self_loaded};
		my $ref = \$values->{$pkey};
		$vars->{keyrefs}{$pkey} = $ref;
		$oops->memory2key($ref, $id, $pkey);
		$oops->{demandwrite}{$id}++;
		print "%*$id/'$pkey' hGETREF MEMORY2KEY $qval{$ref} := *$id/$pkey (ref to: $qval{$values->{$pkey}})\n" if $debug_memory || $debug_refalias;
		return $ref;
	}


	sub LOAD_SELF_REF
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		if ($vars->{ref_to_self_loaded}) {
			print "%*$id hLOAD_SELF_REF - already done\n" if $debug_refalias && $debug_normalhash;
			return 
		}
		$vars->{ref_to_self_loaded} = 1;  # early in function to prevent re-entrency
		print "\%$id searching for references to keys\n" if $debug_refalias || $debug_normalhash;
		my $reftargobjectQ = $oops->query('reftargobject', execute => $id);
		my $refid;
		#
		# When a hash key is deleted, any references to the hash value become
		# independent from the original hash.  We have to have these referneces
		# in-memory so that we can sort this out.
		#
		while (($refid) = $reftargobjectQ->fetchrow_array()) {
			print "\%$id loading reference *$refid\n" if $debug_refalias || $debug_normalhash;
			unless (exists $oops->{cache}{$refid}) {
				$oops->load_object($refid);
				my $x = $oops->{cache}{$refid}; # force untie
			}
		}
		print "%*$id hLOAD_SELF_REF - complete\n" if $vars->{ref_to_self_loaded} && $debug_refalias && $debug_normalhash;
	}

	sub preserve_ptypes
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		return unless defined $oops; # weak ref
		for my $pkey (keys %$values) {
			no warnings qw(uninitialized);
			if (exists $ptypes->{$pkey}) {
				my $ot = $ptypes->{$pkey};
				if ($ot eq 'R') {
					print "OLDOBJECT *$id/$pkey hPreserve_ptypes = *$values->{$pkey}\n" if $debug_oldobject;
					$oops->{oldobject}{$id}{$pkey} = $values->{$pkey};
				} elsif ($ot eq 'B') {
					$oops->{oldbig}{$id}{$pkey} = $values->{$pkey};
				} else {
					confess;
				}
				print "%$id/$pkey hCLEAR oldvalue = $qval{$values->{$pkey}}\n" if $debug_normalhash;
				$oops->{oldvalue}{$id}{$pkey} = $values->{$pkey};
				delete $ptypes->{$pkey};
			} elsif (exists $added->{$pkey}) {
				# nada
			} elsif (! exists $oops->{oldvalue}{$id}{$pkey}) {
				print "%$id/$pkey hCLEAR oldvalue = $qval{$values->{$pkey}}\n" if $debug_normalhash;
				$oops->{oldvalue}{$id}{$pkey} = $values->{$pkey};
			}
		} 
		$oops->assertions;
	}

	sub EXISTS
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		my $pkey = shift;
		no warnings qw(uninitialized);
		print "\%$id/$pkey hEXISTS? = ".(exists($values->{$pkey}) ? "YES" : "NO")."\n" if $debug_normalhash;
		$oops->assertions;
		return exists $values->{$pkey};
	}

	sub FIRSTKEY
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		confess if tied $ptypes;
		my $t = tied %$ptypes;
		$vars->{ineach} = 1;
		keys %$values;
		print "\%$id hFIRSTKEY\n" if $debug_normalhash;
		$oops->assertions if $oops;
		return $self->NEXTKEY();
	}

	sub NEXTKEY
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		my ($pkey, $pval) = each(%$values);
		if (defined $pkey) {
			no warnings qw(uninitialized);
			confess if exists $ptypes->{$pkey} && tied $ptypes->{$pkey};
			print "\%$id hNEXTKEY = ".$qval{$pkey}."\n" if $debug_normalhash;
		} else {
			delete $vars->{ineach};
			print "\%$id hNEXTKEY = undef\n" if $debug_normalhash;
		}
		$oops->assertions if $oops;
		return $pkey;
	}

	sub SCALAR
	{
		my $self = shift;
		my ($values, $ptypes, $added, $oops, $id, $vars) = @$self;
		return scalar(keys(%$values));
	}

}
#	-	-	-	-	-	-	-	-	-	-	- 
{
	package OOPS::DemandHash;

	use Carp qw(confess longmess croak);
	use Scalar::Util qw(weaken refaddr);

	#
	# $oops - OOPS object to use
	# $id - persistant object id
	# $rcache - read cache
	# $wcache - write cache
	# $necache - non-exists cache
	# $dcache - deleted cache
	# $ovcache - old values cache
	# $vars - {
	# 	dbseach - each() database cursor
	#	alldelete - everything has been deleted at least once
	# }
	#

	sub SAVE_SELF
	{
		my $self = shift;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;

		printf "%%%s SAVE_SELF dcache=%s, wcache=%s\n", $id, join('/',keys %$dcache), join('/',keys %$wcache) if $debug_virtual_delete || $debug_virtual_save;

		return unless %$wcache || %$dcache || $vars->{alldelete};
		if ($vars->{alldelete}) {
			print "%$id alldelete\n" if $debug_virtual_save;
			$oops->predelete_object($id);  # doesn't clear object row.
			$oops->{forcesave}{$id} = __LINE__
				if $oops->{do_forcesave};
			$oops->query('postdeleteV', execute => $id);
			$self->LOAD_SELF_REF() if $oops->{reftarg}{$id};
		} elsif (%$dcache || %$wcache) {
			my %done;
			for my $pkey (keys %$dcache, keys %$wcache) {
				no warnings qw(uninitialized);
				confess if $done{$pkey}++;
				my ($pval, $ptype);
				if (exists $ovcache->{$pkey}) {
					($pval, $ptype) = @{$ovcache->{$pkey}};
					print "%$id/'$pkey' - old value is cached ('$pval', $ptype)\n" if $debug_virtual_save;
				} elsif (exists $necache->{$pkey}) {
					print "%$id/'$pkey' - old value known to be absent\n" if $debug_virtual_save;
					next;
				} else {
					print "%$id/'$pkey' - checking old pval in virtual SAVE_SELF\n" if $debug_virtual_delete || $debug_virtual_save;
					my $loadpkeyQ = $oops->query('loadpkey', execute => [ $id, $pkey ]);
					if (($pval, $ptype) = $loadpkeyQ->fetchrow_array) {
						$loadpkeyQ->finish();
						$ovcache->{$pkey} = [ $pval, $ptype ];
					} else {
						# no old value
					}
				}
				if (! $ptype) {
					# nothing
				} elsif ($ptype eq 'R') {
					 print "%$id/'$pkey' - old value was a reference (*$pval)\n" if $debug_virtual_delete || $debug_virtual_save || $debug_refcount; 
					$oops->refchange($id, $pval, -1);
					print "in demandhash save-self, V%$id reference to $oops->{otype}{$pval}*$pval gone (-1)\n" if $debug_refcount;
				} elsif ($ptype eq 'B') {
					print "%$id/'$pkey' - old value was big\n" if $debug_virtual_delete || $debug_virtual_save; 
					$oops->query('deletebig', execute => [ $id, $pkey ]);
				} else {
					confess;
				}
				$self->LOAD_SELF_REF($pkey) if exists $dcache->{$pkey} && $oops->{reftarg}{$id};
			}
		}
		if (%$dcache && ! $vars->{alldelete}) {
			for my $pkey (keys %$dcache) {
				no warnings qw(uninitialized);
				print "%$id/'$pkey' - commit virtual delete (SAVE_SELF)\n" if $debug_virtual_delete || $debug_virtual_save;
				$oops->query('deleteattribute', execute => [ $id, $pkey ]);
			}
		}
		if (%$wcache) {
			my $saveattributeQ = $oops->query('saveattribute');
			for my $pkey (keys %$wcache) {
				no warnings qw(uninitialized);
#				print "%$id/'$pkey' - no change in value\n" if $debug_virtual_save && exists $rcache->{$pkey} && $rcache->{$pkey} eq $wcache->{$pkey} && defined($rcache->{$pkey}) eq defined($wcache->{$pkey}) && ref($rcache->{$pkey}) eq ref($wcache->{$pkey});
#				next if exists $rcache->{$pkey}
#					&& $rcache->{$pkey} eq $wcache->{$pkey}
#					&& defined($rcache->{$pkey}) eq defined($wcache->{$pkey})
#					&& ref($rcache->{$pkey}) eq ref($wcache->{$pkey});
				if (exists($ovcache->{$pkey}) && ! $vars->{alldelete}) {
					my ($atval, $ptype) = $oops->prepare_insert_attribute($id, $pkey, undef, $wcache->{$pkey}, undef);
#print "pkey=$pkey atval=$atval\n";
					print "%$id/'$pkey' - replacement value ('$atval', $ptype [was @{$ovcache->{$pkey}}])\n" if $debug_virtual_save;
					$oops->query('updateattribute', execute => [ $atval, $ptype, $id, $pkey ]);
				} else {
					my ($atval, $ptype) = $oops->prepare_insert_attribute($id, $pkey, undef, $wcache->{$pkey}, undef);
					print "%$id/'$pkey' - new value ('$atval', $ptype)\n" if $debug_virtual_save;
					$oops->query('saveattribute', execute => [ $id, $pkey, $atval, $ptype ]);
				}
				$vars->{new_rcache}{$pkey} = $wcache->{$pkey};
			}
		}
		$oops->assertions;
		return 0;
	}

	sub POST_SAVE
	{
		my $self = shift;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		print "%*$id POST_SAVE\n" if $debug_virtual_save;
		if ($vars->{alldelete}) {
			delete $vars->{original_reference};
			%$ovcache = ();
		} elsif (%$dcache) {
			delete @{$vars->{original_reference}}{keys %$dcache};
			delete @{$ovcache}{keys %$dcache};
		}
		$self->[2] = $vars->{new_rcache} || {};
		%$dcache = ();
		%$wcache = ();
		delete $vars->{alldelete};
		delete $oops->{demandwrite}{$id};
		delete $vars->{has_been_deleted};
	}

	sub destroy
	{
		my $self = shift;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		%$rcache = ();
		%$wcache = ();
		%$necache = ();
		%$ovcache = ();
		%$dcache = ();
		%$vars = ();
		delete $tiedvars{$self} if $debug_tiedvars;
		$oops->assertions if $oops; # tied var
	}

	sub DESTROY
	{
		local($main::SIG{'__DIE__'}) = \&OOPS::die_from_destroy;
		my $self = shift;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		print "DESTROY DemandHash \%$id $self\n" if $debug_free_tied;
		delete $tiedvars{$self} if $debug_tiedvars;
		$oops->assertions if defined $oops; # weak reference
	}

	sub TIEHASH
	{
		my ($pkg, $oops, $id) = @_;
		my $self = bless [ $oops, $id, {}, {}, {}, {}, {}, {} ], $pkg;
		weaken $self->[0];
		push(@{$oops->{vcache}}, $self);
		print "CREATE DemandHash \%$id $self\n" if $debug_free_tied;
		$tiedvars{$self} = "%$id ".longmess if $debug_tiedvars;
		$oops->assertions;
		return $self;
	}

	sub FETCH
	{
		my ($self, $pkey) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		return undef unless defined $oops; # weak ref
		no warnings qw(uninitialized);
		if (exists $dcache->{$pkey}) {
			print "%*$id/'$pkey' vFETCH: undef - in dcache\n" if $debug_virtual_hash;
			return undef ;
		}
		if (exists $wcache->{$pkey}) {
			print "%*$id/'$pkey' vFETCH: $qval{$wcache->{$pkey}} - in wcache\n" if $debug_virtual_hash;
			return $wcache->{$pkey};
		}
		if (exists $rcache->{$pkey}) {
			print "%*$id/'$pkey' vFETCH: $qval{$rcache->{$pkey}} - in rcache\n" if $debug_virtual_hash;
			return $rcache->{$pkey};
		}
		my $val;
		if ($vars->{alldelete}) {
			print "%*$id/'$pkey' vFETCH: undef - alldelete\n" if $debug_virtual_hash;
			$val = undef;
		} else {
			$val = $self->ORIGINAL_VALUE($pkey);
			if (exists $wcache->{$pkey}) {
				# 
				# Override bad value in wcache when reanimating $x{y} = \$x{y};
				#
				print "%*$id/$pkey vFETCH storing original value in WCACHE: $qval{$val}\n" if $debug_virtual_hash || $debug_refalias;
				$wcache->{$pkey} = $val;
			} else {
				print "%*$id/$pkey vFETCH original value: $qval{$val}\n" if $debug_virtual_hash;
				$rcache->{$pkey} = $val;
			}
		}
		$oops->assertions;
		print Carp::longmess("DEBUG: vFETCH(@_) returning") if 0; # debug
		return $val;
	}

	sub EXISTS
	{
		my ($self, $pkey) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		return undef unless defined $oops; # weak ref
		no warnings qw(uninitialized);
		print "%*$id/'$pkey' vEXISTS: 0 - dcache\n" if $debug_virtual_hash && exists $dcache->{$pkey};
		return 0 if exists $dcache->{$pkey};
		print "%*$id/'$pkey' vEXISTS: 1 - rcache\n" if $debug_virtual_hash && exists $rcache->{$pkey};
		print "%*$id/'$pkey' vEXISTS: 1 - wcache\n" if $debug_virtual_hash && exists $wcache->{$pkey};
		print "%*$id/'$pkey' vEXISTS: 1 - ovcache\n" if $debug_virtual_hash && exists $ovcache->{$pkey};
		return 1 if exists $rcache->{$pkey} || exists $wcache->{$pkey} || exists $ovcache->{$pkey};
		print "%*$id/'$pkey' vEXISTS: 0 - necache\n" if $debug_virtual_hash && exists $necache->{$pkey};
		return 0 if exists $necache->{$pkey};
		print "%*$id/'$pkey' vEXISTS: 0 - alldelete\n" if $debug_virtual_hash && $vars->{alldelete};
		return 0 if $vars->{alldelete};
		my ($pval, $ptype);
		my $loadpkeyQ = $oops->query('loadpkey', execute => [ $id, $pkey ]);
		if (($pval, $ptype) = $loadpkeyQ->fetchrow_array) {
			$loadpkeyQ->finish();
			if ($ptype) {
				$ovcache->{$pkey} = [ $pval, $ptype ];
			} else {
				$rcache->{$pkey} = $pval;
			}
			print "%*$id/'$pkey' vEXISTS: 0 - found in db\n" if $debug_virtual_hash;
			return 1;
		} else {
			$necache->{$pkey} = 1;
			print "%*$id/'$pkey' vEXISTS: 0 - not found in db\n" if $debug_virtual_hash;
			return 0;
		}
		$oops->assertions;
	}

	sub ORIGINAL_PTYPE
	{
		my ($self, $pkey) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		no warnings qw(uninitialized);
		if (exists $ovcache->{$pkey}) {
			print "%$id/$pkey vORIGINAL_PTYPE ovcache: @{$ovcache->{$pkey}}\n" if $debug_virtual_ovals;
			return @{$ovcache->{$pkey}};
		} else {
			my ($pval, $ptype);
			my $loadpkeyQ = $oops->query('loadpkey', execute => [ $id, $pkey ]);
			my $found = ($pval, $ptype) = $loadpkeyQ->fetchrow_array;
			$loadpkeyQ->finish();
			print "%$id/$pkey vORIGINAL_PTYPE none found\n" if $debug_virtual_ovals && ! $found;
			return () unless $found;
			$ovcache->{$pkey} = [ $pval, $ptype ]
				if $ptype;
			print "%$id/$pkey vORIGINAL_PTYPE lookup: $qval{$pval}/$ptype\n" if $debug_virtual_ovals;
			return ($pval, $ptype);
		}
	}

	sub ORIGINAL_VALUE
	{
		my ($self, $pkey) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		my ($pval, $ptype) = $self->ORIGINAL_PTYPE($pkey);

		if (! defined $ptype) {
			confess if defined $pval;
		} elsif ($ptype eq 'B') {
			print "%*$id/'$pkey' is big\n" if $debug_virtual_hash;
			$pval = $oops->load_big($id, $pkey);
		} elsif ($ptype eq 'R') {
			my $ov = $pval if $debug_virtual_hash;
			$pval = $oops->load_object($pval);
			print "%*$id/'$pkey' is object: *$ov: $qval{$pval}\n" if $debug_virtual_hash;
			#
			# possible side effects of load_object() include another call
			# to FETCH.
			#
		} elsif ($ptype ne '0') {
			confess;
		}
		no warnings qw(uninitialized);
		print "%*$id/$pkey vORIGINAL_VALUE = $qval{$pval}\n" if $debug_virtual_ovals;


		return $pval;
	}

	sub STORE
	{
		my ($self, $pkey, $pval) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		return undef unless defined $oops; # weak ref
		$oops->workaround27555($pval) if ref $pval;
		no warnings qw(uninitialized);
		$wcache->{$pkey} = $pval;
		$vars->{has_been_deleted}{$pkey} = 1 if $dcache->{$pkey};
		delete $dcache->{$pkey};
		delete $necache->{$pkey};
		delete $rcache->{$pkey};
		$oops->{demandwrite}{$id}++;
		$oops->assertions;
		print "%*$id/'$pkey' vSTORE into $qval{$qmakeref{$wcache->{$pkey}}}\n" if $debug_refalias;
		print "%*$id/'$pkey' vSTORE: $qval{$pval}\n" if $debug_virtual_hash;
		return $pval;
	}

	sub DELETE
	{
		my ($self, $pkey) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		no warnings qw(uninitialized);
		my $x = exists $wcache->{$pkey} 
			? $wcache->{$pkey}
			: $rcache->{$pkey};
		$dcache->{$pkey} = 1; # xxx set to $x?
		if ($oops->{reftarg}{$id}
			&& ! $vars->{alldelete} 
			&& ! exists $vars->{original_reference}{$pkey}
			&& (defined($x) || exists $wcache->{$pkey} || exists $rcache->{$pkey})
			&& ! exists $vars->{has_been_deleted}{$pkey})
		{
			if ($vars->{keyrefs}{$pkey}) {
				print "%$id/'$pkey' vDELETE orignal_reference copy from keyrefs $qaddr{$vars->{keyrefs}{$pkey}} ($vars->{keyrefs}{$pkey})\n" if $debug_refalias;
				$vars->{original_reference}{$pkey} = $vars->{keyrefs}{$pkey};
			} else {
				my $ref = \$x;
				print "%$id/'$pkey' vDELETE orignal_reference copy from keyrefs $qaddr{$ref} ($ref)\n" if $debug_refalias;
				$vars->{original_reference}{$pkey} = ref;
			}
		}
		if ($vars->{keyrefs}{$pkey}) {
			my $addr = refaddr($vars->{keyrefs}{$pkey});
			print "%*$id/'$pkey' vDELETE MEMORY2KEY($addr) := undef\n" if $debug_memory || $debug_refalias;
			$oops->memory2key($vars->{keyrefs}{$pkey});
		}
		delete $vars->{keyrefs}{$pkey};
		delete $wcache->{$pkey};
		delete $rcache->{$pkey};
		$oops->{demandwrite}{$id}++;
		print "%$id/'$pkey' - vDELETE\n" if $debug_virtual_delete || $debug_virtual_hash;
		$oops->assertions;
		return $x;
	}

	sub CLEAR
	{
		my ($self) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		return () unless defined $oops; # weak ref

		if ($vars->{alldelete}) {
			%$wcache = ();
		} else {
			delete @$wcache{keys %{$vars->{has_been_deleted}}};
			$vars->{pre_clear_wcache} = $wcache;
			if ($vars->{keyrefs}) {
				for my $pkey (keys %{$vars->{keyrefs}}) {
					no warnings qw(uninitialized);
					next if exists $vars->{original_reference}{$pkey};
					next if exists $dcache->{$pkey} || exists $vars->{has_been_deleted}{$pkey};
					next unless exists $rcache->{$pkey} || ((undef, undef) = $self->ORIGINAL_PTYPE($pkey));
					print "%$id/'$pkey' vCLEAR orignal_reference copy from keyrefs $qaddr{$vars->{keyrefs}{$pkey}} ($vars->{keyrefs}{$pkey})\n" if $debug_refalias;
					$vars->{original_reference}{$pkey} = $vars->{keyrefs}{$pkey};
				}
			}
			$self->[3] = {};
		}
		if ($vars->{keyrefs}) {
			for my $pkey (keys %{$vars->{keyrefs}}) {
				no warnings qw(uninitialized);
				my $ref = $vars->{keyrefs}{$pkey};
				my $addr = refaddr($ref);
				print "%*$id/'$pkey' vCLEAR MEMORY2KEY($addr) := undef\n" if $debug_memory || $debug_refalias;
				$oops->memory2key($ref);
			}
			delete $vars->{keyrefs};
		}
		delete $vars->{keyrefs};
		%$rcache = ();
		%$necache = ();
		%$ovcache = ();
		%$dcache = ();
		$vars->{alldelete} += 1;
		$oops->{demandwrite}{$id}++;
		$oops->assertions;
		print "%*$id vCLEAR\n" if $debug_virtual_hash;
		return ();
	}

	sub GETREFORIG
	{
		my ($self, $pkey) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		no warnings qw(uninitialized);
		if (exists $dcache->{$pkey} || $vars->{alldelete} || exists $vars->{has_been_deleted}{$pkey}) {
			$self->LOAD_SELF_REF($pkey);
			if (exists $vars->{original_reference}{$pkey}) {
				print "%*$id/$pkey GETREFORIG cached-answer $qaddr{$vars->{original_reference}{$pkey}} ($vars->{original_reference}{$pkey})\n" if $debug_refalias;
				return $vars->{original_reference}{$pkey};
			}
			#
			# If there has been a delete then we want a reference to the orignal value.
			# This reference must be shared between references.
			#
			my $pval;
			if (exists $vars->{pre_clear_wcache}{$pkey} && ((undef, undef) = $self->ORIGINAL_PTYPE($pkey))) {
				$pval = $vars->{pre_clear_wcache}{$pkey};
				print "%*$id/$pkey GETREFORIG pre-clear-wcache $qval{$pval}\n" if $debug_refalias;
			} else {
				$pval = $self->ORIGINAL_VALUE($pkey);
				print "%*$id/$pkey GETREFORIG original-value $qval{$pval}\n" if $debug_refalias;
			}
			my $ref = \$pval;
			print "%*$id/$pkey GETREFORIG new-answer $qaddr{$ref} ($ref)\n" if $debug_refalias;
			return ($vars->{original_reference}{$pkey} = $ref);
		}
		print "%*$id/$pkey GETREFORIG returning GETREF\n" if $debug_refalias;
		return $self->GETREF($pkey);
	}

	# 
	# This should be a normal tie method but it isn't so we depend on it's 
	# being called by workaround27555.
	#
	# The ordering of this is important: we pre-compute the return reference before
	# we figure out what the reference is to.  Subsequent calls can return before
	# we are done.
	#
	sub GETREF
	{
		my $self = shift;
		my $pkey = shift;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		no warnings qw(uninitialized);
		$self->STORE($pkey, undef) unless $self->EXISTS($pkey);
		my $wcache_already = exists $wcache->{$pkey};
		my $ref = \$wcache->{$pkey};
		$vars->{keyrefs}{$pkey} = $ref;
		$oops->memory2key($ref, $id, $pkey);
		$oops->{demandwrite}{$id}++;
		if ($wcache_already) {
			print "%*$id/$pkey vGETREF prior wcache: $qval{$wcache->{$pkey}}\n" if $debug_refalias;
		} else {
			if (exists $dcache->{$pkey}) {
				print "%*$id/$pkey vGETREF no wcache - dcache\n" if $debug_refalias;
				# done
			} elsif (exists $rcache->{$pkey}) {
				$wcache->{$pkey} = $rcache->{$pkey};
				delete $rcache->{$pkey};
				print "%*$id/$pkey vGETREF no wcache - rcache: $qval{$wcache->{$pkey}}\n" if $debug_refalias;
			} elsif ($vars->{alldelete}) {
				print "%*$id/$pkey vGETREF no wcache - alldelete\n" if $debug_refalias;
				# done
			} else {
				$wcache->{$pkey} = $self->ORIGINAL_VALUE($pkey);
				print "%*$id/$pkey vGETREF no wcache - original value: $qval{$wcache->{$pkey}}\n" if $debug_refalias;
			}
		}
		print "%*$id/'$pkey' vGETREF MEMORY2KEY $qval{$ref} := *$id/$pkey\n" if $debug_memory || $debug_refalias;
		$self->LOAD_SELF_REF($pkey);
		return $ref;
	}


	sub LOAD_SELF_REF
	{
		my $self = shift;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		return if exists $vars->{ref_to_self_loaded};
		my $searchQ;
		if (@_) {
			my $pkey = shift;
			no warnings qw(uninitialized);
			return if exists $vars->{ref_to_pkey_loaded}{$pkey};
			$vars->{ref_to_pkey_loaded}{$pkey} = 1; 
			print "\%$id searching for references to $qval{$pkey}\n" if $debug_refalias || $debug_virtual_delete || $debug_virtual_save;
			$searchQ = $oops->query('reftargkey', execute => [ $id, $pkey ]);
		} else {
			$vars->{ref_to_self_loaded} = 1; 
			print "\%$id searching for references to keys\n" if $debug_refalias || $debug_virtual_delete || $debug_virtual_save;
			$searchQ = $oops->query('reftargobject', execute => $id);
		}
		my $refid;
		while (($refid) = $searchQ->fetchrow_array()) {
			print "\%$id loading self-reference *$refid\n" if $debug_refalias || $debug_virtual_delete || $debug_virtual_save;
			unless (exists $oops->{cache}{$refid}) {
				$oops->load_object($refid);
				my $x = $oops->{cache}{$refid}; # force untie
			}
		}
		$searchQ->finish;
	}


	sub FIRSTKEY
	{
		my ($self) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;

		#
		# We don't share these because someone might want to do 
		# each() on more than one virutal object at the same time.
		# Of course, we could check for that...
		#
		$vars->{dbeach}->finish if ref($vars->{dbeach});
		if ($vars->{alldelete}) {
			$vars->{dbeach} = 1;
			print "%*$id vFIRSTKEY - wcache\n" if $debug_virtual_hash || $debug_demand_iterator;
		} else {
			$vars->{dbeach} = $oops->query('objectload', execute => $id);
			print "%*$id vFIRSTKEY - query\n" if $debug_virtual_hash || $debug_demand_iterator;
		}
		keys %$wcache; 			# reset iterator
		$oops->assertions;
		return $self->NEXTKEY();
	}

	sub NEXTKEY
	{
		my ($self, $pkey) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		my $dbe = $vars->{dbeach};
		return () unless $dbe;
		my ($name, $pval, $ptype);
		if (ref($dbe) && (($pkey, $pval, $ptype) = $dbe->fetchrow_array())) {
			{ no warnings; print "%*$id vNEXTKEY: query: '$pkey' ($pval/$ptype)\n" if $debug_virtual_hash || $debug_demand_iterator; }
			no warnings qw(uninitialized);
			if (exists $dcache->{$pkey}) {
				print "%$id - nextpkey deleted\n" if $debug_demand_iterator;
				goto &NEXTKEY;
			}
			unless ($oops->{args}{less_caching}) {
				if ($ptype) {
					$ovcache->{$pkey} = [ $pval, $ptype ];
				} else {
					$rcache->{$pkey} = $pval;
				}
			}
			if (exists $wcache->{$pkey}) {
				print "%$id - nextpkey is in wcache\n" if $debug_demand_iterator;
				goto &NEXTKEY;
			}
			return $pkey;
		} elsif (defined ($pkey = each(%$wcache))) {
			$vars->{dbeach} = 1
				if ref $vars->{dbeach};
			print "%*$id vNEXTKEY: wcache: '$pkey'\n" if $debug_virtual_hash || $debug_demand_iterator;
			return $pkey;
		} else {
			print "%*$id vNEXTKEY: done: undef\n" if $debug_virtual_hash || $debug_demand_iterator;
			delete $vars->{dbeach};
			return ();
		}
	}

	# to retrieve just some of the keys of a hash
	sub WALK_HASH
	{
		my ($self, $stride, $key) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;

		my $gs;
		if (@_ > 2 && defined($key)) {
			$gs = $oops->{dbo}->adhoc_query(<<END, execute => [ $id, $key ]);
				SELECT	pkey, pval, ptype 
				FROM	TP_attribute
				WHERE	id = ? 
				  AND	pkey > ?
				ORDER BY pkey
				LIMIT	$stride
END
		} else {
			$gs = $oops->{dbo}->adhoc_query(<<END, execute => [ $id ]);
				SELECT	pkey, pval, ptype
				FROM	TP_attribute
				WHERE	id = ? 
				ORDER BY pkey
				LIMIT	$stride
END
		}
		my @ret;
		my ($pkey, $pval, $ptype);
		while (($pkey, $pval, $ptype) = $gs->fetchrow_array()) {
			{ no warnings; print "%*$id vAUTO_SLICE: query: '$pkey' ($pval/$ptype)\n" if $debug_virtual_hash};
			no warnings qw(uninitialized);
			if (exists $dcache->{$pkey}) {
				print "%$id - nextpkey deleted\n" if $debug_demand_iterator;
				next;
			}
			unless ($oops->{args}{less_caching}) {
				if ($ptype) {
					$ovcache->{$pkey} = [ $pval, $ptype ];
				} else {
					$rcache->{$pkey} = $pval;
				}
			}
			if (exists $wcache->{$pkey}) {
				print "%$id - nextpkey is in wcache\n" if $debug_demand_iterator;
				next;
			}
			push(@ret, $pkey);
		}
		$gs->finish();
		return @ret;
	}

	sub SCALAR
	{
		my ($self) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;

		if ($vars->{alldelete}) {
			printf "%%*%d' vSCALAR: previous alldelete, returning %d (%s)\n", $id, scalar(keys(%$wcache)), scalar(%$wcache) if $debug_virtual_hash;
			return scalar(keys(%$wcache));
		}

		unless ($vars->{originalKeyCount}) {
			my $originalCountQ = $oops->query('countkeys', execute => [ $id ]);
			($vars->{originalKeyCount}) = $originalCountQ->fetchrow_array();
			$originalCountQ->finish();
		}

		my $doriginal = 0;
		my $loadpkeyQ;
		my %done;
		for my $pkey (keys %$dcache, keys %$wcache) {
			next if $done{$pkey}++;
			if (exists $rcache->{$pkey}) {
				print "%*$id/'$pkey' vSCALAR: in rcache\n"  if $debug_virtual_hash;
				$doriginal++;
				next;
			}
			if (exists $necache->{$pkey}) {
				print "%*$id/'$pkey' vSCALAR: in rcache\n"  if $debug_virtual_hash;
				next;
			}
			$loadpkeyQ = $oops->query('loadpkey')
				unless $loadpkeyQ;
			$loadpkeyQ->execute($id, $pkey);
			if (my ($pval, $ptype) = $loadpkeyQ->fetchrow_array) {
				$loadpkeyQ->finish();
				if ($ptype) {
					$ovcache->{$pkey} = [ $pval, $ptype ];
				} else {
					$rcache->{$pkey} = $pval;
				}
				$doriginal++;
				print "%*$id/'$pkey' vSCALAR: found in db\n" if $debug_virtual_hash;
			} else {
				$necache->{$pkey} = 1;
				print "%*$id/'$pkey' vSCALAR: not found in db\n" if $debug_virtual_hash;
			}
			die if $loadpkeyQ->{Active}; # debug
		}

		print "%*$id' vSCALAR: original key count = $vars->{originalKeyCount}\n" if $debug_virtual_hash;
		print "%*$id' vSCALAR: deleted/replaced count: $doriginal\n" if $debug_virtual_hash;
		printf "%%*%d' vSCALAR: write cache count: %d (%s)\n", $id, scalar(keys(%$wcache)), scalar(%$wcache) if $debug_virtual_hash;

		my $r = $vars->{originalKeyCount} - $doriginal + keys %$wcache;
		print "%*$id' vSCALAR: result = $r\n" if $debug_virtual_hash;
		return $r;
	}

	sub CLEAR_CACHE
	{
		my ($self) = @_;
		my ($oops, $id, $rcache, $wcache, $necache, $ovcache, $dcache, $vars) = @$self;
		$necache = ();
		$ovcache = ();
		if (%$dcache or $vars->{keyrefs}) {
			for my $i (keys %$rcache) {
				delete $rcache->{$i}
					unless	exists $dcache->{$i}
					or	exists $vars->{keyrefs}{$i}
			}
		} else {
			$rcache = ();
		}
		print "%*$id vCLEAR_CACHE\n" if $debug_virtual_hash;
	}
}
#	-	-	-	-	-	-	-	-	-	-	- 
{
	package OOPS::Aware;

	# methods to overload...

	sub object_id_assigned { my ($obj, $id) = @_; }
	sub destroy { }
}

#	-	-	-	-	-	-	-	-	-	-	- 

{
	package OOPS::FrontEnd;

	use Carp qw(longmess);
	use Scalar::Util qw(refaddr);

	sub new 
	{
		my ($pkg, $oops) = @_;
		tie my %x, 'OOPS::NamedObjects', $oops;
		my $self = bless \%x, $pkg;

		#
		# the following is a lie, but hopefully it's one that won't
		# be caught.
		#
		$oops->memory($self, 1);
		print "MEMORY OOPS::FE $qval{$self} := 1\n" if $debug_memory;

		$tiedvars{$self} = __PACKAGE__.longmess if $debug_tiedvars;
		return $self;
	}
	sub destroy		{ my $self = shift; { (tied %$self)->destroy; } untie %$self }
	sub DESTROY		{ my $self = shift; delete $tiedvars{$self} if $debug_tiedvars }
	sub commit		{ my $self = shift; my $tied = tied %$self; $tied->[0]->commit(@_); }
	sub virtual_object	{ my $self = shift; my $tied = tied %$self; $tied->[0]->virtual_object(@_); }
	sub workaround27555	{ my $self = shift; my $tied = tied %$self; $tied->[0]->workaround27555(@_); }
	sub load_object		{ my $self = shift; my $tied = tied %$self; $tied->[0]->load_object(@_); } 
	sub dbh			{ my $self = shift; my $tied = tied %$self; $tied->[0]->{dbo}->dbh }
	sub clear_cache		{ my $self = shift; my $tied = tied %$self; $tied->[0]->clear_cache(@_); }
	sub lock		{ my $self = shift; my $tied = tied %$self; $tied->[0]->lock(@_); }
	sub oops		{ my $self = shift; my $tied = tied %$self; return $self }
}

#	-	-	-	-	-	-	-	-	-	-	- 

{
	package OOPS::NamedObjects;

	use Carp qw(longmess);
	use Scalar::Util qw(refaddr);

	sub TIEHASH
	{
		my ($pkg, $oops) = @_;
		my $not = tied %{$oops->{named_objects}};
		my $self = bless [ $oops, $not ], $pkg;

		#
		# the following is a lie, but hopefully it's one that won't
		# be caught.
		#
		$oops->memory($self, 1);
		print "MEMORY OOPS::NO $qval{$self} := 1\n" if $debug_memory;

		$tiedvars{$self} = __PACKAGE__.longmess if $debug_tiedvars;
		return $self;
	}
	sub destroy	{ my $self = shift; $self->[0]->DESTROY; }
	sub DESTROY	{ my $self = shift; delete $tiedvars{$self} if $debug_tiedvars }
	sub FETCH	{ my $self = shift; $self->[1]->FETCH(@_) }
	sub EXISTS	{ my $self = shift; $self->[1]->EXISTS(@_) }
	sub STORE	{ my $self = shift; $self->[1]->STORE(@_) }
	sub DELETE	{ my $self = shift; $self->[1]->DELETE(@_) }
	sub CLEAR	{ my $self = shift; $self->[1]->CLEAR(@_) }
	sub GETREF	{ my $self = shift; $self->[1]->GETREF(@_) }
	sub FIRSTKEY	{ my $self = shift; $self->[1]->FIRSTKEY(@_) }
	sub NEXTKEY	{ my $self = shift; $self->[1]->NEXTKEY(@_) }
	sub SCALAR	{ my $self = shift; $self->[1]->SCALAR(@_) }
	sub SAVE_SELF	{ my $self = shift; $self->[1]->SAVE_SELF(@_) }
	sub POST_SAVE	{ my $self = shift; $self->[1]->POST_SAVE(@_) }
}

1;

__END__

TODO:

remove $oops->{loaded}?

TEST:

deadlock detection/avoidances multi-process integrety

some more hash tests in the cross-product tests

memory leaks with misc, ref, array, hash, and slowtest.

