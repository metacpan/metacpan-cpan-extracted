package ConfigCascade::Test::HasRole;

use Moose;
with 'ConfigCascade::Test::Role';
with 'MooseX::ConfigCascade';

has non_role_att => (is => 'rw', isa => 'HashRef');

__PACKAGE__->meta->make_immutable;
1;

