#
#
# The most important thing in this example is the use of a domain type object.
# In this case domain type object and the appropriate type adapter are both
# implemented in the same package.
#
#
#   Martin Busik <martin.busik@busik.de>
#
package Test::C2FIT::eg::net::Simulator;
use base 'Test::C2FIT::Fixture';
use Test::C2FIT::eg::net::GeoCoordinate
  ;    # not really used, but coord is an instance of it...
use strict;

sub new {
    my $pkg = shift;
    my $h   = { coord => 'Test::C2FIT::eg::net::GeoCoordinate' };

    return bless {
        nodes               => 0,
        zip                 => undef,
        coord               => undef,
        methodColumnTypeMap => $h,      # getter map
        methodSetterTypeMap => $h,      # setter map
    }, $pkg;
}

sub ok {
    my $self = shift;
    $self->{nodes}++;
}

sub coord {
    my $self = shift;
    $self->{coord} = $_[0] if ( 0 < @_ );
    $self->{coord};
}
sub nodes      { $_[0]->{nodes} }
sub newCity    { }
sub cancel     { }
sub name       { }
sub zip        { }
sub population { }

1;
