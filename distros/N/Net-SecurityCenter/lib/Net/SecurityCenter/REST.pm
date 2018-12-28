package Net::SecurityCenter::REST;

use warnings;
use strict;

use Carp;
use LWP::UserAgent;
use HTTP::Cookies;
use JSON;

our $VERSION = '0.100';

sub new {

    my ($class, $host, $options) = @_;

    my $agent      = LWP::UserAgent->new();
    my $cookie_jar = HTTP::Cookies->new;();

    croak('Specify valid SecurityCenter hostname or IP address')
        unless ($host);

    $agent->agent(_agent());
    $agent->ssl_opts(verify_hostname => 0);

    my $timeout  = delete($options->{timeout});
    my $ssl_opts = delete($options->{ssl_options}) || {};

    $agent->timeout($timeout);
    $agent->ssl_opts($ssl_opts);
    $agent->cookie_jar($cookie_jar);

    my $self = {
        host    => $host,
        options => $options,
        url     => "https://$host/rest",
        token   => undef,
        agent   => $agent,
    };

    bless $self, $class;

    #$self->_init();

    return $self;

}

sub _agent {

    my $class = __PACKAGE__;
    (my $agent = $class) =~ s{::}{-}g;

    return $agent . "/" . $class->VERSION;

}

sub _trim {

  my $string = shift;
  return $string unless($string);

  $string =~ s/^\s+|\s+$//g;
  return $string;

}

sub _init {

    my ($self) = @_;

    my $response = eval { $self->request('GET', '/system') };

    croak('Failed to connect to Security Center via ', $self->{url})
        if ($@);

    if ($response) {

        $self->{version}  = $response->{'version'};
        $self->{build_id} = $response->{'buildID'};
        $self->{license}  = $response->{'licenseStatus'};
        $self->{uuid}     = $response->{'uuid'};

    }

}

sub post {

    my ($self, $path, $params) = @_;

    (@_ == 2 || (@_ == 3 && ref $params eq 'HASH'))
        or croak(q/Usage: $sc->post(PATH, [HASHREF])/);

    return $self->request('POST', $path, $params);

}

sub get {

    my ($self, $path, $params) = @_;

    (@_ == 2 || (@_ == 3 && ref $params eq 'HASH'))
        or croak(q/Usage: $sc->get(PATH, [HASHREF])/);

    return $self->request('GET', $path, $params);

}

sub put {

    my ($self, $path, $params) = @_;

    (@_ == 2 || (@_ == 3 && ref $params eq 'HASH'))
        or croak(q/Usage: $sc->put(PATH, [HASHREF])/);

    return $self->request('PUT', $path, $params);

}

sub delete {

    my ($self, $path, $params) = @_;

    (@_ == 2 || (@_ == 3 && ref $params eq 'HASH'))
        or croak(q/Usage: $sc->delete(PATH, [HASHREF])/);

    return $self->request('DELETE', $path, $params);

}

sub patch {

    my ($self, $path, $params) = @_;

    (@_ == 2 || (@_ == 3 && ref $params eq 'HASH'))
        or croak(q/Usage: $sc->patch(PATH, [HASHREF])/);

    return $self->request('PATCH', $path, $params);

}

sub request {

    my ($self, $method, $path, $params) = @_;

#     (@_ == 3 || (@_ == 4 && ref $params eq 'HASH'))
#         or croak(q/Usage: $sc->request(METHOD, PATH, [HASHREF])/);

    croak('Unsupported request method')
        if ($method !~ /(get|post|put|delete|patch)/i);

    $path =~ s/^\///;

    my $url     = $self->{url} . "/$path";
    my $request = HTTP::Request->new( uc($method) => $url );
    my $content = undef;
       $content = encode_json($params) if ($params);

    $request->header('Content-Type', 'application/json');

    if ($content) {
        $request->content($content);
    }

    my $response = $self->{agent}->request($request);

    my $result  = {};
    my $is_json = ($response->headers->{'content-type'} =~ /application\/json/);

    if ($is_json) {
        $result = eval { decode_json($response->content()) };
    }

    if ($response->is_success()) {

        if ($is_json) {

            if (defined($result->{'response'})) {
                return $result->{'response'};
            } elsif ($result->{'error_msg'}) {
                croak _trim($result->{'error_msg'});
            }

        } else {
            return $response->content();
        }

    } else {

        if ($response->code() == 403) {
            $result  = eval { decode_json($response->content()) };
            $is_json = 1;
        }

        if ($is_json && exists($result->{'error_msg'})) {
            croak _trim($result->{'error_msg'});
        } else {
            croak $response->content();
        }

    }

}

sub login {

    my ($self, $username, $password) = @_;

    (@_ == 3) or croak(q/Usage: $sc->login(USERNAME, PASSWORD)/);

    my $response = $self->request('POST', '/token', { username => $username, password => $password });

    $self->{token} = $response->{'token'};
    $self->{agent}->default_header('X-SecurityCenter', $self->{token});

    return 1;

}

sub logout {

    my ($self) = @_;
    $self->request('DELETE', '/token');

    return 1;

}

sub DESTROY {
    my ($self) = @_;
    $self->logout() if $self->{token};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SecurityCenter::REST - Perl interface to Tenable SecurityCenter REST API

=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    my $sc = Net::SecurityCenter::REST('sc.example.org');

    $sc->login('secman', 'password');

    my $running_scans = $sc->get('/scanResult', { filter => 'running' });

    $sc->logout();

=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the REST API of Tenable
SecurityCenter.

For more information about the SecurityCenter REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>

=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::REST->new ( host [, { timeout => $timeout , ssl_options => $ssl_options } ] )

Create a new instance of B<Net::Security::Center::REST>.

=over 4

=item * C<timeout> : Request timeout in seconds (default is 180) If a socket open,
read or write takes longer than the timeout, an exception is thrown.

=item * C<ssl_options> : A hashref of C<SSL_*> options to pass through to L<IO::Socket::SSL>.

=back

=head1 METHODS

=head2 $sc->post|get|put|delete|patch ( path [, { param => value, ... } ] )

Execute a request to SecurityCenter REST API. These methods are shorthand for
calling C<request()> for the given method.

    my $nessus_scan = $sc->post('/scanResult/1337/download',  { 'downloadType' => 'v2' });

=head2 $sc->request (method, path [, { param => value, ... } ] )

Execute a HTTP request of the given method type ('GET', 'POST', 'PUT', 'DELETE',
''PATCH') to SecurityCenter REST API.

=head2 $sc->login ( username, password )

Login into SecurityCenter.

=head2 $sc->logout

Logout from SecurityCenter.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/LotarProject/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/LotarProject/perl-Net-SecurityCenter>

    git clone https://github.com/LotarProject/perl-Net-SecurityCenter.git

=head1 AUTHORS

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
