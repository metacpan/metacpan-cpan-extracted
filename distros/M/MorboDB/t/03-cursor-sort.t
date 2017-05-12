#!perl

use warnings;
use strict;

use Test::More;
use Test::FailWarnings;
use MorboDB;
use Tie::IxHash;

# Create a collection and add a few numeric values
my $Morbo      = MorboDB->new;
my $DB         = $Morbo->get_database('db');
my $Collection = $DB->get_collection('numbers');
$Collection->batch_insert([
   { value => 1 },
   { value => 2 },
   { value => 3 },
]);


##
## Sort with HashRef
##

{
   # Sort all rows using a hashref argument to sort()
   my @rows = $Collection->find->sort({ value => -1 })->all;

   # Ensure the sort worked
   my @values = map { $_->{value} } @rows;
   is_deeply
      [ @values ],
      [ 3, 2, 1 ],
      "Basic MorboDB::Cursor::sort() works with Hashref argument";
}


##
## Sort with Tie::IxHash
##

{
   # Sort all rows using a Tie::IxHash argument to sort()
   my $sort = Tie::IxHash->new(value => 1);
   my @rows = $Collection->find->sort($sort)->all;

   # Ensure the sort worked
   my @values = map { $_->{value} } @rows;
   is_deeply
      [ @values ],
      [ 1, 2, 3 ],
      "Basic MorboDB::Cursor::sort() works with Tie::IxHash argument";
}


done_testing;
