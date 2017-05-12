package OX::Meta::Role::Application;
BEGIN {
  $OX::Meta::Role::Application::AUTHORITY = 'cpan:STEVAN';
}
$OX::Meta::Role::Application::VERSION = '0.14';
use Moose::Role;
use namespace::autoclean;

requires '_apply_routes';

after apply => sub {
    my $self = shift;
    my ($role, $class) = @_;

    $self->_apply_routes($role, $class);
};

=for Pod::Coverage

=cut

1;
