package Plack::App::DBI::Gofer;

use strict;
use warnings;

our $VERSION = 0.001; 

use Sys::Hostname qw(hostname);
use List::Util qw(min max sum);

use DBI 1.605, qw(dbi_time);
use DBI::Gofer::Execute;
use Socket;
use MIME::Base64 qw(encode_base64 decode_base64);

use Plack::Request;
use Plack::Response;
use Try::Tiny;
use parent qw/Plack::Component/;
use Cwd ();
use Plack::Util;
use Plack::MIME;
use HTTP::Date;
use Safe::Isa;
use DBI::Gofer::Transport::psgi;

use Plack::Util::Accessor qw/
	config
	transport
/;

sub transport_class { "DBI::Gofer::Transport::psgi" }

sub prepare_app {
	my ($self) = @_;
	$self->config({}) unless $self->config;
	$self->transport( $self->transport_class->new($self->config) ) unless $self->transport;
}

sub call {
	my $self = shift;
	my ($env) = shift;

	my $r = Plack::Request->new($env);
	my $res = $r->new_response();

    my $time_received = dbi_time();
    my $headers_in = $r->headers;

    my ($frozen_request,  $request,  $request_serializer);
    my ($frozen_response, $response, $response_serializer);
    my $executor;
	my ($send_frozen_request);

    my $http_status = 500;
	my $remote_ip = $headers_in->header('Client_ip') 		? $headers_in->header('Client_ip') :  # cisco load balancer
					# mod_proxy, multiple ips
					$headers_in->header('X_Forwarded_For')	? (split /,\s*/ => $headers_in->header('X_Forwarded_For'))[0] : 
					# REMOTE_ADDR
					$r->address;

	my $transport = $self->transport;
    try {
        $executor = $self->transport->executor;

        my $request_content_length = $r->content_length;
        my $response_content_type = 'application/x-perl-gofer-response-binary';
        my $of = "";
        if (!$request_content_length) { # assume GET request
            my $args = $r->query_string || "";
            my %args = $r->query_parameters->flatten;
            my $req = $args{req}
                or die "No req argument or Content-Length ($args)\n";
            $frozen_request = decode_base64($req);
        } else {
            my $content_type = $headers_in->content_type;
            die "Unsupported gofer Content-Type"
                unless $content_type eq 'application/x-perl-gofer-request-binary';
            $r->body->read($frozen_request, $request_content_length);
            if (length($frozen_request) != $request_content_length) {
                die sprintf "Gofer request length (%d) doesn't match Content-Length header (%d)",
                    length($frozen_request), $request_content_length;
            }
        }
		$request = $transport->thaw_request($frozen_request);
		$r->env( 'x-gofer.gofer_request' => $request );
		$response = $executor->execute_request( $request );
		$r->env( 'x-gofer.gofer_response' => $response );

		$frozen_response = $transport->freeze_response($response, $response_serializer);

        $res->content_type($response_content_type);
        # setup http headers
        # See http://perl.apache.org/docs/general/correct_headers/correct_headers.html
        # provide Content-Length for KeepAlive so it works if people want it
        $res->content_length(do { use bytes; length($frozen_response) });

        $res->body($frozen_response);

        $http_status = 200;
    } catch {
        # for errors at this level we don't send a serialized Gofer Response 
        # (but we do create one for logging/stats purposes)

        $http_status = 500;

        # discard any response that might have been prepared already
        # (e.g., an exception is thrown after execute_request returns)
        $response = undef;

        my $error = $_;
        my $action;
        if (ref $error) {
            # allow the exception to override some things
            $http_status = $error->{http_status} if $error->{http_status};
            $action      = $error->{http_action} if $error->{http_action};
            $response    = $error->{gofer_response} if $error->{gofer_response};
            $error       = $error->{error_text}  if $error->{error_text};
            $error       = $error->text if $error->$_can('text');
        }

        chomp $error;
        $error .= sprintf " in %s request from %s, http status %d",
                $headers_in->{'Content-Type'}||$r->method, $remote_ip, $http_status;

        # record the error (via Cleanup handler below) so we can see it later
        # remotely if track_recent is enabled.
        # if exception didn't include a response for logging then create one
        $response ||= $executor->new_response_with_err($DBI::stderr||1, $error);
        $r->env( 'x-gofer.gofer_response' => $response);
        $frozen_response = $transport->freeze_response($response);

        my $default_action = sub {   # default error response behaviour
            my ($r, $errstr, $http_status) = @_;
            warn "$errstr\n";
            $res->status($http_status);
            $res->content_type("text/plain");
            $res->body(sprintf "%s. (%s %s, DBI %s, on %s pid $$)",
                $errstr, __PACKAGE__, $VERSION, $DBI::VERSION, hostname());
            return $http_status;
        };
        $action ||= $default_action;

        $http_status = $action->($res, $error, $http_status, $default_action);
    };
	$res->status( $http_status );
	return $res->finalize;

}


sub executor_for_psgi_request {
    my ($self, $r) = @_;

	$self->_executor(do {
        my $config = { %$self };
		my $gofer_execute_class = $self->gofer_execute_class || 'DBI::Gofer::Execute';
        $gofer_execute_class->new($config);
    }) unless $self->_executor;
	$self->_executor;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plack::App::DBI::Gofer - server side http transport for DBI-Gofer using PSGI

=head1 SYNOPSIS

	use Plack::App::DBI::Gofer;
	my $app = Plack::App::DBI::Gofer->new( config => {
		%DBI_Gofer_Execute_config_params
	})->to_app;
	
	# or map a path to a forced dsn
	use Plack::Builder;
	builder {
		mount '/mydb' => Plack::App::DBI::Gofer->new( config => {
			forced_connect_dsn => 'dbi:SQLite:dbname=mydb.db',
		})->to_app;
	};

For a corresponding client-side transport see L<DBD::Gofer::Transport::http>.

=head1 DESCRIPTION

This module implements a DBD::Gofer server-side http transport through PSGI.

This enables DBI to connect to databases through your PSGI-enabled HTTP server.

=head1 CONFIGURATION

=head2 Gofer Configuration

Rather than provide a DBI proxy that will connect to any database as any user,
you may well want to restrict access to just one or a few databases.

Or perhaps you want the database passwords to be stored only in your app.psgi so
you don't have to maintain them in all your clients. 

A typical usage might be to define configurations for each specific
database being used and then define a coresponding location for each of those.
That would also allow standard http location access controls to be used

That approach can also provide a level of indirection by avoiding the need for
the clients to know and use the actual DSN. The clients can just connect to the
specific gofer url with an empty DSN. This means you can change the DSN being used
without having to update the clients.

This enables the use of forking PSGI web servers and handlers, including 
L<Starman>, L<Monoceros> and L<Gazelle> as caching, stateless database proxies.   

At this time, this application doesn't support asynchronous, event driven servers
such as L<Twiggy>.

=over

=item config

Set to a hash of L<DBI::Gofer::Execute> options, optional.

=back

=head1 DIFFERENCES FROM L<DBI::Gofer::Transport::mod_perl>

=over 

=item * No equivalent for the L<Apache::Status> support

=item * No client side transport (relies instead on L<DBD::Gofer::Transport::http>)

=back

=head1 TO DO

=over 

=item * Add a lighter client side http transport that doesn't require installing mod_perl

Possibly using L<HTTP::Tiny> or L<HTTP::Lite>

=item * More tests

=item * Support http authorization (Basic and Digest)

=item * Support PSGI streaming and async.

=back 

Please report any bugs or feature requests to
C<bug-plack-app-dbi-gofer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Tim Bunce, L<http://www.linkedin.com/in/timbunce>

James Wright L<https://metacpan.org/author/JWRIGHT>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Tim Bunce, Ireland. All rights reserved.

Copyright (c) 2018, James Wright, United States.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

=over

=item * L<DBD::Gofer>

=item * L<DBD::Gofer::Transport::http>

=item * L<Plack>

=back

=cut

