package Net::Google::DataAPI::Auth::OAuth;
use Any::Moose;
use Net::Google::DataAPI::Types;
with 'Net::Google::DataAPI::Role::Auth';
use Digest::SHA1;
use LWP::UserAgent;
use Net::OAuth;
use URI;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
our $VERSION = '0.05';

has [qw(consumer_key consumer_secret)] => ( is => 'ro', isa => 'Str', required => 1 );

for my $attr (qw(
    request_token 
    request_token_secret
    access_token 
    access_token_secret
)) { 
    has $attr => ( 
        is => 'rw', 
        isa => 'Str', 
        clearer => "clear_$attr", 
        predicate => "has_$attr" 
    ); 
}

has scope => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1, auto_deref => 1 );
has callback => ( is => 'ro', isa => 'Net::Google::DataAPI::Types::URI', coerce => 1 );
has signature_method => ( is => 'ro', isa => 'Str', default => 'HMAC-SHA1' );
has authorize_token_hd => ( is => 'ro', isa => 'Str', default => 'default' );
has authorize_token_hl => ( is => 'ro', isa => 'Str', default => 'en' );
has mobile => ( is => 'ro', isa => 'Bool', default => 0 );
has ua => ( is => 'ro', isa => 'LWP::UserAgent', required => 1, lazy_build => 1 );
sub _build_ua { 
    LWP::UserAgent->new( max_redirect => 0 );
}

my $url_hash = {
    get_request_token_url => 'https://www.google.com/accounts/OAuthGetRequestToken',
    authorize_token_url => 'https://www.google.com/accounts/OAuthAuthorizeToken',
    get_access_token_url => 'https://www.google.com/accounts/OAuthGetAccessToken',
};

while ( my ($key, $url) = each %$url_hash ) {
    has $key => ( is => 'ro', isa => 'URI', required => 1, default => sub {URI->new($url)} );
}

sub get_request_token {
    my ($self, $args) = @_;
    my $res = $self->_oauth_request(
        'request token',
        { 
            request_url => $self->get_request_token_url,
            extra_params => {
                scope => join(' ', $self->scope),
            },
            callback => $self->callback || 'oob',
        }
    );
    my ($token, $secret) = $self->_res_to_token($res);
    $self->request_token($token);
    $self->request_token_secret($secret);
    return $self;
}

sub get_authorize_token_url {
    my ($self) = @_;
    $self->has_request_token or $self->get_request_token;
    my $url = $self->authorize_token_url;
    $url->query_form(
        oauth_token => $self->request_token,
        hd => $self->authorize_token_hd,
        hl => $self->authorize_token_hl,
        $self->mobile ? ( btmpl => 'mobile' ) : (),
    );
    return $url;
}

sub get_access_token {
    my ($self, $args) = @_;
    my $res = $self->_oauth_request(
        'access token',
        {
            request_url => $self->get_access_token_url,
            token => $self->request_token,
            token_secret => $self->request_token_secret,
            %{$args || {}},
        }
    );
    # now clear them.
    $self->clear_request_token;
    $self->clear_request_token_secret;
    my ($token, $secret) = $self->_res_to_token($res);
    $self->access_token($token);
    $self->access_token_secret($secret);
}

sub _oauth_request {
    my ($self, $type, $args) = @_;
    my $req = $self->_make_oauth_request($type, $args);
    my $res = $self->ua->get($req->to_url);
    unless ($res && $res->is_success) {
        confess sprintf "request failed: %s", $res ? $res->status_line : 'no response returned';
    }
    return $res;
}

sub _make_oauth_request {
    my ($self, $type, $args) = @_;
    my $req = Net::OAuth->request($type)->new(
        version => '1.0',
        consumer_key => $self->consumer_key,
        consumer_secret => $self->consumer_secret,
        request_method => 'GET',
        signature_method => $self->signature_method,
        timestamp => time,
        nonce => Digest::SHA1::sha1_base64(time . $$ . rand),
        %$args,
    );
    $req->sign;
    return $req;
}

sub _res_to_token {
    my ($self, $res) = @_;
    my $uri = URI->new;
    $uri->query($res->content);
    my %query = $uri->query_form;
    return @query{qw(oauth_token oauth_token_secret)};
}

sub sign_request {
    my ($self, $req) = @_;
    my $sign = $self->_make_oauth_request(
        'protected resource',
        {
            request_url => $req->uri,
            request_method => $req->method,
            token => $self->access_token,
            token_secret => $self->access_token_secret,
        }
    );
    $req->header(Authorization => $sign->to_authorization_header);
    return $req;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
__END__

=head1 NAME

Net::Google::DataAPI::Auth::OAuth - (DEPRECATED) OAuth 1.0 support for Google Data APIs

=head1 SYNOPSIS

  use Net::Google::DataAPI::Auth::OAuth;

  my $auth = Net::Google::DataAPI::Auth::OAuth->new(
    consumer_key => 'consumer.example.com',
    consumer_secret => 'mys3cr3t',
    scope => ['http://spreadsheets.google.com/feeds/'],
  );
  my $url = $auth->get_authorize_token_url;

  # show the user $url and get $verifier

  $auth->get_access_token({verifier => $verifier}) or die;
  my $token = $auth->access_token;
  my $secret = $auth->access_token_secret;

=head1 DESCRIPTION

Net::Google::DataAPI::Auth::OAuth interacts with google OAuth service
and adds Authorization header to given request.

=head1 DEPRECATED!

OAuth1.0 protocol is deprecated.
Use L<Net::Google::DataAPI::Auth::OAuth2> instead.

=head1 ATTRIBUTES

You can make Net::Google::DataAPI::Auth::OAuth instance with those arguments below:

=over 2

=item * consumer_key

Consumer key. You can get it at L<https://www.google.com/accounts/ManageDomains>.

=item * consumer_secret

The consumer secret paired with the consumer key.

=item * scope

URL identifying the service(s) to be accessed. You can see the list of the urls to use at L<http://code.google.com/intl/en-US/apis/gdata/faq.html#AuthScopes>.

=item * callback

OAuth callback url. 'oob' will be used if you don't specify it.

=item * signature_method

Signature method. The default is 'HMAC-SHA1'.

=item * authorize_token_hd

Set hosted domain account for hosted google apps users. Defaults to 'default'.

=item * authorize_token_hl

An ISO 639 country code to set authorize user interface language. Defaults to 'en'.

=item * mobile

A boolean value whether you use this auth with mobile or not. defaults to 0.

=back

See L<http://code.google.com/intl/en-US/apis/accounts/docs/OAuth_ref.html> for details.

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<Net::Google::AuthSub>

L<Net::OAuth>

L<Net::Twitter::Role::OAuth>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
