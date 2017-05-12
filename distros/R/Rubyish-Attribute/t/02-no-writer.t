use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Animal;

plan tests => 3;

# There is reader, no writer.
# $dogy->color #=> black
# $dogy->color("white") #=> undef

my $dog_name = "rock";
my $dog_color = 'black';
my $dogy = Animal->new({
    name => $dog_name,
    color => $dog_color,
    type => "unknown",
});

ok($dogy->can("color"), "There is a reader 'color'");
is($dogy->color, $dog_color, "Color of the dog is $dog_color");
is($dogy->color("white"), undef, "Call setter but return undef");

