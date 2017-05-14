package Patterns::ChainOfResponsibility::Broadcast;
 
use Moose;
with 'Patterns::ChainOfResponsibility::Role::Dispatcher';

sub dispatch {
    my ($self, $current_handler, $return, $args) = @_;
    if(@$return) {
        if($current_handler->no_handlers) {
            return 1;
        } else {
            return $self->next_handler($current_handler, @$args);
        }
    } else {
        return;
    }
}
 
=head1 NAME
 
Patterns::ChainOfResponsibility::Broadcast - The Broadcast Dispatch Strategy

=head1 DESCRIPTION

Dispatch @args to each Handler in turn until we have processed each handler
Use this when you want to pass the same args to a bunch of handlers and don't
care about what happens to them.  A possible example would be a bunch of 
loggers that log events differently but independently.

You won't use this class directly.
Please see L<Patterns::ChainOfResponsibility::Role::Handler>
 
=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >> 
 
=head1 LICENSE & COPYRIGHT
 
Copyright 2011, John Napiorkowski C<< <jjnapiork@cpan.org> >>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut

1;
