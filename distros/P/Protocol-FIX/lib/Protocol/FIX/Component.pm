package Protocol::FIX::Component;

use strict;
use warnings;

use Protocol::FIX;
use mro;
use parent qw/Protocol::FIX::BaseComposite/;

our $VERSION = '0.07';    ## VERSION

=head1 NAME

Protocol::FIX::Component - aggregates fields, groups, components under single name

=cut

=head1 METHODS (for protocol developers)

=head3 new

    new($class, $name, $composites)

Creates new Component (performed by Protocol, when it parses XML definition)

=cut

sub new {
    my ($class, $name, $composites) = @_;

    my $obj = next::method($class, $name, 'component', $composites);

    return $obj;
}

1;
