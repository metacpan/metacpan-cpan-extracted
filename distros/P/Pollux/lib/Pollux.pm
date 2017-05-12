package Pollux;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Redux-like store
$Pollux::VERSION = '0.0.2';

use strict;
use warnings;

use Hash::Merge    qw/ merge/;
use Clone          qw/ clone /;
use List::AllUtils qw/ pairmap reduce /;
use Type::Tiny;
use Types::Standard qw/ CodeRef ArrayRef HashRef Any /;
use Scalar::Util qw/ refaddr /;
use Const::Fast;

use List::AllUtils qw/ reduce /;

use Moose;

use Moose::Exporter;


Moose::Exporter->setup_import_methods(
    as_is => [qw/ clone merge combine_reducers /],
);

use MooseX::MungeHas 'is_ro';

use experimental 'signatures', 'current_sub';


has state => (
    is        => 'rwp',
    predicate => 1,
    coerce    =>  1,
    isa       =>Type::Tiny->new->plus_coercions(
                  Any ,=> sub { const my $immu = $_; return $immu }
              ),
    trigger   => sub($self,$new,$old=undef) {
        no warnings 'uninitialized';

        return if $new eq $old;

        $self->unprocessed_subscribers([ $self->all_subscribers ]); 

        $self->notify;
    },
);

has reducer => (
    required => 1,
    coerce   => 1,
    isa      => Type::Tiny->new(
                    parent => CodeRef,
                )->plus_coercions(
                    HashRef ,=> sub { combine_reducers( $_ ) }
                ),
);

has middlewares => (
    is => 'ro',
    traits => [ qw/ Array / ],
    default => sub { [] },
    handles => {
        all_middlewares => 'elements',
    },
);


has subscribers => (
    traits => [ 'Array' ],
    is => 'rw',
    default => sub { [] },
    handles => {
        all_subscribers  => 'elements',
        add_subscriber   => 'push',
        grep_subscribers => 'grep',
    },
);

has unprocessed_subscribers => (
    traits     => [ 'Array' ],
    is         => 'rw',
    default    => sub { [] },
    handles    => {
        shift_unprocessed_subscribers => 'shift',
    },
);



sub subscribe($self,$code) { 
    $self->add_subscriber($code);

    my $addr = refaddr $code;

    return sub { $self->subscribers([ 
        $self->grep_subscribers(sub{ $addr != refaddr $_ })
    ]) } 
}

sub notify($self) {
    my $sub = $self->shift_unprocessed_subscribers or return;
    $sub->($self);
    goto __SUB__;  # tail recursion!
}

sub _dispatch_list {
    my $self = shift;
    return $self->all_middlewares, sub { $self->_dispatch(shift) };
}

sub dispatch($self,$action) { 
    ( reduce {
        # inner scope to thwart reduce scoping issue
        { 
            my ( $inner, $outer ) = ($a,$b);
            sub { $outer->( $self, $inner, shift ) };
        }
    } reverse $self->_dispatch_list )->($action);
}

sub _dispatch($self,$action) { 
    $self->_set_state( $self->reducer->(
        $action, $self->has_state ? $self->state : () 
    ));
}

Hash::Merge::specify_behavior({
        SCALAR => {
            map { $_ => sub { $_[1] } } qw/ SCALAR ARRAY HASH /
        },
        ARRAY => {
            map { $_ => sub { $_[1] } } qw/ SCALAR ARRAY HASH /
        },
        HASH => {
            HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
            map { $_ => sub { $_[1] } } qw/ SCALAR ARRAY /,
        },
}, 'Pollux');

sub combine_reducers {
    my $reducers = shift;

    return sub($action=undef,$store={}) {
        reduce {
            merge( $a, $b ) }  $store,
            pairmap { +{ $a => $b->($action, exists $store->{$a} ? $store->{$a} : () ) } }
            %$reducers;
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pollux - Redux-like store

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use Pollux;
    use Pollux::Action;

    my $store = Pollux->new(
        reducer => {
            visibility_filter => \&visibility_filter,
            todos             => \&todos
        },
    );

    my $AddTodo             = Pollux::Action->new( 'ADD_TODO', 'text' );
    my $CompleteTodo        = Pollux::Action->new( 'COMPLETE_TODO', 'index' );
    my $SetVisibilityFilter = Pollux::Action->new( 'SET_VISIBILITY_FILTER', 'filter' );

    sub visibility_filter($action, $state = 'SHOW_ALL' ) {
        given ( $action ) {
            return $action->{filter} when $SetVisibilityFilter;

            default { return $state }
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
            default { return $state }
        }
    }

    $store->dispatch($AddTodo->('Learn about actions'));
    $store->dispatch($AddTodo->('Learn about reducers'));
    $store->dispatch($AddTodo->('Learn about store'));
    $store->dispatch($CompleteTodo->(0));
    $store->dispatch($CompleteTodo->(1));
    $store->dispatch($SetVisibilityFilter->('SHOW_COMPLETED'));

=head1 DESCRIPTION

B<WARNING:> This is is still thought-experiment alpha-quality software,
and is likely to change a lot in its next iterations.
Use with the maximal caveat you can emptor.

This is a Perl port of L<Redux|http://redux.js.org>, done mostly
to see how easy/hard it'd be. For a longer
explanation and some implementation details, see
the L<blog entry|https://www.iinteractive.com/notebook/2016/09/09/pollux.html>.

=head1 EXPORTED FUNCTIONS

C<Pollux> exports three helper functions, 
C<code>, which is taken directly from L<Clone>,
C<merge>, which is taken from L<Hash::Merge> with the with the
merging logic tweaked ever so slightly to better behave with Pollux,
and C<combine_reducers>, which takes a hashref of sub-states and
their reducers and mash them into a single reducer.

    sub visibility_filter($action, $state = 'SHOW_ALL' ) {
        given ( $action ) {
            return $action->{filter} when $SetVisibilityFilter;

            default { return $state }
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
            default { return $state }
        }
    }

    my $main_reducer = combine_reducers({
        todos             => \&todos,
        visibility_filter => \&visibility_filter,
    });

=head1 CONSTRUCTOR

    my $store = Pollux->new(
        state       => \%original_state,
        reducer     => \&my_reducer,
        middlewares => \@middlewares
    );

Creates a new Pollux store. The constructor's arguments are:

=head2 state

Original state of the store. Can be any type of 
variable reference. Note that the state will
be internally turned into an immutable structure
via L<Const::Fast>.

=head2 reducer

Reducing function to be used to turn dispatches into state
changes.

=head2 middlewares

Array ref of middleware functions that are applied to the
incoming dispatches. Each function has the signature:

    sub my_middling_ware( $store, $next, $action ) {
        ...;
    }

C<$store> and C<$action> are self-evident. C<$next> is a 
code ref to the next step in the dispatch processing.

Middlewares are executed in the order in which they 
are declared. For example:

    sub one   ($store,$next,$action) { $next->( $action->{msg} .= 'a' ) }
    sub two   ($store,$next,$action) { $next->( $action->{msg} .= 'b' ) }
    sub three ($store,$next,$action) { $next->( $action->{msg} .= 'c' ) }

    my $store = Pollux->new(
        middlewares => [ \&one, \&two, \&three ],
        reducer => sub($action,$state) {
            return { msg => $action->{msg };        
        }
    );

    $store->dispatch({ msg => '' });

    say $store->state->{msg}; # prints 'abc'

=head1 METHODS

=head2 dispatch

    $store->dispatch( $action );

Dispatches an action to the store.
The action can be anything your reducers are
ready to receive, but you might
want to use L<Pollux::Action> objects.

=head2 subscribe

    my $unsub = $store->subscribe(sub{
        my $store = shift;
        ...
    });

    # when no longer interested
    $unsub->();

Function that will be called each time a change
in the store has been detected. To unsubscribe,
call the returned code ref.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
