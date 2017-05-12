package SIAM::ServiceUnit;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::ServiceComponent;

=head1 NAME

SIAM::ServiceUnit - Service Unit object class

=head1 SYNOPSIS

   my $components = $svcunit->get_components();

=head1 METHODS

=head2 get_components

Returns arrayref with SIAM::ServiceComponent objects

=cut

sub get_components
{
    my $self = shift;
    return $self->get_contained_objects('SIAM::ServiceComponent');
}


            
    
# mandatory attributes

my $mandatory_attributes =
    [ 'siam.svcunit.name',
      'siam.svcunit.type',
      'siam.svcunit.inventory_id', ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}


sub _manifest_attributes
{
    my $ret = [];
    push(@{$ret}, @{$mandatory_attributes},
         @{ SIAM::ServiceComponent->_manifest_attributes() });

    return $ret;

}


1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
