
use Test::More tests => 10;
use Test::MockObject::Extends;
use strict;
use warnings;
use FindBin;
BEGIN { use_ok('MooseX::Documenter') }

ok( MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basicsimple' ),
  'simple usage of example works.' );

my $doc =
  MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basicsimple' );
$doc->setmooselib("$FindBin::Bin/samplemoose");
my $mock_object = Test::MockObject::Extends->new( $doc->{meta_object} );
$mock_object->set_always( 'get_attribute' => { lazy => 1 } );

is_deeply(
  $doc->local_attributes,
  {
    'x' => { isa => '', is => '', modifiers => 'lazy' },
    'y' => { isa => '', is => '', modifiers => 'lazy' }
  },
  'got expected return from local_attributes'
);

is_deeply( $doc->inherited_attributes, undef,
  'got expected return from inherited_attributes' );

is_deeply(
  $doc->local_methods,
  {
    meta    => undef,
    'clear' => 'sub clear {
  my $self = shift;
  $self->x(0);
  $self->y(0);
}'
  },
  'got expected return from local_methods'
);

my $inherited_methods = $doc->inherited_methods;
isa_ok( $inherited_methods, 'HASH', 'inherited_methods return is hash' );
isa_ok( $inherited_methods->{'Moose::Object'},
  'HASH', 'Key, Moose::Object in hash' );
delete( $inherited_methods->{'Moose::Object'} );
is_deeply( $inherited_methods, {},
  'got expected return from inherited_methods' );

is_deeply( $doc->class_parents, ['Moose::Object'],
  'got expected return from class_parents' );

is_deeply( $doc->roles, undef, 'got expected return from roles' );

