package Net::Whois::Gateway::Client;

use strict;
#use Data::Dumper;
use Carp;
use IO::Socket::INET;

require bytes;
require Storable;

our $VERSION = 0.12;
our $DEBUG = 0;

our $online;

our %POSTPROCESS;
our $default_host = "localhost";
our $default_port = 54321;
our @answer;


our $configuration;

our %SOCKET_FACTORY;

# get whois info from gateway
# %param: queries*, gateway_host, gateway_post, timeout, ?????
sub whois {
    my %param = @_;

    exists $param{query}
	or die "No query given";

    my @answer = _send_request( %param );

    return apply_postprocess(@answer);
}

sub _send_request {
    my %param = @_;

    my $timeout = $param{timeout} || 30;
    my $buffer;

    local $SIG{__DIE__} = sub {
	$online = 0;
	die @_;
    };

    my $resp;

    foreach my $critical (0..1) {
	$resp = eval {
	    local $SIG{ALRM} = sub { warn "timeout\n"; die "timeout\n" }   if $timeout;
	    alarm $timeout*1.2 				 if $timeout;

	    my ($socket, $new_socket) = _get_socket( \%param );
		$socket or die "WHOIS: cannot open socket: $!";

        if ( $new_socket && $configuration ) {
            # repeat configuration as not critical one
            ping( default_config => $configuration );
        }

	    #use Data::Dumper;
	    #warn Dumper $socket;

#	    $socket->connected
#		or die "WHOIS: socket is not connected";

	    my $frozen = Storable::nfreeze( [ \%param ] );
	    $frozen = bytes::length( $frozen ). "\0" . $frozen;
    
	    my $w = $socket->syswrite( $frozen, bytes::length( $frozen ) );
	    
	    if ( ! defined $w || $w <= 0 ) {
		die "WHOIS: Cannot syswrite to socket: $!";
	    }

	    my $r = $socket->sysread( $buffer, 65536 );

	    if ( ! defined $r || $r <= 0 ) {
		die "WHOIS: Cannot sysread from socket: $!";
	    }

        return 1;
	};

	if ( $@ ) {
	    _fail_socket( \%param );
	    warn $@ if ! $critical && $@ ne "timeout\n";
	}

	last if $resp;
    }

    alarm 0 if $timeout;

    if ( $@ ) {
	if ( $@ eq "timeout\n" ) {
	    die "WHOIS: timeout calling sysread/syswrite";
	}
	else {
	    die $@;
	}
    }

    my $answer;

    if (
	$buffer &&
	$buffer =~ /^(\d+)\0/o &&
	bytes::length( $buffer ) >= $1 + bytes::length($1) + 1 
    ) {
	$answer = Storable::thaw( substr( $buffer, bytes::length($1) + 1, $1 ) );
    }
    else {
	die "WHOIS: Cannot parse BUFFER";
    }

    return @$answer;
}

sub _fail_socket {
    my $param_ref = shift;

    my $gateway_host = $param_ref->{gateway_host} || $default_host;
    my $gateway_port = $param_ref->{gateway_port} || $default_port;

    my $addr = $gateway_host.':'.$gateway_port;

    delete $SOCKET_FACTORY{ $addr };
}

sub _get_socket {
    my $param_ref = shift;

    my $gateway_host = $param_ref->{gateway_host} || $default_host;
    my $gateway_port = $param_ref->{gateway_port} || $default_port;

    my $addr = $gateway_host.':'.$gateway_port;

#    use Data::Dumper;
#    warn Dumper \%SOCKET_FACTORY;

    #warn $SOCKET_FACTORY{$addr} && $SOCKET_FACTORY{$addr}->connected;

    return ($SOCKET_FACTORY{ $addr }, 0) if	 $SOCKET_FACTORY{ $addr }
				      && $SOCKET_FACTORY{ $addr }->connected;

    #warn "reconnection $addr";
    $SOCKET_FACTORY{ $addr } = IO::Socket::INET->new( $addr );

    return ($SOCKET_FACTORY{ $addr }, 1);
}

sub close_sockets {
    $_->close() foreach values %SOCKET_FACTORY;
    %SOCKET_FACTORY = ();
}

sub configure {
    my $new_config = shift;
    $configuration = $new_config;
}

sub ping {
    my %params = (ping => 1, @_);
    my $res;
    $online = 1;
    eval {
        ($res) = _send_request(%params);
    };
    return $res;
}

sub apply_postprocess {
    my @all_results = @_;
    my @out_results;
    
    foreach my $result ( @all_results ) {
        my $server = $result->{server};
        if ($result->{whois} && defined $POSTPROCESS{$server}) {
            $result->{whois} = $POSTPROCESS{$server}->($result->{whois});
        }
        push @out_results, $result;
    }
    
    return @out_results;
}

1;
__END__

=head1 NAME

Net::Whois::Gateway::Client - Interface to Net::Whois::Gateway::Server

=head1 SYNOPSIS

    use strict;
    use Net::Whois::Gateway::Client;
    
    my @all_results = Net::Whois::Gateway::Client::whois( query => ['reg.ru', 'yandex.ru'] );
    
    # or
    
    my @domains = qw(
        yandex.ru
        rambler.ru
        reg.ru
        google.com    
    );
    
    my @all_results = Net::Whois::Gateway::Client::whois(
        query        => \@domains,
        gateway_host => '192.168.0.5',    # default 'localhost'
        gateway_port => '888',            # default 54321
        referral     => 0,                # default 1
        server       => 'whois.ripn.net', # default try to auto-determine
        omit_msg     => 0,                # default 2
        use_cnames   => 1,                # default 0
        timeout      => 10,               # default 30
        local_ips    => ['192.168.0.1'],  # default use default ip
        cache_dir    => '~/whois_temp',   # default '/tmp/whois-gateway-d'
        cache_time   => 5,                # default 1
    );

    foreach my $result ( @all_results ) {
        my $query = $result->{query} if $result;
        if ($result->{error}) {
            print "Can't resolve WHOIS-info for ".$result->{query}."\n";
        }
	else {
            print "QUERY: ".$result->{query}."\n";
            print "WHOIS: ".$result->{whois}."\n";
            print "SERVER: ".$result->{server}."\n";
        };
    }                            

=head1 DESCRIPTION

Net::Whois::Gateway::Client - it's an interface to Net::Whois::Gateway::Server,
which  provides a very quick way to get WHOIS-info for list of domains, IPs or registrars.
Internally uses POE to run parallel non-blocking queries to whois-servers.
Supports recursive queries, cache, queries to HTTP-servers.

You definitely need install Net::Whois::Gateway::Server first, to use Net::Whois::Gateway::Client.

=head1 Functions

=over

=item whois()

whois( query => \@query_list [, param => $value] )
Get whois-info for list of queries. One argument is required and some optional:

=back

=head1 whois() parameters

=over 2

=item query

query is an arrayref of domains, ips or registrars to send to
whois server. Required.

=item gateway_host

Host to connect. Whois-gateway should be running there.
Default 'localhost';

=item gateway_port

Port to connect. Default 54321;

=item server

Specify server to connect. Defaults try to be determined by the component. Optional.

=item referral

Optional.

0 - make just one query, do not follow if redirections can be done;

1 - follow redirections if possible, return last response from server; # default

2 - follow redirections if possible, return all responses;


Exapmle:
    my @all_results = Net::Whois::Gateway::Client::whois(
        query    => [ 'google.com', 'godaddy.com' ],
        referral => 2,
    );
    foreach my $result ( @all_results ) {
        my $query = $result->{query} if $result;
        if ($result->{error}) {
            print "Can't resolve WHOIS-info for ".$result->{query}."\n";
        }
	else {
            print "Query for: ".$result->{query}."\n";
            # process all subqueries
            my $count = scalar @{$result->{subqueries}};
            print "There were $count queries:\n";
            foreach my $subquery (@{$result->{subqueries}}) {
                print "\tTo server ".$subquery->{server}."\n";
                # print "\tQuery: ".$subquery->{query}."\n";
                # print "\tResponse:\n".$subquery->{whois}."\n";
            }
        }
    }                       

=item omit_msg

0 - give the whole response;

1 - attempt to strip several known copyright messages and disclaimers;

2 - will try some additional stripping rules if some are known for the spcific server.

Default is 2.

=item use_cnames

Use whois-servers.net to get the whois server name when possible.
Default is to use the hardcoded defaults.

=item timeout

Cancel the request if connection is not made within a specific number of seconds.
Default 10 sec.

=item local_ips

List of local IP addresses to use for WHOIS queries.
Addresses will be used used successively in the successive queries
Default SRS::Comm::get_external_interfaces_ips()

=item cache_dir

Whois information will be cached in this directory.
Default '/tmp/whois-gateway-d'.

=item cache_time

Number of minutes to save cache. Default 1 minute.

=head1 Postrprocessing

Call to a user-defined subroutine on each whois result depending on whois-server supported:

    $Net::Whois::Gateway::Client::POSTPROCESS{whois.crsnic.net} = \&my_func;

=head1 AUTHORS

Pavel Boldin	<davinchi@cpan.org>
Sergey Kotenko	<graykot@gmail.com>

=head1 SEE ALSO

Net::Whois::Gateway::Server L<http://search.cpan.org/perldoc?Net::Whois::Gateway::Server>
