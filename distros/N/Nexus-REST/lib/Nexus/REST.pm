package Nexus::REST;
{
  $Nexus::REST::VERSION = '0.001';
}
# ABSTRACT: Thin wrapper around Nexus's REST API

use 5.010;
use utf8;
use strict;
use warnings;

use Carp;
use URI;
use MIME::Base64;
use URI::Escape;
use JSON;
use Data::Util qw/:check/;
use REST::Client;

sub new {
    my ($class, $URL, $username, $password, $rest_client_config) = @_;

    $URL = URI->new($URL) if is_string($URL);
    is_instance($URL, 'URI')
        or croak __PACKAGE__ . "::new: URL argument must be a string or a URI object.\n";

    # Append the service suffix if not already specified
    unless ($URL->path =~ m@/service/local$@) {
        $URL->path($URL->path . '/service/local');
    }

    # If no password is set we try to lookup the credentials in the .netrc file
    if (! defined $password) {
        eval {require Net::Netrc}
            or croak "Can't require Net::Netrc module. Please, specify the USERNAME and PASSWORD.\n";
        if (my $machine = Net::Netrc->lookup($URL->host, $username)) { # $username may be undef
            $username = $machine->login;
            $password = $machine->password;
        } else {
            croak "No credentials found in the .netrc file.\n";
        }
    }

    is_string($username)
        or croak __PACKAGE__ . "::new: USERNAME argument must be a string.\n";

    is_string($password)
        or croak __PACKAGE__ . "::new: PASSWORD argument must be a string.\n";

    $rest_client_config = {} unless defined $rest_client_config;
    is_hash_ref($rest_client_config)
        or croak __PACKAGE__ . "::new: REST_CLIENT_CONFIG argument must be a hash-ref.\n";

    my $rest = REST::Client->new($rest_client_config);

    # Set default base URL
    $rest->setHost($URL);

    # Follow redirects/authentication by default
    $rest->setFollow(1);

    # Since Nexus doesn't send an authentication chalenge, we may
    # simply force the sending of the authentication header.
    $rest->addHeader(Authorization => 'Basic ' . encode_base64("$username:$password"));

    $rest->addHeader(accept => 'application/json');

    # Configure UserAgent name
    $rest->getUseragent->agent(__PACKAGE__);

    return bless {
        rest => $rest,
        json => JSON->new->utf8->allow_nonref,
    } => $class;
}

sub _error {
    my ($self, $content, $type, $code) = @_;

    $type = 'text/plain' unless $type;
    $code = 500          unless $code;

    my $msg = __PACKAGE__ . " Error[$code";

    if (eval {require HTTP::Status}) {
        if (my $status = HTTP::Status::status_message($code)) {
            $msg .= " - $status";
        }
    }

    $msg .= "]:\n";

    if ($type =~ m:text/plain:i) {
        $msg .= $content;
    } elsif ($type =~ m:application/json:) {
        my $error = $self->{json}->decode($content);
        if (ref $error eq 'HASH' && exists $error->{errorMessages}) {
            foreach my $message (@{$error->{errorMessages}}) {
                $msg .= "- $message\n";
            }
        } else {
            $msg .= $content;
        }
    } elsif ($type =~ m:text/html:i && eval {require HTML::TreeBuilder}) {
        $msg .= HTML::TreeBuilder->new_from_content($content)->as_text;
    } else {
        $msg .= "<unconvertable Content-Type: '$type}'>";
    };
    $msg =~ s/\n*$/\n/s;       # end message with a single newline
    return $msg;
}

sub _content {
    my ($self) = @_;

    my $rest    = $self->{rest};
    my $code    = $rest->responseCode();
    my $type    = $rest->responseHeader('Content-Type');
    my $content = $rest->responseContent();

    $code =~ /^2/
        or croak $self->_error($content, $type, $code);

    return unless $content;

    if (! defined $type) {
        croak $self->_error("Cannot convert response content with no Content-Type specified.");
    } elsif ($type =~ m:^application/json:i) {
        return $self->{json}->decode($content);
    } elsif ($type =~ m:^text/plain:i) {
        return $content;
    } else {
        croak $self->_error("I don't understand content with Content-Type '$type'.");
    }
}

sub _build_query {
    my ($self, $query) = @_;

    is_hash_ref($query) or croak $self->_error("The QUERY argument must be a hash-ref.");

    return '?'. join('&', map {$_ . '=' . uri_escape($query->{$_})} keys %$query);
}

sub GET {
    my ($self, $path, $query) = @_;

    $path .= $self->_build_query($query) if $query;

    $self->{rest}->GET($path);

    return $self->_content();
}

sub DELETE {
    my ($self, $path, $query) = @_;

    $path .= $self->_build_query($query) if $query;

    $self->{rest}->DELETE($path);

    return $self->_content();
}

sub PUT {
    my ($self, $path, $query, $value, $headers) = @_;

    $path .= $self->_build_query($query) if $query;

    $headers                   //= {};
    $headers->{'Content-Type'} //= 'application/json;charset=UTF-8';

    $self->{rest}->PUT($path, $self->{json}->encode($value), $headers);

    return $self->_content();
}

sub POST {
    my ($self, $path, $query, $value, $headers) = @_;

    $path .= $self->_build_query($query) if $query;

    $headers                   //= {};
    $headers->{'Content-Type'} //= 'application/json;charset=UTF-8';

    $self->{rest}->POST($path, $self->{json}->encode($value), $headers);

    return $self->_content();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Nexus::REST - Thin wrapper around Nexus's REST API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Nexus::REST;

    my $nexus = Nexus::REST->new('https://nexus.example.net', 'myuser', 'mypass');

=head1 DESCRIPTION

L<Nexus|http://www.sonatype.org/nexus/> is an artifact repository manager
from L<Sonatype|http://www.sonatype.com/>.

This module is a thin wrapper around Nexus's REST API:

=over

=item * L<Core API|https://repository.sonatype.org/nexus-restlet1x-plugin/default/docs/index.html>

=item * L<Indexer Lucene Plugin|https://repository.sonatype.org/nexus-indexer-lucene-plugin/default/docs/index.html>

=back

=head1 CONSTRUCTOR

=head2 new URL, USERNAME, PASSWORD [, REST_CLIENT_CONFIG]

The constructor needs up to four arguments:

=over

=item * URL

A string or a URI object denoting the base URL of the Nexus
server. This is a required argument.

=item * USERNAME

The username of a Nexus user.

It can be undefined if PASSWORD is also undefined. In such a case the
user credentials are looked up in the C<.netrc> file.

=item * PASSWORD

The HTTP password of the user. (This is the password the user uses to
log in to Nexus's web interface.)

It can be undefined, in which case the user credentials are looked up
in the C<.netrc> file.

=item * REST_CLIENT_CONFIG

A Nexus::REST object uses a REST::Client object to make the REST
invocations. This optional argument must be a hash-ref that can be fed
to the REST::Client constructor. Note that the C<URL> argument
overwrites any value associated with the C<host> key in this hash.

=back

=head1 REST METHODS

Nexus's REST API documentation lists dozens of "resources" which can be
operated via the standard HTTP requests: GET, DELETE, PUT, and
POST. Nexus::REST objects implement four methods called GET, DELETE,
PUT, and POST to make it easier to invoke and get results from Nexus's
REST endpoints.

All four methods need two arguments:

=over

=item * RESOURCE

This is the resource's 'path', sans the C</service/local> prefix. For
example, ...

This argument is required.

=item * QUERY

Some resource methods require or admit parameters which are passed as
a C<query-string> appended to the resource's path. You may construct
the query string and append it to the RESOURCE argument yourself, but
it's easier and safer to pass the arguments in a hash. This way the
query string is constructed for you and its values are properly
L<percent-encoded|http://en.wikipedia.org/wiki/Percent-encoding> to
avoid errors.

This argument is optional for GET and DELETE. For PUT and POST it must
be passed explicitly as C<undef> if not needed.

=back

The PUT and POST methods accept two more arguments:

=over

=item * VALUE

This is the "entity" being PUT or POSTed. It can be any value, but
usually is a hash-ref. The value is encoded as a
L<JSON|http://www.json.org/> string using the C<JSON::encode> method
and sent with a Content-Type of C<application/json>.

It's usually easy to infer from the Nexus REST API documentation which
kind of value you should pass to each resource.

This argument is required.

=item * HEADERS

This optional argument allows you to specify extra HTTP headers that
should be sent with the request. Each header is specified as a
key/value pair in a hash.

=back

All four methods return the value returned by the associated
resource's method, as specified in the documentation, decoded
according to its content type as follows:

=over

=item * application/json

The majority of the API's resources return JSON values. Those are
decoded using the C<decode> method of a C<JSON> object. Most of the
endpoints return hashes, which are returned as a Perl hash-ref.

=item * text/plain

Those values are returned as simple strings.

=back

Some endpoints don't return anything. In those cases, the methods
return C<undef>. The methods croak if they get any other type of
values in return.

In case of errors (i.e., if the underlying HTTP method return an error
code different from 2xx) the methods croak with a multi-line string
like this:

    ERROR: <CODE> - <MESSAGE>
    <CONTENT-TYPE>
    <CONTENT>

So, in order to treat errors you must invoke the methods in an eval
block or use any of the exception handling Perl modules, such as
C<Try::Tiny> and C<Try::Catch>.

=head2 GET RESOURCE [, QUERY]

Returns the RESOURCE as a Perl data structure.

=head2 DELETE RESOURCE [, QUERY]

Deletes the RESOURCE.

=head2 PUT RESOURCE, QUERY, VALUE [, HEADERS]

Creates RESOURCE based on VALUE.

=head2 POST RESOURCE, QUERY, VALUE [, HEADERS]

Updates RESOURCE based on VALUE.

=head1 UTILITY METHODS

This module still doesn't provide any utility methods.

=head1 SEE ALSO

=over

=item * C<REST::Client>

Nexus::REST uses a REST::Client object to perform the low-level interactions.

=back

=head1 REPOSITORY

L<https://github.com/gnustavo/Nexus-REST>

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
