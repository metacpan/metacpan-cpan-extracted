package Mojolicious::Plugin::ACME::Command::acme::automate;
use Mojo::Base 'Mojolicious::Plugin::ACME::Command';

our $VERSION = '0.02';

use Mojo::Collection 'c';
use Mojo::File 'path';
use Mojo::Server::Daemon;
use Mojo::Template;
use Mojo::Util 'getopt';

has description => 'For all specified domains, generate certificates signed by the ACME service';
has usage => sub {
  my $c = shift;
  $c->extract_usage . $c->common_usage;
};

sub run {
  my ($self, @args) = @_;

  my @daemon_args;
  getopt \@args, ['pass_through'],
    'l|listen=s'             => sub { push @daemon_args, '-l', $_[1] },
    'p|proxy'                => sub { push @daemon_args, '-p', $_[1] };

  Mojo::IOLoop->next_tick(sub {
    Mojo::IOLoop->subprocess(
      sub {
        my $subprocess = shift;
        $self->_automate(@args);
      },
      sub {
        my ($subprocess, $err, @results) = @_;
        warn $err if $err;
        say @results if @results;
        Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
      }
    );
  });
  $self->app->commands->run('daemon', @daemon_args);
}

sub _automate {
  my ($self, @args) = @_;

  my $t = 0;
  my %options;
  getopt \@args,
    'intermediate=s' => \my $int_url,
    'full!'          => \(my $full = 1),
    'n|name=s'       => \my $name,
    't|test'         => \my $test,
    'T|template=s'   => \(my $template = 'nginx_default'),
    'o|options=s'    => \%options;
  $name ||= $self->app->moniker;
  $name .= 'test' if $test;

  die 'an ssl directory name is required' unless my $ssldir = $self->app->config('ssldir');

  my $host = $args[0] or die "no canonical host";
  my $account = path($ssldir)->child("$name-account-$host.key")->to_string;
  $name = path($ssldir)->child("$name-cert-$host")->to_string;
  $self->app->log->info("generating $host certificate signed by the ACME service");

  push @args, '-a', $account, ($test?'-t':());
  my $acme = $self->build_acme(\@args);

  sleep 3;

  # Register account

  unless ( -f $account ) {
    my $response = eval { $acme->register };
    print $@ if $@;
    die "Account not registered" unless $response;

    say $response;
    my $key = $acme->account_key;
    if ($key->generated) {
      my $key_path = $key->path;
      $self->app->log->info("Writing $key_path");
      Mojo::File->new($key_path)->spurt($key->string);
    }
    sleep 3;
  }

  # Generate certificate

  $acme->server_url($self->app->config('acme')->{challenge_url});

  my $intermediate;
  if ($full) {
    my $msg = "No certificate generation was attempted. Use --no-full to proceed without it.\n";
    $int_url ||= eval { $acme->ca->intermediate };
    die "Intermediate certificate not specified. $msg"
      unless $int_url;
    my $tx = $acme->ua->get($int_url);
    die "Failed to fetch intermediate cert. $msg"
      unless $tx->result;
    die "Intermediate cert was empty. $msg"
      unless $intermediate = $tx->res->body;
  }

  $acme->new_authz($_) for @args;

  my $cert;
  Mojo::IOLoop->delay(
    sub { $acme->check_all_challenges(shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die Mojo::Util::dumper($err) if $err;
      my $bad = c(values %{ $acme->challenges })->grep(sub { $_->{status} ne 'valid' });
      die 'The following challenges were not validated ' . Mojo::Util::dumper($bad->to_array) if $bad->size;
      #TODO poll for cert when delayed
      $cert = $acme->get_cert(@args);
    },
  )->catch(sub{ warn "$_[-1]\n" })->wait;

  die "No cert was generated for $host" unless $cert;

  my $key_path = "$name.key";
  if ($acme->cert_key->generated) {
    $self->app->log->info("Writing $key_path");
    Mojo::File->new($key_path)->spurt($acme->cert_key->string);
  }

  if ($intermediate) {
    $cert = $cert . $intermediate;
  }

  my $cert_path = "$name.crt";
  $self->app->log->info("Writing $cert_path");
  Mojo::File->new($cert_path)->spurt($cert);

  if ( my $webdir = $self->app->config('webdir') ) {
    path($webdir)->child($host)->spurt(
      Mojo::Template->new->vars(1)->render_file(
        $self->app->home->child('templates', "$template.ep"),
        {%options, hosts => \@args, cert => $cert_path, key => $key_path}
      )
    ) if $template && !$acme->ca->test_mode; # TODO: unless go+w
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ACME::Command::acme::automate - Automate ACME registration and signed certificate generation

=head1 SYNOPSIS

  Usage: APPLICATION acme automate [OPTIONS]
    myapp acme automate
    myapp acme automate -t -a myaccount.key -T template -l http://*:8928 -o proxy_pass=http://127.0.0.1:3000 domain1.com {domain2.com, ...}

  Options:

        --full, --no-full                Automatically chain the resulting
                                         certificate with the intermediate
                                         defaults to true, use --no-full to
                                         disable
    -h, --help                           Show this summary of available options
    -i, --intermediate                   The url of the intermediate cert to
                                         be chained if "full" is passed
    -l, --listen <location>              One or more locations you want to
                                         listen on, defaults to the value of
                                         MOJO_LISTEN or "http://*:3000"
    -n, --name                           The name of the file(s) to be
                                         generated, defaults to the app's
                                         moniker
    -o, --option <key=value>             Options to pass as variables to the
                                         template
    -p, --proxy                          Activate reverse proxy support,
                                         defaults to the value of
                                         MOJO_REVERSE_PROXY
    -T, --template <filename>            Template for building a config file
                                         for your reverse proxy server
                                         (e.g. nginx)

=head1 DESCRIPTION

L<Mojolicious::Plugin::ACME::Command::acme::automate> automates ACME
registration and signed certificate generation for one or more domains.

=head1 ATTRIBUTES

L<Mojolicious::Plugin::ACME::Command::acme::automate> inherits all
attributes from L<Mojolicious::Plugin::ACME::Command> and implements the
following new ones.

=head2 description

  my $description = $v->description;
  $v              = $v->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $v->usage;
  $v        = $v->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Plugin::ACME::Command::acme::automate> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $v->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::ACME>.

=head1 SOURCE REPOSITORY

L<http://github.com/s1037989/Mojolicious-Plugin-ACME-Command-acme-automate>

=head1 AUTHOR

Stefan Adams, E<lt>sadams@cpan.org<gt>

=head1 CONTRIBUTORS

=over

=item *

Joel Berger (jberger)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Stefan Adams and L</CONTRIBUTORS>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
