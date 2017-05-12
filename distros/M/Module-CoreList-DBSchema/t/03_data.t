use strict;
use warnings;
use Test::More 'no_plan';
use Module::CoreList::DBSchema;

my $mcdbs = Module::CoreList::DBSchema->new();
my $data = $mcdbs->data();

is( ref $data, 'ARRAY', 'We got an arrayref back' );
foreach my $stmt ( @{ $data } ) {
  is( ref $stmt, 'ARRAY', 'Should be an arrayref' );
  cmp_ok( scalar @{ $stmt }, '>', 1, 'Should be more than 1 element' );
}
