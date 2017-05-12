
use Test::More tests => 8;
use strict;
use warnings;
use FindBin;
BEGIN { use_ok('MooseX::Documenter') }

ok( MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basicrole' ),
  'simple usage of example works.' );

my $doc = MooseX::Documenter->new( "$FindBin::Bin/samplemoose/", 'basicrole' );
$doc->setmooselib("$FindBin::Bin/samplemoose");

is_deeply( $doc->local_attributes, undef,
  'got expected return from local_attributes' );

is_deeply( $doc->inherited_attributes, undef,
  'got expected return from inherited_attributes' );

is_deeply(
  $doc->local_methods,
  {
    'not_equal_to' => 'sub not_equal_to {
  my( $self, $other ) = @_;
  not $self->equal_to($other);
}'
  },
  'got expected return from local_methods'
);

is_deeply( $doc->inherited_methods, undef,
  'got expected return from inherited_methods' );

is_deeply( $doc->class_parents, [], 'got expected return from class_parents' );

is_deeply( $doc->roles, undef, 'got expected return from roles' );

