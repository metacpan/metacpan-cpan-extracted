package Net::Whois::Gateway::Server;

use strict;

use strict;
use warnings;

use Data::Dumper;
use POE qw(Component::Server::TCP Filter::Reference Component::Client::Whois::Smart);

our $VERSION = 0.09;
our $DEBUG;

my @jobs;
my $tcp_server_id;
my @local_ips;

use Net::Whois::Raw;

# starts Net::Whois::Gateway::Server
sub start {
    my %params = @_;
    @local_ips = @{$params{local_ips}}
        if %params && $params{local_ips};
    
    $POE::Component::Client::Whois::Smart::DEBUG = $DEBUG;

    #my $filter = POE::Filter::Reference->new( 'YAML' );
    
    POE::Component::Server::TCP->new(
        Alias => "whois_server",
        Port         => delete $params{port} || 54321,
        ClientFilter => 'POE::Filter::Reference',
        ClientInput  => \&got_request,
        InlineStates => {
            return_result => \&return_result,
            return_ping   => \&return_ping,
        },
    );

    print "Server started in DEBUG mode\n" if $DEBUG;
    $poe_kernel->run();
    
    return 1;
}

# got client input, starting session for new job:
sub got_request {
    my ($heap, $session, $input) = @_[HEAP, SESSION, ARG0];
    my %params = %{$input->[0]};

    if (my $config = delete $params{default_config}) {
	$heap->{default_config} = $config;
    }
    
    if ($params{ping}) {
        $poe_kernel->yield("return_ping");
        return;
    }

    $tcp_server_id = $session->ID;

    if ( ref $heap->{default_config} eq 'HASH' ) {
	%params = (%{ $heap->{default_config} }, %params);
    }

    $params{omit_msg}  = 2 unless defined $params{omit_msg};
    $params{cache_dir} = '/tmp/whois-gateway-d'
        unless defined $params{cache_dir};
    $params{cache_time} = 1
        unless defined $params{cache_time};
    $params{local_ips} = \@local_ips;

    #delete $params{event} if $params{event};

    POE::Component::Client::Whois::Smart->whois(    
        %params,
        event => 'return_result',
    );

}

# return result to client
sub return_result {
    my ($heap, $answer) = @_[HEAP, ARG0];
    eval {
        $heap->{client}->put( $answer );
    };
}

# return result to client
sub return_ping {
    my $heap = $_[HEAP];
    eval {
        # Megahack!
        $heap->{client}->put( [ { 1 => 1, configured => exists $_[SESSION]->[OBJECT]->{default_config} } ] );
    };
}


sub stop {
    $poe_kernel->stop();
}
1;

=head1 NAME

Net::Whois::Gateway::Server - whois gateway

=head1 DESCRIPTION

Implementation of whois gateway server based on POE::Component::Client::Whois::Smart.
Supports all its features.
Communication whois gateway server implemented in Net::Whois::Gateway::Client
This module also installs whois-gateway-d daemon in /usr/bin (or something similar, depending on your system).
Also see scripts/init.d/whois-gateway in ditsro, which should be placed into /etc/init.d/

=head1 SYNOPSIS

    use strict;
    use Net::Whois::Gateway::Server;
    
    my $port      = 54321;
    my @local_ips = ('192.168.0.2', '192.168.0.3');
    
    Net::Whois::Gateway::Server::start(
        port      => $port,
        local_ips => \@local_ips,
    );
    
=head1 FUNCTIONS

Support single function start()

=item start()

Starts whois gateway server, takes two optional arguments:

=item port

Defult port is 54321.

=item local_ips

List of local IP addresses to use when quereing whois servers.

=head1 AUTHOR

Sergey Kotenko <graykot@gmail.com>

=head1 SEE ALSO

POE::Component::Client::Whois::Smart L<http://search.cpan.org/perldoc?POE::Component::Client::Whois::Smart>

Net::Whois::Gateway::Client L<http://search.cpan.org/perldoc?Net::Whois::Gateway::Client>
    
