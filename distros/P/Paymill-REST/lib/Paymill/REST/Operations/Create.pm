package Paymill::REST::Operations::Create;

use Moose::Role;

sub create {
    my ($self, $data) = @_;

    my $factory = $self;
    if ($self->can('_factory')) {
        $factory = $self->_factory;
    }

    my $uri = $factory->base_url . $factory->type . 's';

    if ($data->{id}) {
        $uri .= '/' . delete $data->{id};
    }

    my $item_attrs = $factory->_get_response({ uri => $uri, query => $data, method => 'POST' });

    if ($self->can('_type_create')) {
        $item_attrs->{_type} = $self->_type_create;
    }

    return $factory->_build_item($item_attrs);
}

no Moose::Role;
1;

__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Operations::Create — Create operation for L<Paymill::REST> as Moose Role

=head1 FUNCTIONS

=head2 create

To create a new item, eg. a transaction or client, via the PAYMILL
REST API, call this method on the respective item factory.  Returns an
instance of the newly created item module (eg. L<Paymill::REST::Item::Transaction>).

B<Note:> might return a different item module for some items, eg. when
creating a preauthorization a transaction is returned.  This behavior
depends on the PAYMILL REST API.

Expects a hash ref as parameter for creating the item.  Please refer to
PAYMILL's API reference and use parameters as key and their values as
the key's values.

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 COPYRIGHT

Copyright 2013 - Matthias Dietrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.