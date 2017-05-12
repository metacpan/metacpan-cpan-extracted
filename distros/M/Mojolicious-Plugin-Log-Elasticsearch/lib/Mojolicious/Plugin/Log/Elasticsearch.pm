package Mojolicious::Plugin::Log::Elasticsearch;
$Mojolicious::Plugin::Log::Elasticsearch::VERSION = '1.162530';
# ABSTRACT: Mojolicious Plugin to log requests to an Elasticsearch instance

use Mojo::Base 'Mojolicious::Plugin';

use Time::HiRes qw/time/;
use Mojo::JSON  qw/encode_json/;

sub register {
  my ($self, $app, $conf) = @_;

  my $index = $conf->{index} || die "no elasticsearch index provided";
  my $type  = $conf->{type}  || die "no elasticsearch type provided";
  my $ts_name = $conf->{timestamp_field};
  my $es_url = $conf->{elasticsearch_url} || die "no elasticsearch url provided";
  my $log_stash_keys = $conf->{log_stash_keys} || [];
  my $extra_keys_sub = $conf->{extra_keys_hook};

  my $geoip;
  if ($conf->{geo_ip_citydb}) { 
    require Geo::IP;
    $geoip = Geo::IP->open($conf->{geo_ip_citydb});
  }

  # We should be smarter and only create this index if it isn't already
  # in existence. There's no harm here, it's just poor form.
  my $tx_c = $app->ua->put("${es_url}/${index}");

  my $index_meta = {
    $type => {
      # let ES generate timestamps if they haven't specified a ts field name
      ! $ts_name ? ("_timestamp" => { enabled => 1, store => 1 }) : (),
      "properties" => { 
        'ip'        => { 'type' => 'ip', 'store' => 1 },
        'path'      => { 'type' => 'string',  index => 'not_analyzed' },
        'location'  => { 'type' => 'geo_point' },
      }
    }
  };

  my $url = "${es_url}/${index}/${type}/_mapping";
  my $tx = $app->ua->post($url, json => $index_meta);

  $app->hook(before_dispatch => sub {
    my $c = shift;
    $c->stash->{'mojolicious-plugin-log-elasticsearch.start'} = time();
  });

  $app->hook(after_dispatch => sub {
    my $c = shift;
    my @n = gmtime();
    my $t = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $n[5]+1900, $n[4]+1, $n[3],
                                                      @n[2,1,0]);
    my $dur = time() - $c->stash->{'mojolicious-plugin-log-elasticsearch.start'};

    # perhaps look up Geo::IP stuff
    my %geo_ip_data;
    my ($lat, $long, $country_code);
    eval {
      return 1 if (! $geoip);
      return 1 if (! $c->tx->remote_address);

      my $rec = $geoip->record_by_addr($c->tx->remote_address);
      return 1 if (! $rec);

      $lat          = $rec->latitude;
      $long         = $rec->longitude;
      $country_code = $rec->country_code;

      %geo_ip_data = ( location => "$lat, $long", country_code => $country_code );

      1;
    } or do {
      $c->app->log->warn("could not lookup lat/long for ip: $@");
    };
    
    my $data = { ip     => $c->tx->remote_address, 
                 path   => $c->req->url->to_abs->path, 
                 code   => $c->res->code,
                 method => $c->req->method,
                 time   => $dur,
                 $ts_name ? ( $ts_name => int(time() * 1000) ) : (),
                 %geo_ip_data,
    };
    foreach (@{ $log_stash_keys}) {
      $data->{$_} = $c->stash->{$_} if (exists $c->stash->{$_});
    }

    if ($extra_keys_sub) {
      my %new_values = $extra_keys_sub->($c);
      $data = { %$data, %new_values };
    }

    my $url = "${es_url}/${index}/${type}/?timestamp=${t}";
    $c->app->ua->post($url, json => $data, sub {
      my ($ua, $tx) = @_;
      if (! $tx) {
        $c->app->log->warn("could not log to elasticsearch");
      }
      elsif ($tx->res && $tx->res->code && $tx->res->code !~ /^20./) {
        $c->app->log->warn("could not log to elasticsearch - " . $tx->res->body);
      }
    });
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Log::Elasticsearch - Mojolicious Plugin to log requests to an Elasticsearch instance

=head1 VERSION

version 1.162530

=head1 SYNOPSIS

  # Config for your elasticsearch instance
  my $config = { elasticsearch_url => 'http://localhost:9200',
                 index             => 'webapps', 
                 type              => 'MyApp',
                 timestamp_field   => 'timestamp',           # optional
                 geo_ip_citydb     => 'some/path/here.dat',  # optional
                 log_stash_keys    => [qw/foo bar baz/],     # optional
                 extra_keys_hook   => sub { .. },            # optional
  };

  # Mojolicious
  $self->plugin('Log::Elasticsearch', $config);

  # Mojolicious::Lite
  plugin 'Log::Elasticsearch', $config;

=head1 DESCRIPTION

L<Mojolicious::Plugin::Log::Elasticsearch> logs all requests to your app to an elasticsearch
instance, allowing you to retroactively slice and dice your application performance in 
fascinating ways.

After each request (via C<after_dispatch>), a non-blocking request is made to the elasticsearch
system via L<Mojo::UserAgent>. This should mean minimal application performance hit, but does mean you
need to run under C<hypnotoad> or C<morbo> for the non-blocking request to work.

The new Elasticsearch index is created if necessary when your application starts. The following
data points will be logged each request:

=over 4

=item * C<ip> - IP address of requestor

=item * C<path> - request path

=item * C<code> - HTTP code of response

=item * C<method> - HTTP method of request

=item * C<time> - the number of seconds the request took to process (internally, not accounting for network overheads)

=back

Additionally, if you supply a path to a copy of the GeoLiteCity.dat database file
in the config key 'C<geo_ip_citydb>', and have the L<Geo::IP> module installed, the
following keys will also be submitted to Elasticsearch:

=over 4

=item * location - latitude and longitude of the city the IP address belongs to

=item * country_code - two letter country code of the country the IP address belongs to

=back

The city database can be obtained here: L<http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz>.

The optional C<timestamp_field> should be used if you'd like to have timestamps submitted
with each entry using a defined name. If no C<timestamp_field> is specified, the elasticsearch
index will be created with an automatic timestamp configuration. Note that that feature was 
deprecated in recent versions of elasticsearch, if using a recent version you must specify
this parameter.

If you specify an arrayref of keys in the C<log_stash_keys> configuration value, those
corresponding values will be pulled from the request's stash (if present) and also
sent to Elasticsearch.

If you supply a coderef for the key C<extra_keys_hook>, that sub will be executed at
end of each request. It will be passed a single argument, the request itself. It should
return a hash, which contains extra key/value pairs which will go into the Elasticsearch
index. These keys may override existing entries for that request - for example if you'd 
like to override the path for some reason, you can do it here.

When the index is created, appropriate types are set for the 'C<ip>', 'C<path>' and 'C<location>' fields - in particular
the 'C<path>' field is set to not_analyzed so that it will not be treated as tokens separated by '/'.

=head1 METHODS

L<Mojolicious::Plugin::Log::Elasticsearch> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>, L<https://www.elastic.co>.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
