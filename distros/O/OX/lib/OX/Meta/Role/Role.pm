package OX::Meta::Role::Role;
BEGIN {
  $OX::Meta::Role::Role::AUTHORITY = 'cpan:STEVAN';
}
$OX::Meta::Role::Role::VERSION = '0.14';
use Moose::Role;
use namespace::autoclean;

with 'OX::Meta::Role::HasRouteBuilders',
     'OX::Meta::Role::HasRoutes',
     'OX::Meta::Role::HasMiddleware';

sub composition_class_roles {
    return 'OX::Meta::Role::Composite';
}

=for Pod::Coverage
  composition_class_roles

=cut

1;
