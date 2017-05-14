package Patterns::ChainOfResponsibility::Filter;
 
use Moose;
with 'Patterns::ChainOfResponsibility::Role::Dispatcher';

sub dispatch {
    my ($self, $current_handler, $return, $args) = @_;
    if(@$return) {
        if($current_handler->no_handlers) {
            return @$return;
        } else {
            return $self->next_handler($current_handler, @$return);
        }
    } else {
        return;
    }
}
 
=head1 NAME
 
Patterns::ChainOfResponsibility::Filter - The Filter Dispatch Strategy

=head1 DESCRIPTION

Dispatch @args to each Handler in turn, passing the results of each handler
to the next unless one handler returns nothing, in which case we exit the
chain immediately.

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
