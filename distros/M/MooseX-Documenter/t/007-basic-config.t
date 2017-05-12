
use Test::More tests => 12;
use strict;
use warnings;
use FindBin;
BEGIN { use_ok('MooseX::Documenter') }

ok( MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basic' ),
  'simple usage of example works.' );

my $doc = MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basic' );
ok(
  $doc->setmooselib("$FindBin::Bin/samplemoose"),
  'able to set new moose lib location'
);

is_deeply( $doc->local_attributes, undef,
  'got expected return from local_attributes' );

is_deeply( $doc->inherited_attributes, undef,
  'got expected return from inherited_attributes' );

is_deeply(
  $doc->local_methods,
  { meta => undef },
  'got expected return from local_methods'
);

my $inherited_methods = $doc->inherited_methods;
isa_ok( $inherited_methods, 'HASH', 'inherited_methods return is hash' );
isa_ok( $inherited_methods->{'Moose::Object'},
  'HASH', 'Key, Moose::Object in hash' );
is(
  $inherited_methods->{'Moose::Object'}->{'new'}, 'sub new {

  #PART of MooseX::Documenter checks
  my $class  = shift;
  my $params = $class->BUILDARGS(@_);
  my $self   = $class->meta->new_object($params);
  $self->BUILDALL($params);
  return $self;
}', 'Is using correct library'
);
delete( $inherited_methods->{'Moose::Object'} );
is_deeply( $inherited_methods, {},
  'got expected return from inherited_methods' );

is_deeply( $doc->class_parents, ['Moose::Object'],
  'got expected return from class_parents' );

is_deeply( $doc->roles, undef, 'got expected return from roles' );

