package MojoX::Authentication::Model::Role::Creator;
{ our $VERSION = '0.003' }

use v5.24;
use Moo::Role;
use experimental qw< signatures >;
use namespace::clean;

# see MojoX::Authentication::Model::Hash::create for usage of this method
sub _create_args ($self, $default_name, $config, %args) {
   my $name = $args{name} //= $default_name;
   $config = $config->{$name} // {};
   %args = (%args, $config->%*, name => $name);
   return %args;
}

1;
