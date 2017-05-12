package OX::Meta::Role::Application::ToInstance;
BEGIN {
  $OX::Meta::Role::Application::ToInstance::AUTHORITY = 'cpan:STEVAN';
}
$OX::Meta::Role::Application::ToInstance::VERSION = '0.14';
use Moose::Role;
use namespace::autoclean;

with 'OX::Meta::Role::Application';

sub _apply_routes {
    my $self = shift;
    my ($role, $obj) = @_;

    $obj->regenerate_router_config;
}

=for Pod::Coverage

=cut

1;
