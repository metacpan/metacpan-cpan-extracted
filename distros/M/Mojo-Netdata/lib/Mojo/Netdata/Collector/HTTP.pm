package Mojo::Netdata::Collector::HTTP;
use Mojo::Base 'Mojo::Netdata::Collector', -signatures;

use Mojo::UserAgent;
use Mojo::Netdata::Util qw(logf safe_id);
use Time::HiRes qw(time);

require Mojo::Netdata;
our $VERSION = $Mojo::Netdata::VERSION;

has jobs => sub ($self) { +[] };
has type => 'HTTP';
has ua   => sub { Mojo::UserAgent->new(insecure => 0, connect_timeout => 5, request_timeout => 5) };
has update_every => 30;

sub register ($self, $config, $netdata) {
      $config->{update_every}      ? $self->update_every($config->{update_every})
    : $netdata->update_every >= 10 ? $self->update_every($netdata->update_every)
    :                                $self->update_every(30);

  $self->ua->insecure($config->{insecure})               if defined $config->{insecure};
  $self->ua->connect_timeout($config->{connect_timeout}) if defined $config->{connect_timeout};
  $self->ua->request_timeout($config->{request_timeout}) if defined $config->{request_timeout};
  $self->ua->proxy->detect                               if $config->{proxy} // 1;
  $self->ua->transactor->name($config->{user_agent} || "Mojo-Netdata/$VERSION (Perl)");
  $self->jobs([]);

  my @jobs = ref $config->{jobs} eq 'HASH' ? %{$config->{jobs}} : @{$config->{jobs}};
  while (my $url = shift @jobs) {
    my $job = $self->_make_job($url => ref $jobs[0] eq 'HASH' ? shift @jobs : {}, $config);
    push @{$self->jobs}, $job if $job;
  }

  return @{$self->jobs} ? $self : undef;
}

sub update_p ($self) {
  my ($ua, @p) = ($self->ua);

  my $t0 = time;
  for my $job (@{$self->jobs}) {
    my $tx = $ua->build_tx(@{$job->[0]});
    push @p, $ua->start_p($tx)->then(sub ($tx) {
      $job->[1]->($tx, $t0);
    })->catch(sub ($err) {
      $job->[1]->($tx, $t0, {message => $err});
    });
  }

  return Mojo::Promise->all(@p);
}

sub _make_job ($self, $url, $params, $defaults) {
  $url = Mojo::URL->new($url);
  return undef unless my $host = $url->host;

  my $headers = Mojo::Headers->new->from_hash($defaults->{headers} || {});
  $headers->header($_ => $params->{headers}{$_}) for keys %{$params->{headers} || {}};
  ($headers->header(Host => $url->host), $url->host($params->{via})) if $params->{via};

  my $dimension = $params->{dimension} || $headers->host || $url->host;
  my $family    = $params->{family}    || $defaults->{family} || $headers->host || $url->host;

  my $code_chart = $self->chart("${family}_code")->title("HTTP Status code for $family")
    ->context('httpcheck.code')->family($family)->units('#');

  if ($code_chart->dimension($dimension)) {
    logf(warnings => 'Family "%s" already has dimension "%s".', $family, $dimension);
    return undef;
  }

  my $time_chart = $self->chart("${family}_time")->title("Response time for $family")
    ->context('httpcheck.responsetime')->family($family)->units('ms');

  $code_chart->dimension($dimension => {});
  $time_chart->dimension($dimension => {});

  my $update = sub ($tx, $t0, $err = undef) {
    $err ||= $tx->error;
    my $req  = $tx->req;
    my $code = $tx->res->code // 0;
    my @msg  = ($req->method, $req->url, $err || {code => $code}, $req->headers->to_hash(1));
    logf(($err ? 'warnings' : 'debug'), '%s %s == %s %s', @msg);

    $time_chart->dimension($dimension => {value => int(1000 * (time - $t0))});
    $code_chart->dimension($dimension => {value => $code});
  };

  my @data;
  push @data, $headers->to_hash(1);
  push @data,
      exists $params->{json} ? (json => $params->{json})
    : exists $params->{form} ? (form => $params->{form})
    : exists $params->{body} ? ($params->{body})
    :                          ();

  return [[$params->{method} || 'GET', $url->to_unsafe_string, @data], $update];
}

1;

=encoding utf8

=head1 NAME

Mojo::Netdata::Collector::HTTP - A website monitorer for Mojo::Netdata

=head1 SYNOPSIS

=head2 Config

Below is an example C</etc/netdata/mojo.conf.d/http.conf.pl> config file. Note
that the file can have any name and you have have as many as you want, as long
as it has the C<.conf.pl> extension.

  {
    # Required
    collector => 'Mojo::Netdata::Collector::HTTP',

    # Optional
    insecure        => 0,     # Set to "1" to allow insecure SSL/TLS connections
    connect_timeout => 5,     # Max time for the connection to be established
    request_timeout => 5,     # Max time for the whole request to complete
    proxy           => 1,     # Set to "0" to disable proxy auto-detect
    update_every    => 30,    # How often to run the "jobs" below
    user_agent      => '...', # Custom User-Agent name

    # Default values, unless defined in the job
    family  => 'default-family-name',
    headers => {'X-Merged-With' => 'headers inside job config'},

    # Required - List of URLs and an optional config hash (object)
    jobs => [

      # List of URLs to check (Config is optional)
      'https://superwoman.example.com',
      'https://superman.example.com',

      # URL and config parameters
      'https://example.com' => {
        method  => 'GET',              # GET (Default), HEAD, POST, ...
        headers => {'X-Foo' => 'bar'}, # HTTP headers

        # Replace "host" in the URL with this IP and set the "Host" header
        via => '192.168.2.1',

        # Set "dimension" to get a custom label in the chart.
        # Default to the "Host" header or the host part of the URL.
        dimension => 'foo', # Default: "example.com"

        # Set "family" to group multiple domains together in one chart,
        # Default to the "Host" header or the host part of the URL.
        family => 'bar', # Default: "example.com"

        # Only one of these can be present
        json   => {...},           # JSON HTTP body
        form   => {key => $value}, # Form data
        body   => '...',           # Raw HTTP body
      },
    ],
  };

=head2 Health

Here is an example C</etc/netdata/health.d/mojo-http.conf> file:

   template: web_server_code
         on: httpcheck.code
      class: Errors
       type: Web Server
  component: HTTP endpoint
     plugin: mojo
     lookup: max -5m absolute foreach *
      every: 1m
       warn: $this >= 300 && $this < 500
       crit: $this >= 500 && $this != 503
         to: webmaster

   template: web_server_up
         on: httpcheck.code
      class: Errors
       type: Web Server
  component: HTTP endpoint
     plugin: mojo
     lookup: min -5m absolute foreach *
      every: 1m
       crit: $this == 0
      units: up/down
         to: webmaster

=head1 DESCRIPTION

L<Mojo::Netdata::Collector::HTTP> is a collector that can chart web page
response time and HTTP status codes.

=head1 ATTRIBUTES

=head2 jobs

  $array_ref = $self->jobs;

A list of jobs generated by L</register>.

=head2 type

  $str = $collector->type;

Defaults to "http".

=head2 ua

  $ua = $collector->ua;

Holds a L<Mojo::UserAgent>.

=head2 update_every

  $num = $chart->update_every;

Default value is 30. See L<Mojo::Netdata::Collector/update_every> for more
details.

=head1 METHODS

=head2 register

  $collector = $collector->register(\%config, $netdata);

Returns a L<$collector> object if any "jobs" are defined in C<%config>. Will
also set L</update_every> from C<%config> or use L<Mojo::Netdata/update_every>
if it is 10 or greater.

=head2 update_p

  $p = $collector->update_p;

Gathers information about the "jobs" registered.

=head1 SEE ALSO

L<Mojo::Netdata> and L<Mojo::Netdata::Collector>.

=cut
