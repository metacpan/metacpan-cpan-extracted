use 5.20.0;

use strict;
use warnings;

use Test::More tests => 5;

use Pollux;
use Pollux::Action;

use experimental 'switch', 'signatures';

my $AddTodo             = Pollux::Action->new( 'ADD_TODO', 'text' );
my $CompleteTodo        = Pollux::Action->new( 'COMPLETE_TODO', 'index' );
my $SetVisibilityFilter = Pollux::Action->new( 'SET_VISIBILITY_FILTER', 'filter' );

sub visibility_filter($action, $state = 'SHOW_ALL' ) {
  given ( $action ) {
      return $action->{filter} when $SetVisibilityFilter;
      default{ return $state }
  }
}

sub todos($action=undef,$state=[]) {
    given( $action ) {
        when( $AddTodo ) {
            return [ @$state, { text => $action->{text}, completed => 0 } ];
        }
        when ( $CompleteTodo ) {
            my $s = clone($state);
            $s->[ $action->{index} ]{completed} = 1;
            return $s;
        }
        default{ return $state }
    }
}

my $todo_app = combine_reducers({
    visibility_filter => \&visibility_filter,
    todos             => \&todos,
});

my $state = $todo_app->();

is_deeply $state => {
    visibility_filter => 'SHOW_ALL',
    todos => [],
}, "intial";

is_deeply visibility_filter( $SetVisibilityFilter->('banana') ) => 'banana',
    "visibility_filter on its own";

$state = $todo_app->( $SetVisibilityFilter->('HIDE_ALL'), $state );

is_deeply $state => {
    visibility_filter => 'HIDE_ALL',
    todos => [],
}, "SET_VISIBILITY_FILTER";

$state = $todo_app->( $AddTodo->('do stuff'), $state );

is_deeply $state => {
    visibility_filter => 'HIDE_ALL',
    todos => [ { text => 'do stuff', completed => 0 } ],
}, "add todo";

$state = $todo_app->( $CompleteTodo->(0), $state );

is_deeply $state => {
    visibility_filter => 'HIDE_ALL',
    todos => [ { text => 'do stuff', completed => 1 } ],
}, "complete todo";
