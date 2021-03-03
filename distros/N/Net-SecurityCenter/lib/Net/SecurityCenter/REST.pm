package Net::SecurityCenter::REST;

use warnings;
use strict;

use version;
use Carp ();
use HTTP::Cookies;
use JSON;
use LWP::UserAgent;

use Net::SecurityCenter::Error;
use Net::SecurityCenter::Utils qw(trim dumper);

our $VERSION = '0.310';
our $ERROR;

#-------------------------------------------------------------------------------
# CONSTRUCTOR
#-------------------------------------------------------------------------------

sub new {

    my ( $class, $host, $options ) = @_;

    if ( !$host ) {
        Carp::croak 'Specify the Tenable.sc hostname or IP address';
    }

    my $agent      = LWP::UserAgent->new();
    my $cookie_jar = HTTP::Cookies->new();

    $agent->agent( _agent() );
    $agent->ssl_opts( verify_hostname => 0 );    # Disable Host verification

    my $timeout  = delete( $options->{'timeout'} );
    my $ssl_opts = delete( $options->{'ssl_options'} ) || {};
    my $logger   = delete( $options->{'logger'} ) || undef;
    my $scheme   = delete( $options->{'scheme'} ) || 'https';

    my $url = "$scheme://$host/rest";

    if ($timeout) {
        $agent->timeout($timeout);
    }

    if ($ssl_opts) {
        $agent->ssl_opts( %{$ssl_opts} );
    }

    $agent->cookie_jar($cookie_jar);

    my $self = {
        host    => $host,
        options => $options,
        url     => $url,
        token   => undef,
        api_key => undef,
        agent   => $agent,
        logger  => $logger,
        error   => undef,
    };

    bless $self, $class;

    if ( !$self->_check ) {
        Carp::croak $self->{error}->message;
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

sub _check {

    my ($self) = @_;

    my $response = $self->request( 'GET', '/system' );

    if ( !$response ) {
        $self->error( 'Failed to connect to Tenable.sc (' . $self->{'host'} . ')', 500 );
        return;
    }

    $self->{'version'}  = $response->{'version'};
    $self->{'build_id'} = $response->{'buildID'};
    $self->{'license'}  = $response->{'licenseStatus'};
    $self->{'uuid'}     = $response->{'uuid'};

    $self->logger( 'info', 'Tenable.sc ' . $self->{'version'} . ' (Build ID:' . $self->{'build_id'} . ')' );
    return 1;

}

#-------------------------------------------------------------------------------

sub error {

    my ( $self, $message, $code ) = @_;

    if ( defined $message ) {
        $self->{error} = Net::SecurityCenter::Error->new( $message, $code );
        return;
    } else {
        return $self->{error};
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
            or Carp::croak("Usage: \$class->$sub_name( PATH, [HASHREF] )\n");
        return \$self->request('$req_method', \$path, \$params || {});
    }
HERE

}

#-------------------------------------------------------------------------------

sub request {

    my ( $self, $method, $path, $params ) = @_;

    ( @_ == 3 || @_ == 4 )
        or Carp::croak( 'Usage: ' . __PACKAGE__ . '->request(GET|POST|PUT|DELETE|PATCH, $PATH, [\%PARAMS])' );

    $method = uc($method);
    $path =~ s{^/}{};

    if ( $method !~ m/(?:GET|POST|PUT|DELETE|PATCH)/ ) {
        Carp::carp( $method . ' is an unsupported request method' );
        Croak::croak( 'Usage: ' . __PACKAGE__ . '->request(GET|POST|PUT|DELETE|PATCH, $PATH, [\%PARAMS])' );
    }

    my $url     = $self->{'url'} . "/$path";
    my $agent   = $self->{'agent'};
    my $request = HTTP::Request->new( $method => $url );

    $self->logger( 'debug', "Method: $method" );
    $self->logger( 'debug', "Path: $path" );
    $self->logger( 'debug', "URL: $url" );

    # Don't log credential
    if ( $path !~ /token/ ) {
        $self->logger( 'debug', "Params: " . dumper($params) );
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

    } else {

        $request->header( 'Content-Type', 'application/json' );

        if ($params) {
            $request->content( encode_json($params) );
        }

    }

    # Reset error
    $self->{'error'} = undef;

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

    $self->logger( 'debug', 'Response status: ' . $response->status_line );

    if ( ref $result->{warnings} eq 'ARRAY' ) {
        foreach my $warning ( @{ $result->{'warnings'} } ) {
            Carp::carp( $warning->{code} . ': ' . $warning->{warning} );
        }
    }

    if ( $response->is_success() ) {

        if ($is_json) {

            if ( defined( $result->{'response'} ) ) {
                return $result->{'response'};

            } elsif ( $result->{'error_msg'} ) {

                my $error_msg = trim( $result->{'error_msg'} );

                $self->logger( 'error', $error_msg );
                $self->error( $error_msg, $response_code );

                return;

            }

        }

        return $response_content;

    }

    if ( $is_json && exists( $result->{'error_msg'} ) ) {

        my $error_msg = trim( $result->{'error_msg'} );

        $self->logger( 'error', $error_msg );
        $self->error( $error_msg, $response_code );

        return;

    }

    $self->logger( 'error', $response_content );
    $self->error( $response_content, $response_code );

    return;

}

#-------------------------------------------------------------------------------
# HELPER METHODS
#-------------------------------------------------------------------------------

sub upload {

    my ( $self, $file ) = @_;

    ( @_ == 2 )
        or Carp::croak( 'Usage: ' . __PACKAGE__ . '->upload( $FILE )' );

    return $self->request( 'POST', '/file/upload', { 'file' => $file } );

}

#-------------------------------------------------------------------------------

sub logger {

    my ( $self, $level, $message ) = @_;

    return if ( !$self->{'logger'} );

    $level = lc($level);

    my $caller = ( caller(1) )[3] || q{};
    $caller =~ s/(::)(\w+)$/->$2/;

    $self->{'logger'}->$level("$caller - $message");

    return 1;

}

#-------------------------------------------------------------------------------

sub login {

    my ( $self, %args ) = @_;

    # Detect "flat" login argument with username and password
    if (   !( defined( $args{'access_key'} ) && defined( $args{'secret_key'} ) )
        && !( defined( $args{'username'} ) && defined( $args{'password'} ) ) )
    {

        my $username = ( keys %args )[0];
        my $password = $args{$username};

        %args = (
            username => $username,
            password => $password,
        );

    }

    my $username   = delete( $args{'username'} );
    my $password   = delete( $args{'password'} );
    my $access_key = delete( $args{'access_key'} );
    my $secret_key = delete( $args{'secret_key'} );

    if ( !$username && !$access_key ) {
        Carp::croak('Specify username/password or API Key');
    }

    if ($username) {

        my $response = $self->request(
            'POST', '/token',
            {
                username => $username,
                password => $password
            }
        );

        return if ( !$response );

        $self->{'token'} = $response->{'token'};
        $self->{'agent'}->default_header( 'X-SecurityCenter', $self->{'token'} );

        $self->logger( 'info',  'Connected to Tenable.sc (' . $self->{'host'} . ')' );
        $self->logger( 'debug', "User: $username" );

    }

    if ($access_key) {

        my $version_check = ( version->parse( $self->{'version'} ) <=> version->parse('5.13.0') );

        if ( $version_check < 0 ) {
            Carp::croak "API Key Authentication require Tenable.sc v5.13.0 or never";
        }

        $self->{'api_key'} = 1;
        $self->{'agent'}->default_header( 'X-APIKey', "accessKey=$access_key; secretKey=$secret_key" );

        my $response = $self->request( 'GET', '/currentUser' );

        return if ( !$response );

        $self->logger( 'info', 'Connected to Tenable.sc (' . $self->{'host'} . ') using API Key' );

    }

    return 1;

}

#-------------------------------------------------------------------------------

sub logout {

    my ($self) = @_;

    if ( $self->{'token'} ) {
        $self->request( 'DELETE', '/token' );
        $self->{'token'} = undef;
    }

    if ( $self->{'api_key'} ) {
        $self->{'agent'}->default_header( 'X-APIKey', undef );
        $self->{'api_key'} = undef;
    }

    $self->logger( 'info', 'Disconnected from Tenable.sc (' . $self->{'host'} . ')' );

    return 1;

}

#-------------------------------------------------------------------------------

sub DESTROY {

    my ($self) = @_;

    if ( $self->{'token'} ) {
        $self->logout();
    }

    return;

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

    if (! $sc->login('secman', 'password')) {
        die $sc->error;
    }

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

=item * C<logger> : A logger instance (eg. L<Log::Log4perl>, L<Log::Any> or L<Mojo::Log>)
for log the REST request and response messages.

=item * C<scheme> : URI scheme (default: HTTPS).

=back

=head3 Two-Way SSL/TLS Mutual Authentication

You can use configure SSL client certificate authentication for Tenable.sc user
account authentication using L<IO::Socket::SSL> C<SSL_*> options in
B<ssl_options> param.

B<Example 1: User certificate + Private Key>

    my $sc = Net::SecurityCenter::REST( $sc_server, {
        ssl_options => {
            SSL_cert_file => '/path/ssl.cer',   # Client Certificate
            SSL_key_file  => '/path/priv.key',  # Private Key
        }
    } );

B<Example 2: User certificate + Private Key + Password>

    my $sc = Net::SecurityCenter::REST( $sc_server, {
        ssl_options => {
            SSL_cert_file => '/path/ssl.cer',   # Client Certificate
            SSL_key_file  => '/path/priv.key',  # Private Key
            SSL_passwd_cb => sub { 'secret' }   # Key secret
        }
    } );

B<Example 3: PKCS#12>

    my $sc = Net::SecurityCenter::REST( $sc_server, {
        ssl_options => {
            SSL_cert_file => '/path/ssl.p12',   # PKCS#12 file
        }
    } );

From L<IO::Socket::SSL> man:

B<SSL_cert_file> | B<SSL_cert> | B<SSL_key_file> | B<SSL_key>

The certificate can be given as a file with C<SSL_cert_file> or as an internal
representation of an X509* object (like you get from L<Net::SSLeay> or
L<IO::Socket::SSL::Utils::PEM_xxx2cert>) with C<SSL_cert>. If given as a file it
will automatically detect the format. Supported file formats are PEM, DER and
PKCS#12, where PEM and PKCS#12 can contain the certificate and the chain to use,
while DER can only contain a single certificate.

For each certificate a key is need, which can either be given as a file with
C<SSL_key_file> or as an internal representation of an EVP_PKEY* object with
C<SSL_key> (like you get from L<Net::SSLeay> or L<IO::Socket::SSL::Utils::PEM_xxx2key>).
If a key was already given within the PKCS#12 file specified by C<SSL_cert_file>
it will ignore any C<SSL_key> or C<SSL_key_file>. If no C<SSL_key> or
C<SSL_key_file> was given it will try to use the PEM file given with
C<SSL_cert_file> again, maybe it contains the key too.

B<SSL_passwd_cb>

If your private key is encrypted, you might not want the default password prompt
from L<Net::SSLeay>. This option takes a reference to a subroutine that should
return the password required to decrypt your private key.


=head1 METHODS

=head2 $sc->post|get|put|delete|patch ( $path [, \%params ] )

Execute a request to Tenable.sc REST API. These methods are shorthand for
calling C<request()> for the given method.

    my $nessus_scan = $sc->post('/scanResult/1337/download',  { 'downloadType' => 'v2' });

=head2 $sc->request ( $method, $path [, \%params ] )

Execute a HTTP request of the given method type ('GET', 'POST', 'PUT', 'DELETE',
''PATCH') to Tenable.sc REST API.

=head2 $sc->login ( ... )

Login into Tenable.sc using username/password or API Key.

=head3 Username and password authentication

    $sc->login( $username, $password ):
    $sc->login( username => ..., password => ... );


=head3 API Key authentication

Since Tenable.SC 5.13 it's possibile to use API Key authentication using C<access_key>
and C<secret_key>:

    $sc->login( access_key => ..., secret_key => ... );

More information about API Key authentication:

=over 4

=item * Enable API Key Authentication - L<https://docs.tenable.com/tenablesc/Content/EnableAPIKeys.htm>

=item * Generate API Keys - L<https://docs.tenable.com/tenablesc/Content/GenerateAPIKey.htm>

=back

=head2 $sc->logout

Logout from Tenable.sc.

=head2 $sc->upload ( $file )

Upload a file into Tenable.sc.

=head2 $sc->error

Catch the Tenable.sc errors and return L<Net::SecurityCenter::Error> class.


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

This software is copyright (c) 2018-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
