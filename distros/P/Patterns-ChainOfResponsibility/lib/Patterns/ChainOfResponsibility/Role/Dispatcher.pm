package Patterns::ChainOfResponsibility::Role::Dispatcher;

use Moose::Role;
requires 'dispatch';

sub next_handler {
    my ($self, $current_handler, @args) = @_;
    my ($next, @remaining) = $current_handler->all_handlers;
    $next->next_handlers(@remaining) if @remaining;
    return $next->process(@args);
}

=head1 NAME
 
Patterns::ChainOfResponsibility::Role::Dispatcher - The Dispatcher Role
    
=head1 DESCRIPTION

Basically a command style class that figure out the strategy for dispatching
arguments to each handler in the chain

=head1 METHODS

This role defines the following methods

=head2 dispatch ( $return, $args)

Gets arrayrefs of the last return from a handler and the initial arguments sent
to process and figure out what to do.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >> 
 
=head1 LICENSE & COPYRIGHT
 
Copyright 2011, John Napiorkowski C<< <jjnapiork@cpan.org> >>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut

1;
