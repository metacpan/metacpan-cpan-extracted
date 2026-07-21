package MojoX::Authentication::Model::Role::MojoDbWrap;
{ our $VERSION = '0.004' }

use v5.24;
use Moo::Role;
use experimental qw< signatures >;
use MojoX::Authentication::Util qw< coercer_for >;
use namespace::clean;

has wmdb => (is => 'ro', required => 1,
   coerce => coercer_for(wmdb => 'MojoX::MojoDbWrap'));

1;
