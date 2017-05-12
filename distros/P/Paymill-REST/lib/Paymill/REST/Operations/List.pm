package Paymill::REST::Operations::List;

use Moose::Role;

sub list {
    my ($self, $filter_and_sort) = @_;

    my $uri = $self->base_url . $self->type . 's';
    my $item_attrs = $self->_get_response({ uri => $uri, query => $filter_and_sort });

    return $self->_build_items($item_attrs);
}

no Moose::Role;
1;

__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Operations::List — List operation for L<Paymill::REST> as Moose Role

=head1 FUNCTIONS

=head2 list

To fetch a list of items, eg. transactions or clients, via the PAYMILL
REST API, use this method.

Expects an hash ref as parameter which defines the filter and sort
conditions.  Please refer to PAYMILL's API reference and use filters as
key and their values as the key's values.

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 COPYRIGHT

Copyright 2013 - Matthias Dietrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.