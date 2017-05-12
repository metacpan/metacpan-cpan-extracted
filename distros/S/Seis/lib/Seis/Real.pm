package Seis::Real;
use strict;
use warnings;
use utf8;
use 5.010_001;

package # Hide from PAUSE
    Real;

use POSIX ();

sub perl { $_[0] }

sub say { CORE::say($_[0]) }

sub clone { 0+$_[0] }

sub WHAT {
    my $self = shift;
    Seis::Class->_new(name => 'Rat');
}

sub Int { CORE::int($_[0]) }
sub floor { POSIX::floor($_[0]) }

sub fmt {
    my ($self, $pattern) = @_;
    sprintf($pattern, $self);
}

sub sign {
    my $self = shift;
    if ($self < 0) {
        -1;
    } elsif ($self == 0) {
        0;
    } else {
        1;
    }
}

sub isa {
    my ($self, $stuff) = @_;
    return UNIVERSAL::isa($self, $stuff->{name}) if UNIVERSAL::isa($stuff, 'Seis::Class');
    return 1 if $stuff eq 'Real';
    return 0;
}

1;

