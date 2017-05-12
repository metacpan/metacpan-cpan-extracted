use strict;
use warnings;

use Test::More tests => 4;

use Pollux::Action;

use experimental 'smartmatch';


my $AddTodo = Pollux::Action->new( 'ADD_TODO', 'text' );
my $DoneTodo = Pollux::Action->new( 'DONE_TODO', 'index' );

is "$AddTodo" => 'ADD_TODO', "stringification";

is_deeply $AddTodo->( 'do something' ) => {
    type => 'ADD_TODO',
    text => 'do something',
}, "create an action";

my $h = { type => 'ADD_TODO' };

ok $h ~~ $AddTodo, "smart match matches";
ok 'ADD_TODO' ~~ $AddTodo, "smart match matches strings";



