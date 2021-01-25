package Mojo::JWT::Google;
use utf8;
use Mojo::Base qw(Mojo::JWT);
use Mojo::File qw(path);
use Mojo::JSON qw(decode_json);
use Carp;

our $VERSION = '0.15';

has client_email => undef;
has expires_in   => 3600;
has issue_at     => undef;
has scopes       => sub { [] };
has target       => q(https://www.googleapis.com/oauth2/v4/token);
has user_as      => undef;
has audience     => undef;

sub new {
  my ($class, %options) = @_;
  my $self = $class->SUPER::new(%options);
  return $self if not defined $self->{from_json};

  my $result = $self->from_json($self->{from_json});

  return $self;
}

sub claims {
  my ($self, $value) = @_;
  if (defined $value) {
    $self->{claims} = $value;
    return $self;
  }
  my $claims = $self->_construct_claims;
  unless (exists $claims->{exp}) {
    $claims->{exp} = $self->now + $self->expires_in ;
  }
  return $claims;
}

sub _construct_claims {
  my $self = shift;
  my $result = {};
  $result->{iss}   = $self->client_email;
  $result->{aud}   = $self->target;
  $result->{sub}   = $self->user_as if defined $self->user_as;
  my @scopes = @{ $self->scopes };

  croak "Can't use both scopes and audience in the same token" if @scopes && $self->audience;
  $result->{scope} = join ' ', @scopes if @scopes;
  $result->{target_audience} = $self->audience if defined $self->audience;

  if ( not defined $self->issue_at ) {
    $self->set_iat(1);
  }
  else {
    $self->set_iat(0);
    $result->{iat} = $self->issue_at;
    $result->{exp} = $self->issue_at + $self->expires_in;
  }
  return $result;
}

sub from_json {
  my ($self, $value) = @_;
  croak 'You did not pass a filename to from_json' if not defined $value;
  croak 'Cannot find file passed to from_json' if not -f $value;
  my $json = decode_json( path($value)->slurp );
  croak 'private key was not found in file passed to from_json' unless $json->{private_key};
  croak 'from_json only works with service accounts' if $json->{type} ne 'service_account';
  $self->algorithm('RS256');
  $self->secret($json->{private_key});
  $self->client_email($json->{client_email});
  return 1
}

sub as_form_data {
  my ($self) = @_;
  return {
    grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion => $self->encode
  }
}

1;


=head1 NAME

Mojo::JWT::Google - Service Account tokens

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  my $gjwt = Mojo::JWT::Google->new(secret => 's3cr3t',
                                    scopes => [ '/my/scope/a', '/my/scope/b' ],
                                    client_email => 'riche@cpan.org')->encode;

  # authenticating for apis as a service account
  my $gjwt = Mojo::JWT::Google->new(
     from_json => '/my/secret/project-b98ale897.json',
     scopes    => 'https://www.googleapis.com/auth/gmail.send',
     user_as   => 'some-email@your-org.com'); # if you have domain-wide delegation
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->post('https://www.googleapis.com/oauth2/v4/token', form => $gjwt->as_form_data);
  $tx->res->json('/access_token') # will contain your access token 
  
  # authenticating to use the Identity Aware Proxy
  my $gjwt = Mojo::JWT::Google->new(
     from_json => '/my/secret/project-b98ale897.json',
     audience  => 'the-client-id-from-your-IAP');
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->post('https://www.googleapis.com/oauth2/v4/token', form => $gjwt->as_form_data);
  $tx->res->json('/id_token') # will contain your id token 

=head1 DESCRIPTION

Like L<Mojo::JWT>, you can instantiate this class by using the same syntax,
except that this class constructs the claims for you.

 my $jwt = Mojo::JWT::Google->new(secret => 's3cr3t')->encode;

And add any attribute defined in this class.  The JWT is fairly useless unless
you define your scopes.

 my $gjwt = Mojo::JWT::Google->new(secret => 's3cr3t',
                                   scopes => [ '/my/scope/a', '/my/scope/b' ],
                                   client_email => 'riche@cpan.org')->encode;

You can also get your information automatically from the .json you received
from Google.  Your secret key is in that file, so it's best to keep it safe
somewhere.  This will ease some busy work in configuring the object -- with
virtually the only things to do is determine the scopes and the user_as if you
need to impersonate.

  my $gjwt = Mojo::JWT::Google
    ->new( from_json => '/my/secret.json',
           scopes    => [ '/my/scope/a', '/my/scope/b' ])->encode;


To authenticate, send a post request to https://www.googleapis.com/oauth2/v4/token, 
with your Mojo::JWT::Google's as_form_data method as the payload.

  $ua->post('https://www.googleapis.com/oauth2/v4/token', form => $gjwt->as_form_data);

=cut

=head1 ATTRIBUTES

L<Mojo::JWT::Google> inherits all attributes from L<Mojo::JWT> and defines the
following new ones.

=head2 claims

Overrides the parent class and constructs a hashref representing Google's
required attribution.


=head2 client_email

Get or set the Client ID email address.

=head2 expires_in

Defines the threshold for when the token expires.  Defaults to 3600.

=head2 issue_at

Defines the time of issuance in epoch seconds. If not defined, the claims issue
at date defaults to the time when it is being encoded.

=head2 scopes

Get or set the Google scopes.  If impersonating, these scopes must be set up by
your Google Business Administrator.

=head2 target

Get or set the target.  At the time of writing, there is only one valid target:
https://www.googleapis.com/oauth2/v4/token.  This is the default value; if you
have no need to customize this, then just fetch the default.


=head2 user_as

Set the Google user to impersonate.  Your Google Business Administrator must
have already set up your Client ID as a trusted app in order to use this
successfully.

=cut

=head1 METHODS

Inherits all methods from L<Mojo::JWT> and defines the following new ones.

=head2 from_json

Loads the JSON file from Google with the client ID information in it and sets
the respective attributes.

Dies on failure: file not found or value not defined

 $gjwt->from_json('/my/google/app/project/sa/json/file');


=head1 SEE ALSO

L<Mojo::JWT>

=head1 SOURCE REPOSITORY

L<http://github.com/rabbiveesh/Mojo-JWT-Google>

=head1 AUTHOR

Richard Elberger, <riche@cpan.org>

=head1 CONTRIBUTORS

Scott Wiersdorf, <scott@perlcode.org>
Avishai Goldman, <veesh@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Richard Elberger

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
