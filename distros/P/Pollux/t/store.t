use strict;
use warnings;

use Test::More tests => 2;

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
            my $i = 0;
            [ map { ( $i++ != $action->{index} ) ? $_ : merge( $_, { completed => 1 } ) } @$state ];
        }
        default{ return $state }
    }
}

my $store = Pollux->new( reducer => {
    visibility_filter => \&visibility_filter,
    todos => \&todos });


my @log;

push @log, $store->state;

my $unsubscribe = $store->subscribe(sub($store) {
    push @log, $store->state;
});

$store->dispatch($AddTodo->('Learn about actions'));
$store->dispatch($AddTodo->('Learn about reducers'));
$store->dispatch($AddTodo->('Learn about store'));
$store->dispatch($CompleteTodo->(0));
$store->dispatch($CompleteTodo->(1));
$store->dispatch($SetVisibilityFilter->('SHOW_COMPLETED'));

$unsubscribe->();

$store->dispatch($AddTodo->('One more'));

is scalar @log => 7, '6 events + initial state';

is_deeply $store->state, {
   'todos' => [
     {
       'completed' => 1,
       'text' => 'Learn about actions'
     },
     {
       'completed' => 1,
       'text' => 'Learn about reducers'
     },
     {
       'completed' => 0,
       'text' => 'Learn about store'
     },
     {
       'completed' => 0,
       'text' => 'One more'
     }
   ],
   'visibility_filter' => 'SHOW_COMPLETED'
}, 'final state';


