package ClassUsingRoleWithAttributes;
use Moose;
# FIXME - This should not have to be here.
use MooseX::MethodAttributes;

use namespace::autoclean;

with 'RoleWithAttributes';

__PACKAGE__->meta->make_immutable;

