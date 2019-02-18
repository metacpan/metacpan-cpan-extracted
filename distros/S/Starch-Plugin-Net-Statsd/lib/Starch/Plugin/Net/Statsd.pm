package Starch::Plugin::Net::Statsd;

$Starch::Plugin::Net::Statsd::VERSION = '0.03';

=head1 NAME

Starch::Plugin::Net::Statsd - Record store timing information to statsd.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::Net::Statsd'],
    );

=head1 DESCRIPTION

This plugin will record get, set, and remove store timings to statsd
using L<Net::Statsd>.

By default, for example, if you are using L<Starch::Store::Memory>, stats
like this will be recorded:

    starch.Memory.set
    starch.Memory.get-hit
    starch.Memory.get-miss
    starch.Memory.remove
    starch.Memory.set-error
    starch.Memory.get-error
    starch.Memory.remove-error

Note that stats will not be collected for L<Starch::Store::Layered>, as
data about it isn't really useful as its just a proxy store.

Since this plugin detects exceptions and records the C<*-error> stats for
them you should, if you are using it, put the L<Starch::Plugin::LogStoreExceptions>
plugin after this plugin in the plugins list.  If you don't then exceptions
will be turned into log messages before this store gets to see them.

=cut

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::Bundle
);

sub bundled_plugins {
    return [qw(
        ::Net::Statsd::Manager
        ::Net::Statsd::Store
    )];
}

1;
__END__

=head1 MANAGER OPTIONAL ARGUMENTS

=head2 statsd_host

Setting this will cause the C<$Net::Statsd::HOST> variable to be
localized to it before the timing information is recorded.

=head2 statsd_port

Setting this will cause the C<$Net::Statsd::PORT> variable to be
localized to it before the timing information is recorded.

=head2 statsd_root_path

The path to store all of the Starch timing stats in, defaults to
C<starch>.

=head2 statsd_sample_rate

The sample rate to use, defaults to C<1>.  See L<Net::Statsd/ABOUT SAMPLING>.

=head1 STORE OPTIONAL ARGUMENTS

=head2 statsd_path

The path prefix which will be appended to the L</statsd_root_path>.
Defaults to L<Starch::Store/short_store_class_name>, but normalized to
be a valid graphite path.

=head2 statsd_full_path

This is the full path, C<statsd_root_path.statsd_path>.  This can be
set to override L</statsd_root_path> and L</statsd_path>.

=head1 SUPPORT

Please submit bugs and feature requests to the
Starch-Plugin-Net-Statsd GitHub issue tracker:

L<https://github.com/bluefeet/Starch-Plugin-Net-Statsd/issues>

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

