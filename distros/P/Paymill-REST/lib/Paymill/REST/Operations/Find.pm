package Paymill::REST::Operations::Find;

use Moose::Role;

sub find {
    my ($self, $identifier) = @_;

    my $uri = $self->base_url . $self->type . 's/' . $identifier;
    my $item_attrs = $self->_get_response({ uri => $uri });

    return $self->_build_item($item_attrs);
}

no Moose::Role;
1;

__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Operations::Find — Find operation for L<Paymill::REST> as Moose Role

=head1 FUNCTIONS

=head2 find

Fetching an item, eg. a transaction or client, via the PAYMILL REST API
is made possible through find.  Can be called on all item factories.

Expects an identifier string as parameter.  An error is thrown when the
identifier is not available via the API.

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 COPYRIGHT

Copyright 2013 - Matthias Dietrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.