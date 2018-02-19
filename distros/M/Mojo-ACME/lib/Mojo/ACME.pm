package Mojo::ACME;

use Mojo::Base -base;

our $VERSION = '0.12';
$VERSION = eval $VERSION;

use Mojo::Collection 'c';
use Mojo::JSON qw/encode_json/;
use Mojo::URL;

use Crypt::OpenSSL::PKCS10;
use MIME::Base64 qw/encode_base64url encode_base64 decode_base64/;
use Scalar::Util ();

use Mojo::ACME::Key;
use Mojo::ACME::ChallengeServer;

has account_key => sub { Mojo::ACME::Key->new(path => 'account.key') };
has ca => sub { die 'ca is required' };
has challenges => sub { {} };
#TODO use cert_key->key if it exists
has cert_key => sub { Mojo::ACME::Key->new };

has secret => sub { die 'secret is required' };
has server => sub { Mojo::ACME::ChallengeServer->new(acme => shift)->start };
has server_url => 'http://127.0.0.1:5000';
has ua => sub {
  my $self = shift;
  Scalar::Util::weaken $self;
  my $ua = Mojo::UserAgent->new;
  $ua->on(start => sub {
    my (undef, $tx) = @_;
    $tx->on(finish => sub {
      my $tx = shift;
      return unless $self && $tx->success;
      return unless my $nonce = $tx->res->headers->header('Replay-Nonce');
      push @{$self->{nonces} ||= []}, $nonce;
    });
  });
  return $ua;
};

sub check_all_challenges {
  my ($self, $cb) = (shift, pop);
  my @pending = $self->pending_challenges->each;
  Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $delay->pass unless @pending;
      $self->check_challenge_status($_, $delay->begin) for @pending;
    },
    sub {
      my $delay = shift;
      if (my $err = c(@_)->first(sub{ ref })) { return $self->$cb($err) }
      return $self->$cb(undef) unless $self->pending_challenges->size;
      Mojo::IOLoop->timer(2 => $delay->begin);
    },
    sub { $self->check_all_challenges($cb) },
  );
}

sub check_challenge_status {
  my ($self, $token, $cb) = @_;
  return Mojo::IOLoop->next_tick(sub{ $self->$cb({token => $token, message => 'unknown token'}) })
    unless my $challenge = $self->challenges->{$token};
  $self->ua->get($challenge->{uri} => sub {
    my ($ua, $tx) = @_;
    my $err;
    if (my $res = $tx->success) {
      $self->challenges->{$token} = $res->json;
    } else {
      $err = $tx->error;
      $err->{token} = $token;
    }
    $self->$cb($err);
  });
}

sub get_cert {
  my ($self, @names) = @_;
  my $csr = _pem_to_der($self->generate_csr(@names));
  my $req = $self->signed_request({
    resource => 'new-cert',
    csr => encode_base64url($csr),
  });
  my $url = $self->ca->url('/acme/new-cert');
  my $tx = $self->ua->post($url, $req);
  _die_if_error($tx, 'Failed to get cert');
  return _der_to_cert($tx->res->body);
}

sub get_nonce {
  my $self = shift;
  my $nonces = $self->{nonces} ||= [];
  return shift @$nonces if @$nonces;

  # try to populate the nonce cache
  my $url = $self->ca->url('/directory');
  my $tx = $self->ua->head($url);
  return shift @$nonces if @$nonces;

  # use result directly otherwise
  # if say the default ua has been replaced
  _die_if_error($tx, 'Could not get nonce');
  my $nonce = $tx->res->headers->header('Replay-Nonce');
  return $nonce if $nonce;
  die "Response did not contain a nonce\n" unless @$nonces;
}

sub generate_csr {
  my ($self, $primary, @alts) = @_;

  my $rsa = $self->cert_key->key_clone;
  my $req = Crypt::OpenSSL::PKCS10->new_from_rsa($rsa);
  $req->set_subject("/CN=$primary");
  if (@alts) {
    my $alt = join ',', map { "DNS:$_" } ($primary, @alts);
    $req->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_alt_name, $alt);
  }
  $req->add_ext_final;
  $req->sign;
  return $req->get_pem_req;
}

sub keyauth {
  my ($self, $token) = @_;
  return $token . '.' . $self->account_key->thumbprint;
}

sub new_authz {
  my ($self, $value) = @_;
  $self->server; #ensure initialized
  my $url = $self->ca->url('/acme/new-authz');
  my $req = $self->signed_request({
    resource => 'new-authz',
    identifier => {
      type  => 'dns',
      value => $value,
    },
  });
  my $tx = $self->ua->post($url, $req);
  _die_if_error($tx, 'Error requesting challenges', 201);

  my $challenges = $tx->res->json('/challenges') || [];
  die "No http challenge available\n"
    unless my $challenge = c(@$challenges)->first(sub{ $_->{type} eq 'http-01' });

  my $token = $challenge->{token};
  $self->challenges->{$token} = $challenge;

  my $trigger = $self->signed_request({
    resource => 'challenge',
    keyAuthorization => $self->keyauth($token),
  });
  $tx = $self->ua->post($challenge->{uri}, $trigger);
  _die_if_error($tx, 'Error triggering challenge', 202);
}

sub pending_challenges {
  my $self = shift;
  c(values %{ $self->challenges })
    ->grep(sub{ $_->{status} eq 'pending' })
    ->map(sub{ $_->{token} })
}

sub register {
  my $self = shift;
  my $url = $self->ca->url('/acme/new-reg');
  my $req = $self->signed_request({
    resource => 'new-reg',
    agreement => $self->ca->agreement,
  });
  my $res = $self->ua->post($url, $req)->result;
  my $code = $res->code;
  if ($code == 400) {
    my $detail = $res->json('/detail');
    die "$detail\n" || 'An error occurred';
  }
  return
    $code == 201 ? 'Account Created' :
    $code == 409 ? 'Account Exists' :
                   undef;
}

sub signed_request {
  my ($self, $payload) = @_;
  $payload = encode_base64url(encode_json($payload));
  my $key = $self->account_key;
  my $jwk = $key->jwk;

  my $header = {
    alg => 'RS256',
    jwk => {%$jwk}, # clone the jwk for safety's sake
  };

  my $protected = do {
    local $header->{nonce} = $self->get_nonce;
    encode_base64url(encode_json($header));
  };

  my $sig = encode_base64url($key->sign("$protected.$payload"));
  return encode_json {
    header    => $header,
    payload   => $payload,
    protected => $protected,
    signature => $sig,
  };
}

sub _die_if_error {
  my ($tx, $msg, $code) = @_;
  return if $tx->success && (!$code || $code == $tx->res->code);
  my $error = $tx->error;
  if ($error->{code}) { $msg .= " (code $error->{code})" }
  $msg .= " $error->{message}";
  my $json = $tx->res->json || {};
  if (my $detail = $json->{detail}) { $msg .= " - $detail" }
  die "$msg\n";
}

sub _pem_to_der {
  my $cert = shift;
  $cert =~ s/^-{5}.*$//mg;
  return decode_base64(Mojo::Util::trim($cert));
}

sub _der_to_cert {
  my $der = shift;
  my $pem = encode_base64($der, '');
  $pem =~ s!(.{1,64})!$1\n!g; # stolen from Convert::PEM
  return sprintf "-----BEGIN CERTIFICATE-----\n%s-----END CERTIFICATE-----\n", $pem;
}

1;

=head1 NAME

Mojo::ACME - Mojo-based ACME-protocol client

=head1 SYNOPSIS

  # myapp.pl
  use Mojolicious::Lite;
  plugin 'ACME';
  get '/' => {text => 'Hello World'};
  app->start;

  # then on the command line, while the app is available on port 80
  # NOTE! you should use -t when testing on following command

  # register an account key if necessary
  $ ./myapp.pl acme account register
  Writing account.key

  # generate your domain cert
  $ ./myapp.pl acme cert generate mydomain.com
  Writing myapp.key
  Writing myapp.crt

  # install your cert and restart your server per server instructions

=head1 DESCRIPTION

L<Let's Encrypt|https://letsencrypt.org> (also known as letsencrypt) is a service that provices free SSL certificates via an automated system.
The service uses (and indeed defines) a protocol called ACME to securely communicate authentication, verification, and certificate issuance.
If you aren't familiar with ACME or at least certificate issuance, you might want to see L<how it works|https://letsencrypt.org/how-it-works> first.
While many clients already exist, web framework plugins have the unique ability to handle the challenge response internally and therefore make for the easiest possible letsencrypt (or other ACME service) experience.

=head1 DEVELOPMENT STATUS

The plugin and command level apis should be fairly standardized; the author expects few changes to this level of the system.
That said, the lower level modules, like L<Mojo::ACME> are to be considered unstable and should not be relied upon.
Use of these classes directly is highly discouraged for the time being.

=head1 ARCHITECTURE

The system consists of three major component classes, the plugin L<Mojolicious::Plugin::ACME>, the commands, and the lower level classes which they rely on.

=head2 Plugin

The plugin is the glue that holds the system together.
It adds the C<acme> command (and its subcommands) to your app's command system.
It also establishes a route which handles the challenge request from the ACME service.
During your certificate issuance, you must prove that you control the requested domain by serving specified content at a specific location.
This route makes that possible.

The plugin itself reads configuration out of the application's L<config|Mojo/config> method.
This can be set directly in the application or loaded from a file via say L<Mojolicious::Plugin::Config> in the usual way.
It looks for a config key C<acme> containing a hash of configuration options.
Those options can be seen in the L<Mojolicious::Plugin::ACME> documentation.

The most important of these is C<challenge_url>.
In order to know how to respond to the challenge request, your server will make a signed HTTP request to your ACME client which will be listening.
This url is used both as the listen value of the ACME client's built-in server, as well as the base of your server's request.
It is advised that you use a url which isn't publically available if possible, though the requests are HMAC signed in any event.

=head2 Commands

The system provides several commands, including those for creating and verifying an account, as well as certificate issuance (and soon, revoking).
The commands are made available simply by using the plugin in your application.
They are then available in the same manner as built-in commands

  $ ./myapp.pl acme ...

While some options are sub-command specific, all sub-commands take a few options.
Important among those is the C<--ca> option and more conveniently the C<--test> (or C<-t>) flag.
Let's Encrypt has severe rate limiting for issuance of certicates on its production hosts.
Using the test flag uses the staging server which has greatly relaxed rate limits, though doesn't issue signed certs or create real accounts.
It does however use exactly the same process as the production service and issue valid (if not signed) certs.
The author highly recommends trying the process on the staging server first.

=head2 Modules (Low Level Usage)

As mentioned before, the author hopes to stabilize the low-level interface to be reusable/accessible, however for the time being that is not so and things WILL CHANGE UNEXPECTEDLY!

=head1 SEE ALSO

=over

=item *

L<Mojolicious> - L<http://mojolicio.us>

=item *

Let's Encrypt - L<https://letsencrypt.org/>

=item *

ACME Protocol - L<https://github.com/letsencrypt/acme-spec>

=item *

acme-tiny client from which I took a lot of inspiration/direction - L<https://github.com/diafygi/acme-tiny>

=back


=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojo-ACME>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

=over

=item *

Mario Domgoergen (mdom)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Joel Berger and L</CONTRIBUTORS>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

