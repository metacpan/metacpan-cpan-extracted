package SOAP::Transport::ActiveWorks::HTTP::Apache;


BEGIN
{
	use strict;
	use vars qw($VERSION);
	$VERSION = '0.28a';

	use Apache;
	use Apache::Constants qw(:common :response);

	require SOAP::Transport::ActiveWorks::HTTP::Proxy;
}


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
    # my $http_protocol = $r->protocol();
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

    my $s = SOAP::Transport::ActiveWorks::HTTP::Proxy->new();

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

SOAP::Transport::ActiveWorks::HTTP::Apache - Forward SOAP requests from Apache to an ActiveWorks broker

=head1 SYNOPSIS

 package Apache::SOAPServer;
 use strict;
 use Apache;
 use SOAP::Transport::HTTP::Apache;
 use SOAP::Transport::ActiveWorks::HTTP::Apache;

 sub handler {

     my $http_safe_classes = {
         ClassA => undef,
         ClassB => undef,
     };

     my $aw_safe_classes = {
         ClassC     => undef,
         Calculator => undef,
     };

     my $r = Apache->request();

     my %args = $r->args();

     if ( $http_safe_classes->{$args{class}} ) {
          #
          #  Handle requests here and now.
          #
          SOAP::Transport::HTTP::Apache->handler($http_safe_classes);
     }
     else {
          #
          #  Forward to an adapter for handling. 
          #
          SOAP::Transport::ActiveWorks::HTTP::Apache->handler($aw_safe_classes);
     }

 }

=head1 DESCRIPTION

This package is a minor rewrite of the SOAP::Transport::HTTP::Apache.  The
difference is that it uses a proxy handler to forward requests to an ActiveWorks
broker instead the HTTP server handler.

=head1 DEPENDENCIES

SOAP::Transport::HTTP::Server;

=head1 AUTHOR

Daniel Yacob, L<yacob@rcn.com|mailto:yacob@rcn.com>

=head1 SEE ALSO

S<perl(1). SOAP(3). SOAP::Transport::ActiveWorks::HTTP::Proxy(3).>
