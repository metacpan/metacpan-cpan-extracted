package UsesMultipleRoles;
use Moose;
use namespace::autoclean;

with qw/
    RoleWithAttributes
    OtherRoleWithAttributes
/;

#__PACKAGE__->meta->make_immutable;

