#!/bin/false
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
# PODNAME: Net::Proxmox::VE
# ABSTRACT: Pure Perl API for Proxmox Virtual Environment

use strict;
use warnings;

package Net::Proxmox::VE;
$Net::Proxmox::VE::VERSION = '0.40';
use HTTP::Headers;
use HTTP::Request::Common qw(GET POST DELETE);
use JSON::MaybeXS         qw(decode_json);
use LWP::UserAgent;

use Net::Proxmox::VE::Exception;

# done
use Net::Proxmox::VE::Access;
use Net::Proxmox::VE::Cluster;
use Net::Proxmox::VE::Pools;
use Net::Proxmox::VE::Storage;

# wip
use Net::Proxmox::VE::Nodes;

my $API2_BASE_URL = 'https://%s:%s/api2/json/';


sub action {

    my $self   = shift or return;
    my %params = @_;

    unless (%params) {
        Net::Proxmox::VE::Exception->throw(
            'action() requires a hash for params');
    }
    Net::Proxmox::VE::Exception->throw('path param is required')
      unless $params{path};

    $params{method}    ||= 'GET';
    $params{post_data} ||= {};

    # Check for a valid method
    Net::Proxmox::VE::Exception->throw(
        "invalid http method specified: $params{method}")
      unless $params{method} =~ m/^(GET|PUT|POST|DELETE)$/;

    # Strip prefixed / to path if present
    $params{path} =~ s{^/}{};

    # Collapse duplicate slashes
    $params{path} =~ s{//+}{/};

    unless ( $params{path} eq 'access/domains'
        or $self->check_login_ticket )
    {
        print "DEBUG: invalid login ticket\n"
          if $self->{params}->{debug};
        return unless $self->login();
    }

    my $url = $self->url_prefix . $params{path};

    # Grab the useragent
    my $ua = $self->{ua};

    # Set up the request object
    my $request = HTTP::Request->new();
    $request->uri($url);
    $request->header( 'Cookie' => 'PVEAuthCookie=' . $self->{ticket}->{ticket} )
      if defined $self->{ticket};

    # all methods other than get require the prevention token
    # (ie anything that makes modification)
    unless ( $params{method} eq 'GET' ) {
        $request->header(
            'CSRFPreventionToken' => $self->{ticket}->{CSRFPreventionToken} );
    }

    my $response;
    if ( $params{method} =~ m/^(PUT|POST)$/ ) {
        $request->method( $params{method} );
        my $content = join '&', map { $_ . '=' . $params{post_data}->{$_} }
          sort keys %{ $params{post_data} };
        $request->content($content);
        $response = $ua->request($request);
    }
    elsif ( $params{method} =~ m/^(GET|DELETE)$/ ) {
        $request->method( $params{method} );
        if ( %{ $params{post_data} } ) {
            my $qstring = join '&', map { $_ . '=' . $params{post_data}->{$_} }
              sort keys %{ $params{post_data} };
            $request->uri("$url?$qstring");
        }
        $response = $ua->request($request);
    }
    else {

        # this shouldnt happen
        Net::Proxmox::VE::Exception->throw(
            'This shouldnt happen. Unknown method: ' . $params{method} );
    }

    if ( $response->is_success ) {
        print "DEBUG: successful request: " . $request->as_string . "\n"
          if $self->{params}->{debug};

        my $data = decode_json( $response->decoded_content );

        if ( ref $data eq 'HASH'
            && exists $data->{data} )
        {
            if ( ref $data->{data} eq 'ARRAY' ) {

                return wantarray
                  ? @{ $data->{data} }
                  : $data->{data};

            }

            return $data->{data};

        }

        # just return true
        return 1;

    }
    else {
        Net::Proxmox::VE::Exception->throw( "WARNING: request failed: "
              . $request->as_string . "\n"
              . "WARNING: response status: "
              . $response->status_line
              . "\n" );
    }
    return;

}


sub api_version {
    my $self = shift or return;
    return $self->action( path => '/version', method => 'GET' );
}


sub api_version_check {
    my $self = shift or return;

    my $data = $self->api_version;

    if ( ref $data eq 'HASH' && $data->{version} ) {
        my ($version) = $data->{version} =~ m/^(\d+)/;
        return 1 if $version > 2.0;
    }

    return;
}


sub check_login_ticket {

    my $self = shift or return;

    my $ticket = $self->{ticket} // return;
    return unless ref $ticket eq 'HASH';

    my $is_valid =
         $ticket->{ticket}
      && $ticket->{CSRFPreventionToken}
      && $ticket->{username} eq
      "$self->{params}{username}\@$self->{params}{realm}"
      && $self->{ticket_timestamp}
      && ( $self->{ticket_timestamp} + $self->{ticket_life} ) > time();

    $self->clear_login_ticket unless $is_valid;
    return $is_valid;

}


sub clear_login_ticket {

    my $self = shift or return;

    if ( $self->{ticket} or $self->{timestamp} ) {
        $self->{ticket}           = undef;
        $self->{ticket_timestamp} = undef;
        return 1;
    }

    return;

}


sub debug {
    my $self = shift or return;
    my $d    = shift;

    if ($d) {
        $self->{params}->{debug} = 1;
    }
    elsif ( defined $d ) {
        $self->{params}->{debug} = 0;
    }

    return 1 if $self->{params}->{debug};
    return;

}


sub delete {
    my $self = shift or return;
    my @path = @_    or return;    # using || breaks this

    if ( $self->nodes ) {
        return $self->action( path => join( '/', @path ), method => 'DELETE' );
    }
    return;
}


sub _get {
    my $self      = shift;
    my $post_data = pop @_;
    my @path      = @_;
    return $self->action(
        path      => join( '/', @path ),
        method    => 'GET',
        post_data => $post_data
    );
}

sub get {
    my $self = shift or return;
    my $post_data;
    $post_data = pop
      if ref $_[-1];
    my @path = @_ or return;    # using || breaks this

    # Calling nodes method here would call get method itself and so on
    # Commented out to avoid an infinite loop
    if ( $self->nodes ) {
        return $self->_get( @path, $post_data );
    }
    return;
}


sub login {
    my $self = shift or return;

    # Prepare login request
    my $url = $self->url_prefix . 'access/ticket';

    # Perform login request
    my $request_time = time();
    my $response     = $self->{ua}->post(
        $url,
        {
            'username' => $self->{params}->{username} . '@'
              . $self->{params}->{realm},
            'password' => $self->{params}->{password},
        },
    );

    if ( $response->is_success ) {
        my $login_ticket_data = decode_json( $response->decoded_content );
        $self->{ticket} = $login_ticket_data->{data};

# We use request time as the time to get the json ticket is undetermined,
# id rather have a ticket a few seconds shorter than have a ticket that incorrectly
# says its valid for a couple more
        $self->{ticket_timestamp} = $request_time;
        print "DEBUG: login successful\n"
          if $self->{params}->{debug};
        return 1;
    }
    else {
        if ( $self->{params}->{debug} ) {
            print "DEBUG: login not successful\n";
            print "DEBUG: " . $response->status_line . "\n";
        }
    }

    return;
}


sub new {

    my $c     = shift;
    my @p     = @_;
    my $class = ref($c) || $c;

    my %params;

    if ( scalar @p == 1 ) {

        Net::Proxmox::VE::Exception->throw('new() requires a hash for params')
          unless ref $p[0] eq 'HASH';

        %params = %{ $p[0] };

    }
    elsif ( scalar @p % 2 != 0 ) {    # 'unless' is better than != but anyway
        Net::Proxmox::VE::Exception->throw(
            'new() called with an odd number of parameters');

    }
    else {
        %params = @p
          or
          Net::Proxmox::VE::Exception->throw('new() requires a hash for params');
    }

    my $host = delete $params{host}
      || Net::Proxmox::VE::Exception->throw('host param is required');
    my $password = delete $params{password}
      || Net::Proxmox::VE::Exception->throw('password param is required');
    my $port     = delete $params{port}     || 8006;
    my $username = delete $params{username} || 'root';
    my $realm    = delete $params{realm}    || 'pam';
    my $debug    = delete $params{debug};
    my $timeout  = delete $params{timeout} || 10;
    my $ssl_opts = delete $params{ssl_opts};
    Net::Proxmox::VE::Exception->throw(
        'unknown parameters to new: ' . join( ', ', keys %params ) )
      if keys %params;

    my $self->{params} = {
        host     => $host,
        password => $password,
        port     => $port,
        username => $username,
        realm    => $realm,
        debug    => $debug,
        timeout  => $timeout,
        ssl_opts => $ssl_opts,
    };

    $self->{'ticket'}           = undef;
    $self->{'ticket_timestamp'} = undef;
    $self->{'ticket_life'}      = 7200;    # 2 Hours

    my %lwpUserAgentOptions;
    if ($ssl_opts) {
        $lwpUserAgentOptions{ssl_opts} = $ssl_opts;
    }

    my $ua = LWP::UserAgent->new(%lwpUserAgentOptions);
    $ua->timeout($timeout);
    $self->{ua} = $ua;

    return bless $self, $class;

}


sub post {

    my $self = shift or return;
    my $post_data;
    $post_data = pop
      if ref $_[-1];
    my @path = @_ or return;    # using || breaks this

    if ( $self->nodes ) {

        return $self->action(
            path      => join( '/', @path ),
            method    => 'POST',
            post_data => $post_data
        );

    }
    return;
}


sub put {

    my $self = shift or return;
    my $post_data;
    $post_data = pop
      if ref $_[-1];
    my @path = @_ or return;    # using || breaks this

    if ( $self->nodes ) {

        return $self->action(
            path      => join( '/', @path ),
            method    => 'PUT',
            post_data => $post_data
        );

    }
    return;
}


sub url_prefix {

    my $self = shift or return;

    # Prepare prefix for request
    my $url_prefix = sprintf( $API2_BASE_URL,
        $self->{params}->{host},
        $self->{params}->{port} );

    return $url_prefix;

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Proxmox::VE - Pure Perl API for Proxmox Virtual Environment

=head1 VERSION

version 0.40

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

This Class provides a framework for talking to Proxmox VE 2.0 API instances including ticket headers required for authentication.
You can use just the get/delete/put/post abstraction layer or use the api function methods.
This class provides the building blocks for someone wanting to use
Perl to talk to Proxmox PVE.
It provides a get/put/post/delete abstraction layer as methods on top of Proxmox's REST API, while also handling the Login Ticket headers required for authentication.

Object representations of the Proxmox VE REST API are included in seperate modules.

=head1 WARNING

We are still moving things around and trying to come up with something
that makes sense. We havent yet implemented all the API functions,
so far we only have a basic internal abstraction of the REST interface
and a few modules for each function tree within the API.

Any enhancements are greatly appreciated ! (use github, link below)

Please dont be offended if we refactor and rework submissions.
Perltidy with default settings is prefered style.

Oh, our tests are all against a running server. Care to help make them better?

=head1 METHODS

=head2 action

This calls raw actions against your proxmox server.
Ideally you don't use this directly.

=head2 api_version

Returns the API version of the proxmox server we are talking to,
including some parts of the global datacenter config.

No arguments are available.

A hash will be returned which will include the following:

=over 4

=item release

String. The current Proxmox VE point release in `x.y` format.

=item repoid

String. The short git revision from which this version was build.

=item version

String. The full pve-manager package version of this node.

=item console

Enum. The default console viewer to use. Optional.

Available values: applet, vv, html5, xtermjs

=back

=head2 api_version_check

Checks that the api we are talking to is at least version 2.0

Returns true if the api version is at least 2.0 (perl style true or false)

=head2 check_login_ticket

Verifies if the objects login ticket is valid and not expired

Returns true if valid
Returns false and clears the the login ticket details inside the object if invalid

=head2 clear_login_ticket

Clears the login ticket inside the object

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

=head2 login

Initiates the log in to the PVE Server using JSON API, and potentially obtains an Access Ticket.

Returns true if success

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
$path to post to, hash ref to %post_data

You are returned what action() with the POST method returns

=head2 put

An action helper method that takes two parameters:
$path, hash ref to \%put_data

You are returned what action() with the PUT method returns

=head2 url_prefix

Returns the url prefix used in the rest api calls

=head1 PVE VERSIONS SUPPORT

Firstly, there isn't currently any handling of different versions of the API.

Secondly, Proxmox API reference documentation is also, frustratingly, published only alongside the current release. This makes it difficult to support older versions of the API or different versions of the API concurrently.

Fortunately the API is relatively stable.

Based on the above the bug reporting policy is as follows:

=over 2

=item A function in this module doesn't work against the current published API? This a bug and hope to fix it. Pull requests welcome.

=item A function in this module doesn't exist in the current published API? Pull requests welcomes and promptly merged.

=item A function in this module doesn't work against a previous version of the API? A note will be made in the pod only.

=item A function in this module doesn't exist against a previous version of the API? Pull requests will be merged on a case per case basis.

=back

As such breaking changes may be made to this module to support the current API when necessary.

=head1 DESIGN NOTE

This API would be far nicer if it returned nice objects representing different aspects of the system.
Such an arrangement would be far better than how this module is currently layed out. It might also be
less repetitive code.

=head1 SEE ALSO

=over 4

=item Proxmox Website

http://www.proxmox.com

=item API Reference

More details on the API can be found at L<http://pve.proxmox.com/wiki/Proxmox_VE_API> and
L<http://pve.proxmox.com/pve-docs/api-viewer/index.html>

=back

=head1 AUTHOR

Brendan Beveridge <brendan@nodeintegration.com.au>, Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Dean Hamstad.

This is free software, licensed under:

  The MIT (X11) License

=cut
