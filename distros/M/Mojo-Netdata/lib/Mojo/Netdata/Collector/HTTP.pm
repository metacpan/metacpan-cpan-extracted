package Mojo::Netdata::Collector::HTTP;
use Mojo::Base 'Mojo::Netdata::Collector', -signatures;

use Mojo::UserAgent;
use Mojo::Netdata::Util qw(logf);
use Time::HiRes qw(time);

has context => 'web';
has type    => 'HTTP';
has ua => sub { Mojo::UserAgent->new(insecure => 0, connect_timeout => 5, request_timeout => 5) };
has update_every => 30;
has _jobs        => sub ($self) { +[] };

sub register ($self, $config, $netdata) {
      $config->{update_every}      ? $self->update_every($config->{update_every})
    : $netdata->update_every >= 10 ? $self->update_every($netdata->update_every)
    :                                $self->update_every(30);

  $self->ua->insecure($config->{insecure})               if defined $config->{insecure};
  $self->ua->connect_timeout($config->{connect_timeout}) if defined $config->{connect_timeout};
  $self->ua->request_timeout($config->{request_timeout}) if defined $config->{request_timeout};
  $self->ua->proxy->detect;

  $self->_add_jobs_for_site($_ => $config->{jobs}{$_}) for sort keys %{$config->{jobs}};
  return @{$self->_jobs} ? $self : undef;
}

sub update_p ($self) {
  my ($ua, @p) = ($self->ua);

  my $t0 = time;
  for my $job (@{$self->_jobs}) {
    my $dimension_id = $job->[0];
    my $charts       = $job->[1];
    my $tx           = $ua->build_tx(@{$job->[2]});
    push @p, $ua->start_p($tx)->catch(
      sub ($err, @) {
        logf(warnings => '%s %s == %s', $tx->req->method, $tx->req->url, $err);
        return $tx;
      }
    )->then(sub ($tx) {
      logf(debug => '%s %s == %s', $tx->req->method, $tx->req->url, $tx->res->code)
        if $tx->res->code;
      $charts->{code}->dimension($dimension_id => {value => $tx->res->code // 0});
      $charts->{time}->dimension($dimension_id => {value => int(1000 * (time - $t0))});
    });
  }

  return Mojo::Promise->all(@p);
}

sub _add_jobs_for_site ($self, $url, $site) {
  $url = Mojo::URL->new($url);
  return unless my $host = $url->host;

  my $family  = $site->{family} || $site->{direct_ip} || $url =~ s!https?://!!r;
  my $method  = $site->{method} || 'GET';
  my %headers = %{$site->{headers} || {}};
  my %charts;

  $charts{code} = $self->chart("${family}_code")->title("HTTP Status code for $family")->units('#')
    ->dimension($host => {})->family($family);
  $charts{time} = $self->chart("${family}_time")->title("Response time for $family")->units('ms')
    ->dimension($host => {})->family($family);

  my @body
    = exists $site->{json} ? (json => $site->{json})
    : exists $site->{form} ? (form => $site->{form})
    : exists $site->{body} ? ($site->{body})
    :                        ();

  push @{$self->_jobs}, [$host, \%charts, [$method => "$url", {%headers}, @body]];

  if ($site->{direct_ip}) {
    $charts{code}->dimension("${host} direct" => {});
    $charts{time}->dimension("${host} direct" => {});
    $headers{Host} = $host;
    my $direct_url = $url->clone->host($site->{direct_ip});
    push @{$self->_jobs},
      ["${host} direct", \%charts, [$method => "$direct_url", {%headers}, @body]];
  }

  logf(info => 'Tracking %s', $url);
}

1;

=encoding utf8

=head1 NAME

Mojo::Netdata::Collector::HTTP - A HTTP collector for Mojo::Netdata

=head1 SYNOPSIS

Supported variant of L<Mojo::Netdata/config>:

  {
    collectors => [
      {
        # It is possible to load this collector multiple times
        class           => 'Mojo::Netdata::Collector::HTTP',
        connect_timeout => 5, # Optional
        request_timeout => 5, # Optional
        update_every    => 30,
        jobs            => {
          # The key is the URL to request
          'https://example.com' => {

            # Optional
            method => 'GET',               # GET (Default), HEAD, POST, ...
            headers => {'X-Foo' => 'bar'}, # HTTP headers

            # Set this to also send the request directly to an IP,
            # with the "Host" headers set to the host part of "url".
            direct_ip => '192.0.2.42',

            # Set "family" to group multiple domains together in one chart,
            # Default value is either "direct_ip" or the host part of the URL.
            family => 'test',

            # Only one of these can be present
            json   => {...},           # JSON HTTP body
            form   => {key => $value}, # Form data
            body   => '...',           # Raw HTTP body
          },
        },
      },
    ],
  }

=head1 DESCRIPTION

L<Mojo::Netdata::Collector::HTTP> is a collector that can chart a web page
response time and HTTP status codes.

=head1 ATTRIBUTES

=head2 context

  $str = $collector->context;

Defaults to "web".

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
