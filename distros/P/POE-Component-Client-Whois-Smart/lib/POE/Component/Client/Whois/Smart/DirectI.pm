#
#===============================================================================
#
#         FILE:  DirectI.pm
#
#  DESCRIPTION:  POE::Component::Client::Whois::Smart::DirectI;
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

package POE::Component::Client::Whois::Smart::DirectI;

use strict;
use warnings;

use Time::HiRes qw( time );

use Net::Whois::Raw::Common;
use SOAP::DirectI::Serialize;
use SOAP::DirectI::Parse;

use Data::Dumper;

use Tie::Cache::LRU;

tie my %directi_cache, 'Tie::Cache::LRU', 200;

use POE qw/Component::Client::HTTP/;

sub DEBUG { 1 }

sub initialize {
    POE::Component::Client::HTTP->spawn(
	Alias => 'ua_directi',
	Timeout => 10, #$self->{request}->{timeout},
    );

    return 1;
}

sub query_order {
    10;
}

sub query {
    my $class = shift;
    my $query_list = shift;
    my $heap = shift;
    my $args_ref = shift;

    my @my_queries;

    @$query_list = grep { 
	if ( s/^directi:// ) {
	    push @my_queries, $_;
	    ();
	}
	else {
	    $_
	}
    } @$query_list;

    #warn Dumper $args_ref;

    if ( @my_queries ) {
	++$heap->{tasks};
	$class->get_whois_directi(
	    \@my_queries, $heap, $args_ref,
	);
    }
}

sub get_whois_directi {
    my ($package, $domains, $heap, $args_ref) = @_;

    my @request_domains = grep { not exists $directi_cache{ $_ } } @$domains;

#    warn Dumper $args_ref;

    my $self = bless { 
	domains		=> $domains,
	request_domains => \@request_domains,
	request	        => $args_ref,
	result		=> $heap->{result},
    }, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [ 
            $self => [
                qw( _start _done )
            ],
        ],
        options => { trace => 0 },
    )->ID();

    if ( DEBUG ) {
	print time, " $self->{session_id}: Query ",
	      join(', ', @$domains), " from DirectI\n"
    }


    return $self;
}

my $_directi_signature = {
    'namespace' => 'com.logicboxes.foundation.sfnb.order.DomOrder',
    'args' => [
	{
	    'type' => 'string',
	    'key' => 'SERVICE_USERNAME',
	    'hash_key' => 'service_username',
	},
	{
	    'type' => 'string',
	    'key' => 'SERVICE_PASSWORD',
	    'hash_key' => 'service_password',
	},
	{
	    'type' => 'string',
	    'key' => 'SERVICE_ROLE',
	    'hash_key' => 'service_role',
	},
	{
	    'type' => 'string',
	    'key' => 'SERVICE_LANGPREF',
	    'hash_key' => 'service_langpref',
	},
	{
	    'type' => 'int',
	    'key' => 'SERVICE_PARENTID',
	    'hash_key' => 'service_parentid',
	},
	{
	    'elem_sig' => {
		'type' => 'string',
		'key' => 'item'
	    },
	    'type' => 'array',
	    'key' => 'domainNames'
	},
	{
	    'elem_sig' => {
		'type' => 'string',
		'key' => 'item'
	    },
	    'type' => 'array',
	    'key' => 'tlds'
	},
	{
	    'type' => 'boolean',
	    'key' => 'suggestAlternative'
	},
    ],
    'name' => 'checkAvailabilityMultiple'
};

sub _get_directi_request_body {
    my ($self, $names, $tlds) = @_;

    my $serializer = 'SOAP::DirectI::Serialize';

    #warn Dumper $self->{request}{directi_params};

    my %directi_data = (
	%{ $self->{request}{directi_params} },
	domain_names => $names  ,
	tlds	     => $tlds	,
	suggest_alternative => 0,
    );

    return $serializer->hash_to_soap( \%directi_data, $_directi_signature );
}

sub _start {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    #warn @_[KERNEL, OBJECT];

    my $url = $self->{request}{directi_params}{url};

    my (%names, %tlds);

    foreach my $query ( @{ $self->{request_domains} } ) {
	my ($name, $tld) = ($query =~ m/^([^\.]*)\.(.*)$/g);

	$names{$name}	= 1;
	$tlds{$tld}	= 1;
    }

    my @names	= keys %names;
    my @tlds	= keys %tlds;

    if ( ! @names ) {
	my $request = delete $self->{request};
	my $session = $request->{manager_id};

	my $response = {
	    host    => 'soap_directi',
	    domains => $self->{domains},
	};

	$response->{data} = \%directi_cache;
	$self->_response( $response );
	
	#warn Dumper $response, \%directi_cache;

	$kernel->post( $session => $request->{event} => $response );
	return;
    }

    my $request = eval { _get_directi_request_body( $self, \@names, \@tlds ) };

    if ( ! $request && $@ ) { 
	my $request = delete $self->{request};
	my $session = $request->{manager_id };


	$self->_response( { domains => $self->{domains}, error => $@ });
	$kernel->post( $session => $request->{event} );
	return;
    }

    #warn $request;

    my $header = HTTP::Headers->new;
    $header->header('SOAPAction' => '');  # set
    my $req = new HTTP::Request 'POST', $url, $header;

    $req->content_type('text/xml');
    $req->content($request);

    #warn $request;

    #warn Dumper $self->{request};

    $kernel->alias_resolve('ua_directi')->[OBJECT]{factory}->timeout(
        $self->{request}->{timeout},
    );

    $kernel->post("ua_directi", "request", "_done", $req);
}

sub _done {
    my ($kernel, $heap, $self, $request_packet, $response_packet)
	= @_[KERNEL, HEAP, OBJECT, ARG0, ARG1];


    # response obj
    my $http_response = $response_packet->[0];    
    # response content
    my $content  = $http_response->content();
    #warn "" . $content;    

    my $parser = SOAP::DirectI::Parse->new;

    my $data;

    #warn $content;

    eval {
	$parser->parse_xml_string( $content );

	($data) = $parser->fetch_data_and_signature;
    };

    #warn $content, $@;

    my $response;

    if ( $@ ) {
	$response->{error} = $content =~ /Timeout/i ? 'Timeout' : $@;
    }
    elsif ( exists $data->{faultstring} ) {
	$response->{error} = $data->{faultstring};
    }
    else {
	$response->{data} = $data;
    }


    my $request = delete $self   ->{request};
    my $session = delete $request->{manager_id};

    $response->{host}    = 'soap_directi';
    $response->{domains} = $self->{domains};

    #warn Dumper $content, $self->{response}, $data;

    $self->_response( $response );

    $kernel->post( $session => $request->{event} => $response );
    
    undef;
}

sub _response { 
    my $self     = shift;
    my $response = shift;

    my $data = $response->{data};

    foreach my $domain (keys %$data) {
	$directi_cache{$domain} = $data->{$domain};
    }

    foreach my $domain (@{ $response->{domains} }) {
	my $status = $data->{ $domain };

#	warn $domain, Dumper $data, $response;

	$status ||= { error => $response->{error} };

	push @{ $self->{result}{ 'directi:'.$domain } }, {
	    query  => $domain,
	    whois  => $status->{status},
	    server => 'directi',
	    error  => $status->{error},
	}
    }

    if ( DEBUG ) {
        # awainting 5.10 with //=
        $self->{session_id} = defined $self->{session_id} 
                            ?         $self->{session_id} : 'cached';
	print	time,
		" $self->{session_id}: DONE: Query ",
		join(', ',@{ $response->{domains} } ), " from DirectI\n"
    }


    #warn Dumper \%directi_cache;

    #$heap->{tasks}--;
#    check_if_done( $kernel, $heap );
#    return;
}

1;
