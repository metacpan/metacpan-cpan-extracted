package SOAP::Transport::HTTP::CGI;

use strict;
use vars qw($VERSION);
$VERSION = '0.28';

use SOAP::Transport::HTTP::Server;

my $status_strings = {
    400 => "Bad Request",
};

sub handler {
    my (undef, $safe_classes, $optional_dispatcher) = @_;

    unless ($ENV{QUERY_STRING} =~ /class=(.+$)/) {
	    return _send_status(400);
    }
    my $request_class = $1;

    unless (exists $safe_classes->{$request_class}) {
	    return _send_status(400);
    }

    my $http_method   = $ENV{REQUEST_METHOD};

    my $request_header_reader = sub {
        my ($base_name, $standard_cgi_header) = @_;
        my $s = uc($base_name);
        $s =~ s/-/_/g;
        $s = 'HTTP_' . $s unless $standard_cgi_header;
        $ENV{$s};
    };

    my $request_content_reader = sub {
	    read STDIN, $_[0], $_[1];
    };

    my $response_header_writer = sub {
	    print $_[0] . ":" . $_[1] . "\n";
    };

    my $sent_headers = 0;
    my $response_content_writer = sub {
	    print "\n" unless $sent_headers++;
	    print shift;
    };

    my $s = SOAP::Transport::HTTP::Server->new();

    $s->handle_request($http_method, $request_class,
                       $request_header_reader, 
                       $request_content_reader,
                       $response_header_writer,
		       $response_content_writer,
		      $optional_dispatcher);
}

sub _send_status {
    my ($status_code) = @_;
    my $status_string = $status_strings->{$status_code};
    print "Status: $status_code $status_string\n\n";
}

1;
__END__

=head1 NAME

SOAP::Transport::HTTP::CGI - Generic SOAP CGI handler

=head1 SYNOPSIS

Use this class to expose SOAP endpoints using vanilla CGI.
Here's an example SOAP endpoint exposed using this class:

    package ServerDemo;
    use strict;
    use SOAP::Transport::HTTP::CGI;

    sub handler {
	my $safe_classes = {
	    Calculator => undef,
	};
      SOAP::Transport::HTTP::CGI->handler($safe_classes);
    }

    1;

(I leave it up to you to figure out how to get Perl scripts
to run as CGI scripts - please see your Perl docs for details)

=head1 DESCRIPTION

This class encapsulates the details of hooking up to CGI,
and then calls SOAP::Transport::HTTP::Server to do the SOAP-specific
stuff. This way the Server class can be reused with any web server
configuration (including mod_perl), by simply composing it with a different
front-end (for instance, SOAP::Transport::HTTP::Apache, for instance.

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

Also, nothing is stopping you from messing around with the response
yourself if you'd like to add some headers or whatever;
you can always call print() dump more headers to STDOUT.
Just make sure you finish what you're doing before you
return to SOAP::Transport::HTTP::Server, because at that
point the response is marshaled and sent back.

See SOAP::Transport::HTTP::Server for details on the
OptionalDispatcher parameter.

=head1 DEPENDENCIES

SOAP::Transport::HTTP::Server

=head1 AUTHOR

Keith Brown

=cut
