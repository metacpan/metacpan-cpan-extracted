package Neovim::RPC::Plugin;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: base role for Neovim::RPC plugins
$Neovim::RPC::Plugin::VERSION = '1.0.1';




use strict;
use warnings;

use Moose::Role;

use MooseX::ClassAttribute;
use Moose::Exporter;
use Moose::Util qw/ apply_all_roles /;

use Promises qw/ deferred /;

Moose::Exporter->setup_import_methods(
    also => [ 'Moose' ],
    with_meta => [ 'subscribe' ],
    as_is => [ 'rpcrequest', 'accumulate_responses' ],
);

use experimental 'signatures', 'postderef';

class_has subscriptions => (
    is => 'ro',
    default => sub { +{} },
);

has rpc => (
    is => 'ro',
    required => 1,
    handles => [ 'api' ],
    trigger => sub { $_[0]->register },
);

sub register($self) {
    while( my( $event, $chain ) = each $self->subscriptions->%* ) {
        $self->rpc->subscribe( $event => $self->expand_subscription_chain(@$chain) );
    }
}

sub expand_subscription_chain($self,@chain) {
    return sub($event) {
        my $d = deferred;
        $d->resolve($event);
        my $current = $d;

        for my $next ( @chain ) {
            if( ref $next eq 'CODE' ) {
                $current = $current->then(sub{
                    $next->($self,@_);
                })
            }
            elsif( ref $next eq 'ARRAY' ) {
                $current = $current->then(
                    sub{ $next->[0]($self,@_) },
                    sub{ $next->[1]($self,@_) },
                )

            }
            elsif( ref $next eq 'HASH' ) {
                die "hash can only have exactly one key\n"
                    unless 1 == keys %$next;

                my( $method, $sub ) = %$next;

                $current = $current->$method(
                    sub{ $sub->($self,@_) },
                )

            }
        }

        return $current;
    };
}

sub subscribe($self, $name, @chain) {
    $self->name->subscriptions->{$name} = \@chain;
}

sub init_meta {
    shift;
    
    my $meta = Moose->init_meta(@_);

    apply_all_roles( $meta->name, __PACKAGE__ );
    
    return $meta;
}


sub rpcrequest {
    my @chain = @_;
    sub {
        my( $self, $event ) = @_;

        $self->expand_subscription_chain( 
            @chain,
            { finally => sub { $event->resp('ok') } }
        )->($event);

    }
}

sub accumulate_responses( @subs ) {
    sub($self,@args) {
        my $promise = deferred;

        my @return =$self->expand_subscription_chain(@subs)->(@args);

        if( @return == 1 and eval { $return[0]->isa('Promises::Promise') } ) {
            $return[0]->then(
                sub{ $promise->resolve(@args, [ @_ ]) },
                sub{ $promise->reject(@_)  },
            );
        }
        else {
            $promise->resolve(@args, \@return);
        }

        return $promise;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::Plugin - base role for Neovim::RPC plugins

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    package Neovim::RPC::Plugin::Foo;

    use Neovim::RPC::Plugin;

    use experimental 'signatures';

    subscribe 'say_hi' => sub($self, $event) {
        $self->api->nvim_set_current_line( 'hi!' );
    };

=head1 DESCRIPTION

This is the base role used to set up plugins for L<Neovim::RPC>.

=head1 EXPORTED KEYWORDS

The role automatically exports two keywords C<subscribe> and C<rpcrequest>.

=head2 subscribe

The keyword C<subscribe> is used to define a new rpc event the plugin will
subscribe to. The declaration syntax is

    subscribe event_name => @chain_of_actions;

C<event_name> is the name of the event as sent by neovim. The chain is a list of actions
to take when the event is received. A simple one-link chain would be:

    subscribe say_hi => sub($self,$event) {
        $self->rpc->nvim_set_current_line( "Hi " . ( $event->all_args )[0] );
    };

The sub receives the plugin object and the L<MsgPack::RPC::Message::Request>
object as its arguments, as is expected to return either a promise of a list of values.

If more than one sub is given, they will be chained together as a series of promise C<then>s.
I.e.,

    subscribe censor => sub($self,$event) {

        my @bad_words = $event->all_args;

        $self->rpc
            ->nvim_get_current_line
            ->then(sub{ 
                my $line = shift;
                $line =~ s/$_/*beep*/g for @bad_words;
                return $line;
            })
            ->then(sub{ $self->rpc->nvim_set_current_line( shift ) } );
    };

    # equivalent to

    subscribe censor 
        => sub($self,$event) { my @bad_words = $event->all_args; }
        => sub($self, @bad ) { $self->rpc->get_current_line->then(sub{ ($line,@bad) }) }
        => sub($self, $line, @bad ) { 
                $line =~ s/$_/*beep*/g for @bad_words;
                return $line;
            })
        => sub($self,$new_line){ $self->rpc->nvim_set_current_line( $new_line ) };

Each sub in the chain will be given the plugin object as first argument, and 
whatever values the previous sub/promise return as the following ones. 

In addition of subs, a part of the chain can be an arrayref of two subs, which will be converted
into a C<->then($sub1, $sub2)>. 

    subscribe foo => \&sub_a  => [ \&sub_b, \&sub_c ];

    # equivalent to

    subscribe foo => sub( $self, $event ) {
        my $promise = deferred;
        $promise->resolve( $sub_a->($self, $event) );

        return $promise->then( \&sub_b, \&sub_c );
    };

A part of the chain can also be a one pair/value hashref, where the key
will be taken as the promise method to use.

    subscribe foo => \&sub_a  => { finally => \&sub_b };

    # equivalent to

    subscribe foo => sub( $self, $event ) {
        my $promise = deferred;
        $promise->resolve( $sub_a->($self, $event) );

        return $promise->finally( \&sub_b );
    };

=head2 rpcrequest

    subscribe 'foo' => rpcrequest(
        sub($self,$event) { my @x = $event->all_args; reverse @x },
        sub($self,@args)  { $self->api->nvim_set_current_line( join ' ', @args ) },
    );

Utility wrapper for subscription chains. Automatically send an C<ok> response
at the end of the chain.

=head2 accumulate_responses

    subscribe censor 
        => sub($self,$event) { [ $event->all_args ] }
        => accumulate_responses( sub($self, @) { $self->rpc->api->nvim_get_current_line }) 
        => sub($self, $bad_words, $line ) { 
            $line->[0] =~ s/$_/*beep*/g for @$bad_words;
            return $line->[0];
        }
        => sub($self,$new_line){ $self->rpc->nvim_set_current_line( $new_line ) };

Utility function that captures the response of the previous sub/promise and augment it
with the values returned by the one provided as argument. The returned values are appended
as an arrayref.

=head1 METHODS

=head2 new

    my $plugin = Neovim::RPC::Plugin::Foo->new( rpc => $rpc );

Constructor. Must be passed a L<Neovim::RPC> object. Upon creation, 
all the subscriptions will be registered against neovim.

=head2 subscriptions

Hashref of the subscriptions and their sub chains registered for the plugin class.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
