#
#===============================================================================
#
#         FILE:  NetWhoisRawHTTP.pm
#
#  DESCRIPTION:  POE::Component::Client::Whois::Smart::NetWhoisRawHTTP
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  24.05.2009 19:09:08 MSD
#     REVISION:  ---
#===============================================================================

package POE::Component::Client::Whois::Smart::NetWhoisRawHTTP;

use strict;
use warnings;

use Net::Whois::Raw::Common;

use Data::Dumper;

use POE qw/ Component::Client::HTTP /;

use POE::Component::Client::Whois::Smart::NetWhoisRaw;
use base 'POE::Component::Client::Whois::Smart::NetWhoisRaw';

use Socket;
use HTTP::Request;

sub get_server {
    my ($query, $use_cnames) = @_;

    my $whois_server = Net::Whois::Raw::Common::get_server($query, $use_cnames);

    unless ( $whois_server ) {
	warn "Could not determine whois server from query string, defaulting to internic \n";
	$whois_server = 'whois.internic.net';
    }

    return $whois_server;
}

sub initialize {
    POE::Component::Client::HTTP->spawn(
	Alias => 'ua',
	Timeout => 10,
    );
    return 1;
}

sub query_order {
    10
}

sub query {
    my $class = shift;
    my $query_list = shift;
    my $heap = shift;
    my $args_ref = shift;

    my @my_queries;

    foreach (0..$#$query_list) {
	my $query = shift @$query_list;

	if ( $query !~ m/:/ && get_server( $query ) eq 'www_whois' ) {
	    push @my_queries, $query;
	    next;
	}

	push @$query_list, $query;
    }

    $class->get_whois_for_all( \@my_queries, $heap, $args_ref );
}

sub get_whois {
    my $package = shift;
    my %args = @_;

    if ( $args{query} eq 'pleasetesttimeoutonthisdomainrequest.com' ) {
	sleep 10;
	return;
    }

    unless ( $args{host} ) {
        my $whois_server = Net::Whois::Raw::Common::get_server($args{query}, $args{params}->{use_cnames});
        unless ( $whois_server ) {
            warn "Could not determine whois server from query string, defaulting to internic \n";
            $whois_server = 'whois.internic.net';
        }
        $args{host} = $whois_server;
    }

    my $self = bless {
	result  => delete( $args{result} ),
	params	=> delete( $args{params} ),
	request => \%args,
    }, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [ 
            $self => [
                qw( _start _http_down )
            ],
        ],
        options => { trace => 0 },
    )->ID();

    return $self;
}

# connects to whois-server (http)
sub _start {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    my ($name, $tld) = Net::Whois::Raw::Common::split_domain(
	$self->{request}->{query}
    );

    my ($http_query_data) = Net::Whois::Raw::Common::get_http_query_url($self->{request}->{query});

    my $url  = $http_query_data->[0]->{url };
    my $form = $http_query_data->[0]->{form};

    $self->{request}->{tld} = $tld;
    my $referer = delete $form->{referer} if $form && $form->{referer};
    my $method = $form && scalar(keys %$form) ? 'POST' : 'GET';

    my $header = HTTP::Headers->new;
    $header->header('Referer' => $referer) if $referer;
    my $req = new HTTP::Request $method, $url, $header;

    if ($method eq 'POST') {
	require URI::URL;
	import URI::URL;

	my $curl = url("http:");
	$req->content_type('application/x-www-form-urlencoded');
	$curl->query_form(%$form);
	$req->content($curl->equery);
    }

    $kernel->alias_resolve('ua')->[OBJECT]{factory}->timeout( $self->{request}{timeout} );
    $kernel->post("ua", "request", "_http_down", $req);
    
    undef;

}

# cach result from http whois-server
sub _http_down {
    my ($kernel, $heap, $self, $request_packet, $response_packet)
	= @_[KERNEL, HEAP, OBJECT, ARG0, ARG1];

    # response obj
    my $response = $response_packet->[0];    
    # response content
    my $content  = $response->content();
#    warn "" . $content;    

    $self->{request}->{whois}
	= Net::Whois::Raw::Common::parse_www_content($content, $self->{request}->{tld});
    
    my $request = $self->{request};

    if ($request->{whois}) {
        delete $request->{error};
    } else {
        $request->{error} ||= "No information";
    }


    next unless $self->process_query( $request );

    $kernel->post( $request->{manager_id} => $request->{event} => $request );
    
    undef;
}

1;
