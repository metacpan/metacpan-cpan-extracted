
use Test::More tests => 10;
use strict;
use warnings;
use FindBin;
BEGIN { use_ok('MooseX::Documenter') }

ok( MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basic' ),
  'simple usage of example works.' );

my $doc = MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basic' );
$doc->setmooselib("$FindBin::Bin/samplemoose");

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
delete( $inherited_methods->{'Moose::Object'} );
is_deeply( $inherited_methods, {},
  'got expected return from inherited_methods' );

is_deeply( $doc->class_parents, ['Moose::Object'],
  'got expected return from class_parents' );

is_deeply( $doc->roles, undef, 'got expected return from roles' );

