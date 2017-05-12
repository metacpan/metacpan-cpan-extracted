package SIAM::Contract;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::Service;

=head1 NAME

SIAM::Contract - Contract object class

=head1 SYNOPSIS

   my $all_contracts = $siam->get_all_contracts();
   my $user_contracts =
       $siam->get_contracts_by_user_privilege($user, 'ViewContract');

   my $services = $contract->get_services();

=head1 METHODS

=head2 get_services

Returns arrayref with SIAM::Service objects

=cut

sub get_services
{
    my $self = shift;
    return $self->get_contained_objects('SIAM::Service');
}


# mandatory attributes

my $mandatory_attributes =
    [ 'siam.contract.inventory_id',
      'siam.contract.customer_name',
      'siam.contract.customer_id',];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}

sub _manifest_attributes
{
    my $ret = [];
    push(@{$ret}, @{$mandatory_attributes},
         @{ SIAM::Service->_manifest_attributes() });

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
