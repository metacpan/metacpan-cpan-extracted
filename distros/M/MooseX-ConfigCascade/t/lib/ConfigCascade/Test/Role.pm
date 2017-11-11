package ConfigCascade::Test::Role;

use Moose::Role;

has role_att => (is => 'rw', isa => 'Str', default => 'role_att from package');

1;
