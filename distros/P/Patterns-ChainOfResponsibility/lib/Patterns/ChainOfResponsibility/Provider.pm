package Patterns::ChainOfResponsibility::Provider;
 
use Moose;
with 'Patterns::ChainOfResponsibility::Role::Dispatcher';

sub dispatch {
    my ($self, $current_handler, $return, $args) = @_;
    if(@$return) {
        return @$return;
    } else {
        if($current_handler->no_handlers) {
            return;
        } else {
            return $self->next_handler($current_handler, @$args);
        }
    }
}

=head1 NAME
 
Patterns::ChainOfResponsibility::Provider - The Provider Dispatch Strategy

=head1 DESCRIPTION

Dispatch @args to each Handler in turn until we find one that processes them.
This is probably the most classic "CoR" behavior.

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
