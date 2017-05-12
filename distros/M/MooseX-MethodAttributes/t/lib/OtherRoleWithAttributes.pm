package OtherRoleWithAttributes;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

sub bar : AnAttr { 'bar' }

1;

