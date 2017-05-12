package Net::WURFL::ScientiaMobile::Cache::Cache;
use Moo;

use Digest::MD5 qw(md5_hex);

with 'Net::WURFL::ScientiaMobile::Cache';
has 'cache'     => (is => 'ro', required => 1);
has 'prefix'    => (is => 'rw', default => sub { 'dbapi_' });

sub getDevice {
    my $self = shift;
    my ($user_agent) = @_;
    
    my $device_id = $self->cache->get(md5_hex($user_agent));
    if (defined $device_id) {
        my $caps = $self->cache->get($device_id);
        if (defined $caps) {
            $self->incrementHit;
            return $caps;
        }
    }
    $self->incrementMiss;
    return 0;
}

sub getDeviceFromID {
    my $self = shift;
    my ($device_id) = @_;
    
    return $self->cache->get($device_id) // 0; #/
}

sub setDevice {
    my $self = shift;
    my ($user_agent, $capabilities) = @_;
    
    $self->cache->set(md5_hex($user_agent), $capabilities->{id});
    $self->cache->set($capabilities->{id}, $capabilities);
    return 1;
}

sub setDeviceFromID {
    my $self = shift;
    my ($device_id, $capabilities) = @_;
    
    $self->cache->set($device_id, $capabilities);
    return 1;
}

sub getMtime {
    my $self = shift;
    
    return $self->cache->get($self->prefix . 'mtime');
}

sub setMtime {
    my $self = shift;
    my ($server_mtime) = @_;
    
    $self->cache->set($self->prefix . 'mtime', $server_mtime);
    return 1;
}

sub purge {
    my $self = shift;
    
    $self->cache->clear;
    return 1;
}

sub _increment_counter {
    my $self = shift;
    my ($key) = @_;
    
    $key = $self->prefix . $key;
    $self->cache->set($key, ($self->cache->get($key) || 0) + 1);
    return 1;
}

sub incrementHit {
    my $self = shift;
    return $self->_increment_counter('hit');
}

sub incrementMiss {
    my $self = shift;
    return $self->_increment_counter('miss');
}

sub incrementError {
    my $self = shift;
    return $self->_increment_counter('error');
}

sub getCounters {
    my $self = shift;
    
    return {
        age => $self->getReportAge,
        (map { $_ => $self->cache->get($_) || 0 } qw(hit miss error)),
    };
}

sub resetCounters {
    my $self = shift;
    
    $self->cache->set($self->prefix . $_, 0) for qw(hit miss error);
    return 1;
}

sub resetReportAge  {
    my $self = shift;
    
    $self->cache->set($self->prefix . 'reportTime', time);
    return 1;
}

sub getReportAge {
    my $self = shift;
    
    if (my $last_time = $self->cache->get($self->prefix . 'reportTime')) {
        return time - $last_time;
    }
    return 0;
}

sub stats   { {} }
sub close   {}

=head1 NAME

Net::WURFL::ScientiaMobile::Cache::Cache - Cache provider for the WURFL Cloud Client based on Cache.pm

=head1 SYNOPSIS

    use Net::WURFL::ScientiaMobile;
    use Net::WURFL::ScientiaMobile::Cache::Cache;
    
    my $scientiamobile = Net::WURFL::ScientiaMobile->new(
        api_key => '...',
        cache   => Net::WURFL::ScientiaMobile::Cache::Cache->new(
            cache => Cache::File->new(cache_root => '/tmp/cacheroot'),
        ),
    );

=head1 DESCRIPTION

This WURFL Cloud Client Cache Provider provides a bridge to use L<Cache>-based modules.

=head1 CONSTRUCTOR

The C<new> constructor accepts the following named arguments.

=head2 cache

Required. An instance of a caching module which implements the L<Cache> interface.

=head2 prefix

You can use this argument to customize the namespace prefix used by this module to
store general data. The default is I<dbapi_>.

=head1 SEE ALSO

L<Net::WURFL::ScientiaMobile>, L<Net::WURFL::ScientiaMobile::Cache>

=head1 COPYRIGHT & LICENSE

Copyright 2012, ScientiaMobile, Inc.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
