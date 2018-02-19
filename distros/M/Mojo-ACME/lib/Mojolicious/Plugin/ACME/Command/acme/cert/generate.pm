package Mojolicious::Plugin::ACME::Command::acme::cert::generate;
use Mojo::Base 'Mojolicious::Plugin::ACME::Command';

use Mojo::Collection 'c';
use Mojo::File;

use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case); # no_auto_abbrev

has description => 'Generate a certificate signed by the ACME service';
has usage => sub {
  my $c = shift;
  $c->extract_usage . $c->common_usage;
};

sub run {
  my ($c, @args) = @_;
  my $acme = $c->build_acme(\@args);
  $acme->server_url($c->app->config('acme')->{challenge_url});

  my @domains;
  GetOptionsFromArray(\@args,
    'name|n=s' => \my $name,
    'domain|d=s' => \@domains,
    'intermediate|i=s' => \my $int_url,
    'full!' => \(my $full = 1),
    'wildcard|w' => \my $wildcard,
  );
  $name ||= $c->app->moniker;

  push @domains, @args;
  die 'a domain name is required' unless @domains;

  #Note: wildcard domains are at the discrecion of the ACME service and
  #are not supported by letsencrypt, even if they are allowed they are
  #never to be challenged and thus @new is not @domains

  my @new = grep { $_ !~ /^\*/ } @domains;
  die "ACME does not explicitly allow wildcard certs, use --wildcard to override\n"
    unless (@new == @domains || $wildcard);

  my $intermediate;
  if ($full) {
    my $msg = "No certificate generation was attempted. Use --no-full to proceed without it.\n";
    $int_url ||= eval { $acme->ca->intermediate };
    die "Intermediate certificate not specified. $msg"
      unless $int_url;
    my $tx = $acme->ua->get($int_url);
    die "Failed to fetch intermediate cert. $msg"
      unless $tx->success;
    die "Intermediate cert was empty. $msg"
      unless $intermediate = $tx->res->body;
  }

  $acme->new_authz($_) for @new;

  my $cert;
  Mojo::IOLoop->delay(
    sub { $acme->check_all_challenges(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die Mojo::Util::dumper($err) if $err;
      my $bad = c(values %{ $acme->challenges })->grep(sub { $_->{status} ne 'valid' });
      die 'The following challenges were not validated ' . Mojo::Util::dumper($bad->to_array) if $bad->size;
      #TODO poll for cert when delayed
      $cert = $acme->get_cert(@domains);
    },
  )->catch(sub{ warn "$_[-1]\n" })->wait;

  die "No cert was generated\n" unless $cert;

  if ($acme->cert_key->generated) {
    my $key_path = "$name.key";
    say "Writing $key_path";
    Mojo::File->new($key_path)->spurt($acme->cert_key->string);
  }

  if ($intermediate) {
    $cert = $cert . $intermediate;
  }

  my $cert_path = "$name.crt";
  say "Writing $cert_path";
  Mojo::File->new($cert_path)->spurt($cert);
}

1;

=head1 NAME

Mojolicious::Plugin::ACME::Command::acme::cert::generate - ACME signed certificate generation

=head1 SYNOPSIS

  Usage: APPLICATION acme cert generate [OPTIONS]
    myapp acme cert generate mydomain.com
    myapp acme cert generate -t -a myaccount.key mydomain.com

  Options:

    -n, --name          the name of the file(s) to be generated, defaults to the app's moniker
    -d, --domain        the domain (or domains is passed multiple times) to be issued (on a single cert)
                          note that bare arguments are also used as domains
    -i, --intermediate  the url of the intermediate cert to be chained if "full" is passed
    --full, --no-full   automatically chain the resulting certificate with the intermediate
                          defaults to true, use --no-full to disable
    -w, --wildcard      allow wildcard requests, letsencrypt does not issue wildcard certs (yet?), though others might
=cut

