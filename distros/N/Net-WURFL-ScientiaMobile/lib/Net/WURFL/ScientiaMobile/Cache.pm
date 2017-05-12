package Net::WURFL::ScientiaMobile::Cache;
use Moo::Role;

requires qw(
    getDevice
    getDeviceFromID
    setDevice
    setDeviceFromID
    getMtime
    setMtime
    purge
    incrementHit
    incrementMiss
    incrementError
    getCounters
    resetCounters
    getReportAge
    resetReportAge
    stats
    close
);

=head1 NAME

Net::WURFL::ScientiaMobile::Cache - Role that all Cache providers must implement to be compatible with the WURFL Cloud Client

=head1 SYNOPSIS

    package Net::WURFL::ScientiaMobile::Cache::MyProvider;
    use Moo;

    with 'Net::WURFL::ScientiaMobile::Cache';

    sub getDevice {
        my $self = shift;
        my ($user_agent) = @_;
        ...
        return $capabilities;
    }
    ....

=head1 DESCRIPTION

This L<Moo::Role> class defines the methods that all Cache providers must implement to be used with
the L<Net::WURFL::ScientiaMobile> module.

The following implementations are currently available, but you can write your own:

=over 4

=item L<Net::WURFL::ScientiaMobile::Cache::Null>

=item L<Net::WURFL::ScientiaMobile::Cache::Cache>

=item L<Net::WURFL::ScientiaMobile::Cache::Cookie>

=back

=head1 REQUIRED METHODS

=head2 getDevice

    my $capabilities = $cache->getDevice($user_agent);

Get the device capabilities for the given user agent from the cache provider.
It accepts the user agent name as a string and returns the capabilities as a hashref, or false
if the device wasn't found in cache.

=head2 getDeviceFromID

    my $capabilities = $cache->getDeviceFromID($wurfl_device_id);

Get the device capabilities for the given user agent from the cache provider.
It accepts the device ID as a string and returns the capabilities as a hashref, or false
if the device wasn't found in cache.

=head2 setDevice

    $cache->setDevice($user_agent, $capabilities);

Stores the given user agent with the given device capabilities in the cache provider for the given 
time period.

=head2 setDeviceFromID

    $cache->setDeviceFromID($wurfl_device_id, $capabilities);

Stores the given user agent with the given device capabilities in the cache provider for the given 
time period.

=head2 getMtime

    my $time = $cache->getMtime;

Gets the last loaded WURFL timestamp from the cache provider - this is used to detect when a new 
WURFL has been loaded on the server.

=head2 setMtime

    $cache->setMtime($time);

Sets the last loaded WURFL timestamp in the cache provider.

=head2 purge

    $cache->purge;

Deletes all the cached devices and the mtime from the cache provider.

=head2 incrementHit

    $cache->incrementHit;

Increments the count of cache hits.

=head2 incrementMiss

    $cache->incrementMiss;

Increments the count of cache misses.

=head2 incrementError

    $cache->incrementError;

Increments the count of errors.

=head2 getCounters

    my $counters = $cache->getCounters;

Returns an array of all the counters.

=head2 resetCounters

    $cache->resetCounters;

Resets the counters to zero.

=head2 getReportAge

    my $seconds = $cache->getReportAge;

Returns the number of seconds since the counters report was last sent.

=head2 resetReportAge

    $cache->resetReportAge;

Resets the report age to zero.

=head2 stats

    my $stats = $cache->stats;

Gets statistics from the cache provider like memory usage and number of cached devices.

=head2 close

    $cache->close;

Close the connection to the cache provider.

=head1 SEE ALSO

L<Net::WURFL::ScientiaMobile>

=head1 AUTHOR

Alessandro Ranellucci C<< <aar@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012, ScientiaMobile, Inc.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
