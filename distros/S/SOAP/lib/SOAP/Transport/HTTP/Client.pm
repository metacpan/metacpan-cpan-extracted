package SOAP::Transport::HTTP::Client;

use strict;
use vars qw($VERSION);
$VERSION = '0.28';

use SOAP::Defs;
use LWP::UserAgent;
use Carp;

sub new {
    my ($class) = @_;

    my $self = {
        debug_request => 0,
    };
    bless $self, $class;

    $self;
}

sub debug_request {
    my ($self) = @_;
    $self->{debug_request} = 1;
}

sub send_receive {
    my ($self, $host, $port, $endpoint, $method_uri, $method_name, $soap_request) = @_;

    $port = 80 unless(defined($port) and $port);
	
    my $http_endpoint = qq[http://$host:$port$endpoint];
    my $ua = LWP::UserAgent->new();
    my $post = HTTP::Request->new('POST', $http_endpoint, new HTTP::Headers, $soap_request);

    #
    # NOTE NOTE NOTE
    # CLR prefers a semicolon here
    # clearly this needs some fixing - maybe allow client to specify SOAPAction directly?
    #
    $post->header('SOAPAction' => $method_uri . '#' . $method_name);

    if ($self->{debug_request}) {
        $post->header('DebugRequest' => '1');
    }

    #
    # TBD: content-length isn't taking into consideration CRLF translation
    #
    $post->content_type  ('text/xml');
    $post->content_length(length($soap_request));
    
    my $http_response = $ua->request($post);

    my $code    = $http_response->code();
    my $content = $http_response->content();

    unless (200 == $code) {
        # CLR (technically, HTTP/1.1) hack
	my $ok = 0;
	if (100 == $code) {
	    if ($content =~ /^HTTP\/1\.1 200 OK/) {
		$ok = 1;
		$code = 200;
		# this hack really doesn't work because the resulting content
		# includes the HTTP/1.1 response headers. Geez...
	    }
	}
	unless ($ok) {
            #
            # TBD: need to deal with redirects, M-POST retrys, anything else?
            #
            croak 'HTTP ' . $post->method() . ' failed: ' . $http_response->code() .
                  ' (' . $http_response->message() .
                  "), in SOAP method call. Content of response:\n$content";
        }
    }
    ($code, $content);
}

1;
__END__

=head1 NAME

SOAP::Transport::HTTP::Client - Client side HTTP support for SOAP/Perl

=head1 SYNOPSIS

    use SOAP::Transport::HTTP::Client;

=head1 DESCRIPTION

Forthcoming...

=head1 DEPENDENCIES

LWP::UserAgent
SOAP::Defs

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO


=cut
