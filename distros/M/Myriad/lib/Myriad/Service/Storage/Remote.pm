package Myriad::Service::Storage::Remote;

use Myriad::Class;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Service::Storage::Remote - abstraction to access other services storage.

=head1 SYNOPSIS

 my $storage = $api->service_by_name('service')->storage;
 await $storage->get('some_key');

=head1 DESCRIPTION

=cut

use Myriad::Role::Storage;

use Metrics::Any qw($metrics);

BEGIN {

    $metrics->make_timer(time_elapsed =>
        name => [qw(myriad storage remote)],
        description => 'Time taken to process remote storage request',
        labels => [qw(method status service)],
    );

    my $meta = Object::Pad::MOP::Class->for_class('Myriad::Service::Storage::Remote');

    for my $method (@Myriad::Role::Storage::READ_METHODS) {
        $meta->add_method($method, sub {
            my ($self, $key, @rest) = @_;
            return $self->storage->$method($self->apply_prefix($key), @rest)->on_ready(sub {
                my $f = shift;
                $metrics->report_timer(time_elapsed =>
                    $f->elapsed // 0, {method => $method, status => $f->state, service => $self->local_service_name});
            });
        });
    }
}


has $prefix;
has $storage;
has $local_service_name;
method storage { $storage };
method local_service_name { $local_service_name // 'local' };

BUILD (%args) {
    my $service_prefix = delete $args{prefix} // die 'need a prefix';
    $prefix = "service.$service_prefix";
    $storage = delete $args{storage} // die 'need a storage instance';
    $local_service_name = delete $args{local_service_name};
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


