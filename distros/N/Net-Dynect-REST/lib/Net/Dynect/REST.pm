package Net::Dynect::REST;
# $Id: REST.pm 175 2010-09-27 07:28:53Z james $
use strict;
use warnings;
use Net::Dynect::REST::Request;
use Net::Dynect::REST::Response;
use Net::Dynect::REST::Session;
use LWP::UserAgent;
use HTTP::Request::Common;
use Time::HiRes qw(gettimeofday tv_interval);
use Carp qw(carp cluck);
our $VERSION = do { my @r = (q$Revision: 175 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME

Net::Dynect::REST - A REST implementation to communicate with Dynect

=head1 SYNOPSIS

 use Net::Dynect::REST
 my $dynect = Net::Dynect::REST->new();
 $dynect->login(user_name => $user, customer_name => $customer, password => $password;

=head1 METHODS

=head2 Creating

=over 4

=item Net::Dynect::REST->new()

This constructor will return an object, and can optionally attempt to establish a session if sufficient authentication details are passed as parameters. It takes the optional arguments of:

=over 4

=item * debug

A numeric debug level, where 0 is silent, 1 is standard output, and higher gives more details.

=item * server

=item * protocol

=item * base_path

=item * port

=item * user_name

=item * customer_name

=item * password

=over 4

=back

=back

=cut

sub new {
    my $proto = shift;
    my $self  = bless {}, ref($proto) || $proto;
    my %args  = @_;
    $self->_debug_level( $args{debug} )  if defined $args{debug};
    $self->server( $args{server} )       if defined $args{server};
    $self->protocol( $args{protocol} )   if defined $args{protocol};
    $self->base_path( $args{base_path} ) if defined $args{base_path};
    $self->port( $args{port} )           if defined $args{port};
    if (   defined( $args{user_name} )
        && defined( $args{password} )
        && defined( $args{customer_name} ) )
    {
        my $login = $self->login(
            user_name     => $args{user_name},
            customer_name => $args{customer_name},
            password      => $args{password}
        );
        if ( not $login ) {

            #carp "Tried to log in, but failed";
            return;
        }
    }
    return $self;
}

=back

=head2 Methods

=over 4

=item $dynect->login()

This will attempt to create a valid Session object by forming and sending a login request, and parsing the response. Parameters are:

=over 4

=item * user_name

=item * customer_name

=item * password

=back

=cut

sub login {
    my $self = shift;
    my %args = @_;
    if (
        not(   defined( $args{user_name} )
            && defined( $args{customer_name} )
            && defined( $args{password} ) )
      )
    {
        carp "Login method requires user_name, customer_name and password";
        return;
    }

    my $dynect_rest_request = Net::Dynect::REST::Request->new(
        operation => 'create',
        service   => 'Session',
        params    => {
            user_name     => $args{user_name},
            customer_name => $args{customer_name},
            password      => $args{password}
        }
    );

    if ( not $dynect_rest_request ) {
        carp "Invalid request object";
        return;
    }

    my $dynect_rest_response = $self->execute($dynect_rest_request);

    if ( not $dynect_rest_response ) {
        carp "Did not get a response object";
        return;
    }

    if ( $dynect_rest_response->status !~ /^success$/i ) {
        carp join( ', ', map { $_->info } @{ $dynect_rest_response->msgs } );
        return;
    }

    $self->session(
        Net::Dynect::REST::Session->new( response => $dynect_rest_response ) );
    return 1;
}

=item $dynect->logout()

If we have a valid session, then this will try and perform a logout against Dynect, and remove our sesssion object.

=cut

sub logout {
    my $self = shift;
    if ( not $self->session ) {
        carp "Cannot logout with out current session";
        return;
    }

    my $dynect_rest_request = Net::Dynect::REST::Request->new(
        operation => 'delete',
        service   => 'Session'
    );
    if ( not $dynect_rest_request ) {
        carp "Invalid request object";
        return;
    }

    my $dynect_rest_response = $self->execute($dynect_rest_request);

    if ( not $dynect_rest_response ) {
        carp "Did not get a response";
        return;
    }

    if ( $dynect_rest_response->status !~ /^success$/i ) {
        carp "Could not log out";
        return;
    }
    $self->session(undef);
    return 1;
}

=item $dynect->execute()

This is the main heavy lifting; where Net::Dynect::REST::Request objects get sent to the server, and a Net::Dynect::REST::Response is returned, if all is OK. It takes one argument - the Net::Dynect::REST::Request object.

=cut

sub execute {
    my $self                = shift;
    my $dynect_rest_request = shift;
    if ( ref($dynect_rest_request) ne "Net::Dynect::REST::Request" ) {
        carp "Need a request to execute";
        return;
    }
    elsif (
        not(   defined( $dynect_rest_request->service )
            && defined( $dynect_rest_request->operation ) )
      )
    {
        carp "Error with request - need to set operation and service: "
          . $dynect_rest_request;
        return;
    }

    my $uri = $self->base_uri . $dynect_rest_request->service . "/";

    my $http_request;
    if ( $dynect_rest_request->operation eq "create" ) {
        if ( $dynect_rest_request->params ) {
            $http_request = HTTP::Request::Common::POST(
                $uri,
                'Content-Type' => $dynect_rest_request->mime_type
                  . '; charset=utf-8',
                Content => $dynect_rest_request->params
            );
        }
        else {
            $http_request = HTTP::Request::Common::POST( $uri,
                    'Content-Type' => $dynect_rest_request->mime_type
                  . '; charset=utf-8' );
        }
    }
    elsif ( $dynect_rest_request->operation eq "read" ) {
        if ( $dynect_rest_request->params ) {
            $http_request = HTTP::Request::Common::GET(
                $uri,
                'Content-Type' => $dynect_rest_request->mime_type
                  . '; charset=utf-8',
                Content => $dynect_rest_request->params
            );
        }
        else {
            $http_request = HTTP::Request::Common::GET( $uri,
                    'Content-Type' => $dynect_rest_request->mime_type
                  . '; charset=utf-8' );
        }
    }
    elsif ( $dynect_rest_request->operation eq "update" ) {
        if ( $dynect_rest_request->params ) {
            $http_request = HTTP::Request::Common::PUT(
                $uri,
                'Content-Type' => $dynect_rest_request->mime_type
                  . '; charset=utf-8',
                Content => $dynect_rest_request->params
            );
        }
        else {
            $http_request = HTTP::Request::Common::PUT( $uri,
                    'Content-Type' => $dynect_rest_request->mime_type
                  . '; charset=utf-8' );
        }
    }
    elsif ( $dynect_rest_request->operation eq "delete" ) {
        if ( $dynect_rest_request->params ) {
            $http_request = HTTP::Request::Common::DELETE(
                $uri,
                'Content-Type' => $dynect_rest_request->mime_type
                  . '; charset=utf-8',
                Content => $dynect_rest_request->params
            );
        }
        else {
            $http_request = HTTP::Request::Common::DELETE( $uri,
                    'Content-Type' => $dynect_rest_request->mime_type
                  . '; charset=utf-8' );
        }
    }
    else {
        die "Unrecognised operation: " . $dynect_rest_request->operation;
    }

    $self->_debug( 4, "Making a request to $uri" );
    $self->_debug( 5,
        "Request will be:\n" . $dynect_rest_request . "\n" . ( '-' x 70 ) );

    my $time_start = [gettimeofday];

    my $http_response = $self->_webclient->request($http_request);

    if ($http_response->code eq 307) {
      if ($http_response->decoded_content =~ m!/REST/Job/(\d+)$!) {
        my $job = Net::Dynect::REST::Job->new(connection => $self, job_id => $1);
        carp "Request was deferred; a Job object is being returned. Please check back on ->find() shortly to get your response.";
        return $job;
      } else {
        carp "We got a 307 but we couldnt understand it: ". $http_response->decoded_content;
        return;
      }
    }

    my $time_elapsed         = tv_interval($time_start);
    my $dynect_rest_response = Net::Dynect::REST::Response->new(
        content          => $http_response->decoded_content,
        format           => $dynect_rest_request->format,
        request_duration => $time_elapsed,
        request_time     => $time_start->[0]
    );

    $self->_debug( 2,
        join( '; ', map { $_->info } @{ $dynect_rest_response->msgs } ) ) if defined $dynect_rest_response->msgs;
    $self->_debug( 5,
            "Response received in $time_elapsed:\n"
          . $dynect_rest_response . "\n"
          . ( '-' x 70 ) );

    return $dynect_rest_response;
}

=item $dynect->session()

This is a Net::Dynect::REST::Session object, which should eb the current valid session for this Net::Dynect::REST object to use. It updates the web client to include the B<Auth-Token> header for subsequent requests

=cut

sub session {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( defined($new) && ref($new) ne "Net::Dynect::REST::Session" ) {
            carp "Invalid session: $new";
            return;
        }

        $self->{session} = $new;
        return
          unless
            defined $new;   # Allow the sesison to be undefined if its now dead!
        $self->_debug( 6, "Adding auth token to default headers" );
        $self->_webclient->default_headers(
            HTTP::Headers->new( ':Auth-Token' => $new->token ) );
    }
    return $self->{session};
}

sub _webclient {
    my $self = shift;
    if ( not defined $self->{_webclient} ) {
        $self->{_webclient} = LWP::UserAgent->new(
            agent     => ref($self) . "/" . $VERSION,
            env_proxy => 1
        );
    }
    return $self->{_webclient};
}

sub _debug_level {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^\d$/ ) {
            carp "Invalid debug level: " . $new;
            return;
        }
        $self->{_debug_level} = $new;
        $self->_debug( 0, "Debug set to " . $self->{_debug_level} );
    }
    return $self->{_debug_level} || 0;
}

sub _debug {
    my $self = shift;
    my ( $level, $message ) = @_;
    return unless $level <= $self->_debug_level;

    if ( $level > 8 ) {
        $Carp::CarpLevel = 1;
        cluck $message;
    }
    else {
        carp $message;
    }
}

=back

=head2 Attributes

=over 4

=item $dynect->server()

This is the server host name that we will send our requests to. Default is B<api2.dynect.net>.

=cut

sub server {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{server} = $new;
    }
    return $self->{server} || 'api2.dynect.net';
}

=item $dynect->protocol()

This is the protocol we will use, either B<http> or B<https>. Default is B<https>.

=cut

sub protocol {
    my $self = shift;
    if (@_) {
        my $new = shift;
        return unless $new =~ /^https?$/;
        $self->{protocol} = $new;
    }
    return $self->{protocol} || "https";
}

=item $dynect->base_path()

This is the path that is used to find the services we will be accessing. Default is B</REST/>.

=cut

sub base_path {
    my $self = shift;
    if (@_) {
        my $new = shift;
        return unless $new =~ m!^/[\w\d/-]*$!;
        $self->{base_path} = $new;
    }
    return $self->{base_path} || '/REST/';
}

=item $dynect->port()

The TCP port that we will use. The default is to use whatever is apropriate for the protocol.

=cut

sub port {
    my $self = shift;
    if (@_) {
        my $new = shift;
        return unless $new =~ /^\d+$/;
        $self->{port} = $new;
    }
    return $self->{port};
}

=item $dynect->base_uri()

A convenience method to put together the protocl, server, port and base_path attributes into a URI.

=cut

sub base_uri {
    my $self = shift;
    return unless ( $self->protocol && $self->server && $self->base_path );
    return
        $self->protocol . "://"
      . $self->server
      . ( defined( $self->port ) ? ":" . $self->port : "" )
      . $self->base_path;
}

=back

=head1 SEE ALSO

L<Net::Dynect::REST::Request>, L<Net::Dynect::REST::Response>, L<Net::Dynect::REST::info>.

=head1 AUTHOR

James bromberger, james@rcpt.to

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
