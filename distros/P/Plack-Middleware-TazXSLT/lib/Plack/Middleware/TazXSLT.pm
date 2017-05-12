package Plack::Middleware::TazXSLT;
use strict;
use warnings;

use parent qw( Plack::Middleware );
use Plack::Util::Accessor
  qw(user_agent xml_parser xslt_parser name timeout log_filter response request );
use XML::LibXML;
use XML::LibXSLT;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Message::PSGI;
use Plack::Response;
use Plack::Request;
use Try::Tiny;
use Capture::Tiny qw(capture);
use URI::QueryParam;
use Plack::Util;

use constant TAZ_XSLT_PROFILE => $ENV{TAZ_XSLT_PROFILE};

our $VERSION = '0.55';

sub HTTP::Response::to_psgi {
    my ($self) = @_;
    return Plack::Response->new( $self->code, $self->headers, $self->content )
      ->finalize;
}

sub prepare_app {
    my $self = shift;
    $self->timeout(19)                        unless defined $self->timeout;
    $self->name('tazxslt')                    unless defined $self->name;
    $self->xslt_parser( XML::LibXSLT->new() ) unless defined $self->xslt_parser;
    $self->xml_parser( XML::LibXML->new() )   unless defined $self->xml_parser;
    $self->log_filter( \&parse_libxml_error ) unless defined $self->log_filter;
    $self->user_agent( $self->build_user_agent() )
      unless defined $self->user_agent;
    return;
}

sub call {
    my ( $self, $env ) = @_;
    my $request          = Plack::Request->new($env);
    my $uri              = $request->uri;
    my $res              = $self->unbuffer( $self->app->($env) );
    my $backend_response = HTTP::Response->from_psgi($res);

    $self->request( $request );
    $self->response( $backend_response );

    if ( !$self->is_transformable_response() ) {
        $backend_response->header( x_taz_mode => 'proxy' );
        return $backend_response->to_psgi;
    }

    my $content_type;
    my $response = try {
        my $xml_dom = $self->parse_xml();
        my $xsl_uri = try { $self->find_pi( $xml_dom ) };

        if ( !$xsl_uri ) {
            $self->response->header( x_taz_mode => 'proxy' );
            return $self->response;
        }

        $xsl_uri = URI->new_abs( $xsl_uri, $request->uri );

        my $xslt_response = $self->get_stylesheet($xsl_uri);

        $self->xml_parser->base_uri($xsl_uri);

        my $xslt_dom = $self->parse_stylesheet($xslt_response);

        $self->register_elements( $xslt_dom, $xml_dom );

        my $result;
        my ( $stdout, $stderr ) = do {

            ## stdin, stderr and stdout needs to be localised to
            ## retain the originals values when running under fcgi, see
            ## https://metacpan.org/module/Capture::Tiny#Modifying-filehandles-before-capturing

            local ( *STDIN, *STDERR, *STDOUT );
            capture {
                if (TAZ_XSLT_PROFILE) {
                    my $start = [Time::HiRes::gettimeofday];
                    $result =
                      $self->apply_transformation( $xslt_dom, $xml_dom );
                    my $end = [Time::HiRes::gettimeofday];
                    printf STDERR "xslt-processing-time: %.6f\n",
                      Time::HiRes::tv_interval $start, $end;
                }
                else {
                    $result =
                      $self->apply_transformation( $xslt_dom, $xml_dom );
                }
            };
        };

        if ($stderr) {
            $env->{'psgi.errors'}->print("[$uri] $stderr");
        }

        $content_type = $xslt_dom->media_type();
        $content_type .= ';charset=' . $xslt_dom->output_encoding();

        my $content = $xslt_dom->output_as_bytes($result);
        $backend_response->content_length(
            do { use bytes; length $content }
        );
        $self->response->content_type($content_type);
        $self->response->content($content);
        $self->response->header( x_taz_mode => 'transform' );
        return $self->response;
    }
    catch {
        $env->{'psgi.errors'}->print("[$uri] $_");
        return HTTP::Response->new(500);
    };

    return $response->to_psgi;
}

sub parse_stylesheet {
    my ( $self, $response ) = @_;
    my $xslt_dom = try {
        $self->xslt_parser->parse_stylesheet(
            $self->xml_parser->parse_string( $response->decoded_content ) );
    }
    catch {
        die "Can't parse stylesheet: $_";
    };
    return $xslt_dom;
}

sub apply_transformation {
    my ( $self, $xslt_dom, $xml_dom ) = @_;
    my $result;
    try {
        $result = $xslt_dom->transform( $xml_dom, $self->xslt_variables() );
    }
    catch {
        s/\s at \s \S+ \s line \s \d+ [.\s]+//smx;
        die "Error while transforming (died): $_\n";
    };
    return $result;
}

sub parse_libxml_error {
    my $libxml_error = shift;
    $libxml_error =~ s/\A(.+?)\s+\^.*/$1/sm;
    $libxml_error =~ s/\s+/ /smg;
    return $libxml_error;
}

sub get_stylesheet {
    my ( $self, $xsl_uri ) = @_;
    my $response = $self->user_agent->get($xsl_uri);

    if ( not $response->is_success ) {
        die "Can't get xslt stylesheet: " . $response->status_line() . "\n";
    }
    return $response;
}

sub is_transformable_response {
    my $self = shift;

    return 0
      if $self->response->is_redirect
          || !$self->response->is_success
          || $self->request->method eq 'HEAD'
          || ( defined $self->response->content_length
              && $self->response->content_length == 0 )
          || !$self->response->content_is_xml;
    return 1;
}

sub parse_xml {
    my $self = shift;
    my $body = $self->response->content;
    my $xml_dom = try {
        $self->xml_parser->parse_string($body);
    }
    catch {
        s/\s at \s \S+ \s line \s \d+ .*?$//smx;
        die "Can't parse xml: " . $self->log_filter->($_) . "\n";
    };
    return $xml_dom;
}

sub find_pi {
    my ( $self, $dom ) = @_;
    my $xsl_uri;
    if ( $self->request->header('X-Taz-XSLT-Stylesheet') ) {
        $xsl_uri = $self->request->header('X-Taz-XSLT-Stylesheet');
    }
    else {
        my $stylesheet_href;
        my $pi_str =
          ( $dom->findnodes('processing-instruction()') )[0]->getData;
        if ( $pi_str
            and ( $pi_str =~ m{type="text/xsl} or $pi_str !~ /type=/ ) )
        {
            ($stylesheet_href) = ( $pi_str =~ m{href="([^"]*)"} );
        }
        if ($stylesheet_href) {
            $xsl_uri = replace_header( $self->request, $stylesheet_href );
        }
    }
    return $xsl_uri;
}

sub register_elements {
    my ( $self, $xslt_dom, $xml_dom ) = @_;

    $xslt_dom->register_element( 'http://www.mod-xslt2.com/ns/1.0', 'header-set', sub { return; } );

    $xslt_dom->register_function( 'http://taz.de/xmlns/tazxslt/http_response',
        'header',
	sub { 
		$self->response->header( @_ );
        } 
    );

    $xslt_dom->register_function( 'http://taz.de/xmlns/tazxslt/http_response',
        'code',
	sub { 
		$self->response->code( @_ );
        } 
    );

    $xslt_dom->register_element(
        'http://www.mod-xslt2.com/ns/1.0',
        'value-of',
        sub {
            my $string = $_[2]->getAttribute("select");
            return XML::LibXML::Text->new(
                replace_header( $self->request, $string ) );
        }
    );
    return;
}

sub build_user_agent {
    my $self = shift;
    my $ua   = LWP::UserAgent->new;
    $ua->timeout( $self->timeout );
    $ua->env_proxy;
    return $ua;
}

sub xslt_variables {
    my $self = shift;
    return XML::LibXSLT::xpath_to_string(
        'modxslt-name'    => $self->name,
        'modxslt-version' => $self->VERSION,
    );
}

sub replace_header {
    my ( $request, $string ) = @_;
    $string =~ s/\$HEADER\[(.*?)\]/$request->header($1)||''/ge;
    $string =~ s/\$GET\[(.*?)\]/$request->uri->query_param($1)||''/ge;
    return $string;
}

sub unbuffer {
    my ( $self, $res ) = @_;
    return $res if ref($res) ne 'CODE';

    my $ret;
    $res->(
        sub {
            my $write = shift;
            if ( @$write == 2 ) {
                my @body;
                $ret = [ @$write, \@body ];
                return Plack::Util::inline_object(
                    write => sub { push @body, $_[0] },
                    close => sub { },
                );
            }
            else {
                $ret = $write;
                return;
            }
        }
    );
    return $ret;
}

1;

__END__

=head1 NAME 

Plack::Middleware::TazXSLT - transform xml documents by applying xsl stylesheets on the fly

=head1 DESCRIPTION

Plack::Middleware::TazXSLT is an plack aware middleware that transforms
xml documents by applying xsl stylesheets on the fly. It was developed to
serve an replacement for the L<http://modxslt.org/> as its development
seems stalled for a long time. When using the word replacement please
keep in mind that it is not really a drop in alternative for modxslt,
as it just implements a very basic subset of modxslts functionality.

Every time the plack backend return a response to
Plack::Middleware::TazXSLT it checks if the response is successful,
not a redirect, not a HEAD request, has content and is actually a xml
document. If all that applies, it parses the xml document and applies
the supplied stylesheet to it.

There are two way to communicate which stylesheet to use. If
the response returned by the application contains the HTTP header
X-Taz-XSLT-Stylesheet, it's value is expected to be an URL pointing to
an XSLT stylesheet which is than downloaded and applied. If the response
misses this header, Plack::Middleware::TazXSLT tries to find a processing
instruction of type of I<text/xsl>:

  <?modxslt-stylesheet 
    type="text/xsl" 
    href="http://$HEADER[Host]/$HEADER[X-Taz-Base]/base.xsl" ?>

All occurrences of $HEADER[] in its I<href> attribute are replaced the
the values from the backends http response.

=head1 SYNOPSIS

  my $app = builder {
    enable "TazXSLT";
    Plack::App::Proxy->new( backend => 'LWP', remote => 'http://example.com/ )->to_app;
  };

=head1 ATTRIBUTES

=over 4

=item user_agent

HTTP user agent to fetch the the necessary stylesheets. Defaults to
an LWP::UserAgent with its timeout set to I<timeout> seconds and act
according to the environment variables HTTP_PROXY and HTTPS_PROXY.

It is possible to provide an useragent object of another class as long
as it respond to a call of I<get> and returns an object that provides
the method calls I<is_redirect>, I<is_success>, I<content_length>,
I<content_length>, I<content_is_xml> and behaves semantically similar
to LWPs HTTP::Reponse.

=item xml_parser

An instance of XML::LibXML. Defaults to the following simple call:

  XML::LibXML->new();

=item xslt_parser

An instance of XML::LibXSLT. Defaults to the following simple call:

  XML::LibXSLT->new();

=item name

A string with is accessible via the xslt variable
I<modxslt-name>. Defaults to I<tazxslt>.

=item timeout

Timeout for http connections this objects I<user_agent>
attribute. Defaults to 180 seconds.

=item log_filter

A subroutine reference that is called with the error message as
its only argument every time libxml is not able to parse the xml
document. Unfortunately libxml returns multiline error messages with
indentation. This defaults to the function I<parse_libxml_error> that
strips the string of all newlines and replaces consecutive whitespace
characters into one space character.

=back

=head1 ENVIRONMENT

=over 4

=item TAZ_XSLT_PROFILE

If this environment variable is set to a true value, every call to
apply_transformation is profiled and the result will be printed to
wherever I<$env-E<gt>{'psgi.errors'}> is pointing.

  [http://example.com] xslt-processing-time: 0.01245

=back

=head1 SEE ALSO

L<http://modxslt.org/>, L<https://metacpan.org/module/Plack::Middleware::XSLT>
