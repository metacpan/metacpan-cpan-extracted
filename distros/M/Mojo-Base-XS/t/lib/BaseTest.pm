package BaseTest;

use strict;
use warnings;

use Mojo::Base 'BaseTest::Base2';

# "When I first heard that Marge was joining the police academy,
#  I thought it would be fun and zany, like that movie Spaceballs.
#  But instead it was dark and disturbing.
#  Like that movie... Police Academy."
__PACKAGE__->attr(heads => 1);
__PACKAGE__->attr('name' => sub { 'Named!' });
__PACKAGE__->attr('def_array' => sub { ['Named!'] });

1;
