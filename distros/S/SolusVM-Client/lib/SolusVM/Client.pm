package SolusVM::Client;
$SolusVM::Client::VERSION = '0.001';
use v5.36;
use warnings FATAL => 'all';
use re '/aa';

use Cpanel::JSON::XS ();
use HTTP::Tiny       ();
use Sub::Install     ();
use Time::Piece      ();

use SolusVM::Client::Specification ();

# ABSTRACT: Client for the SolusVM 2 API, built from its own specification


# What counts as "about to expire".  A token good for another half minute is one
# that will be rejected mid-provision.
our $EXPIRY_MARGIN = 60;

# The methods this class defines itself.  An operation named after one of these
# would be silently shadowed by it, so the spec is checked against the list
# rather than trusted.
our @RESERVED = qw{new catalog login token host base_url paginate last_meta last_links last_response};


sub new ( $class, %options ) {
    my $self = bless {
        scheme     => 'https',
        prefix     => '/api/v1',
        timeout    => 60,
        verify_SSL => 1,
        debug      => 0,
        %options,
    }, $class;

    die "SolusVM::Client needs the host of a management node.\n" unless defined $self->{host} && length $self->{host};
    die "SolusVM::Client needs either a token, or the email and password to get one with.\n"
      unless defined $self->{token} || ( defined $self->{email} && defined $self->{password} );

    $self->{spec} = SolusVM::Client::Specification::load( defined $self->{spec_file} ? ( file => $self->{spec_file} ) : () );
    $self->{ua} //= HTTP::Tiny->new(
        agent      => 'SolusVM-Client/' . ( __PACKAGE__->VERSION // 'dev' ),
        timeout    => $self->{timeout},
        verify_SSL => $self->{verify_SSL},
    );

    $self->_build_subs();
    return $self;
}


sub host ($self) { return $self->{host} }


sub base_url ($self) {
    my $port = defined $self->{port} && length $self->{port} ? ":$self->{port}" : q{};
    return "$self->{scheme}://$self->{host}$port$self->{prefix}";
}


sub token ($self) {
    $self->login() if $self->_needs_token();
    return $self->{token};
}


sub catalog ( $self, %options ) {
    my $like = $options{like};

    my @wanted = sort { $a->{name} cmp $b->{name} } values %{ $self->{spec} };
    @wanted = grep { "$_->{name} $_->{uri} $_->{summary}" =~ $like } @wanted if $like;

    my $listing = q{};
    foreach my $entry (@wanted) {
        my %required = map { $_ => 1 } @{ $entry->{required} };

        $listing .= sprintf "%-46s %-6s %s\n",   $entry->{name}, $entry->{method}, $entry->{uri};
        $listing .= sprintf "%-46s %s\n",        q{}, $entry->{summary} if length $entry->{summary};
        $listing .= sprintf "%-46s query: %s\n", q{}, join q{ }, @{ $entry->{query_params} }                                   if @{ $entry->{query_params} };
        $listing .= sprintf "%-46s body:  %s\n", q{}, join q{ }, map { $required{$_} ? "$_*" : $_ } @{ $entry->{body_params} } if @{ $entry->{body_params} };
    }

    return $listing;
}


sub login ($self) {
    die "There is no token left and no email and password to get another with.\n"
      unless defined $self->{email} && defined $self->{password};

    # Not authorized, and not only because there is nothing to authorize it
    # with: asking for the token would call this, which would ask again.
    my $answer = $self->_http(
        'login', 'POST',
        $self->base_url . '/auth/login',
        body      => { email => $self->{email}, password => $self->{password} },
        authorize => 0,
    );

    my $credentials = $answer->{data}{credentials};
    die "The management node accepted the login but sent back no access token.\n" unless ref $credentials eq 'HASH' && defined $credentials->{access_token};

    $self->{token}      = $credentials->{access_token};
    $self->{expires_at} = $credentials->{expires_at};

    return $credentials;
}


sub paginate ( $self, $name, %params ) {
    my @everything;
    my $page = $params{page} // 1;

    while (1) {
        my $answer = $self->_request( $name, %params, page => $page );
        my $data   = $answer->{data};
        push @everything, ref $data eq 'ARRAY' ? @{$data} : ($data);

        my $meta = $answer->{meta};
        last unless ref $meta eq 'HASH' && defined $meta->{last_page};
        last if $page >= $meta->{last_page};
        $page++;
    }

    return @everything;
}


sub last_meta     ($self) { return $self->{last_meta} }
sub last_links    ($self) { return $self->{last_links} }
sub last_response ($self) { return $self->{last_response} }

# One closure per operation, installed into the package rather than the object
# because that is where perl looks for a method.  Guarded by can(), so a spec
# that grows an operation called `login` cannot quietly replace this class's
# own -- and there is a test that fails if one ever does, because the guard on
# its own would only make the collision silent.
sub _build_subs ($self) {
    foreach my $name ( keys %{ $self->{spec} } ) {
        next if __PACKAGE__->can($name);
        Sub::Install::install_sub(
            {
                code => sub { my $invocant = shift; return $invocant->_request( $name, @_ ) },
                as   => $name,
                into => __PACKAGE__,
            }
        );
    }

    return 1;
}

sub _request ( $self, $name, %params ) {
    my $entry = $self->{spec}{$name} or die "The SolusVM API has no operation called $name.\n";

    my $uri = $entry->{uri};
    foreach my $placeholder ( @{ $entry->{path_params} } ) {
        my $value = delete $params{$placeholder};
        die "$name needs a $placeholder: its path is $entry->{uri}.\n" unless defined $value;
        $uri =~ s/[{]\Q$placeholder\E[}]/$value/g;
    }

    my $url = $self->base_url . $uri;
    my $body;
    if ( $entry->{has_body} ) {
        $body = \%params;
    }
    elsif ( $entry->{method} eq 'GET' ) {
        $url .= '?' . $self->{ua}->www_form_urlencode( \%params ) if %params;
    }
    elsif (%params) {
        die "$name takes nothing but its path, so there is nowhere to put " . join( q{, }, sort keys %params ) . ".\n";
    }

    my $answer  = eval { $self->_http( $name, $entry->{method}, $url, body => $body ) };
    my $failure = $@;
    return $answer                                                                                          unless $failure;
    die $failure                                                                                            unless $self->_rejected_the_token();
    die $failure . "Pass email and password as well as the token, and this client will renew it for you.\n" unless $self->_can_renew();

    # The token was good as far as we knew and the API disagreed -- its clock,
    # a revoked token, a restarted management node.  Worth exactly one more go.
    $self->login();
    return $self->_http( $name, $entry->{method}, $url, body => $body );
}

sub _http ( $self, $name, $method, $url, %options ) {
    my %request = (
        headers => {
            'Accept'       => 'application/json',
            'Content-Type' => 'application/json',
        },
    );
    $request{headers}{'Authorization'} = 'Bearer ' . $self->token()                                       if $options{authorize} // 1;
    $request{content}                  = Cpanel::JSON::XS->new->utf8->canonical->encode( $options{body} ) if defined $options{body};

    say {*STDERR} "SolusVM: $method $url" . ( defined $request{content} ? ' ' . _redact( $request{content} ) : q{} ) if $self->{debug};

    my $response = $self->{ua}->request( $method, $url, \%request );
    $self->{last_response} = $response;

    say {*STDERR} "SolusVM: $response->{status} $response->{reason} " . _redact( $response->{content} // q{} ) if $self->{debug};

    die "SolusVM $name ($method $url) failed: $response->{status} $response->{reason}\n" . _redact( $response->{content} // q{} ) . "\n"
      unless $response->{success};

    my $answer = length( $response->{content} // q{} ) ? Cpanel::JSON::XS->new->utf8->decode( $response->{content} ) : {};
    @{$self}{qw{last_meta last_links}} = ( $answer->{meta}, $answer->{links} ) if ref $answer eq 'HASH';

    return $answer;
}

# A password that reached a log line or an exception is a password in a ticket.
sub _redact ($content) {
    $content =~ s/("password"\s*:\s*")[^"]*"/$1********"/g;
    return $content;
}

sub _can_renew ($self) {
    return defined $self->{email} && defined $self->{password} ? 1 : 0;
}

sub _rejected_the_token ($self) {
    return ref $self->{last_response} eq 'HASH' && $self->{last_response}{status} == 401 ? 1 : 0;
}

sub _needs_token ($self) {
    return 1 unless defined $self->{token};
    return 0 unless $self->_can_renew();

    my $expiry = _epoch_of( $self->{expires_at} );
    return 0 unless defined $expiry;
    return time >= $expiry - $EXPIRY_MARGIN ? 1 : 0;
}

# The spec calls expires_at a string and leaves it at that, so this parses the
# two shapes the API has been seen to use and gives up quietly on anything else.
# Giving up means falling back on the retry in _request, which is a slower way
# to notice an expired token but not a wrong one.
sub _epoch_of ($when) {
    return undef unless defined $when && length $when;

    # strptime warns its way through a format that does not fit before failing,
    # and trying formats until one fits is the whole method here.
    local $SIG{__WARN__} = sub { return 1 };

    foreach my $format ( '%Y-%m-%dT%H:%M:%S', '%Y-%m-%d %H:%M:%S' ) {
        my $parsed = eval { Time::Piece->strptime( substr( $when, 0, 19 ), $format ) };
        return $parsed->epoch if $parsed;
    }

    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SolusVM::Client - Client for the SolusVM 2 API, built from its own specification

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use SolusVM::Client ();

    my $solus = SolusVM::Client->new(
        host     => 'solus.example.tld',
        email    => 'you@example.tld',
        password => $ENV{SOLUSVM_PASSWORD},
    );

    my $servers = $solus->get_list_of_servers( 'filter[status]' => 'started' );
    print "$_->{name}\n" for @{ $servers->{data} };

    my $made = $solus->create_a_new_server(
        name      => 'web01.example.tld',
        plan      => 3,
        location  => 1,
        os        => 17,
        user_data => "#cloud-config\npackages:\n  - rsync\n",
    );

    $solus->delete_server( id => $made->{data}{id} );

=head1 DESCRIPTION

Every method of this client comes out of the OpenAPI document SolusVM publishes
for version 2 of its API.  All of its operations are here, and they are named after
the C<operationId> the vendor gave them, which is why they read the way they do:
C<get_list_of_servers>, C<create_a_new_server>, C<get_an_existing_api_token>.
Nothing is hand-maintained, so nothing drifts from the published reference, and
an endpoint added upstream arrives by regenerating
L<SolusVM::Client::Specification> rather than by writing a method.

L</catalog> is how you find the one you want.

=head2 Two of nearly everything

A good half of the API exists twice: C</servers> and C</plans> are the whole
management node, and C</projects/{id}/servers> and C</projects/{id}/plans> are
one project's view of it.  Which pair answers depends on what the token's
account is, and an account with the C<CLIENT> role gets C<403 This action is
unauthorized.> from the first pair and its own resources from the second.  So

    $solus->get_list_of_servers()                       # administering a node
    $solus->get_list_of_project_servers( id => $id )    # using one

are both right, and picking the wrong one is not a bug in your credentials.
C<get_user_info> says which roles the token has.

=head2 Calling an operation

Named arguments, in one flat list.  Anything the path declares as a placeholder
fills the placeholder:

    $solus->get_an_existing_server( id => 42 );        # GET /servers/42

Everything left over goes into the request body if the operation declares one,
and into the query string if it is a listing.  That rule is unambiguous because
in the whole of the SolusVM API no operation takes both -- there is a test in
this distribution that fails if a future specification changes that.

The write operations that declare no body -- every C<delete_*>, and the actions
like C<server_start> that are entirely described by their path -- take nothing
else, and say so rather than quietly hanging an argument off the end
of the URL where the API will ignore it.

    $solus->get_list_of_servers( page => 2, 'filter[status]' => 'started' );
    $solus->server_start( id => 42 );

The decoded JSON document comes back whole, so a listing is
C<< $result->{data} >> and its pagination is C<< $result->{meta} >>.  A failure
dies.

=head1 METHODS

=head2 new

    SolusVM::Client->new( host => 'solus.example.tld', token => $token );

Takes:

=over 4

=item * C<host> -- required, the management node's hostname

=item * C<token>, or C<email> and C<password> -- see L</AUTHENTICATION>

=item * C<expires_at> -- when a C<token> you passed runs out, as the API spells it

=item * C<scheme>, C<port>, C<prefix> -- default C<https>, none, and C</api/v1>

=item * C<timeout>, C<verify_SSL> -- handed to L<HTTP::Tiny>; verification is on

=item * C<ua> -- your own L<HTTP::Tiny>, if you have one

=item * C<spec_file> -- a spec written by L<SolusVM::Client::Specification/fetch>, to run against an API newer than this release

=item * C<debug> -- print each request and its response to STDERR, passwords redacted

=back

=head2 host

The management node this client talks to.

=head2 base_url

Everything an operation's URI hangs off: scheme, host, port if there is one, and
the API prefix.

=head2 token

The bearer token in use, logging in first if there is not one yet.  Returns it,
which is what you want if the reason you passed credentials was to mint a token
to put somewhere else.

=head2 catalog

Returns a printable listing of the operations, one stanza each: the verb and the
path, the vendor's summary, what a listing can be filtered on, and what a body
takes, with the required properties starred.

    print $solus->catalog( like => qr/snapshot/ );

C<like> filters on the name, the path and the summary together.  With no
arguments you get the lot, which is a lot, and still the fastest way to find out
what the API calls something -- and, since the properties of a body are not
guessable from the ones the operation next to it takes, what to call the
arguments once you have.

=head2 login

Exchanges the email and password for a token and remembers it, along with when it
expires.  Returns the credentials hashref the API answered with.  Called for you
when it is needed; call it yourself to find out now rather than later whether the
credentials are any good.

=head2 paginate

    my @servers = $solus->paginate( 'get_list_of_servers', 'filter[status]' => 'started' );

Walks a listing to its last page and returns every C<data> element from all of
them.  The generated methods deliberately return one page: walking a listing of
unknown length is a decision, not something to have happen by surprise in the
middle of something else.

=head2 last_meta

=head2 last_links

=head2 last_response

The C<meta> and C<links> of the most recent answer, and the raw L<HTTP::Tiny>
response hash behind it.  For the cases where a listing's totals matter, or where
a caller wants to look at a status code this client only turned into a message.

=head1 AUTHENTICATION

The API takes a bearer token.  Give the constructor one you already have:

    SolusVM::Client->new( host => ..., token => $token );

or give it the credentials to get one with, in which case it logs in when it
first needs to, renews the token before it expires, and renews it again if the
API rejects it anyway:

    SolusVM::Client->new( host => ..., email => ..., password => ... );

Passing both uses the token and keeps the credentials for when it expires.  Where
those arguments come from is the caller's business: this distribution reads no
configuration file and no environment variable.

C<POST /auth/login> authenticates against the management node's own user table,
and nothing else.  A node that signs its people in through an identity provider
instead -- SolusVM does this with Laravel Socialite, and the button on the login
page is a plain link to C</api/v1/socialite/E<lt>providerE<gt>> -- sends a browser
off to that provider and back, which is not a thing a client with no browser can
do.  Those accounts have no password to give, so the token is the only way in:
make one in the panel under Account, and C<create_a_new_account_api_token> will
mint the rest.  Such a token does not expire, and this client will not try to
renew it.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/perl-solusvm-client/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords Andy Baugh

Andy Baugh <andy@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
