#
# This file is part of Redis
#
# This software is Copyright (c) 2015 by Pedro Melo, Damien Krotkine.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
package Redis::Sentinel;
$Redis::Sentinel::VERSION = '1.998';
# ABSTRACT: Redis Sentinel interface

use warnings;
use strict;

use Carp;

use base qw(Redis);

sub new {
    my ($class, %args) = @_;
    # these args are not allowed when contacting a sentinel
    delete @args{qw(sentinels service)};

    $class->SUPER::new(%args);
}

sub get_service_address {
    my ($self, $service) = @_;
    my ($ip, $port) = $self->sentinel('get-master-addr-by-name', $service);
    defined $ip
      or return;
    $ip eq 'IDONTKNOW'
      and return $ip;
    return "$ip:$port";
}

sub get_masters {
    map { +{ @$_ }; } @{ shift->sentinel('masters') || [] };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Redis::Sentinel - Redis Sentinel interface

=head1 VERSION

version 1.998

=head1 SYNOPSIS

    my $sentinel = Redis::Sentinel->new( ... );
    my $service_address = $sentinel->get_service_address('mymaster');
    my @masters = $sentinel->get_masters;

=head1 DESCRIPTION

This is a subclass of the Redis module, specialized into connecting to a
Sentinel instance. Inherits from the C<Redis> package;

=head1 CONSTRUCTOR

=head2 new

See C<new> in L<Redis.pm>. All parameters are supported, except C<sentinels>
and C<service>, which are silently ignored.

=head1 METHODS

All the methods of the C<Redis> package are supported, plus the additional following methods:

=head2 get_service_address

Takes the name of a service as parameter, and returns either void (emptly list)
if the master couldn't be found, the string 'IDONTKNOW' if the service is in
the sentinel config but cannot be reached, or the string C<"$ip:$port"> if the
service were found.

=head2 get_masters

Returns a list of HashRefs representing all the master redis instances that
this sentinel monitors.

=head1 AUTHORS

=over 4

=item *

Pedro Melo <melo@cpan.org>

=item *

Damien Krotkine <dams@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Pedro Melo, Damien Krotkine.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
