package Net::SecurityCenter::REST;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use HTTP::Cookies;
use JSON;
use LWP::UserAgent;

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.203';

#-------------------------------------------------------------------------------
# CONSTRUCTOR
#-------------------------------------------------------------------------------

sub new {

    my ( $class, $host, $options ) = @_;

    if ( !$host ) {
        $@ = 'Specify valid Tenable.sc (SecurityCenter) hostname or IP address';    ## no critic
        return;
    }

    my $agent      = LWP::UserAgent->new();
    my $cookie_jar = HTTP::Cookies->new();

    $agent->agent( _agent() );
    $agent->ssl_opts( verify_hostname => 0 );

    my $timeout  = delete( $options->{'timeout'} );
    my $ssl_opts = delete( $options->{'ssl_options'} ) || {};
    my $logger   = delete( $options->{'logger'} ) || undef;
    my $no_check = delete( $options->{'no_check'} ) || 0;

    if ($timeout) {
        $agent->timeout($timeout);
    }

    if ($ssl_opts) {
        $agent->ssl_opts($ssl_opts);
    }

    $agent->cookie_jar($cookie_jar);

    my $self = {
        host    => $host,
        options => $options,
        url     => "https://$host/rest",
        token   => undef,
        agent   => $agent,
        logger  => $logger,
        _error  => undef,
    };

    bless $self, $class;

    if ( !$no_check ) {
        $self->check();
    }

    return $self;

}

#-------------------------------------------------------------------------------
# UTILS
#-------------------------------------------------------------------------------

sub _agent {

    my $class = __PACKAGE__;
    ( my $agent = $class ) =~ s{::}{-}g;

    return "$agent/" . $class->VERSION;

}

#-------------------------------------------------------------------------------

sub _dumper {

    my (@data) = @_;

    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;

    return Dumper(@data);

}

#-------------------------------------------------------------------------------

sub _trim {

    my ($string) = @_;

    return if ( !$string );

    $string =~ s/^\s+|\s+$//g;
    return $string;

}

#-------------------------------------------------------------------------------

sub check {

    my ($self) = @_;

    my $response = $self->request( 'GET', '/system' );

    if ( !$response ) {
        $self->error( 'Failed to connect to Tenable.sc (SecurityCenter) : ', $self->{'host'}, 500 );
        return;
    }

    $self->{'version'}  = $response->{'version'};
    $self->{'build_id'} = $response->{'buildID'};
    $self->{'license'}  = $response->{'licenseStatus'};
    $self->{'uuid'}     = $response->{'uuid'};

    if ( $self->{'logger'} ) {
        $self->logger( 'info',
            'Tenable.sc (SecurityCenter) ' . $self->{'version'} . ' (Build ID:' . $self->{'build_id'} . ')' );
    }

    return 1;

}

#-------------------------------------------------------------------------------

sub error {

    my ( $self, $message, $code ) = @_;

    if ( defined $message ) {
        $self->{'_error'} = Net::SecurityCenter::Error->new( $message, $code );
        return;
    } else {
        return $self->{'_error'};
    }

}

#-------------------------------------------------------------------------------
# REST HELPER METHODS (get, head, put, post, delete and patch)
#-------------------------------------------------------------------------------

for my $sub_name (qw/get head put post delete patch/) {

    my $req_method = uc $sub_name;
    no strict 'refs';    ## no critic
    eval <<"HERE";       ## no critic
    sub $sub_name {
        my ( \$self, \$path, \$params ) = \@_;
        my \$class = ref \$self;
        ( \@_ == 2 || ( \@_ == 3 && ref \$params eq 'HASH' ) )
            or croak("Usage: \$class->$sub_name( PATH, [HASHREF] )\n");
        return \$self->request('$req_method', \$path, \$params || {});
    }
HERE

}

#-------------------------------------------------------------------------------

sub request {

    my ( $self, $method, $path, $params ) = @_;

    ( @_ == 3 || @_ == 4 )
        or croak( 'Usage: ' . __PACKAGE__ . '->request(GET|POST|PUT|DELETE|PATCH, $PATH, [\%PARAMS])' );

    $method = uc($method);
    $path =~ s{^/}{};

    if ( $method !~ m/(GET|POST|PUT|DELETE|PATCH)/ ) {
        carp( $method, ' is an unsupported request method' );
        croak( 'Usage: ' . __PACKAGE__ . '->request(GET|POST|PUT|DELETE|PATCH, $PATH, [\%PARAMS])' );
    }

    my $url             = $self->{'url'} . "/$path";
    my $agent           = $self->{'agent'};
    my $request         = HTTP::Request->new( $method => $url );
    my $request_content = undef;

    if ( $self->{'logger'} ) {

        $self->logger( 'info', "Method: $method" );
        $self->logger( 'info', "Path: $path" );
        $self->logger( 'info', "URL: $url" );

        # Don't log credential
        if ( $path !~ /token/ ) {
            $self->logger( 'info', "Params: " . _dumper($params) );
        }

    }

    if ( $params->{'file'} ) {

        require HTTP::Request::Common;

        $request = HTTP::Request::Common::POST(
            $url,
            'Content-Type' => 'multipart/form-data',
            'Content'      => [
                Filedata => [ $params->{'file'}, undef, 'Content-Type' => 'application/octet-stream' ]
            ],
        );

        if ( $self->{'logger'} ) {
            $self->logger( 'debug', $request->dump );
        }

    } else {

        $request->header( 'Content-Type', 'application/json' );

        if ($params) {
            $request_content = encode_json($params);
        }

        if ($request_content) {
            $request->content($request_content);
        }

    }

    my $response         = $agent->request($request);
    my $response_content = $response->content();
    my $response_ctype   = $response->headers->{'content-type'};
    my $response_code    = $response->code();

    my $result  = {};
    my $is_json = ( $response_ctype =~ /application\/json/ );

    # Force JSON decode for 403 Forbidden message without JSON Content-Type header
    if ( $response_code == 403 && $response_ctype !~ /application\/json/ ) {
        $is_json = 1;
    }

    if ($is_json) {
        $result = eval { decode_json($response_content) };
    }

    if ( $self->{'logger'} ) {

        my $log_http_status = 'Response status: ' . $response->status_line;

        if ( $response->is_success() ) {
            $self->logger( 'info', $log_http_status );
        } else {
            $self->logger( 'error', $log_http_status );
        }

    }

    if ( $response->is_success() ) {

        if ($is_json) {

            if ( defined( $result->{'response'} ) ) {
                return $result->{'response'};

            } elsif ( $result->{'error_msg'} ) {

                my $error_msg = _trim( $result->{'error_msg'} );

                if ( $self->{'logger'} ) {
                    $self->logger( 'error', $error_msg );
                }

                $self->error( $error_msg, $response_code );
                return;
            }

        }

        return $response_content;

    }

    if ( $is_json && exists( $result->{'error_msg'} ) ) {

        my $error_msg = _trim( $result->{'error_msg'} );

        if ( $self->{'logger'} ) {
            $self->logger( 'error', $error_msg );
        }

        $self->error( $error_msg, $response_code );
        return;

    }

    if ( $self->{'logger'} ) {
        $self->logger( 'error', $response_content );
    }

    $self->error( $response_content, $response_code );
    return;

}

#-------------------------------------------------------------------------------
# HELPER METHODS
#-------------------------------------------------------------------------------

sub upload {

    my ( $self, $file ) = @_;

    ( @_ == 2 )
        or croak( 'Usage: ' . __PACKAGE__ . 'upload( $FILE )' );

    return $self->request( 'POST', '/file/upload', { 'file' => $file } );

}

#-------------------------------------------------------------------------------

sub logger {

    my ( $self, $level, $message ) = @_;

    if ( !$self->{'logger'} ) {
        return 0;
    }

    $level = lc($level);

    my $caller = ( caller(1) )[3] || q{};
    $caller =~ s/(::)(\w+)$/->$2/;

    $self->{'logger'}->$level("$caller - $message");

    return 1;

}

#-------------------------------------------------------------------------------

sub login {

    my ( $self, $username, $password ) = @_;

    ( @_ == 3 ) or croak( 'Usage: ' . __PACKAGE__ . '->login( $USERNAME, $PASSWORD )' );

    my $response = $self->request(
        'POST', '/token',
        {
            username => $username,
            password => $password
        }
    );

    if ( !$response ) {
        return;
    }

    $self->{'token'} = $response->{'token'};
    $self->{'agent'}->default_header( 'X-SecurityCenter', $self->{'token'} );

    if ( $self->{'logger'} ) {
        $self->logger( 'info',  'Connected to SecurityCenter (' . $self->{'host'} . ')' );
        $self->logger( 'debug', "User: $username" );
        $self->logger( 'debug', "Token: " . $self->{'token'} );
    }

    return 1;

}

#-------------------------------------------------------------------------------

sub logout {

    my ($self) = @_;

    $self->request( 'DELETE', '/token' );
    $self->{'token'} = undef;

    if ( $self->{'logger'} ) {
        $self->logger( 'info', 'Disconnected from SecurityCenter (' . $self->{'host'} . ')' );
    }

    return 1;

}

#-------------------------------------------------------------------------------

sub DESTROY {

    my ($self) = @_;

    if ( $self->{'token'} ) {
        $self->logout();
    }

}

#-------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SecurityCenter::REST - Perl interface to Tenable.sc (SecurityCenter) REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;

    my $sc = Net::SecurityCenter::REST('sc.example.org');

    $sc->login('secman', 'password');

    my $running_scans = $sc->get('/scanResult', { filter => 'running' });

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::REST->new ( host [, $params ] )

Create a new instance of L<Net::SecurityCenter::REST>.

Params:

=over 4

=item * C<timeout> : Request timeout in seconds (default is 180) If a socket open,
read or write takes longer than the timeout, an exception is thrown.

=item * C<ssl_options> : A hashref of C<SSL_*> options to pass through to L<IO::Socket::SSL>.

=item * C<logger> : A logger instance (eg. L<Log::Log4perl> or L<Log::Any> for log
the REST request and response messages.

=item * C<no_check> : Disable the check of SecurityCenter installation.

=back


=head1 METHODS

=head2 $sc->post|get|put|delete|patch ( $path [, \%params ] )

Execute a request to SecurityCenter REST API. These methods are shorthand for
calling C<request()> for the given method.

    my $nessus_scan = $sc->post('/scanResult/1337/download',  { 'downloadType' => 'v2' });

=head2 $sc->request ( $method, $path [, \%params ] )

Execute a HTTP request of the given method type ('GET', 'POST', 'PUT', 'DELETE',
''PATCH') to SecurityCenter REST API.

=head2 $sc->login ( $username, $password )

Login into SecurityCenter.

=head2 $sc->logout

Logout from SecurityCenter.

=head2 $sc->upload ( $file )

Upload a file into SecurityCenter.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2019 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
