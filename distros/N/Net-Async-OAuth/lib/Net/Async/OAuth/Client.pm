package Net::Async::OAuth::Client;
$Net::Async::OAuth::Client::VERSION = '0.001';
use strict;
use warnings;

=head1 NAME

Net::Async::OAuth::Client - client for oauth handling

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Provides a badly-documented abstraction for oauth.

=cut

use MIME::Base64 qw(encode_base64 decode_base64);
use URI::Escape qw(uri_escape_utf8);

sub new { my $class = shift; bless { @_ }, $class }

sub configure {
	my ($self, %args) = @_;
	for (qw(consumer_key consumer_secret token token_secret)) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	die "unknown args - " . join ',', sort keys %args if %args;
	$self
}
{
my @chars = ('a'..'z', 'A' .. 'Z', '0'..'9');

=head2 nonce

Generates a 32-character pseudo random string.

If security is an important consideration, you may want to override this
with an algorithm that uses something stronger than L<rand>.

Takes no parameters. Returns a 32-character string consisting of C<a-zA-Z0-9>.

=cut

sub nonce {
	my $self = shift;
	join('', map $chars[@chars * rand], 1..32)
}
}

=head1 oauth_fields

Generates signature information for the given request.

=over 4

=item * uri - the URI we're requesting

=item * method - GET/POST for HTTP method

=item * parameters - hashref of parameters we're sending

=back

Returns a hashref which contains information.

=cut

sub oauth_fields {
	use Scalar::Util qw(blessed);
	use namespace::clean qw(blessed);

	my ($self, %args) = @_;
	my $uri = delete($args{uri});
	$uri = URI->new($uri) unless blessed $uri;

	my %info = (
		%{$args{parameters} || {}},
		oauth_signature_method => $self->signature_method,
		oauth_nonce            => $args{nonce} // $self->nonce,
		oauth_consumer_key     => ($self->consumer_key // die "no ->consumer_key"),
		oauth_timestamp        => time,
		oauth_version          => $self->oauth_version,
		oauth_token            => $self->token,
	);

	my $bare_uri = $uri->clone;
	$bare_uri->query_form({});

	$info{oauth_signature} = $self->sign(
		method     => $args{method},
		uri        => $bare_uri,
		parameters => {
			$uri->query_form,
			%{ $args{parameters} || {} },
			%info
		},
	);
	return \%info;
}

=head2 sign

=cut

sub sign {
	use Digest::SHA qw(hmac_sha1_base64);
	use namespace::clean qw(hmac_sha1_base64);
	my ($self, %args) = @_;
	my $parameters = $self->parameter_string($args{parameters});
	my $base = $self->signature_base(
		%args,
		parameters => $parameters
	);
	my $signing_key = $self->signing_key;
	my $signature = hmac_sha1_base64($base, $signing_key);

	# Pad to multiple-of-4
	$signature .= '=' while length($signature) % 4;
	return $signature;
}

=head2 signing_key

=cut

sub signing_key {
	my $self = shift;
	join '&', map uri_escape_utf8($_), ($self->consumer_secret // die 'no ->consumer_secret'),( $self->token_secret // die 'no ->token_secret');
}

=head2 parameter_string

=cut

sub parameter_string {
	use List::UtilsBy qw(sort_by);
	use namespace::clean qw(sort_by);
	my ($self, $param) = @_;
	join '&', map {
		uri_escape_utf8($_) . '=' . uri_escape_utf8($param->{$_})
	} sort_by { uri_escape_utf8($_) } keys %$param;
}

=head2 signature_base

=cut

sub signature_base {
	my ($self, %args) = @_;
	join '&', map uri_escape_utf8($_), uc($args{method}), $args{uri}->as_string, $args{parameters};
}

=head2 oauth_consumer_key

=cut

sub oauth_consumer_key { shift->{oauth_consumer_key} }


=head2 oauth_signature_method

=cut

sub oauth_signature_method { 'HMAC-SHA1' }

=head2 oauth_version

=cut

sub oauth_version { '1.0' }

=head2 token

=cut

sub token { shift->{token} }

=head2 consumer_key

=cut

sub consumer_key { shift->{consumer_key} }

=head2 consumer_secret

=cut

sub consumer_secret { shift->{consumer_secret} }

=head2 token_secret

=cut

sub token_secret { shift->{token_secret} }

=head2 signature_method

=cut

sub signature_method { 'HMAC-SHA1' }

=head2 parameters_from_request

=cut

sub parameters_from_request {
	my ($self, $req) = @_;
	my $uri = $req->uri->clone->query_form({});
	my %param = $req->uri->query_form;
	# POST, PATCH, PUT... PROPFIND??
	if($req->method =~ /^P/) {
		my %body_param = map { split /=/, $_, 2 } split /&/, $req->decoded_content;
		$param{$_} = $body_param{$_} for keys %body_param;
	}
	return \%param;
}

=head2 authorization_header

=cut

sub authorization_header {
	my ($self, %args) = @_;
	my $oauth = $self->oauth_fields(%args);
	return 'OAuth ' . join(',', map { $_ . '="' . uri_escape_utf8($oauth->{$_}) . '"' } sort keys %$oauth);
}

1;

=head1 SEE ALSO

There are plenty of other oauth implementations on CPAN, and it's likely that
this one will be retired in favour of one of them.

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2014-2017. Licensed under the same terms as Perl itself.
