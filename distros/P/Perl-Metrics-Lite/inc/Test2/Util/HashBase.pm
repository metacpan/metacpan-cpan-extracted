#line 1
package Test2::Util::HashBase;
use strict;
use warnings;

#################################################################
#                                                               #
#  This is a generated file! Do not modify this file directly!  #
#  Use hashbase_inc.pl script to regenerate this file.          #
#  The script is part of the Object::HashBase distribution.     #
#                                                               #
#################################################################

{
    no warnings 'once';
    $Test2::Util::HashBase::VERSION = '0.002';
    *Test2::Util::HashBase::ATTR_SUBS = \%Object::HashBase::ATTR_SUBS;
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

my %STRIP = (
    '^' => 1,
    '-' => 1,
);

sub import {
    my $class = shift;
    my $into  = caller;

    my $isa       = _isa($into);
    my $attr_subs = $Test2::Util::HashBase::ATTR_SUBS{$into} ||= {};
    my %subs      = (
        ($into->can('new') ? () : (new => \&_new)),
        (map %{$Test2::Util::HashBase::ATTR_SUBS{$_} || {}}, @{$isa}[1 .. $#$isa]),
        (
            map {
                my $p = substr($_, 0, 1);
                my $x = $_;
                substr($x, 0, 1) = '' if $STRIP{$p};
                my ($sub, $attr) = (uc $x, $x);
                $sub => ($attr_subs->{$sub} = sub() { $attr }),
                $attr => sub { $_[0]->{$attr} },
                  $p eq '-' ? ("set_$attr" => sub { Carp::croak("'$attr' is read-only") })
                : $p eq '^' ? ("set_$attr" => sub { Carp::carp("set_$attr() is deprecated"); $_[0]->{$attr} = $_[1] })
                :             ("set_$attr" => sub { $_[0]->{$attr} = $_[1] }),
            } @_
        ),
    );

    no strict 'refs';
    *{"$into\::$_"} = $subs{$_} for keys %subs;
}

sub _new {
    my ($class, %params) = @_;
    my $self = bless \%params, $class;
    $self->init if $self->can('init');
    $self;
}

1;

__END__

#line 289
