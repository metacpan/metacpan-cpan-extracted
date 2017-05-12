package Net::OpenVPN::Agent;

use strict;
use warnings;
use HTTP::Tiny;
use HTTP::CookieJar;
use Net::OpenVPN::Launcher;
use sigtrap qw/die normal-signals/;
use Log::Log4perl;
use YAML::XS qw/LoadFile/;

our $VERSION = 0.01;

=head1 NAME

Net::OpenVPN::Agent - a resilient anonimizing user agent that provides IP and useragent masking, full logging capability using OpenVPN and log4perl.

=head1 REQUIREMENTS

An account with L<HideMyAss.com|http://hidemyass.com/vpn/r14824/> VPN service (affiliate link) is required. This module has been tested on Linux and *may* work on other UNIX-based OSes. OpenVPN must be installed.

    use Net::OpenVPN::Agent;
    my $ua = Net::OpenVPN::Agent->new;
    my $html = $ua->get_page('http://google.com'); # connect to HMA VPN and request the page, decrement request count

=head1 METHODS

=head2 new

Returns a new Agent object. Requires a YAML config file called agent.conf in to be present in the root program directory.

Example agent.conf

    ---
    USERNAME: sillymoose
    PASSWORD: itsasecret
    SERVER_REQUEST_LIMIT_MAX: 31
    SERVER_REQUEST_LIMIT_MIN: 15
    SERVER_REQUEST_CHECK_LIMIT: 5
    RETRY_DELAY_SECS: 10
    TIMEOUT_SECS: 5
    COOKIES:
        - google.com:
            - PREF=ID=dd1e749e64f70eb6:U=99aeb3ab0a5582ce:FF=0:TM=1385654322:LM=1385654323:S=JNn9pYDiSZipdvLU

    AGENTS:
    - Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22
    - Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)
    - Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)
    - Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0)
    - Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 5.1; Trident/5.0)
    - Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22
    - Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.15 (KHTML, like Gecko) Chrome/24.0.1295.0 Safari/537.15
    - Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/125.2 (KHTML, like Gecko) Safari/125.8
    - Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/537.22 (KHTML like Gecko) Safari/537.22
    LOG_CONF:
    - log4perl.logger=DEBUG, Screen
    - log4perl.appender.Screen=Log::Dispatch::Screen
    - log4perl.appender.Screen.stderr=0
    - log4perl.appender.Screen.Threshold=DEBUG
    - log4perl.appender.Screen.layout=Log::Log4perl::Layout::SimpleLayout


=over 4

=item * 

USERNAME/PASSWORD: these are your HMA credentials

=item * 

SERVER_REQUEST_LIMIT_MIN / MAX: this is lower-upper limit from which to randomly calculate the maximum number of GET requests to be allowed per server. Once this limit is reached, the Agent.pm object will automatically connect to a new HMA VPN server, changing the IP address.

=item * 

SERVER_REQUEST_CHECK_LIMIT: this is the number of times Agent.pm will check your IP address after connecting to a new server. If after this limit Agent.pm was not able to get a new IP address, it will automatically disconnect and connect to a new HMA VPN server.

=item *

RETRY_DELAY_SECS: the number of seconds Agent.pm will delay before retrying a failed request to validate a new server connection.

=item *

COOKIES: any cookies you want Agent.pm to use.

=item *

AGENTS: a list of useragent strings. Every time Agent.pm connects to a new server and obtains a new IP address, a new useragent string will be randomly selected from this list.

=item *

LOG_CONF: a list of log4perl settings for the logging requests and results.

=back

=cut

sub new {
    my ($class) = @_;

    my $config = -e 'agent.conf'
        ? LoadFile('agent.conf')
        : undef;

    # load log4perl settings
    my $log_conf = exists $config->{LOG_CONF}
        ? join("\n", @{$config->{LOG_CONF}})
        : "log4perl.logger.Net.OpenVPN.Agent=ERROR, Screen\n
          log4perl.appender.Screen=Log::Dispatch::Screen\n
          log4perl.appender.Screen.stderr=0\n
          log4perl.appender.Screen.Threshold=ERROR\n
          log4perl.appender.Screen.layout=Log::Log4perl::Layout::SimpleLayout";

    Log::Log4perl->init(\$log_conf);
    my $log = Log::Log4perl->get_logger('Net::OpenVPN::Agent');

    $log->logdie('agent.conf not found') unless $config;

    my $self = bless {
        USERNAME                    => $config->{USERNAME} || $log->logdie("USERNAME not found in agent.conf"),
        PASSWORD                    => $config->{PASSWORD} || $log->logdie("PASSWORD not found in agent.conf"),
        SERVER_REQUEST_LIMIT_MAX    => $config->{SERVER_REQUEST_LIMIT_MAX} || 30,
        SERVER_REQUEST_LIMIT_MIN    => $config->{SERVER_REQUEST_LIMIT_MIN} || 15,
        SERVER_REQUEST_CHECK_LIMIT  => $config->{SERVER_REQUEST_CHECK_LIMIT} || 5,
        RETRY_DELAY_SECS            => $config->{RETRY_DELAY_SECS} || 10,
        TIMEOUT_SECS                => $config->{TIMEOUT_SECS} || 5,
        COOKIES                     => $config->{COOKIES} || {},
        AGENTS                      => $config->{AGENTS} || ["Net::OpenVPN::Agent $VERSION"],
        log                         => $log,
        GET_REQUEST_LIMIT           => $config->{GET_REQUEST_LIMIT} || 1,
    }, $class;
    
    $self->{ua} = $self->_makeAgent;
     
    return $self;
}

=head2 get_page

Requires a URL an argument. Performs an HTTP get and returns the HTML page. Will initiate an HMA VPN connection using OpenVPN. Every call to get_page decrements the page request limit ($self->{request_limit}). When the request limit reaches zero this method will connect to another HMA server.

=cut

sub get_page {
    my ( $self, $url ) = @_;
    $self->{log}->logdie("Missing mandatory argument url") unless $url;

    # Get home ip address first time called
    unless (exists $self->{home_ip} ) {
        $self->{log}->debug("setting ip address");
        $self->{home_ip} = $self->get_ip_address;
        $self->{ip} = $self->{home_ip};
        unless ($self->{ip}) {
            $self->{log}->logdie("Unable to get home ip address.")
        }
    }

    # Connect to another server unless request limit has not been reached
    unless ( $self->_decrement_request_limit ) {
        for (my $i = 0; $i < $self->{SERVER_REQUEST_CHECK_LIMIT}; $i++) {
            last if $self->_connect_to_random_server;
            if ($i == $self->{SERVER_REQUEST_CHECK_LIMIT}) {
                $self->{log}->logdie("Maximum server connection attempts reached.");
            }
        }
        $self->{ua} = $self->_makeAgent;
    }
    return $self->_get($url);
}

=head2 get_ip_address

Will return the current IP address or 0 if the ip lookup is not successful.

=cut

sub get_ip_address {
    my $self     = shift;
    return $self->_get('http://geoip.hidemyass.com/ip/');
}

=head2 DESTROY

Object destructor that cleans up any .conf files created by the UserAgent.

=cut

sub DESTROY {
    my $self = shift;
    unlink './user.conf'    if ( -e './user.conf'    and -w './user.conf' );
    unlink './openvpn.conf' if ( -e './openvpn.conf' and -w './openvpn.conf' );
}

=head1 INTERNAL METHODS

=head2 _makeAgent

Internal Method. Returns a new useragent.

=cut

sub _makeAgent {
    my $self = shift;

    my $jar = HTTP::CookieJar->new;
    if (exists $self->{COOKIES}) {
        foreach my $url (keys $self->{COOKIES}) {
            foreach (@{$self->{COOKIES}->{$url}}) {
                $jar->add($url, $_);
            }
        }
    }
    return  HTTP::Tiny->new(
        cookie_jar => $jar,
        agent      => $self->_get_ua_string,
        timeout    => $self->{TIMEOUT_SECS},
    );
}

=head2 _get

Internal method. Requires a URL as a an argument. Performs an HTTP get and returns the response hashref. Does not connect to a HMA server and does not decrement the page request limit count. Internally this method is used to check the Agent's current IP address.

=cut

sub _get {
    my ( $self, $url ) = @_;
    $self->{log}->logdie("Missing mandatory argument url") unless $url;
    $self->{log}->debug("GET: $url");
    my $response = $self->{ua}->get($url);
    my $requestLimit = $self->{GET_REQUEST_LIMIT};
    while ($requestLimit > 0) {
        if ( $response->{success} ) {
            $self->{log}->debug("Request successful");
            return $response->{content};
        }
        else {
            $self->{log}->error(
                "Request failed for $url. $response->{status}: $response->{reason}."
            );
            $requestLimit--;
        }
    }
    return 0;
}

=head2 _connect_to_random_server

This internal method will invoke openvpn and connect to a new HMA server.

=cut

sub _connect_to_random_server {
    my $self = shift;

    # reload server list if empty      
    unless (exists $self->{server_list} and @{$self->{server_list}}) {
        $self->{server_list} = $self->_get_server_list;
        $self->{log}->logdie("Unable to get server list") unless $self->{server_list};
    }
    # remove a randomly selected server from the list
    my $server = splice( @{$self->{server_list}}, int( rand($#{$self->{server_list}}) ), 1);
    my $config_filepath = $self->_make_config_file($server);

    # Start a launcher object if it doesnt exist
    if ($self->{vpn}) {
        $self->{vpn}->stop;
        $self->{log}->debug("Disconnecting from server.");
        sleep(30);
    }
    else {
        $self->{vpn} = Net::OpenVPN::Launcher->new;
    }
    $self->{log}->debug("Connecting to $server->{ip}, $server->{name}, $server->{country_code}");
    $self->{vpn}->start($config_filepath);    
    my $current_ip = $self->{ip};
    for (my $i = 0; $i < $self->{SERVER_REQUEST_CHECK_LIMIT}; $i++) {
        if ($self->{ip} ne '0' and $self->{ip} ne $current_ip and $self->{ip} ne $self->{home_ip}) {
            $self->{log}->debug("Ip address changed to $self->{ip} from $current_ip");
            return 1;
        }
        else {
            $self->{log}->warn("Ip address not changed, re-requesting ip");
            sleep($self->{RETRY_DELAY_SECS});
            $self->{ip} = $self->get_ip_address;
        }
    }
    $self->{log}->error("Unable to get ip address");
    return 0;
}

=head2 _get_ua_string

Internal method. Returns a randomly selected UA string from an array of useragents. This can be provided in the agent.conf YAML file as AGENTS. If none are provided, will return a useragent string containing this module name and version.

=cut

sub _get_ua_string {
    my $self = shift;
    return $self->{AGENTS}->[ int( rand($#{$self->{AGENTS}}) ) ];
}

=head2 _decrement_request_limit

Internal method. Resets the current request limit to be a random number between the agent.conf variables SERVER_REQUEST_LIMIT_MIN and SERVER_REQUEST_LIMIT_MAXunless the request limit is greater than 1, in which case this method will decrement the count by 1.

=cut

sub _decrement_request_limit {
    my $self = shift;
    if ( exists $self->{request_limit} and $self->{request_limit} > 0 ) {
        $self->{request_limit}--;
        return 1;
    }
    else {
        $self->{log}
          ->debug("Request limit is zero, resetting the request limit.");

        # if min / max are  not equal, set rand range, else fix
        my $diff = $self->{SERVER_REQUEST_LIMIT_MAX} - $self->{SERVER_REQUEST_LIMIT_MIN};
        if ($diff) {
            $self->{request_limit} = $self->{SERVER_REQUEST_LIMIT_MIN} + int( rand($diff) );
        }
        else {
            $self->{request_limit} = $self->{SERVER_REQUEST_LIMIT_MAX};
        }
        return 0;
    }
}

=head2 _get_hma_config

Internal method. Gets the HMA OpenVPN config file.

=cut

sub _get_hma_config {
    my $self = shift;
    return $self->_get(
        'http://securenetconnection.com/vpnconfig/openvpn-template.ovpn');
}

=head2 _get_server_list

Internal method. Gets the current HMA server list.

=cut

sub _get_server_list {
    my $self = shift;
    my $response =
      $self->_get('http://securenetconnection.com/vpnconfig/servers-cli.php');
    if ($response) {
        my $server_list_arrayhash;
        for my $server ( split qr/\n/, $response) {
            my @server_data = split qr/\|/, $server;
            push @{$server_list_arrayhash},
            {
                'ip'            => $server_data[0],
                'name'          => $server_data[1],
                'country_code'  => $server_data[2],
                'tcp_flag'      => $server_data[3],
                'udp_flag'      => $server_data[4],
                'norandom_flag' => $server_data[5],
            };
        }
        return $server_list_arrayhash;
    }
    else {
        $self->{log}->logdie(
"Failed to retrieve server list via get_server_list. Last known ip: $self->{ip}"
        );
    }
}

=head2 _make_config_file

Internal method. Accepts a server_hashref and creates a config file, returning the filepath.

=cut

sub _make_config_file {
    my ( $self, $server_hashref ) = @_;
    
    # get config unless it exists already
    $self->{config} = $self->_get_hma_config unless $self->{config};
    $self->{log}->logdie("Unable to get HMA config") unless $self->{config};
    my $config_string = $self->{config};
    my ( $proto, $port ) =
      defined $server_hashref->{udp_flag} ? qw/udp 53/ : qw/tcp 443/;
    $config_string .=
      "\nremote $server_hashref->{ip} $port\nproto $proto\nauth-nocache";
    $config_string =~ s/\ndev tun\n/\ndev tun0\n/;
    $config_string =~ s/\ntun-mtu-extra 32//;
    $config_string =~ s/\nauth-user-pass/\nauth-user-pass user.conf/;
    $config_string .= "\nlog /dev/null";
    open( my $configfile, '>', './openvpn.conf' )
      or $self->{log}->logdie("Error unable to open FH to openvpn.conf $!");
    print $configfile $config_string;
    open( my $userfile, '>', './user.conf' )
      or $self->{log}->logdie("Error unable to open FH to user.conf $!");
    print $userfile $self->{USERNAME} . "\n" . $self->{PASSWORD};
    return './openvpn.conf';
}

=head1 AUTHOR

David Farrell, C<< <sillymoos at cpan.org> >> L<http://perltricks.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Net-OpenVPN-Agent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-OpenVPN-Agent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::OpenVPN::Agent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-OpenVPN-Agent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-OpenVPN-Agent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-OpenVPN-Agent>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-OpenVPN-Agent/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Farrell.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
__END__


=head2 get_servers_by_country_code

Returns an arrayhash of HMA servers with a matching location. If no arguments are passed to this method, it will return the entire arrayhash of available servers.

=cut

sub get_servers_by_country_code {
	my ($self, $country_code) = @_;
	my $server_list_arrayhash;	
	if ($country_code){
		push @{$server_list_arrayhash},	grep { 
			$_->{country_code} =~ m/$country_code/i} @{$self->hma_server_list};
	}
	else {
		push @{$server_list_arrayhash}, $self->hma_server_list;
	}
	return $server_list_arrayhash;
}

=head2 get_servers_by_name

Returns an arrayhash of HMA severs with a matching name. If no arguments are passed to this method, it will return the entire arrayhash of available servers.

=cut

sub get_servers_by_name {
	my ($self, $name) = @_;
	my $server_list_arrayhash;	
	if ($name){
		push @{$server_list_arrayhash},	grep { 
			$_->{name} =~ m/$name/i} @{$self->hma_server_list};
	}
	else {
		push @{$server_list_arrayhash}, $self->hma_server_list;
	}
	return $server_list_arrayhash;
}

