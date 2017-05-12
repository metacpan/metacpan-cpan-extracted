package Net::Salesforce;
BEGIN {
  $Net::Salesforce::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Salesforce::VERSION = '1.101';
# ABSTRACT: An authentication module for Salesforce OAuth 2.

use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Parameters;
use Digest::SHA;

has 'key';

has 'secret';

has 'redirect_uri' => 'https://localhost:8081/callback';

has 'api_host' => 'https://na15.salesforce.com/';

has 'access_token_path' => 'services/oauth2/token';

has 'authorize_path' => 'services/oauth2/authorize';

has 'scope' => 'api refresh_token';

has 'response_type' => 'code';

has 'params' => sub {
    my $self = shift;
    return {
        client_id     => $self->key,
        client_secret => $self->secret,
        redirect_uri  => $self->redirect_uri,
    };
};

has 'json' => sub {
    my $self = shift;
    my $json = Mojo::JSON->new;
    return $json;
};

has 'ua' => sub {
    my $self = shift;
    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name("Net::Salesforce/$Net::Salesforce::VERSION");
    return $ua;
};

sub verify_signature {

    # TODO: fix verify
    my ($self, $payload) = @_;
    my $sha = Digest::SHA->new(256);
    $sha->hmac_sha256($self->secret);
    $sha->add($payload->{id});
    $sha->add($payload->{issued_at});
    $sha->b64digest eq $payload->{signature};
}

sub refresh {
    my ($self, $refresh_token) = @_;
    $self->params->{refresh_token} = $refresh_token;
    $self->params->{grant_type} = 'refresh_token';
    return $self->oauth2;
}

sub password {
    my $self = shift;
    $self->params->{grant_type} = 'password';
    return $self->oauth2;
}

sub authenticate {
    my ($self, $code) = @_;
    $self->params->{code} = $code;
    $self->params->{grant_type} = 'authorization_code';
    return $self->oauth2;
}

sub authorize_url {
    my $self = shift;
    $self->params->{response_type} = 'code';
    my $url = Mojo::URL->new($self->api_host)
      ->path($self->authorize_path)
      ->query($self->params);
    return $url->to_string;
}

sub access_token_url {
    my $self = shift;
    my $url  = Mojo::URL->new($self->api_host)->path($self->access_token_path);
    return $url->to_string;
}

sub oauth2 {
    my $self = shift;

    my $tx =
      $self->ua->post($self->access_token_url => form => $self->params);

    die $tx->res->body unless $tx->success;

    my $payload = $self->json->decode($tx->res->body);

  # TODO: fix verify signature
  # die "Unable to verify signature" unless $self->verify_signature($payload);

    return $payload;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Salesforce - An authentication module for Salesforce OAuth 2.

=head1 VERSION

version 1.101

=head1 SYNOPSIS

  use Net::Salesforce;

  my $sf = Net::Salesforce->new(
      'key'          => $ENV{SFKEY},
      'secret'       => $ENV{SFSECRET},
      'redirect_uri' => 'https://localhost:8081/callback'
  );

=head1 ATTRIBUTES

=head2 api_host

Returns a L<Mojo::URL> of the Salesforce api host, defaults to
https://na15.salesforce.com/

=head2 authorize_path

Endpoint to Salesforce's authorize page.

=head2 access_token_path

Endpoint to Salesforce's access token page

=head2 params

Form parameters attribute

=head2 redirect_uri

Callback URI defined in your Salesforce application

=head2 response_type

Response type for authorization callback

=head2 scope

Scopes available as defined by the Salesforce application.

=head2 secret

Acts as Salesforce client_secret

=head2 key

Acts as Salesforce client_key

=head2 ua

A L<Mojo::UserAgent> object.

=head2 json

A L<Mojo::JSON> object.

=head1 METHODS

=head2 verify_signature

=head2 refresh

=head2 oauth2

=head2 authorize_url

=head2 access_token_url

=head2 authenticate

=head2 password

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
