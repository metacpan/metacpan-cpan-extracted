#
# This software is the Copyright of ScientiaMobile, Inc.
# 
# Please refer to the LICENSE.txt file distributed with the software for licensing information.
# 
# @package NodeWurflCloudClient
#

package Net::WURFL::ScientiaMobile;
our $VERSION = '1.0.3';

use Exception::Class (
    'Net::WURFL::ScientiaMobile::Exception',
    'Net::WURFL::ScientiaMobile::Exception::InvalidCapability' => {
        isa     => 'Net::WURFL::ScientiaMobile::Exception',
    },
    'Net::WURFL::ScientiaMobile::Exception::HTTP' => {
        isa     => 'Net::WURFL::ScientiaMobile::Exception',
        fields  => ['response', 'code'],
    },
    'Net::WURFL::ScientiaMobile::Exception::Auth' => {
        isa     => 'Net::WURFL::ScientiaMobile::Exception::HTTP',
    },
    'Net::WURFL::ScientiaMobile::Exception::ApiKeyInvalid' => {
        isa         => 'Net::WURFL::ScientiaMobile::Exception::Auth',
        description => 'API Authentication error, check your API Key',
    },
    'Net::WURFL::ScientiaMobile::Exception::NoAuthProvided' => {
        isa         => 'Net::WURFL::ScientiaMobile::Exception::Auth',
        description => 'API Authentication error, check your API Key',
    },
    'Net::WURFL::ScientiaMobile::Exception::ApiKeyExpired' => {
        isa         => 'Net::WURFL::ScientiaMobile::Exception::Auth',
        description => 'API Authentication error, your WURFL Cloud subscription is expired',
    },
    'Net::WURFL::ScientiaMobile::Exception::ApiKeyRevoked' => {
        isa         => 'Net::WURFL::ScientiaMobile::Exception::Auth',
        description => 'API Authentication error, your WURFL Cloud subscription is revoked',
    },
    'Net::WURFL::ScientiaMobile::Exception::InvalidSignature' => {
        isa         => 'Net::WURFL::ScientiaMobile::Exception::Auth',
        description => 'API Authentication error, your request signature is invalid',
    },
);
use JSON qw(decode_json);
use List::Util qw(first sum);
use LWP::UserAgent;
use Module::Load qw(load);
use Moo;
use Try::Tiny;
use URI::Escape qw(uri_unescape);

use constant ERROR_CONFIG       => 1;       # Configuration error
use constant ERROR_NO_SERVER    => 2;       # Unable to contact server or Invalid server address
use constant ERROR_TIMEOUT      => 4;       # Timed out while contacting server
use constant ERROR_BAD_RESPONSE => 8;       # Unable to parse response
use constant ERROR_AUTH         => 16;      # API Authentication failed
use constant ERROR_KEY_DISABLED => 32;      # API Key is disabled or revoked
use constant SOURCE_NONE        => 'none';  # No detection was performed
use constant SOURCE_CLOUD       => 'cloud'; # Response was returned from cloud
use constant SOURCE_CACHE       => 'cache'; # Response was returned from cache

has 'cache' => (
    is      => 'rw',
    default => sub { q{Net::WURFL::ScientiaMobile::Cache::Null} },
    coerce  => sub { (ref $_[0]) ? $_[0] : do { load($_[0]); $_[0]->new } },
    isa     => sub { Role::Tiny::does_role($_[0], 'Net::WURFL::ScientiaMobile::Cache') },
);

has 'api_key' => (
    is       => 'rw',
    required => 1,
    isa      => sub {
        die "The API Key provided is invalid"
            unless length($_[0]) == 39 && index($_[0], ':') == 6;
    },
);

has 'http_timeout'          => (is => 'rw', default => sub { 1000 });
has 'compression'           => (is => 'rw', default => sub { 1 });
has 'auto_purge'            => (is => 'rw', default => sub { 0 });
has 'report_interval'       => (is => 'rw', default => sub { 60 });
has 'wcloud_servers'        => (
    is      => 'rw',
    default => sub { { 'wurfl_cloud' => [ 'api.wurflcloud.com' => 80 ] } },
    isa     => sub { die "wcloud_servers must be a hashref\n" unless ref $_[0] eq 'HASH' },
);

has 'wcloud_host'           => (is => 'lazy', default => sub { $_[0]->getWeightedServer->[0] }, reader => 'getCloudServer');
has '_current_server'       => (is => 'ro', default => sub { [] });
has 'capabilities'          => (is => 'rw', default => sub { {} });
has '_errors'               => (is => 'rw', default => sub { [] });
has '_search_capabilities'  => (is => 'ro', default => sub { [] });
has '_user_agent'           => (is => 'rw'); # The HTTP User-Agent that is being evaluated
has '_http_request'         => (is => 'rw'); # The HTTP Request (PSGI env) that is being evaluated
has '_json'                 => (is => 'rw'); # The raw json response from the server
has '_report_data'          => (is => 'rw', default => sub { {} }); # Storage for report data (cache hits, misses, errors)
has '_api_version'          => (is => 'rw', reader => 'getAPIVersion'); # The version of the WURFL Cloud Server
has '_api_username'         => (is => 'lazy', default => sub { substr $_[0]->api_key, 0, 6 });  # The 6-digit API Username
has '_api_password'         => (is => 'lazy', default => sub { substr $_[0]->api_key, 7 });     # The 32-character API Password
has '_loaded_date'          => (is => 'rw'); # The date that the WURFL Cloud Server's data was updated
has '_source'               => (is => 'rw', default => sub { SOURCE_NONE }, reader => 'getSource'); # The source of the last detection
has '_http_client'          => (is => 'rw', default => sub { LWP::UserAgent->new }); # The HTTP Client that will be used to call WURFL Cloud
has '_http_headers'         => (is => 'ro', default => sub { {} });
has '_http_success'         => (is => 'rw');

# The HTTP Headers that will be examined to find the best User Agent, if one is not specified
my @user_agent_headers = qw(
    HTTP_X_DEVICE_USER_AGENT    X-Device-User-Agent
    HTTP_X_ORIGINAL_USER_AGENT  X-Original-User-Agent
    HTTP_X_OPERAMINI_PHONE_UA   X-OperaMini-Phone-UA
    HTTP_X_SKYFIRE_PHONE        X-Skyfire-Phone
    HTTP_X_BOLT_PHONE_UA        X-Bolt-Phone-UA
    HTTP_USER_AGENT             User-Agent
);

sub getWeightedServer {
    my $self = shift;
    
    return $self->_current_server if @{$self->_current_server} == 1;
    return [ map @$_, values %{$self->wcloud_servers} ] if keys %{$self->wcloud_servers} == 1;
    
    my $max = sum(map $_->[1], values %{$self->wcloud_servers});
    my $wrand = int rand $max;
    my $rcount = 0;
    my $k = first { $wrand <= ($rcount += $self->wcloud_servers->{$_}[1] ) }
        keys %{$self->wcloud_servers};
    $k ||= +(keys %{$self->wcloud_servers})[0];
    $self->_current_server($self->_wcloud_servers->{$k});
    return $self->_current_server;
}

sub clearServers {
    my $self = shift;
    $self->wcloud_servers({});
}

sub addCloudServer {
    my $self = shift;
    my ($nickname, $host, $weight) = @_;
    $self->wcloud_servers->{$nickname} = [ $host => $weight || 100 ];
}

sub detectDevice {
    my $self = shift;
    my ($env, $search_capabilities) = @_;
    
    $self->_source(SOURCE_NONE);
    $self->_http_request($env);
    $self->_search_capabilities($search_capabilities) if ref $search_capabilities eq 'ARRAY';
    $self->_user_agent($self->getUserAgent($env));
    my $result = $self->cache->getDevice($self->_user_agent);
     unless (ref $result eq 'HASH') {
        $self->_source(SOURCE_CLOUD);
        $self->_callWurflCloud;
        $self->_validateCache;
        if ($self->getSource eq SOURCE_CLOUD) {
            $self->cache->setDevice($self->_user_agent, $self->capabilities);
        }
    } else {
        $self->_source(SOURCE_CACHE);
        $self->capabilities($result);
        # The user requested capabilities that don't exist in the cached copy.  
        # Retrieve and cache the missing capabilities
        if (!$self->_allCapabilitiesPresent) {
            $self->_source(SOURCE_CLOUD);
            my $initial_capabilities = $self->capabilities;
            $self->_callWurflCloud;
            $self->capabilities({ %$initial_capabilities, @{$self->capabilities} });
            if ($self->getSource eq SOURCE_CLOUD) {
                $self->cache->setDevice($self->_user_agent, $self->capabilities);
            }
        }
    }
}

sub _allCapabilitiesPresent {
    my $self = shift;
    return (first { !exists $self->capabilities->{$_} } @{$self->_search_capabilities}) ? 0 : 1;
}

sub getDeviceCapability {
    my $self = shift;
    my ($capability) = @_;
    
    $capability = lc $capability;
    return $self->capabilities->{$capability} if exists $self->capabilities->{$capability};
    
    if (!$self->_http_success) {
        # The capability is not in the cache (http_client was not called) - query the Cloud
        # to see if we even have the capability
        $self->_source(SOURCE_CLOUD);
        $self->callWurflCloud;
        $self->validateCache;
        if ($self->_source eq SOURCE_CLOUD) {
            $self->cache->setDevice($self->_user_agent, $self->capabilities);
            return $self->capabilities->{$capability} if exists $self->capabilities->{$capability};
        }
    }
    Net::WURFL::ScientiaMobile::Exception::InvalidCapability->throw
        ("The requested capability ($capability) is invalid or you are not subscribed to it.");
}

sub getUserAgent {
    my $self = shift;
    my ($env) = @_;
    
    $env ||= \%ENV;
    $env = $env->to_hash if ref $env eq 'Mojo::Headers';
    if (ref $env eq 'HTTP::Headers') {
        my $headers = {};
        $env->scan(sub { $headers->{$_[0]} = $_[1] });
        $env = $headers;
    }
    
    my $user_agent;
    if (defined $env->{QUERY_STRING} && $env->{QUERY_STRING} =~ /\bUA=([^&]+)/) {
        $user_agent = uri_unescape($1);
    } else {
        $user_agent = first { $_ } @$env{@user_agent_headers};
    }
    return substr $user_agent || '', 0, 255;
}

sub _callWurflCloud {
    my $self = shift;
    
    my %headers = ();
    
    # If the reportInterval is enabled and past the report age, include the report data
    # in the next request
    if ($self->report_interval > 0 && $self->cache->getReportAge >= $self->report_interval) {
        $self->addReportDataToRequest;
        
        $self->_report_data($self->cache->getCounters);
        $headers{'X-Cloud-Counters'} = join ',',
            map "$_:" . $self->_report_data->{$_},
            keys %{$self->report_data};
        
        $self->cache->resetReportAge;
        $self->cache->resetCounters;
    }
    
    # Add HTTP Headers to pending request
    $headers{'User-Agent'} = $self->_user_agent;
    $headers{'X-Cloud-Client'} = __PACKAGE__ . " $VERSION";
    
    # Add X-Forwarded-For
    {
        my $ip = $self->_http_request->{REMOTE_ADDR};
        my $fwd = $self->_http_request->{HTTP_X_FORWARDED_FOR};
        if ($ip) {
            $headers{'X-Forwarded-For'} = "$ip" . ($fwd ? ", $fwd" : "");
        }
    }
    
    # We use 'X-Accept' so it doesn't stomp on our deflate/gzip header
    $headers{'X-Accept'} = $self->_http_request->{HTTP_ACCEPT} if $self->_http_request->{HTTP_ACCEPT};
    {
        my $wap_profile = first { $_ } @{$self->_http_request}{qw(HTTP_X_WAP_PROFILE HTTP_PROFILE)};
        $headers{'X-Wap-Profile'} = $wap_profile if $wap_profile;
    }
    
    my $request_path = @{$self->_search_capabilities} == 0
        ? '/v1/json/'
        : '/v1/json/search:(' . join(',', @{$self->_search_capabilities}) . ')';
    
    # Prepare request
    my $url = sprintf 'http://%s%s', $self->getCloudServer, $request_path;
    my $request = HTTP::Request->new(GET => $url);
    $request->header($_ => $headers{$_}) for keys %headers;
    $request->authorization_basic($self->_api_username, $self->_api_password);
    
    # Execute call
    $self->_http_client->timeout($self->http_timeout / 1000);
    my $response = $self->_http_client->request($request);
    $self->_http_success($response->is_success);
    if (!$response->is_success) {
        my %exceptions_by_status = qw(
            API_KEY_INVALID         ApiKeyInvalid
            AUTHENTICATION_REQUIRED NoAuthProvided
            API_KEY_EXPIRED         ApiKeyExpired
            API_KEY_REVOKED         ApiKeyRevoked
            INVALID_SIGNATURE       InvalidSignature
        );
        if (exists $exceptions_by_status{$response->message}) {
            ("Net::WURFL::ScientiaMobile::Exception::" . $exceptions_by_status{$response->message})->throw
                (error => $response->status_line, response => $response);
        } else {
            Net::WURFL::ScientiaMobile::Exception::HTTP->throw(
                error    => "Unable to contact server: " . $response->status_line,
                response => $response,
            );
        }
    }
    try {
        $self->_json(decode_json($response->content));
    } catch {
        Net::WURFL::ScientiaMobile::Exception::HTTP->throw(
            error    => "Unable to parse JSON response from server: $_",
            response => $response,
            code     => ERROR_BAD_RESPONSE,
        );
    };
    
    $self->_errors($self->_json->{errors});
    $self->_api_version($self->_json->{apiVersion} || '');
    $self->_loaded_date($self->_json->{mtime} || '');
    $self->capabilities->{id} = $self->_json->{id} || '';
    $self->capabilities->{$_} = $self->_json->{capabilities}{$_}
        for keys %{$self->_json->{capabilities}};
}

sub getLoadedDate {
    my $self = shift;
    $self->_loaded_date($self->cache->getMtime) unless $self->_loaded_date;
    return $self->_loaded_date;
}

sub _validateCache {
    my $self = shift;
    
    my $cache_mtime = $self->cache->getMtime;
    if (!$cache_mtime || $cache_mtime != $self->_loaded_date) {
        $self->cache->setMtime($self->_loaded_date);
        $self->cache->purge if $self->auto_purge;
    }
}

=head1 NAME

Net::WURFL::ScientiaMobile - Client for the ScientiaMobile cloud webservice

=head1 SYNOPSIS

    use Net::WURFL::ScientiaMobile;
    
    my $scientiamobile = Net::WURFL::ScientiaMobile->new(
        api_key => '...',
    );
    
    # process this HTTP request
    $scientiamobile->detectDevice($env);
    
    # check if the device is mobile
    if ($scientiamobile->getDeviceCapability('ux_full_desktop')) {
        print "This is a desktop browser.";
    }

=head1 DESCRIPTION

The WURFL Cloud Service by ScientiaMobile, Inc. is a cloud-based
mobile device detection service that can quickly and accurately
detect over 500 capabilities of visiting devices.  It can differentiate
between portable mobile devices, desktop devices, SmartTVs and any 
other types of devices that have a web browser.

This is the Perl Client for accessing the WURFL Cloud Service, and
it requires a free or paid WURFL Cloud account from ScientiaMobile:
L<http://www.scientiamobile.com/cloud>

This module analyzes the C<$env> data structure of your incoming HTTP request and extracts
the device identifier string(s). It then queries the WURFL Cloud Service or the local cache 
(if any is configured) to get the device capabilities.

If you use a PSGI-compatible web framework (such as L<Catalyst>, L<Dancer>, L<Mojo> and others),
the easiest way to use this client is to apply the L<Plack::Middleware::WURFL::ScientiaMobile> 
module to your application. It will provide the device capabilities to your request handlers
automatically with minimal programming effort.

=head1 CONSTRUCTOR

The C<new> constructor accepts the following named arguments.

=head2 api_key

Required. The full API key provided by the WURFL Cloud Service.

=head2 cache

A L<Net::WURFL::ScientiaMobile::Cache> object (or class name as string). If none is provided, 
no caching will happen.

=head2 http_timeout

The timeout in milliseconds to wait for the WURFL Cloud request to complete. Defaults to 1000.

=head2 compression

Boolean flag to enable/disable compression for querying the WURFL Cloud Service. 
Using compression can increase CPU usage in very high traffic environments, but will decrease 
network traffic and latency. Defaults to true.

=head2 auto_purge

If true, the entire cache (e.g. memcache, etc.) will be cleared if the WURFL Cloud Service has
been updated. This option should not be enabled for production use since it will result in a
massive cache purge, which will result in higher latency lookups. Defaults to false.

=head2 report_interval

The interval in seconds that after which API will report its performance.

=head2 wcloud_servers

WURFL Cloud servers to use for uncached requests. The "weight" field can contain any positive 
number, the weights are relative to each other. Use this if you want to override the built-in 
server list. For example:

    my $scientiamobile = Net::WURFL::ScientiaMobile->new(
        api_key => '...',
        wcloud_servers => {
            # nickname => [ host => weight ],
            'wurfl_cloud' => [ 'api.wurflcloud.com' => 80 ],
        },
    );

=head1 METHODS FOR CAPABILITY DETECTION

=head2 detectDevice

    $scientiamobile->detectDevice($env);
    $scientiamobile->detectDevice($env, ['ux_full_desktop', 'brand_name']);

Get the requested capabilities from the WURFL Cloud for the given HTTP Request. If the second
argument is not provided, all available capabilities will be fetched.

Refer to the documentation of your web framework to learn how to access C<$env>. For example,
L<Catalyst> provides it in C<$ctx-E<gt>request-E<gt>env>, L<Dancer> provides it in 
C<request-E<gt>env>, L<Mojo> provides it in C<$self-E<gt>tx-E<gt>req-E<gt>env>.

Instead of the C<$env> hashref you can also supply a L<HTTP::Headers> or a L<Mojo::Headers> object.
This is handy when you're not running in a PSGI environment and your web server doesn't supply
a PSGI-compatible C<$env> hashref (for example, when running C<./myapp.pl daemon> in a 
L<Mojolicious::Lite> application. Note that the L<Dancer> built-in web server still provides
a PSGI-compatible C<$env>).

=head2 getDeviceCapability

    my $is_wireless = $scientiamobile->getDeviceCapability('is_wireless_device');

Returns the value of the requested capability. If the capability does not exist, returns undef.

=head2 capabilities

Flat capabilities hashref, thus containing I<'key' => 'value'> pairs. 
Since it is 'flattened', there are no groups in this array, just individual capabilities.

=head1 METHODS FOR SERVERS POOL MANAGEMENT

=head2 addCloudServer

    $scientiamobile->addCloudServer('wurfl_cloud', 'api.wurflcloud.com', 80);

Adds the specified WURFL Cloud Server. The last argument is the server's weight. It specifies 
the chances that this server will be chosen over the other servers in the pool. This number is 
relative to the other servers' weights.

=head2 clearServers

    $scientiamobile->clearServers;

Removes the WURFL Cloud Servers.

=head2 getWeightedServer

    my $server = $scientiamobile->getWeightedServer;

Uses a weighted-random algorithm to chose a server from the pool. It returns an arrayref whose 
first argument is the host and the second argument is the weight.
You don't need to call this method usually. It is called internally when the client prepares the
request to the WURFL Cloud Service.

=head1 UTILITY METHODS

=head2 getUserAgent

    my $user_agent = $scientiamobile->getUserAgent($env);

Reads the user agent string from C<$env>.

=head2 getLoadedDate

    my $date = $scientiamobile->getLoadedDate;

Get the date that the WURFL Cloud Server was last updated as a UNIX timestamp (seconds since Epoch).
This will be undef if there has not been a recent query to the server, or if the cached value was 
pushed out of memory.

=head1 SEE ALSO

L<Net::WURFL::ScientiaMobile::Cache>, L<Plack::Middleware::WURFL::ScientiaMobile>

=head1 AUTHOR

Alessandro Ranellucci C<< <aar@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012, ScientiaMobile, Inc.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
