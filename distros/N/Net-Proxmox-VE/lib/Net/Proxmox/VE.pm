#!/bin/false
# PODNAME: Net::Proxmox::VE
# ABSTRACT: Pure perl API for Proxmox virtualisation

use strict;
use warnings;

package Net::Proxmox::VE;
$Net::Proxmox::VE::VERSION = '0.32';

use Carp qw( croak );
use HTTP::Headers;
use HTTP::Request::Common qw(GET POST DELETE);
use JSON qw(decode_json);

# done
use Net::Proxmox::VE::Pools;
use Net::Proxmox::VE::Storage;
use Net::Proxmox::VE::Access;
use Net::Proxmox::VE::Cluster;

# wip
use Net::Proxmox::VE::Nodes;


sub action {

    my $self = shift or return;
    my %params = @_;

    unless (%params) {
        croak 'new requires a hash for params';
    }
    croak 'path param is required' unless $params{path};

    $params{method} ||= 'GET';
    $params{post_data} ||= {};

    # Check its a valid method

    croak "invalid http method specified: $params{method}"
      unless $params{method} =~ m/^(GET|PUT|POST|DELETE)$/;

    # Strip prefixed / to path if present
    $params{path} =~ s{^/}{};

    # Collapse duplicate slashes
    $params{path} =~ s{//+}{/};

    unless ( $self->check_login_ticket ) {
        print "DEBUG: invalid login ticket\n"
          if $self->{params}->{debug};
        return unless $self->login();
    }

    my $url = $self->url_prefix . '/api2/json/' . $params{path};

    # Grab the useragent
    my $ua = $self->{ua};

    # Set up the request object
    my $request = HTTP::Request->new();
    $request->uri($url);
    $request->header(
        'Cookie' => 'PVEAuthCookie=' . $self->{ticket}->{ticket} );

    my $response;

    # all methods other than get require the prevention token
    # (ie anything that makes modification)
    unless ( $params{method} eq 'GET' ) {
        $request->header(
            'CSRFPreventionToken' => $self->{ticket}->{CSRFPreventionToken} );
    }

# Not sure why but the php api for proxmox ve uses PUT instead of post for
# most things, the api doc only lists GET|POST|DELETE and the api returns 'PUT' as
# an unrecognised method
# so we'll just force POST from PUT
    if ( $params{method} =~ m/^(PUT|POST)$/ ) {
        $request->method( $params{method} );    # Patch removed
        my $content = join '&', map { $_ . '=' . $params{post_data}->{$_} }
          sort keys %{ $params{post_data} };
        $request->content($content);
        $response = $ua->request($request);
    }
    elsif ( $params{method} =~ m/^(GET|DELETE)$/ ) {
        $request->method( $params{method} );
        $response = $ua->request($request);
    }
    else {

        # this shouldnt happen
        croak 'this shouldnt happen';
    }

    if ( $response->is_success ) {
        print "DEBUG: successful request: " . $request->as_string . "\n"
          if $self->{params}->{debug};

        # my $content = $response->decoded_content;
        my $data    = decode_json( $response->decoded_content );

        if ( ref $data eq 'HASH'
            && exists $data->{data} )
        {
            if ( ref $data->{data} ) {

                return wantarray
                  ? @{ $data->{data} }
                  : $data->{data};

            }

            return $data->{data}

        }

        # just return true
        return 1

    }
    else {
        print "WARNING: request failed: " . $request->as_string . "\n";
        print "WARNING: response status: " . $response->status_line . "\n";
    }
    return

}


sub api_version {
    my $self = shift or return;
    return $self->action( path => '/version', method => 'GET' );
}


sub api_version_check {
    my $self = shift or return;

    my $data = $self->api_version;

    if (   ref $data eq 'HASH'
        && $data->{version}
        && $data->{version} >= 2.0 )
    {
        return 1;
    }

    return;
}


sub debug {
    my $self = shift or return;
    my $d = shift;

    if ($d) {
        $self->{debug} = 1;
    }
    elsif ( defined $d ) {
        $self->{debug} = 0;
    }

    return 1 if $self->{debug};
    return

}


sub delete {
    my $self = shift or return;
    my @path = @_    or return;    # using || breaks this

    if ( $self->nodes ) {
        return $self->action( path => join( '/', @path ), method => 'DELETE' );
    }
    return
}


sub get {
    my $self = shift or return;
    my $post_data;
    $post_data = pop
        if ref $_[-1];
    my @path = @_    or return;    # using || breaks this

    # Calling nodes method here would call get method itself and so on
    # Commented out to avoid an infinite loop
    #if ( $self->nodes ) {
        return $self->action( path => join( '/', @path ), method => 'GET', post_data => $post_data );
    #}
    return;
}


sub new {

    my $c     = shift;
    my @p     = @_;
    my $class = ref($c) || $c;

    my %params;

    if ( scalar @p == 1 ) {

        croak 'new() requires a hash for params'
          unless ref $p[0] eq 'HASH';

        %params = %{ $p[0] };

    }
    elsif ( scalar @p % 2 != 0 ) {    # 'unless' is better than != but anyway
        croak 'new() called with an odd number of parameters'

    }
    else {
        %params = @p
          or croak 'new() requires a hash for params';
    }

    croak 'host param is required'     unless $params{'host'};
    croak 'password param is required' unless $params{'password'};

    $params{port}     ||= 8006;
    $params{username} ||= 'root';
    $params{realm}    ||= 'pam';
    $params{debug}    ||= undef;
    $params{timeout}  ||= 10;

    my $self->{params} = \%params;
    $self->{'ticket'}           = undef;
    $self->{'ticket_timestamp'} = undef;
    $self->{'ticket_life'}      = 7200;    # 2 Hours

    bless $self, $class;
    return $self

}


sub post {

    my $self      = shift or return;
    my $post_data;
    $post_data = pop
        if ref $_[-1];
    my @path = @_    or return;    # using || breaks this

    if ( $self->nodes ) {

        return $self->action(
            path      => join( '/', @path ),
            method    => 'POST',
            post_data => $post_data
          )

    }
    return
}


sub put {

    my $self      = shift or return;
    my $post_data;
    $post_data = pop
        if ref $_[-1];
    my @path = @_    or return;    # using || breaks this

    if ( $self->nodes ) {

        return $self->action(
            path      => join( '/', @path ),
            method    => 'PUT',
            post_data => $post_data
          )

    }
    return
}



sub url_prefix {

    my $self = shift or return;

    # Prepare prefix for request
    my $url_prefix = sprintf( 'https://%s:%s',
        $self->{params}->{host},
        $self->{params}->{port} );

    return $url_prefix

}


1;

=pod

=encoding UTF-8

=head1 NAME

Net::Proxmox::VE - Pure perl API for Proxmox virtualisation

=head1 VERSION

version 0.32

=head1 SYNOPSIS

    use Net::Proxmox::VE;

    %args = (
        host     => 'proxmox.local.domain',
        password => 'barpassword',
        username => 'root', # optional
        port     => 8006,   # optional
        realm    => 'pam',  # optional
    );

    $host = Net::Proxmox::VE->new(%args);

    $host->login() or die ('Couldn\'t log in to proxmox host');

=head1 DESCRIPTION

This Class provides the framework for talking to Proxmox VE 2.0 API instances.
This just provides a get/delete/put/post abstraction layer as methods on Proxmox VE REST API
This also handles the ticket headers required for authentication

More details on the API can be found here:
http://pve.proxmox.com/wiki/Proxmox_VE_API
http://pve.proxmox.com/pve2-api-doc/

This class provides the building blocks for someone wanting to use PHP to talk to Proxmox 2.0. Relatively simple piece of code, just provides a get/put/post/delete abstraction layer as methods on top of Proxmox's REST API, while also handling the Login Ticket headers required for authentication.

=head1 WARNING

We are still moving things around and trying to come up with something
that makes sense. We havent yet implemented all the API functions,
so far we only have a basic internal abstraction of the REST interface
and a few modules for each function tree within the API.

Any enchancements are greatly appreciated ! (use github, link below)

Please dont be offended if we refactor and rework submissions.
Perltidy with default settings is prefered style.

Oh, our tests are all against a running server. Care to help make them better?

=head1 DESIGN NOTE

This API would be far nicer if it returned nice objects representing different aspects of the system.
Such an arrangement would be far better than how this module is currently layed out. It might also be
less repetitive code.

=head1 METHODS

=head2 action

This calls raw actions against your proxmox server.
Ideally you don't use this directly.

=head2 api_version

Returns the API version of the proxmox server we are talking to

=head2 api_version_check

Checks that the api we are talking to is at least version 2.0

Returns true if the api version is at least 2.0 (perl style true or false)

=head2 debug

Has a single optional argument of 1 or 0 representing enable or disable debugging.

Undef (ie no argument) leaves the debug status untouched, making this method call simply a query.

Returns the resultant debug status (perl style true or false)

=head2 delete

An action helper method that just takes a path as an argument and returns the
value of action() with the DELETE method

=head2 get

An action helper method that just takes a path as an argument and returns the
value of action with the GET method

=head2 new

Creates the Net::Proxmox::VE object and returns it.

Examples...

  my $obj = Net::Proxmox::VE->new(%args);
  my $obj = Net::Proxmox::VE->new(\%args);

Valid arguments are...

=over 4

=item I<host>

Proxmox host instance to interact with. Required so no default.

=item I<username>

User name used for authentication. Defaults to 'root', optional.

=item I<password>

Pass word user for authentication. Required so no default.

=item I<port>

TCP port number used to by the Proxmox host instance. Defaults to 8006, optional.

=item I<realm>

Authentication realm to request against. Defaults to 'pam' (local auth), optional.

=item I<ssl_opts>

If you're using a self-signed certificate, SSL verification is going to fail, and we need to tell C<IO::Socket::SSL> not to attempt certificate verification.

This option is passed on as C<ssl_opts> options to C<LWP::UserAgent-E<gt>new()>, ultimately for C<IO::Socket::SSL>.

Using it like this, causes C<LWP::UserAgent> and C<IO::Socket::SSL> not to attempt SSL verification:

    use IO::Socket::SSL qw(SSL_VERIFY_NONE);
    ..
    %args = (
        ...
        ssl_opts => {
            SSL_verify_mode => SSL_VERIFY_NONE,
            verify_hostname => 0
        },
        ...
    );
    my $proxmox = Net::Proxmox::VE->new(%args);

Your connection will work now, but B<beware: you are now susceptible to a man-in-the-middle attack>.

=item I<debug>

Enabling debugging of this API (not related to proxmox debugging in any way). Defaults to false, optional.

=back

=head2 post

An action helper method that takes two parameters: $path, \%post_data
$path to post to,  hash ref to %post_data

You are returned what action() with the POST method returns

=head2 put

An action helper method that takes two parameters:
path
hash ref to post data
your returned what post returns

=head2 url_prefix

returns the url prefix used in the rest api calls

=head1 SEE ALSO

=over 4

=item Proxmox Website

http://www.proxmox.com

=item API reference

http://pve.proxmox.com/pve2-api-doc

=back

=head1 AUTHOR

Brendan Beveridge <brendan@nodeintegration.com.au>, Dean Hamstead <dean@bytefoundry.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# vim: softtabstop=2 tabstop=2 shiftwidth=2 ft=perl expandtab smarttab
