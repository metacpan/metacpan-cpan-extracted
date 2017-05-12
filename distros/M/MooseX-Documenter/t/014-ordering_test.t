
use Test::More tests => 10;
use strict;
use warnings;
use FindBin;
BEGIN { use_ok('MooseX::Documenter') }

ok( MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basiccomplex' ),
  'simple usage of example works.' );

my $doc =
  MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basiccomplex' );
$doc->setmooselib("$FindBin::Bin/samplemoose");

is_deeply(
  $doc->inherited_attributes,
  {
    'usesrole' => {
      'x' => { isa => 'Int', is => 'rw', modifiers => 'required' },
      'y' => { isa => 'Int', is => 'rw', modifiers => 'required' } }
  },
  'got expected return from inherited_attributes'
);

is_deeply( $doc->roles, undef, 'got expected return from roles' );

is_deeply(
  $doc->class_parents,
  [ 'usesrole', 'Moose::Object' ],
  'got expected return from class_parents'
);

my $inherited_methods = $doc->inherited_methods;
isa_ok( $inherited_methods, 'HASH', 'inherited_methods return is hash' );
isa_ok( $inherited_methods->{'Moose::Object'},
  'HASH', 'Key, Moose::Object in hash' );
delete( $inherited_methods->{'Moose::Object'} );
is_deeply(
  $inherited_methods,
  {
    'usesrole' => {
      'clear' => 'sub clear {
  my $self = shift;
  $self->x(0);
  $self->y(0);
}',
      'meta' => undef
    }
  },
  'got expected return from inherited_methods'
);

is_deeply(
  $doc->local_attributes,
  { 'z' => { isa => 'Int', is => 'rw', modifiers => 'required' } },
  'got expected return from local_attributes'
);

is_deeply(
  $doc->local_methods,
  {
    meta    => undef,
    'clear' => 'sub clear {
  my $self = shift;
  $self->x(0);
  $self->y(0);
  $self->z(0);
}'
  },
  'got expected return from local_methods'
);

