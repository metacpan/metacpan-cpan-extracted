package Mojolicious::Plugin::ACME::Command;
use Mojo::Base 'Mojolicious::Command';

has common_usage => sub { shift->extract_usage };

use Mojo::ACME;
use Mojo::ACME::CA;
use Mojo::URL;
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case pass_through); # no_auto_abbrev

sub build_acme {
  my ($c, $args) = @_;
  my $acme = Mojo::ACME->new(secret => $c->app->secrets->[0]);
  GetOptionsFromArray( $args,
    'account-key|a=s' => sub { $acme->account_key->path($_[1]) },
    'ca|c=s' => \my $ca,
    'test|t' => \my $test,
  );

  if ($ca) {
    if ($ca =~ m[^http(?:s)?://]) {
      $acme->ca(Mojo::ACME::CA->new(primary_url => $ca));
      die 'Specifying test mode with a CA URL is unsupported' if $test;
    } else {
      die 'Unknown CA'
        unless my $spec = $c->app->config->{acme}{cas}{$ca};
      $acme->ca(Mojo::ACME::CA->new($spec));
    }
  } else {
    $acme->ca($c->app->config->{acme}{ca});
  }

  $acme->ca->test_mode($test) if defined $test;
  return $acme;
}

1;

=head1 NAME

Mojolicious::Plugin::ACME::Command - ACME command common functionality

=head1 SYNOPSIS

  Common Options:
    -a, --account-key   file containing your account key
                          defaults to account.key
    -c, --ca            short name or url of the certificate authority
                          defaults to letsencrypt
    -t, --test          use the certificate authority's test server
=cut

