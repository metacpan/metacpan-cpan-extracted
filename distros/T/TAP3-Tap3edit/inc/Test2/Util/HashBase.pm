#line 1
package Test2::Util::HashBase;
use strict;
use warnings;

our $VERSION = '1.302175';

#################################################################
#                                                               #
#  This is a generated file! Do not modify this file directly!  #
#  Use hashbase_inc.pl script to regenerate this file.          #
#  The script is part of the Object::HashBase distribution.     #
#  Note: You can modify the version number above this comment   #
#  if needed, that is fine.                                     #
#                                                               #
#################################################################

{
    no warnings 'once';
    $Test2::Util::HashBase::HB_VERSION = '0.009';
    *Test2::Util::HashBase::ATTR_SUBS = \%Object::HashBase::ATTR_SUBS;
    *Test2::Util::HashBase::ATTR_LIST = \%Object::HashBase::ATTR_LIST;
    *Test2::Util::HashBase::VERSION   = \%Object::HashBase::VERSION;
    *Test2::Util::HashBase::CAN_CACHE = \%Object::HashBase::CAN_CACHE;
}


require Carp;
{
    no warnings 'once';
    $Carp::Internal{+__PACKAGE__} = 1;
}

BEGIN {
    # these are not strictly equivalent, but for out use we don't care
    # about order
    *_isa = ($] >= 5.010 && require mro) ? \&mro::get_linear_isa : sub {
        no strict 'refs';
        my @packages = ($_[0]);
        my %seen;
        for my $package (@packages) {
            push @packages, grep !$seen{$_}++, @{"$package\::ISA"};
        }
        return \@packages;
    }
}

my %SPEC = (
    '^' => {reader => 1, writer => 0, dep_writer => 1, read_only => 0, strip => 1},
    '-' => {reader => 1, writer => 0, dep_writer => 0, read_only => 1, strip => 1},
    '>' => {reader => 0, writer => 1, dep_writer => 0, read_only => 0, strip => 1},
    '<' => {reader => 1, writer => 0, dep_writer => 0, read_only => 0, strip => 1},
    '+' => {reader => 0, writer => 0, dep_writer => 0, read_only => 0, strip => 1},
);

sub import {
    my $class = shift;
    my $into  = caller;

    # Make sure we list the OLDEST version used to create this class.
    my $ver = $Test2::Util::HashBase::HB_VERSION || $Test2::Util::HashBase::VERSION;
    $Test2::Util::HashBase::VERSION{$into} = $ver if !$Test2::Util::HashBase::VERSION{$into} || $Test2::Util::HashBase::VERSION{$into} > $ver;

    my $isa = _isa($into);
    my $attr_list = $Test2::Util::HashBase::ATTR_LIST{$into} ||= [];
    my $attr_subs = $Test2::Util::HashBase::ATTR_SUBS{$into} ||= {};

    my %subs = (
        ($into->can('new') ? () : (new => \&_new)),
        (map %{$Test2::Util::HashBase::ATTR_SUBS{$_} || {}}, @{$isa}[1 .. $#$isa]),
        (
            map {
                my $p = substr($_, 0, 1);
                my $x = $_;

                my $spec = $SPEC{$p} || {reader => 1, writer => 1};

                substr($x, 0, 1) = '' if $spec->{strip};
                push @$attr_list => $x;
                my ($sub, $attr) = (uc $x, $x);

                $attr_subs->{$sub} = sub() { $attr };
                my %out = ($sub => $attr_subs->{$sub});

                $out{$attr}       = sub { $_[0]->{$attr} }                                                  if $spec->{reader};
                $out{"set_$attr"} = sub { $_[0]->{$attr} = $_[1] }                                          if $spec->{writer};
                $out{"set_$attr"} = sub { Carp::croak("'$attr' is read-only") }                             if $spec->{read_only};
                $out{"set_$attr"} = sub { Carp::carp("set_$attr() is deprecated"); $_[0]->{$attr} = $_[1] } if $spec->{dep_writer};

                %out;
            } @_
        ),
    );

    no strict 'refs';
    *{"$into\::$_"} = $subs{$_} for keys %subs;
}

sub attr_list {
    my $class = shift;

    my $isa = _isa($class);

    my %seen;
    my @list = grep { !$seen{$_}++ } map {
        my @out;

        if (0.004 > ($Test2::Util::HashBase::VERSION{$_} || 0)) {
            Carp::carp("$_ uses an inlined version of Test2::Util::HashBase too old to support attr_list()");
        }
        else {
            my $list = $Test2::Util::HashBase::ATTR_LIST{$_};
            @out = $list ? @$list : ()
        }

        @out;
    } reverse @$isa;

    return @list;
}

sub _new {
    my $class = shift;

    my $self;

    if (@_ == 1) {
        my $arg = shift;
        my $type = ref($arg);

        if ($type eq 'HASH') {
            $self = bless({%$arg}, $class)
        }
        else {
            Carp::croak("Not sure what to do with '$type' in $class constructor")
                unless $type eq 'ARRAY';

            my %proto;
            my @attributes = attr_list($class);
            while (@$arg) {
                my $val = shift @$arg;
                my $key = shift @attributes or Carp::croak("Too many arguments for $class constructor");
                $proto{$key} = $val;
            }

            $self = bless(\%proto, $class);
        }
    }
    else {
        $self = bless({@_}, $class);
    }

    $Test2::Util::HashBase::CAN_CACHE{$class} = $self->can('init')
        unless exists $Test2::Util::HashBase::CAN_CACHE{$class};

    $self->init if $Test2::Util::HashBase::CAN_CACHE{$class};

    $self;
}

1;

__END__

#line 473
