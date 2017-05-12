#
# High-level API interface to Opera Link
#
# http://www.opera.com/docs/apis/linkrest/
#

package Net::OperaLink;

our $VERSION = '0.05';

use 5.010;
use feature qw(state);
use strict;
use warnings;

use Carp           ();
use CGI            ();
use Data::Dumper   ();
use LWP::UserAgent ();
use Net::OAuth 0.25;
use URI            ();
use JSON::XS       ();

use Net::OperaLink::Bookmark;
use Net::OperaLink::Note;
use Net::OperaLink::Speeddial;

# Opera supports only OAuth 1.0a
$Net::OAuth::PROTOCOL_VERSION = &Net::OAuth::PROTOCOL_VERSION_1_0A;

use constant {
    LINK_SERVER    => 'https://link.api.opera.com',
    OAUTH_PROVIDER => 'auth.opera.com',
};

# API/OAuth URLs
use constant {
    LINK_API_URL   => LINK_SERVER . '/rest',
    OAUTH_BASE_URL => 'https://' . OAUTH_PROVIDER . '/service/oauth',
};

sub new {
    my ($class, %opts) = @_;

    $class = ref $class || $class;

    for (qw(consumer_key consumer_secret)) {
        if (! exists $opts{$_} || ! $opts{$_}) {
            Carp::croak "Missing '$_'. Can't instance $class\n";
        }
    }

    my $self = {
        _consumer_key => $opts{consumer_key},
        _consumer_secret => $opts{consumer_secret},
        _access_token => undef,
        _access_token_secret => undef,
        _request_token => undef,
        _request_token_secret => undef,
        _authorized => 0,
    };

    bless $self, $class;

    return $self;
}

sub authorized {
    my ($self) = @_;

    # We assume to be authorized if we have access token and access token secret
    my $acc_tok = $self->access_token();
    my $acc_tok_secret = $self->access_token_secret();

    # TODO: No real check if the token is still valid
    unless ($acc_tok && $acc_tok_secret) {
        return;
    }

    return 1;
}

sub access_token {
    my $self = shift;
    if (@_) {
        $self->{_access_token} = shift;
    }
    return $self->{_access_token};
}

sub access_token_secret {
    my $self = shift;
    if (@_) {
        $self->{_access_token_secret} = shift;
    }
    return $self->{_access_token_secret};
}

sub consumer_key {
    my ($self) = @_;
    return $self->{_consumer_key};
}

sub consumer_secret {
    my ($self) = @_;
    return $self->{_consumer_secret};
}

sub request_token {
    my $self = shift;
    if (@_) {
        $self->{_request_token} = shift;
    }
    return $self->{_request_token};
}

sub request_token_secret {
    my $self = shift;
    if (@_) {
        $self->{_request_token_secret} = shift;
    }
    return $self->{_request_token_secret};
}

sub get_authorization_url {
    my ($self) = @_;

    # TODO: Get a request token first
    # and then build the authorize URL
    my $oauth_resp = $self->request_request_token();

    warn 'CONTENT=' . $oauth_resp;

    my $req_tok = $oauth_resp->{oauth_token};
    my $req_tok_secret = $oauth_resp->{oauth_token_secret};

    if (! $req_tok || ! $req_tok_secret) {
        Carp::croak("Couldn't get a valid request token from " . OAUTH_BASE_URL);
    }

    # Store in the object for the access-token phase later
    $self->request_token($req_tok);
    $self->request_token_secret($req_tok_secret);

    return $self->oauth_url_for('authorize', oauth_token=> $req_tok);
}

sub _do_oauth_request {
    my ($self, $url) = @_;

    my $ua = $self->_user_agent();
    my $resp = $ua->get($url);

	if ($resp->is_success) {
		my $query = CGI->new($resp->content());
		return {
			ok => 1,
            response => $resp,
            content => $resp->content(),
            data => { $query->Vars },
		};
	}

	return {
		ok => 0,
        response => $resp,
        content => $resp->content(),
		errstr => $resp->status_line(),
	}

}

sub _user_agent {
    my $ua = LWP::UserAgent->new();
    return $ua;
}

sub oauth_url_for {
    my ($self, $step, %args) = @_;

    $step = lc $step;

    my $url = URI->new(OAUTH_BASE_URL . '/' . $step);
    $url->query_form(%args);

    return $url;
}

sub request_access_token {
    my ($self, %args) = @_; 

    if (! exists $args{verifier}) { 
        Carp::croak "The 'verifier' argument is required. Check the docs."; 
    } 

    my $verifier = $args{verifier};

    my %opt = (
        step           => 'access_token',
        request_method => 'GET',
        request_url    => $self->oauth_url_for('access_token'),
        token          => $self->request_token(),
        token_secret   => $self->request_token_secret(),
        verifier       => $verifier,
    );

    my $request = $self->_prepare_request(%opt);
    if (! $request) {
        Carp::croak "Unable to initialize access-token request";
    }

    my $access_token_url = $request->to_url();

    #print 'access_token_url:', $access_token_url, "\n";

    my $response = $self->_do_oauth_request($access_token_url);

    # Check if the request-token request failed
    if (! $response || ref $response ne 'HASH' || $response->{ok} == 0) {
        Carp::croak "Access-token request failed. Might be a temporary problem. Please retry later.";
    }

    $response = $response->{data};

    # Store access token for future requests
    $self->access_token($response->{oauth_token});
    $self->access_token_secret($response->{oauth_token_secret});
 
    # And return them as well, so user can save them to persistent storage
    return (
        $response->{oauth_token},
        $response->{oauth_token_secret}
    );
}

sub request_request_token {
    my ($self) = @_;

    my %opt = (
        step => 'request_token',
        callback => 'oob',
        request_method => 'GET',
        request_url => $self->oauth_url_for('request_token'),
    );

    my $request = $self->_prepare_request(%opt);
    if (! $request) {
        Carp::croak "Unable to initialize request-token request";
    }

    my $request_token_url = $request->to_url();

    my $response = $self->_do_oauth_request($request_token_url);

    # Check if the request-token request failed
    if (! $response || ref $response ne 'HASH' || $response->{ok} == 0) {
        Carp::croak "Request-token request failed. Might be a temporary problem. Please retry later.";
    }

    return $response->{data};
}

sub _fill_default_values {
    my ($self, $req) = @_;

    $req ||= {};

    $req->{step}  ||= 'request_token';
    $req->{nonce} ||= _random_string(32);
    $req->{request_method} ||= 'GET';
    $req->{consumer_key} ||= $self->consumer_key();
    $req->{consumer_secret} ||= $self->consumer_secret();
    # Opera OAuth provider supports only HMAC-SHA1
    $req->{signature_method} = 'HMAC-SHA1';
    $req->{timestamp} ||= time();
    $req->{version} = '1.0';

    return $req;
}

sub _prepare_request {
    my ($self, %opt) = @_;

    # Fill in the default OAuth request values
    $self->_fill_default_values(\%opt);

    # Use Net::OAuth to obtain a valid request object
    my $step = delete $opt{step};
    my $request = Net::OAuth->request($step)->new(%opt);

    # User authorization step doesn't need signing
    if ($step ne 'user_auth') {
        $request->sign;
    }

    return $request;
}

sub _random_string {
    my ($length) = @_;
    if (! $length) { $length = 16 } 
    my @chars = ('a'..'z','A'..'Z','0'..'9');
    my $str = '';
    for (1 .. $length) {
        $str .= $chars[ int rand @chars ];
    }
    return $str;
}

sub api_get_request {
    my ($self, $datatype, @args) = @_;

    my $api_url = $self->api_url_for($datatype, @args);

    $api_url->query_form(
        oauth_token => $self->access_token(),
        api_output => 'json',
    );

    #warn "api-url: $api_url\n";
    #print 'acc-tok:', $self->access_token(), "\n";
    #print 'acc-tok-sec:', $self->access_token_secret(), "\n";

    my %opt = (
        step           => 'protected_resource',
        request_method => 'GET',
        request_url    => $api_url,
        token          => $self->access_token(),
        token_secret   => $self->access_token_secret(),
    );

    my $request = $self->_prepare_request(%opt);
    if (! $request) {
        Carp::croak('Unable to initialize api request');
    }

    my $oauth_url = $request->to_url();
    my $response = $self->_do_oauth_request($oauth_url);

    #warn "api-url: $oauth_url\n";
    #warn "response: " . Data::Dumper::Dumper($response) . "\n";

    if (! $response || ref $response ne 'HASH' || $response->{ok} == 0) {
        $self->error($response->{status});
        return;
    }

    # Given a HTTP::Response, return the data hash
    return $self->api_result($response->{response});
}

sub error {
    my $self = shift;

    if (@_) {
        $self->{error} = shift;
    }

    return $self->{error};
}

sub _json_decoder {
    state $json_obj = JSON::XS->new();
    return $json_obj;
}

sub api_result { 
    my ($self, $res) = @_;
    my $json_str = $res->content;
    my $json_obj = $self->_json_decoder();
    return $json_obj->decode($json_str);
}

sub api_url_for {
    my ($self, @args) = @_;

    my $datatype = shift @args;
    my $root_url = LINK_API_URL;
    my $uri;

    $datatype = ucfirst lc $datatype;

    # Net::OperaLink + '::' + Bookmark/Speeddial/...
    my $package = join('::', ref($self), $datatype);

    #warn "package=$package\n";
    #warn "args=".join(',',@args)."\n";
    #warn "api_url_for=" . $package->api_url_for(@args) . "\n";

    eval {
        $uri = URI->new(
            $root_url . "/" . $package->api_url_for(@args) . "/"
        )
    } or do {
        Carp::croak("Unknown or unsupported datatype $datatype ?");
    };

    return $uri;
}

sub _datatype_query_node {
    my ($self, $datatype, $id, $query_mode) = @_;

    if (not defined $id or not $id) {
        $self->error("Incorrect API usage: $datatype(\$id) or $datatype(\$id, \$query_mode)");
        return;
    }

    return $self->api_get_request($datatype, $id);
}

sub _datatype_query_subtree {
    my ($self, $datatype, $query_mode) = @_;

    $query_mode ||= 'children';

    return $self->api_get_request($datatype, $query_mode);
}

sub bookmark {
    my ($self, $id, $query_mode) = @_;
    return $self->_datatype_query_node('bookmark', $id, $query_mode);
}

sub bookmarks {
    my ($self, $query_mode) = @_;
    return $self->_datatype_query_subtree('bookmark', $query_mode);
}

sub note {
    my ($self, $id, $query_mode) = @_;
    return $self->_datatype_query_node('note', $id, $query_mode);
}

sub notes {
    my ($self, $query_mode) = @_;
    return $self->_datatype_query_subtree('note', $query_mode);
}

sub speeddial {
    my ($self, $id, $query_mode) = @_;
    return $self->_datatype_query_node('speeddial', $id, $query_mode);
}

sub speeddials {
    my ($self, $query_mode) = @_;
    return $self->_datatype_query_subtree('speeddial', $query_mode);
}

1;

__END__

=pod

=head1 NAME

Net::OperaLink - a Perl interface to the My Opera Community API

=head1 SYNOPSIS

Example:

    use Net::OperaLink;

    my $link = Net::OperaLink->new(
        consumer_key => '{your-consumer-key-here}',
        consumer_secret => '{your-consumer-secret-here}',
    );

    if (! $link->authorized) {

        print "I need authorization at: ", $link->get_authorization_url, "\n";
        print "then type the verifier + ENTER to continue\n";

        chomp (my $verifier = <STDIN>);

        my ($access_token, $access_token_secret) = $link->request_access_token(verifier => $verifier);

        # and save your precious access token + secret somewhere
    }

    my $bookmarks = $link->bookmarks();
    my $speeddials = $link->speeddials();
    my $notes = $link->notes();

    my $single_bookmark = $link->bookmark('{bookmark-id}');

    # ...

In reality, it's a bit more complicated than that, but look at the
complete example script provided in C<examples/link-api-example>.
That should work out of the box, and provide you with a nice base
to build upon.

=head1 DESCRIPTION

This module will be useful to you if you use the Opera Browser
(L<http://www.opera.com/download/>) and you use its B<Opera Link> feature.

=head2 What is Opera Link?

Opera Link is a convenient way to share browser information between
computers and devices, so you always have it with you, wherever you go.

With most devices, you can synchronize custom search engines and typed history.
Any Web-site address you have typed in one device will be available in your
other computers or mobile phones running Opera.

Opera Link synchronizes your:

=over 4

=item Bookmarks

=item Speed Dial

=item Personal bar

=item Notes

=item Typed browser history

=item Custom searches

=back

=head2 The Opera Link API

The B<Opera Link API> is a REST API that will let you access your
own Opera Link data.

The official Opera Link API documentation is up at
L<http://www.opera.com/docs/apis/linkrest/>.

=head2 How the module works

If you know how L<Net::Twitter> works, then you will have no problem
using L<Net::OperaLink> because it behaves in the same way,
also based on OAuth.

If you're not familiar with OAuth, go to L<http://oauth.net> and
read the documentation there. There's also some very nice
tutorials out there, such as:

=over 4

=item L<http://dev.opera.com/articles/view/introducing-the-opera-link-api/|Introducing the Opera Link API>

=item L<http://dev.opera.com/articles/view/building-your-first-link-api-application/|Building your first Opera Link application>

=item L<http://dev.opera.com/articles/view/gentle-introduction-to-oauth/|Gentle introduction to OAuth>

=back

and others of course.

=head2 Opera Link API keys

To use this module, B<you will need your set of OAuth API keys>.
To get your own OAuth consumer key and secret, you need to go to:

L<https://auth.opera.com/service/oauth/>

where you will be able to B<sign up to the My Opera Community>
and B<create your own application> and get your set of consumer keys.

=head1 SUBROUTINES/METHODS

=head2 CLASS CONSTRUCTOR

=head3 C<new( %args )>

Class constructor. 

There's two, both mandatory, arguments,
B<consumer_key> and B<consumer_secret>.

Example:

    my $link = Net::OperaLink->new(
        consumer_key => '...',
        consumer_secret => '...',
    );

To get your own consumer key and secret, you need to head over to:

L<https://auth.opera.com/service/oauth/>

where you will be able to sign up to the My Opera Community
and create your own application and get your set of consumer keys.

=head2 Opera Link-related methods

=head3 C<bookmarks()>

=head3 C<notes()>

=head3 C<speeddials()>

These three methods retrieve the entire tree of your bookmarks,
notes and speeddials respectively.

You will get back an array ref, where each element of the array is a 
hash. See the included C<examples/link-api-example> script for
a working example.

=head3 C<bookmark($id)>

=head3 C<bookmark($id, $query_type)>

=head3 C<note($id)>

=head3 C<note($id, $query_type)>

=head3 C<speeddial($id)>

=head3 C<speeddial($id, $query_type)>

Retrieves data for a single bookmark (or note or speeddial).

You need to specify the bookmark id. Typically you do this when you have
already loaded a subtree of bookmarks and you know already the id.

This is useful together with query type (C<$query_type>) on those datatypes
that are structured in folders (bookmarks and notes for now), so you can
get all the subentries and subfolders of a bookmark for example.

There's 2 allowed values for C<$query_type>:

=over 4

=item C<children>

Gets the 1st level children of the node (or root)

=item C<descendants> or C<recurse>

Gets all the descendants of a node.
Using C<descendants> on a data type that doesn't support it (f.ex. speeddials)
is not going to work, so don't do it.

=back

=head2 OAuth-related methods

=head3 C<access_token()>

=head3 C<access_token($new_value)>

=head3 C<access_token_secret()>

=head3 C<access_token_secret($new_value)>

=head3 C<consumer_key()>

=head3 C<consumer_key($new_value)>

=head3 C<consumer_secret()>

=head3 C<consumer_secret($new_value)>

=head3 C<request_token()>

=head3 C<request_token($new_value)>

=head3 C<request_token_secret()>

=head3 C<request_token_secret($value)>

All of these are simple accessors/mutators, to store access token and secret data.
This store is volatile. It doesn't get saved on disk or database.

=head3 C<authorized()>

Returns true if you already have a valid access token that's also
authorized. If not, you will need to get a request token.
You need to be familiar with the OAuth protocol flow.
Refer to L<http://oauth.net/>.

=head3 C<get_authorization_url()>

Returns the URL that a user can use to authorize the request token.
Under the hood, it first requests a new request token.

=head3 C<oauth_url_for($oauth_phase)>

=head3 C<oauth_url_for($oauth_phase, %arguments)>

Internal method to generate URLs towards the Opera OAuth server.

=head3 C<request_access_token( verifier => $verifier )>

When the request token is authorized by the user, the user will
be given a "verifier" code. You need to have the user input the
verifier code, and use it for this method.

In case of success, this method will return you both the
OAuth access token and access token secret, which you
will be able to use to finally perform the API requests,
namely status update.

=head3 C<request_request_token()>

Requests and returns a new request token.
First step of the OAuth flow. You can use this method
B<also> to quickly check that your set of API keys work
as expected.

If they don't work, the method will croak (die badly
with an error message).

=head1 AUTHORS

Cosimo Streppone, E<lt>cosimo@opera.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-operalink at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-OperaLink>.
We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=head1 SEE ALSO

=head2 Opera Link REST API documentation

L<http://www.opera.com/docs/apis/linkrest/>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::OperaLink

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-OperaLink>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-OperaLink>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-OperaLink>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-OperaLink>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c), 2010 Opera Software ASA.
All rights reserved.

