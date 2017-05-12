package Paymill::REST::Operations::Delete;

use Moose::Role;

sub delete {
    my ($self, $identifier) = @_;

    if (!$identifier && $self->can('id')) {
        $identifier = $self->id;
    }

    my $factory = $self;
    if ($self->can('_factory')) {
        $factory = $self->_factory;
    }

    my $uri = $factory->base_url . $factory->type . 's/' . $identifier;
    my $item_attrs = $factory->_get_response({ uri => $uri, method => 'DELETE' });

    return $factory->_build_item($item_attrs);
}

no Moose::Role;
1;

__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Operations::Delete — Delete operation for L<Paymill::REST> as Moose Role

=head1 FUNCTIONS

=head2 delete

To delete an existing item, eg. a transaction or client, via the
PAYMILL REST API, call this method on the respective item factory or on
an already fetched item (if delete operation is available).  Returns an
instance of the item module (eg. L<Paymill::REST::Item::Transaction>)
for endpoints that return the item again.  This behavior depends ob the
PAYMILL REST API which doesn't always return the items upon deletion.

Expects an identifier string as parameter when called from the item
factory.  No parameter is needed when called on an already fetched item.

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 COPYRIGHT

Copyright 2013 - Matthias Dietrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.