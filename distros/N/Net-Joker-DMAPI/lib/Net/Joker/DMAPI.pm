package Net::Joker::DMAPI;

our $VERSION = '0.09';
use strict;
use warnings;
use 5.010;
use Carp;
use Data::Censor;
use Data::Dump;
use DateTime;
use Hash::Merge;
use LWP::UserAgent;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use URI;

=head1 NAME

Net::Joker::DMAPI - interface to Joker's Domain Management API

=head1 DESCRIPTION

An attempt at a sane wrapper around Joker's DMAPI (domain management API).

Automatically logs in, and parses responses into something a bit more usable as
much as possible.

=head1 SYNOPSIS

    my $dmapi = Net::Joker::DMAPI->new(
        username => 'bob@example.com',
        password => 'hunter2',
    );

    # Get whois details for a domain - returns parsed data structure
    my $whois_details = $dmapi->query_whois({ domain => $domain });
    my @nameservers = @{ $whos_details->{domain}{nameservers} };
    
    # can also use query_whois on contact handles
    my $admin_handle_details = $dmapi->query_whois(
        { contact => $whois_details->{domain}{admin_c} }
    );
    
    my $current_balance = $dmapi->current_balance;

    my $tlds = $dmapi->available_tlds;


=head1 ATTRIBUTES

=over

=item username

Your Joker account username.

=cut

has username => (
    is => 'rw',
    isa => Str,
);

=item password

Your Joker account password

=cut

has password => (
    is => 'rw',
    isa => Str,
);

=item debug

Whether to omit debug messages; disabled by default, set to a true value to
enable.  See also the C<logger> attribute to which you can provide a coderef
which will be called with messages.  If C<debug> is true, all messages will be
output to STDOUT as well as passed to the C<logger> coderef (if provided).

=cut

has debug => (
    is => 'rw',
    isa => Int,
    default => 0,
);

=item logout_on_destroy

End the Joker session upon object destruction, 1 by default.

=cut

has logout_on_destroy => (
    is      => 'rw',
    isa     => Int,
    default => 1,
);

=item ua

An LWP::UserAgent object to use.  One is constructed by default, so you don't
need to supply this unless you have a specific need to do so.

=cut

has ua => (
    is => 'rw',
    isa => InstanceOf['LWP::UserAgent'],
    builder => 1,
);
sub _build_ua {
    my $ua = LWP::UserAgent->new;
    $ua->agent(__PACKAGE__ . "/$VERSION");
    return $ua;
}

=item dmapi_url

The URL to Joker's DMAPI.  You won't need to provide this unless you for some
reason need to have requests go elsewhere; it defaults to Joker's live DMAPI
URL.

=cut

has dmapi_url => (
    is => 'rw',
    isa => Str,
    default => 'https://dmapi.joker.com/request',
);

=item balance

The current balance of your Joker account; automatically updated each time a
response from the Joker API is received.

=cut

has balance => (
    is => 'rw',
    isa => Str,
);

=item available_tlds_list

An arrayref of TLDs which are available to the reseller.  Joker return this in
response to the login call, so this is populated after login; it's recommended
you access it via the C<available_tlds> method (see below) though, which will
call C<login> for you first then return the list.

=cut

has available_tlds_list => (
    is => 'rw',
    isa => ArrayRef,
);


=item logger

A coderef to be used to log interactions with Joker; if this is defined, the
coderef provided is called with the log messages, so you can log them however
your application usually does.

The coderef will be called with two parameters - the log level (C<debug>,
C<info>, C<error>), and the message.

=cut

has logger => (
    is => 'rw',
    isa => CodeRef,
    predicate => 'has_logger',
);

has auth_sid => (
    is => 'rw',
    isa => Str,
    default => '',
    predicate => 'has_auth_sid',
);

=back

=head1 METHODS

=over

=item login

Logs in to the Joker DMAPI, retrieves the C<Auth-Sid> from the response, and
stores it in the C<auth_sid> attribute for future requests.  You won't usually
need to call this, as it will happen automatically if you use the convenience
methods, but if you want to poke at C<do_request> yourself, you'll need it.

=cut

has _joker_session_expiry_time => (
    is  => 'rw',
    isa => Int,
);

sub _joker_session_still_valid {
    my $self = shift;

    return 1 if $self->_joker_session_expiry_time > time();
}

sub login {
    my $self = shift;
    
    # If we've already logged in, we're fine
    if ($self->auth_sid && $self->_joker_session_still_valid()) {
        $self->_log(debug => "Already have auth_sid, no need to log in");
        return 1;
    }

    $self->_log(info => "Logging in as " . $self->username);
    my ($login_body, %headers) = $self->do_request(
        'login',
        { username => $self->username, password => $self->password }
    );

    my $session_timeout
        = exists $headers{'Session-Timeout'}
        ? $headers{'Session-Timeout'}
        : 3600;

    $self->_joker_session_expiry_time(time() + $session_timeout);
    # If we got back an Auth-Sid: header, do_request will have 
    # $self->auth_sid with it, so check that happened - if not, login failed
    if (!$self->has_auth_sid) {
        $self->_log(error => "Login request failed!");
        die "Login request did not return an Auth-Sid";
    }

    # OK, the response body to the login call, strangely, is a list of TLDs
    # we can sell.  Parse it and store it for reference.
    my @tlds = split /\n/, $login_body;
    $self->available_tlds_list([sort @tlds]);

    $self->_log(debug => "Login was successful");
}


=item do_request

Takes the method name you want to call, and a hashref of arguments, calls the
method, and returns the response.

For instance:

  my $response = $dmapi->do_request('query-whois', { domain => $domain });

The response returned is as given by Joker's (inconsistent) API, though; so
you'll probably want to look for a suitable method in this class which takes
care of parsing the response and returning something useful.  If a method for
the DMAPI method you wish to use doesn't yet exist, contact me or submit a patch
:)  In particular, some requests don't return the result, just an ID which
you'll then need to use to poll for the result.

=cut

# Given a method name and some params, perform the request, check for success,
# and return the result
sub do_request {
    my ($self, $method, $params) = @_;

    $params ||= {};
    my $url = $self->_form_request_url($method, $params);
    $self->_log(
        info => "Calling $method with params: "
            . Data::Dump::dump(Data::Censor->clone_and_censor($params))
    );
    my $response = $self->ua->get($url);

    $self->_log(
        info => "$method response status " . $response->status_line
            . " - body: " . $response->decoded_content
    );

    if (!$response->is_success) {
        my $error = "$method request failed: " . $response->status_line;
        $self->_log( error => $error );
        die $error;
    } else {
        my $content = $response->decoded_content;

        # Response will consist of some headers (e.g. Version, Status-Text,
        # Status-Code) then some body lines
        my ($headers_blob, $body) = split /(?:\r?\n){2,}/, $content, 2;
        my %headers;
        for my $header (split /\r?\n/, $headers_blob) {
            my ($k,$v) = split /:\s/, $header, 2;
            $headers{$k} = $v;
        }

        my ($dmapi_major_version) = $headers{Version} =~ /^(\d+\.\d+)\.?/;
        if ($dmapi_major_version ne '1.2') {
            warn __PACKAGE__ . " $VERSION has not been tested with Joker"
                . " DMAPI version $headers{Version}";
        }
        if ($headers{'Status-Code'} != 0) {
            my $error = "Joker request failed with status "
                . $headers{'Status-Text'};
            $self->_log(error => $error);
            die $error;
        }

        $self->balance($headers{'Account-Balance'}) if defined $headers{'Account-Balance'};
        $self->auth_sid($headers{'Auth-Sid'}) if $headers{'Auth-Sid'};

        return wantarray ? ($body, %headers) : $body;
    };
}

=item available_tlds

Returns the list of TLDs which are available to the reseller to sell.

=cut

sub available_tlds {
    my $self = shift;
    $self->login;
    return $self->available_tlds_list;
}

=item account_balance

Returns the current balance of your Joker account.  The C<balance> attribute is
automatically updated after every API call; this method is simply provided to
ensure you're logged in and return the balance - useful if you want to monitor
the balance from a Nagios plugin, say, rather than just seeing what the balance
was after making another API call.

=cut

sub account_balance {
    my $self = shift;
    $self->login;
    return $self->balance;
}

=item query_whois

A convenient method to call the DMAPI C<query_whois> method, and return the
response after parsing it into something useful.

    my $whois = $dmapi->query_whois({ domain => $domain });

The DMAPI accepts C<domain>, C<contact> or C<host>, to look up domains, contact
handles or nameservers respectively.

The response is parsed into a data structure - for instance, the domain's
status, which is returned by Joker as C<domain.status>, will be found at
C<$whois->{domain}{status}>.  Nameservers are collated into a hashref.
Datetimes returned by Joker are automatically inflated to DateTime objects.

=cut

sub query_whois {
    my ($self, $params) = @_;
    my @acceptable_params = qw(domain contact host);
    my @specs = grep { defined $_ } map { $params->{$_} } @acceptable_params;
    if (scalar @specs != 1) {
        Carp::croak(
            "query_whois must be called with exactly one of the params: "
            . join ',', @acceptable_params
        );
    }
    $self->login;
    my $result = $self->do_request('query-whois', $params);

    return $self->_parse_whois_response($result);
}

=item expiry_date

Returns the expiry date for the given domain.

  my $expires_datetime = $dmapi->expiry_date($domain);

=cut

sub expiry_date {
    my ($self, $domain) = @_;
    return $self->query_whois({ domain => $domain })->{domain}{expires};
}

# Given a method name and parameters, return the appropriate URL for the request
sub _form_request_url {
    my ($self, $method, $args) = @_;
    my $uri = URI->new($self->dmapi_url . "/$method");
    $uri->query_form({ 'auth-sid' => $self->auth_sid, %{ $args || {} } });
    return $uri->canonical;
}


# Log stuff by calling the logger coderef if provided.
# If debug is true, also output it to STDERR.
sub _log {
    my ($self, $level, $message) = @_;
    if ($self->has_logger) {
        $self->logger->($level, $message);
    }
    if ($self->debug) {
        print STDERR "($level) $message\n";
    }
}
    


# Parse the format we get back from query-whois into a sensible data strucuture
# The format looks like lines in the format:
# domain.status: lock,transfer-autoack
# domain.name: J Example
# domain.created.date: 20000914175917
# ...etc - and we want to parse that into a data structure, e.g.:
# { domain => { status => '...', name => '...', created => { date => '...' } } }
# TODO: may need a more generic name if this format is used for other API
# responses
sub _parse_whois_response {
    my ($self, $response) = @_;

    my $results = {};
    my @nameservers;
    my %key_value_pairs = (
        map {
            my ($key, $value) = $_ =~ /(\S+): (.+)/;
            # BODGE: don't like doing this in the map, but the data will be
            # lost if we do it later, as Joker return multiple nameservers
            # as pairs of lines like:
            # domain.nservers.nserver.no: 1
            # domain.nservers.nserver.handle: ns.example.com
            if ($key eq 'domain.nservers.nserver.handle') {
                push @nameservers, $value;
            }
            # For easier use as hashref keys, swap hyphens for underscores
            $key  =~ s/-/_/g;
            $key => $value
        } split /\n/, $response
    );

    # First pass: match dates and inflate them into DateTime objects:
    for my $date_key (grep { 
        $_ =~ /\.date$/ || $_ eq 'domain.expires'
        } keys %key_value_pairs) {
        $key_value_pairs{$date_key} =~ m{
                (?<year>   \d{4} )
                (?<month>  \d{2} )
                (?<day>    \d{2} )
                (?<hour>   \d{2} )
                (?<minute> \d{2} )
                (?<second> \d{2} )
        }x;
        my $dt = DateTime->new(%+);
        $key_value_pairs{$date_key} = $dt;
    }

    # This parsing code was based on a solution kindly supplied by atta on
    # Freenode/#perl late one night when my brain couldn't quite attack this
    # problem.  Thanks, atta!
    while (my($key, $value) = each %key_value_pairs) {
        my @parts = split qr(\.), $key;
        my $r->{ pop @parts } = $value;
        my $aux;

        for my $part (reverse @parts) {
            $aux = {};
            $aux->{$part} = $r;
            $r = $aux;
        }
        $results = Hash::Merge::merge($results, $r);
    }
    
    if (@nameservers) {
        $results->{domain}{nameservers} = \@nameservers;
        delete $results->{domain}{nservers};
    }
    return $results;
}


# Destructor, to end session
sub DESTROY {
    my ($self) = @_;
    if ( $self->has_auth_sid  && $self->logout_on_destroy ) {
        $self->_joker_session_expiry_time(time());
        $self->do_request('logout');
    }
}

=back

=head1 AUTHOR

David Precious C<< <davidp@preshweb.co.uk> >>

=head1 ACKNOWLEDGEMENTS

Tomasz Czepiel (@tczepiel)


=head1 BUGS / FEATURE REQUESTS

If you've found a bug, or have a feature request or wish to contribute a patch,
this module is developed on GitHub - please feel free to raise issues or pull
requests against the repo at:
L<https://github.com/bigpresh/Net-Joker-DMAPI>


=head1 LICENSE AND COPYRIGHT

Copyright 2014-17 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

Joker's DMAPI documentation is at:
L<https://joker.com/faq/category/39/22-dmapi.html>

L<WWW::Domain::Registry::Joker> is another module for talking to Joker's DMAPI,
but hasn't been updated for some time and doesn't provide any convenient methods
or parsing of responses, just the basics.

=cut


1;

