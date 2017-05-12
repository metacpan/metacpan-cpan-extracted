# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Base.pm $ $Author: autrijus $
# $Revision: #8 $ $Change: 3850 $ $DateTime: 2003/01/25 20:03:29 $

package OurNet::BBS::Base;
use 5.006;

use strict;
no warnings 'deprecated';

use constant EGO    => 0; use constant FLAG  => 1;
use constant HASH   => 1; use constant ARRAY => 2;
use constant CODE   => 3; use constant GLOB  => 4;
use constant TYPES  => [qw/_ego _hash _array _code _glob/];
use constant SIGILS => [qw/$ % @ & */];

require PerlIO if $] >= 5.008;

# These magical hashes below holds all cached initvar constants:
# = subrountines   as $RegSub{$glob}
# = module imports as $RegMod{$glob}
# = variables      as $RegVar{$class}{$sym}

my (%RegVar, %RegSub, %RegMod);

my %Packlists; # $packlist cache for contains()

## Class Methods ######################################################
# These methods expects a package name as their first argument.

# constructor method; turn into an pseudo hash if _phash exists

use constant CONSTRUCTOR => << '.';
sub __PKG__::new {
    my __PACKAGE__ $self = bless([\%{__PKG__::FIELDS}], '__PACKAGE__');

#    eval {
    if (ref($_[1])) {
        # Passed in a single hashref -- assign it!
	%{$self} = %{$_[1]};
    }
    else {
        # Automagically fill in the fields.
	$self->{$_} = $_[$self->[0]{$_}] foreach ((__KEYS__)[0 .. $#_-1]);
    }
#    };

#    require Carp and Carp::confess($@) if $@;
    
__TIE__
    return $self->{_ego} = bless (\[$self, __OBJ__], '__PKG__');
}

1;
.

# import does following things:
# 1. set up @ISA.
# 2. export type constants.
# 3. set overload bits.
# 4. install accessor methods.
# 5. handle variable propagation.
# 6. install the new() handler.

require overload; # no import, please

sub import {
    my $class = shift;
    my $pkg   = caller(0);

    no strict 'refs';
    no warnings 'once';

    # in non-direct usage, only ournet client gets symbols and sigils.
    my $is_client = ($pkg eq 'OurNet::BBS::Client' or $pkg eq 'OurNet::BBS::OurNet::BBS');
    return unless $class eq __PACKAGE__ or $is_client;

    *{"$pkg\::$_"} = \&{$_} foreach qw/EGO FLAG HASH ARRAY CODE GLOB/;
    return *{"$pkg\::SIGILS"} = \&{SIGILS} if $is_client;

    *{"$pkg\::ego"} = sub { ${$_[0]}->[0] };

    push @{"$pkg\::ISA"}, $class;

    my (@overload, $tie_eval, $obj_eval);
    my $fields = \%{"$pkg\::FIELDS"};

    foreach my $type (HASH .. GLOB) {
	if (exists($fields->{TYPES->[$type]})) { # checks for _hash .. _glob
	    my $sigil = SIGILS->[$type];

	    push @overload, "$sigil\{}" => sub { 
		# use Carp; eval { ${$_[0]}->[$type] } || Carp::confess($@) 
		${$_[0]}->[$type]
	    };

	    if ($type == HASH or $type == ARRAY) {
		$tie_eval = "tie my ${sigil}obj => '$pkg', ".
		            "[\$self, $type];\n" . $tie_eval;
		$obj_eval .= ", \\${sigil}obj";
	    }
	    elsif ($type == CODE) {
		$tie_eval .= 'my $code = sub { $self->refresh(undef, CODE);'.
			     '$self->{_code}(@_) };';
		$obj_eval .= ', $code';
	    }
	    elsif ($type == GLOB) {
		$tie_eval = 'my $glob = \$self->{_glob};' . $tie_eval;
		$obj_eval .= ', $glob';
	    }
	}
	else {
	    $obj_eval .= ', undef';
	    
	}
    }

    $obj_eval =~ s/(?:, undef)+$//;

    my $sub_new = CONSTRUCTOR;
    my $keys = join(' ', sort {
	$fields->{$a} <=> $fields->{$b} 
    } grep {
	/^[^_]/ 
    } keys(%{$fields}));

    $sub_new =~ s/__TIE__/$tie_eval/g;
    $sub_new =~ s/__OBJ__/$obj_eval/g;
    $sub_new =~ s/__PKG__/$pkg/g;
    $sub_new =~ s/__KEYS__/qw{$keys}/g;
    $sub_new =~ s/__PACKAGE__/OurNet::BBS::Base/g;

    unless (eval $sub_new) {
	require Carp;
	Carp::confess "$sub_new\n\n$@";
    }

    $pkg->overload::OVERLOAD(
	@overload,
	'""'   => sub { overload::AddrRef($_[0]) },
	'0+'   => sub { 0 },
	'bool' => sub { 1 },
	'cmp' => sub { "$_[0]" cmp "$_[1]" },
	'<=>' => sub { "$_[0]" cmp "$_[1]" }, # for completeness' sake
    );

    # install accessor methods
    unless (UNIVERSAL::can($pkg, '__accessor')) {
        foreach my $property (keys(%{"$pkg\::FIELDS"}), '__accessor') {
            *{"$pkg\::$property"} = sub {
                my $self = ${$_[0]}->[EGO];
		$self->refresh_meta;
                $self->{$property} = $_[1] if $#_;
                return $self->{$property};
            };
        }
    }

    # my $backend = $1 if $pkg =~ m|^OurNet::BBS::([^:]+)|;
    my $backend = substr($pkg, 13, index($pkg, ':', 14) - 13); # fast

    my @defer; # delayed aliasing until variables are processed
    foreach my $parent (@{"$pkg\::ISA"}) {
        next if $parent eq __PACKAGE__; # Base won't use mutable variables

        while (my ($sym, $ref) = each(%{"$parent\::"})) {
	    push @defer, ($pkg, $sym, $ref);
        }

	unshift @_, @{$RegMod{$parent}} if ($RegMod{$parent});
    }

    while (my ($mod, $symref) = splice(@_, 0, 2)) {
        if ($mod =~ m/^\w/) { # getvar from other modules
	    push @{$RegMod{$pkg}}, $mod, $symref;

            require "OurNet/BBS/$backend/$mod.pm";
            $mod = "OurNet::BBS::$backend\::$mod";

            foreach my $symref (@{$symref}) {
                my ($ch, $sym) = CORE::unpack('a1a*', $symref);
		die "can't import: $mod\::$sym" unless *{"$mod\::$sym"};

		++$RegVar{$pkg}{$sym};

                *{"$pkg\::$sym"} = (
                    $ch eq '$' ? \${"$mod\::$sym"} :
                    $ch eq '@' ? \@{"$mod\::$sym"} :
                    $ch eq '%' ? \%{"$mod\::$sym"} :
                    $ch eq '*' ? \*{"$mod\::$sym"} :
                    $ch eq '&' ? \&{"$mod\::$sym"} : undef
                );
            }
        }
        else { # this module's own setvar
            my ($ch, $sym) = CORE::unpack('a1a*', $mod);

	    *{"$pkg\::$sym"} = ($ch eq '$') ? \$symref : $symref;
	    ++$RegVar{$pkg}{$sym};
        }
    }

    my @defer_sub; # further deferred subroutines that needs localizing
    while (my ($pkg, $sym, $ref) = splice(@defer, 0, 3)) {
	next if exists $RegVar{$pkg}{$sym} # already imported
	     or *{"$pkg\::$sym"}{CODE}; # defined by use subs

	if (defined(&{$ref})) { 
	    push @defer_sub, ($pkg, $sym, $ref);
	    next; 
	}

	next unless ($ref =~ /^\*(.+)::(.+)/)
	        and exists $RegVar{$1}{$2};

	*{"$pkg\::$sym"} = $ref;
	++$RegVar{$pkg}{$sym};
    } 

    # install per-package wrapper handlers for mutable variables
    while (my ($pkg, $sym, $ref) = splice(@defer_sub, 0, 3)) {
	my $ref = ($RegSub{$ref} || $ref);
	next unless ($ref =~ /^\*(.+)::([^:]+)$/);
	next if defined(&{"$pkg\::$sym"});

	if (%{$RegVar{$pkg}}) {
	    eval qq(
		sub $pkg\::$sym {
	    ) . join('', 
		map { qq(
		    local *$1\::$_ = *$pkg\::$_;
		)} (keys(%{$RegVar{$pkg}}))
	    ) . qq(
		    &{$ref}(\@_);
		};
	    );
	}
	else {
	    *{"$pkg\::$sym"} = $ref;
	};

	$RegSub{"*$pkg\::$sym"} = $ref;
    }

    return unless $OurNet::BBS::Encoding;
    *{"$pkg\::unpack"} = \&_unpack;
    *{"$pkg\::pack"} = \&_pack;
}

sub _unpack {
    require Encode;
    return map Encode::decode($OurNet::BBS::Encoding => $_), CORE::unpack($_[0], $_[1]);
}

sub _pack {
    require Encode;
    return CORE::pack($_[0], map Encode::encode($OurNet::BBS::Encoding => $_), @_[1..$#_]);
}

## Instance Methods ###################################################
# These methods expects a tied object as their first argument.

# unties through an object to get back the true $self
sub ego { $_[0] }

# the all-important cache refresh instance method
sub refresh {
    my $self = shift;
    my $ego;

    ($self, $ego) = (ref($self) eq __PACKAGE__)
	? ($self->{_ego}, $self)
	: ($self, ${$self}->[EGO]);

    no strict 'refs';

    my $prefix = ref($self)."::refresh_";
    my $method = $_[0] && defined(&{"$prefix$_[0]"}) 
	? "$prefix$_[0]" : $prefix.'meta';

    return $method->($ego, @_);
}

# opens access to connections via OurNet protocol
sub daemonize {
    require OurNet::BBS::Server;
    OurNet::BBS::Server->daemonize(@_);
}

=begin comment

# The following code doesn't work, because they always override.

# permission checking; fall-back for undefined packages
sub writeok {
    my ($self, $user, $op, $argref) = @_;

    print "warning: permission model for ".ref($self)." unimplemented.\n".
          "         access forbidden for user ".$user->id().".\n"
	if $OurNet::BBS::DEBUG;

    return;
}

# ditto
sub readok {
    my ($self, $user, $op, $argref) = @_;

    print "warning: permission model for ".ref($self)." unimplemented.\n".
          "         access forbidden for user ".$user->id().".\n"
	if $OurNet::BBS::DEBUG;

    return;
}

=end comment
=cut

# clears internal memory; uses CLEAR instead
sub purge {
    $_[0]->ego->{_ego}->CLEAR;
}

# returns the BBS backend for the object
sub backend {
    my $backend = ref($_[0]);

    $backend = ref($_[0]{_ego}) if $backend eq __PACKAGE__;
    $backend = substr($backend, 13, index($backend, ':', 14) - 13); # fast
    # $backend = $1 if $backend =~ m|^OurNet::BBS::(\w+)|;

    return $backend;
}

# developer-friendly way to check files' timestamp for mtime fields
sub filestamp {
    my ($self, $file, $field, $check_only) = @_;
    my $time = (stat($file))[9];

    no warnings 'uninitialized';

    return 1 if $self->{$field ||= 'mtime'} == $time;
    $self->{$field} = $time unless $check_only;

    return 0; # something changed
}

# developer-friendly way to check timestamp for mtime fields
sub timestamp {
    my ($self, $time, $field, $check_only) = @_;

    no warnings 'uninitialized';

    return 1 if $self->{$field ||= 'mtime'} == $time;
    $self->{$field} = $time unless $check_only;

    return 0; # something changed
}

# check if something's in packlist; packages don't contain undef
sub contains {
    my ($self, $key) = @_;
    $self = $self->{_ego} if ref($self) eq __PACKAGE__;

    no strict 'refs';
    no warnings 'uninitialized';
    # print "checking $key against $self: @{ref($self).'::packlist'}\n";

    return (length($key) and index(
        $Packlists{ref($self)} ||= " @{ref($self).'::packlist'} ",
        " $key ",
    ) > -1);
}

# loads a module: ($self, $backend, $module).
sub fillmod {
    my $self = $_[0];
    $self =~ s|::|/|g;
    
    require "$self/$_[1]/$_[2].pm";
    return "$_[0]::$_[1]::$_[2]";
}

# create a new module and fills in arguments in the expected order
sub fillin {
    my ($self, $key, $class) = splice(@_, 0, 3);
    return if defined($self->{_hash}{$key});

    $self->{_hash}{$key} = OurNet::BBS->fillmod(
	$self->{backend}, $class
    )->new(@_);

    return 1;
}

# returns the module in the same backend, or $val's package if supplied
sub module {
    my ($self, $mod, $val) = @_;

    if ($val and UNIVERSAL::isa($val, 'UNIVERSAL')) {
	my $pkg = ref($val);

	if (UNIVERSAL::isa($val, 'HASH')) {
	    # special case: somebody blessed a hash to put into STORE.
	    bless $val, 'main'; # you want black magic?
	    $_[2] = \%{$val};   # curse (unbless) it!
	}

	return $pkg;
    }

    my $backend = $self->backend;
    require "OurNet/BBS/$backend/$mod.pm";
    return "OurNet::BBS::$backend\::$mod";
}

# object serialization for OurNet::Server calls; does nothing otherwise
sub SPAWN { return $_[0] }
sub REF { return ref($_[0]) }
sub KEYS { return keys(%{$_[0]}) }

# XXX: Object injection
sub INJECT {
    my ($self, $code, @param) = @_;

    if (UNIVERSAL::isa($code, 'CODE')) {
	require B::Deparse;

	my $deparse = B::Deparse->new(qw/-p -sT/);
	$code = $deparse->coderef2text($code);
	$code =~ s/^\s+use (?:strict|warnings)[^;\n]*;\n//m;
    }

    require Safe;
    my $safe = Safe->new;
    $safe->permit_only(qw{
	:base_core padsv padav padhv padany rv2gv refgen srefgen ref gvsv gv gelem
    });

    my $result = $safe->reval("sub $code");
    warn $@ if $@;

    return sub { $result->($self, @_) };
}

## Tiescalar Accessors ################################################
# XXX: Experimental: Globs only.

sub TIESCALAR {
    return bless(\$_[1], $_[0]);
}

## Tiearray Accessors #################################################
# These methods expects a raw (untied) object as their first argument.

# merged hasharray!
sub TIEARRAY {
    return bless(\$_[1], $_[0]);
}

sub FETCHSIZE {
    my ($self, $key) = @_;
    my ($ego, $flag) = @{${$self}};

    $self->refresh(undef, ARRAY);

    return scalar @{$ego->{_array} ||= []};
}

sub PUSH {
    my $self = shift;
    my $size = $self->FETCHSIZE;

    foreach my $item (@_) {
        $self->STORE($size++, $item);
    }
}

## Tiehash Accessors ##################################################
# These methods expects a raw (untied) object as their first argument.

# the Tied Hash constructor method
sub TIEHASH {
    return bless(\$_[1], $_[0]);
}

# fetch accessesor
sub FETCH {
    my ($self, $key) = @_;
    my ($ego, $flag) = @{${$self}};

    $self->refresh($key, $flag);

    return ($flag == HASH) ? $ego->{_hash}{$key} : $ego->{_array}[$key];
}

# fallback implementation to STORE
sub STORE {
    die "@_: STORE unimplemented";
}

# delete an element; calls its remove() subroutine to handle actual removal
sub DELETE {
    my ($self, $key) = @_;
    my ($ego, $flag) = @{${$self}};

    $self->refresh($key, $flag);

    if ($flag == HASH) {
	return unless exists $ego->{_hash}{$key};
	$ego->{_hash}{$key}->ego->remove
	    if UNIVERSAL::can($ego->{_hash}{$key}, 'ego');
	return delete($ego->{_hash}{$key});
    }
    else {
	return unless exists $ego->{_array}[$key];
	$ego->{_array}[$key]->ego->remove
	    if UNIVERSAL::can($ego->{_array}[$key], 'ego');
	return delete($ego->{_array}[$key]);
    }
}

# check for existence of a key.
sub EXISTS {
    my ($self, $key) = @_;
    my ($ego, $flag) = @{${$self}};

    $self->refresh($key, $flag);

    return ($flag == HASH) ? exists $ego->{_hash}{$key} 
                           : exists $ego->{_array}[$key];
}

# iterator; this one merely uses 'scalar keys()'
sub FIRSTKEY {
    my $self = $_[0];
    my $ego = ${$self}->[EGO];

    $ego->refresh_meta(undef, HASH);

    scalar keys (%{$ego->{_hash}});
    return $self->NEXTKEY;
}

# ditto
sub NEXTKEY {
    my $self = $_[0];

    return each %{${$self}->[EGO]->{_hash}};
}

# empties the cache, do not DELETE the objects themselves
sub CLEAR {
    my $self = ${$_[0]}->[EGO];

    %{$self->{_hash}}  = () if (exists $self->{_hash});
    @{$self->{_array}} = () if (exists $self->{_array});
}

# could care less
sub DESTROY () {};
sub UNTIE   () {};

our $AUTOLOAD;

sub AUTOLOAD {
    my $action = substr($AUTOLOAD, (
        (rindex($AUTOLOAD, ':') - 1) || return
    ));

    no strict 'refs';

    *{$AUTOLOAD} = sub {
	use Carp; confess ref($_[0]->{_ego}).$action
	    unless defined &{ref($_[0]->{_ego}).$action};
	goto &{ref($_[0]->{_ego}).$action}
    };

    goto &{$AUTOLOAD};
}

1;
