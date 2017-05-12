package SOAP::Transport::HTTP::Log4perl;

=head1 NAME

SOAP::Transport::HTTP::Log4perl - SOAP::Lite plugin that adds Log4perl traces

=head1 SYNOPSIS

    use Log::Log4perl qw(:easy);
    
    # Load this module and request to send all log messages through the logger 'mysoap.soap'
    use SOAP::Transport::HTTP::Log4perl logger => 'myapp.soap';
    
    # Load SOAP lite *AFTER* this module
    use SOAP::Lite 
        uri   => 'http://www.soaplite.com/Server',
        proxy => 'http://localhost:8080/',
    ;
    
    # Initialize log4perl
    Log::Log4perl->easy_init($TRACE);
    my $LOG = Log::Log4perl->get_logger("myapp.client");
    $LOG->info("Program start");
    
    # Make a SOAP::Lite call and watch for the logs
    my $value = SOAP::Lite->new->test(1)->result;

=head1 DESCRIPTION

This module logs all L<SOAP::Lite>'s messages (requests and responses) through
L<Log::Log4perl>. The module works by changing SOAP::Lite's default HTTP client,
which means that the module has to be loaded before SOAP::Lite is first loaded.

It's a simple debugging tool that provides a good overview of what's been
sent and received by L<SOAP::Lite> that can be quite handy when dealing with
services over secure channels (HTTPS) or when going through corporate a proxy.

This module is more of a proof of concept that can be used by anyone that wants
to have a closer understanding of what's being passed through the network.

=head1 DISCLAIMER

This module takes no approach regarding privacy and simply dumps everything that's
sent and received. If you need to remove sensitive data (passwords, personal information)
make sure that you modify the module or don't log the data into a persistent appender.

This module was developed for debugging purposes where privacy is not a concern.

=head1 API

=head2 import

This module can be configured through the import mechanism.

To change the name of the logger (I<soap>) used simply provide a name through
the parameter I<logger>:

    use SOAP::Transport::HTTP::Log4perl logger => 'app.soap';

=head1 AUTHOR

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>

=head1 COPYRIGHT

(C) 2010 Emmanuel Rodriguez

=cut

use strict;
use warnings;

use base 'LWP::UserAgent';

use Log::Log4perl ':nowarn';

use XML::LibXML;
use LWP;
use SOAP::Lite;
use SOAP::Transport::HTTP;

# Register this class as being the LWP::UserAgent instance to use for all SOAP communication.
BEGIN {
    $SOAP::Transport::HTTP::Client::USERAGENT_CLASS = __PACKAGE__;
}

our $VERSION = '0.01';

# We get a default logger, the function import allows us to redefine the name
# of the logger through:
#  use SOAP::Transport::HTTP::Log4perl logger => 'SOAP.transport';
my $LOG = Log::Log4perl->get_logger('soap');


sub import {
    my $class = shift;
    my %args = @_;

    if (my $name = $args{logger}) {
        $LOG = Log::Log4perl->get_logger($name);
    }
}


#
# Pretty print the SOAP envelopes with nicely formatted XML.
#
sub request {
    my $self = shift;
    my ($request) = @_;
    
    _log_message($request);

    # Ask our parent to perform the real SOAP call
    my $response = $self->SUPER::request($request);
    
    _log_message($response);
    
    return $response;
}


#
# Logs an HTTP message (request or response) through log4perl.
#
sub _log_message {
    my ($message) = @_;
    my $content_type = $message->content_type;
    my $content = $message->decoded_content;

    $LOG->trace("SOAP HTTP Headers:\n", $message->headers_as_string);

    my $is_response = 0; # We want to inspect responses for faults
    if (_isa_http_type($message, 'request')) {
        # SOAP requests sent through SOAP::Lite don't have a content type.
        $content_type = 'text/xml' if $content_type eq '';
    }
    elsif (_isa_http_type($message, 'response')) {
        $is_response = 1;
    }
    else {
        $LOG->error("Unknwon SOAP message type ", ref($message), " with content:\n", $content);
        return;
    }

    # Ideally we will only deal with xml but Google can send HTML responses
    # sometimes. In that case we pretty format the response too and assume that
    # it's an error.
    my $is_html = 0;
    if ($content_type eq 'text/xml') {
        # XML is what we expect, nothing to do here at this moment
    }
    elsif ($content_type eq 'text/html') {
        # We will use the HTML parser and issue an error later on
        $is_html = 1;
    }
    else {
        $LOG->error("SOAP message not in xml ($content_type), content:\n$content");
        return;
    }


    # Pretty print the content. We use LibXML's toString function, so the idea
    # is to parse the SOAP message and print the DOM tree. That's how pretty
    # print is done. Once we have a DOM object we can then look for faults in
    # the document too!
    my $parser = XML::LibXML->new();
    $parser->load_ext_dtd(0);
    $parser->validation(0);
    $parser->pedantic_parser(0);

    my $dom;
    eval {
        if ($is_html) {
            $dom = $parser->parse_html_string($content);
        }
        else {
            $dom = $parser->parse_string($content);
        }
        1;
    } or do {
        $LOG->error("Got error $@ when parsing:\n$content");
        return;
    };
    my $pretty = $dom->toString(1);


    if ($is_html) {
        # That's no legit SOAP response!
        $LOG->error("SOAP HTML:\n", $pretty);
        return;
    }


    # In the case of a response check if we have a fault
    if ($is_response) {
        # NOTE: I was using a very old version of XML::LibXML which doesn't support namespaces!
        my $result = $dom->find('/*[local-name() = "Envelope"]/*[local-name() = "Body"]/*[local-name() = "Fault"]');
        if ($result) {
            $LOG->warn("SOAP Fault:\n", $pretty);
            return;
        }

        $LOG->debug("SOAP Response:\n", $pretty);
        return;
    }


    $LOG->debug("SOAP Request:\n", $pretty);
}


# Returns true if the given message is of the given type.
# Ex: $message is a HTTP::Response
sub _isa_http_type {
    my ($message, $type) = @_;
    $type = ucfirst lc $type;
    return UNIVERSAL::isa($message, "HTTP::$type");
}


1;
