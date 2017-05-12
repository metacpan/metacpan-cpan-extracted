package Net::WURFL::ScientiaMobile::Cache::Cookie;
use Moo;

use JSON qw(decode_json encode_json);
use Plack::Request;

with 'Net::WURFL::ScientiaMobile::Cache';

has 'cookie_name'       => (is => 'rw', default => sub { 'WurflCloud_Client' });
has 'cache_expiration'  => (is => 'rw', default => sub { 86400 });
has 'env'               => (is => 'rw');
has 'cookies'           => (is => 'rw');

sub getDevice {
    my $self = shift;
    my ($user_agent) = @_;
    
    my $request = Plack::Request->new($self->env);
    return 0 unless $request->cookies->{$self->cookie_name};
    
    my $cookiedata = eval { decode_json($request->cookies->{$self->cookie_name}) };
    return 0 unless ref $cookiedata eq 'HASH';
    return 0 if !$cookiedata->{date_set} || ($cookiedata->{date_set} - $self->cache_expiration) < time;
    return 0 if !$cookiedata->{capabilities} || !%{$cookiedata->{capabilities}};
    return $cookiedata->{capabilities};
}

sub getDeviceFromID { 0 }

sub setDevice {
    my $self = shift;
    my ($user_agent, $capabilities) = @_;
    
    my $data = {
        date_set     => time,
        capabilities => $capabilities,
    };
    
    $self->cookies({
        $self->cookie_name => encode_json($data),
    });
}

sub setDeviceFromID { 1 }
sub getMtime        { 0 }
sub setMtime        { 1 }
sub purge           { 1 }
sub incrementHit    {}
sub incrementMiss   {}
sub incrementError  {}
sub getCounters     { { hit => 0, miss => 0, error => 0, age => 0 } }
sub resetCounters   {}
sub resetReportAge  {}
sub getReportAge    { 0 }
sub stats           { {} }
sub close           {}

=head1 NAME

Net::WURFL::ScientiaMobile::Cache::Cookie - Cookie-based cache provider for the WURFL Cloud Client

=head1 SYNOPSIS

    use Net::WURFL::ScientiaMobile;
    use Net::WURFL::ScientiaMobile::Cache::Cookie;
    
    my $cache = Net::WURFL::ScientiaMobile::Cache::Cookie->new;
    my $scientiamobile = Net::WURFL::ScientiaMobile->new(
        api_key => '...',
        cache   => $cache,
    );
    
    # ...later, in your HTTP request handler...
    $cache->env($env);
    $scientiamobile->detectDevice($env);
    my $new_cookies = $cache->cookies;

=head1 DESCRIPTION

The cookie WURFL Cloud Client Cache Provider. This module reads the user agent capabilities
from a HTTP cookie.

=head1 CONSTRUCTOR

The C<new> constructor accepts the following named arguments.

=head2 cookie_name

The name of the HTTP cookie. It defaults to I<WurflCloud_Client>.

=head2 cache_expiration

The expiration time in seconds. It defaults to 86400.

=head1 METHODS

=head2 env

Use this method to set the Plack env when you get a new request. This will link
the cache to the request data, allowing for cookie inspection.

=head2 cookies

Use this method to retrieve the cookie(s) that you have to send back to your 
client. Cookies are returned as a hashref whose values are the cookie contents
(your implementation can decide the other attributes of the cookie at
serialization time).

=head1 SEE ALSO

L<Net::WURFL::ScientiaMobile>, L<Net::WURFL::ScientiaMobile::Cache>

=head1 COPYRIGHT & LICENSE

Copyright 2012, ScientiaMobile, Inc.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
