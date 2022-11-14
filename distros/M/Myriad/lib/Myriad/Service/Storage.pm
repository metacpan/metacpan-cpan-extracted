package Myriad::Service::Storage;

use Myriad::Class;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Service::Storage - microservice storage abstraction layer

=head1 SYNOPSIS

 my $storage = $myriad->storage;
 await $storage->get('some_key');
 await $storage->hash_add('some_key', 'hash_key', 13);

=head1 DESCRIPTION

This module provides service storage access.

It implements L<Myriad::Role::Storage> in an object available as the C<$storage>
lexical in any service class. See that module for more details on the API.

=cut

use Myriad::Role::Storage;
use Metrics::Any qw($metrics);

BEGIN {
    $metrics->make_timer(time_elapsed =>
        name => [qw(myriad storage)],
        description => 'Time taken to process storage request',
        labels => [qw(method status service)],
    );

    my $meta = Object::Pad::MOP::Class->for_class('Myriad::Service::Storage');
    for my $method (@Myriad::Role::Storage::WRITE_METHODS, @Myriad::Role::Storage::READ_METHODS) {
        $meta->add_method($method, sub {
            my ($self, $key, @rest) = @_;
            return $self->storage->$method($self->apply_prefix($key), @rest)->on_ready(sub {
                my $f = shift;
                $metrics->report_timer(time_elapsed => $f->elapsed // 0, {method => $method, status => $f->state, service => $self->prefix});
            });
        });
    }
}

has $storage;
has $prefix;

method storage { $storage }
method prefix { $prefix }

BUILD (%args) {
    my $service_prefix = delete $args{prefix} // die 'need a prefix';
    $prefix = "service.$service_prefix";
    $storage = delete $args{storage} // die 'need a storage instance';
}

=head2 apply_prefix

Maps the requested key into the service's keyspace
so we can pass it over to the generic storage layer.

Takes the following parameters:

=over 4

=item * C<$k> - the key

=back

Returns the modified key.

=cut

method apply_prefix ($k) {
    return $prefix . '/' . $k;
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

