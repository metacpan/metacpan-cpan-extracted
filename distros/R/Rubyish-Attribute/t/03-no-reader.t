use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Animal;

plan tests => 3;

# There is writer, no reader;
# $dogy->type #=> undef
# $dogy->type("newtype") #=> $dogy
my $dog_name = "rock";
my $dog_color = 'black';
my $dog_type = "unknown";

my $dogy = Animal->new({
    name => $dog_name,
    color => $dog_color,
    type => $dog_type,
});

not ok($dogy->can("type"), "There is no reader 'type'");
is($dogy->type("newtype"),$dogy, "Call setter and return itself");
isnt($dogy->type, $dog_type, "There is no reader here.");

