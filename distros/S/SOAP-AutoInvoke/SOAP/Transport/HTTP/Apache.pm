package SOAP::Transport::HTTP::Apache;

use strict;
use vars qw($VERSION);
$VERSION = '0.28a';

use SOAP::Transport::HTTP::Server;

use Apache;
use Apache::Constants qw(:common :response);

sub handler {
    my (undef, $safe_classes) = @_;
    my $optional_dispatcher;

    my $r = Apache->request();

    my %args = $r->args();
    unless (exists $args{class}) {
        return BAD_REQUEST;
    }
    my $request_class = $args{class};
    unless (exists $safe_classes->{$request_class}) {
        return BAD_REQUEST;
    }
    if ( $safe_classes->{$request_class}
         && (ref($safe_classes->{$request_class}) eq "CODE") ) {
         $optional_dispatcher = $safe_classes->{$request_class};
    }
    my $http_protocol = $r->protocol();
    my $http_method   = $r->method();

    my $request_header_reader = sub {
        $r->header_in($_[0]);
    };
    my $request_content_reader = sub {
        $r->read(@_);
    };

    my $response_header_writer = sub {
	# TBD: call err_header_out on error
	$r->header_out(@_);
    };

    my $sent_headers = 0;
    my $response_content_writer = sub {
	# TBD: call custom_response on error
	$r->send_http_header() unless $sent_headers++;
	$r->print(shift);
    };

    my $s = SOAP::Transport::HTTP::Server->new();

    $s->handle_request($http_method, $request_class,
			   $request_header_reader, 
			   $request_content_reader,
			   $response_header_writer,
			   $response_content_writer,
			   $optional_dispatcher);
    OK;
}

1;
__END__

=head1 NAME

SOAP::Transport::HTTP::Apache - SOAP mod_perl handler

=head1 SYNOPSIS

Use this class to expose SOAP endpoints using Apache and mod_perl.
Here's an example of a class that would like to receive SOAP
packets. Note that it implements a single interesting function,
handle_request, that takes there arguments: an array of headers,
a body, and an EnvelopeMaker for creating the response:

    package Calculator;
    use strict;

    sub new {
        bless {}, shift;
    }

    sub handle_request {
        my ($self, $headers, $body, $envelopeMaker) = @_;

        $body->{extra_stuff} = "heres some extra stuff";

        foreach my $header (@$headers) {
            $header->{extra_stuff} = "heres some more extra stuff";
	    $envelopeMaker->add_header(undef, undef, 0, 0, $header);
	}
	$envelopeMaker->set_body(undef, 'myresponse', 0, $body);
    }

    1;

In order to translate HTTP requests into calls on your Calculator
class above, you'll need to write an Apache handler. This is where
you'll use the SOAP::Transport::HTTP::Apache class:

    package ServerDemo;
    use strict;
    use SOAP::Transport::HTTP::Apache;

    sub handler {
	my $safe_classes = {
	    Calculator => undef,
	};
      SOAP::Transport::HTTP::Apache->handler($safe_classes);
    }

1;

As you can see, this class basically does it all - parses the HTTP
headers, reads the request, and sends a response. All you have to do
is specify the names of classes that are safe to dispatch to.

Of course, in order to tell Apache about your handler class above,
you'll need to modify httpd.conf. Here's a simple example that shows
how to set up an endpoint called "/soap" that maps to your ServerDemo
handler above:

    <Location /soap>
        SetHandler perl-script
        PerlHandler ServerDemo
    </Location>

(I leave it up to you to make sure ServerDemo is in
Perl's @INC path - see Writing Apache Modules
with Perl and C by O'Reilly for help with mod_perl,
or just man mod_perl)

=head1 DESCRIPTION

This class encapsulates the details of hooking up to mod_perl,
and then calls SOAP::Transport::HTTP::Server to do the SOAP-specific
stuff. This way the Server class can be reused with any web server
configuration (including CGI), by simply composing it with a different
front-end (for instance, SOAP::Transport::HTTP::CGI).

=head2 handler(SafeClassHash, OptionalDispatcher)

This is the only method on the class, and you must pass a
hash reference whose keys contain the collection of classes
that may be invoked at this endpoint. If you specify class
FooBar in this list, for instance, and a client sends a SOAP
request to http://yourserver/soap?class=FooBar, then the
SOAP::Transport::HTTP::Server class will eventually attempt
to load FooBar.pm, instatiate a FooBar, and call
its handle_request function (see SOAP::Transport::HTTP::Server
for more detail). If you don't include a class in this hash,
SOAP/Perl won't run it. I promise.

By the way, only the keys in this hash are important, the
values are ignored. 

Also, nothing is stopping you from messing around with the request
object yourself if you'd like to add some headers or whatever;
you can always call Apache->request() to get the request object
inside your handle_request function. Just make sure you finish
what you're doing before you return to SOAP::Transport::HTTP::Server,
because at that point the response is marshaled and sent back.

See SOAP::Transport::HTTP::Server for a description of the
OptionalDispatcher argument.

=head1 DEPENDENCIES

SOAP::Transport::HTTP::Server

=head1 AUTHOR

Keith Brown

=cut
