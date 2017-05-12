#
# Flush stats to ElasticSearch (http://www.elasticsearch.org/)
#
# To enable this backend, include 'elasticsearch' in the backends
# configuration array:
#
#   backends: ['./backends/elasticsearch'] 
#  (if the config file is in the statsd folder)
#
# A sample configuration can be found in exampleElasticConfig.js
#
# This backend supports the following config options:
#
#   host:          hostname or IP of ElasticSearch server
#   port:          port of Elastic Search Server
#   path:          http path of Elastic Search Server (default: '/')
#   indexPrefix:   Prefix of the dynamic index to be created (default: 'statsd')
#   indexType:     The dociment type of the saved stat (default: 'stat')
#

package Net::Statsd::Server::Backend::Elasticsearch;

use 5.008;
use strict;
use warnings;
use base qw(Net::Statsd::Server::Backend);

our $VERSION = '0.01';

use HTTP::Request  ();
use LWP::UserAgent ();

my $debug;
my $flushInterval;
my $elasticFilter;
my $elasticHost;
my $elasticPort;
my $elasticPath;
my $elasticIndex;
my $elasticCountType;
my $elasticTimerType;
my $elasticStats = {};
my $statsdIndex;

sub bulk_insert {
  my ($self, $listCounters, $listTimers, $listTimerData) = @_;

  my @utc_date = gmtime();
  my $utc_date = sprintf("%04d.%02d.%02d", $utc_date[5] + 1900, $utc_date[4] + 1, $utc_date[3]);

  $statsdIndex = $elasticIndex . '-' . $utc_date;
  my $payload = '';

  my $key = 0;
  for (@{ $listCounters }) {
    $payload .= '{"index":{"_index":"' . $statsdIndex . '","_type":"' . $elasticCountType . '"}}' . "\n"; 
    $payload .= '{';
    my $innerPayload = '';
    for my $statKey (keys %{ $listCounters->[$key] }) {
      if ($innerPayload) { $innerPayload .= ',' }
      $innerPayload .= '"' . $statKey . '":"' . $listCounters->[$key]->{$statKey} . '"';
    }
    $payload .= $innerPayload . '}' . "\n";
    $key++;
  }

  $key = 0;
  for (@{ $listTimers }) {
    $payload .= '{"index":{"_index":"' . $statsdIndex . '","_type":"' . $elasticTimerType . '"}}' . "\n";
    $payload .= '{';
    my $innerPayload = '';
    for my $statKey (keys %{ $listTimers->[$key] }) {
      if ($innerPayload) { $innerPayload .= ',' }
      $innerPayload .= '"' . $statKey . '":"' . $listTimers->[$key]->{$statKey} . '"';
    }
    $payload .= $innerPayload . '}' . "\n";
    $key++;
  }

  $key = 0;
  for (@{ $listTimerData }) {
    $payload .= '{"index":{"_index":"' . $statsdIndex . '","_type":"' . $elasticTimerType . '_stats"}}' . "\n";
    $payload += '{';
    my $innerPayload = '';
    for my $statKey (keys %{ $listTimerData->[$key] }) {
      if ($innerPayload) { $innerPayload .= ','; }
      $innerPayload .= '"' . $statKey . '":"' . $listTimerData->[$key]->{$statKey} . '"';
    }
    $payload .= $innerPayload . '}' . "\n";
    $key++;
  }

  return $payload;
}

sub post_stats {
  my ($self, $payload) = @_;

  my $optionsPost = {
    host => $elasticHost,
    port => $elasticPort,
    path => $elasticPath . $statsdIndex . '/_bulk',
    method => 'POST',
    headers => {
      'Content-Type'   => 'application/json',
      'Content-Length' => length($payload),
    }
  };

  my $req = HTTP::Request->new();
  $req->method($optionsPost->{method});
  $req->uri("http://" . $optionsPost->{host} . ":" . ($optionsPost->{port} || 80) . $optionsPost->{path});
  while (my ($name, $value) = each %{ $optionsPost->{headers} }) {
    $req->header($name => $value);
  }
  $req->content($payload);
  warn "-------------- Sending to Elasticsearch:\n$payload\n\n";
  my $lwp = LWP::UserAgent->new();
  $lwp->agent("Net::Statsd::Server::Backend::ElasticSearch/$VERSION");
  return $lwp->request($req);
}

sub flush {
  my ($self, $timestamp, $metrics) = @_;

  my $statString = '';
  my $numStats = 0;
  my $key;
  my @counts;
  my @timers;
  my @timer_data;

  $timestamp *= 1000;

  for my $key (keys %{ $metrics->{counters} }) {
    #my @keys = split m{\.}, $key;
    if (defined $elasticFilter && $key !~ $elasticFilter) {
      next;
    }
    my $value = $metrics->{counters}->{$key};
    #push @counts, {
    #  ns  => $keys[0] || '',
    #  grp => $keys[1] || '',
    #  tgt => $keys[2] || '',
    #  act => $keys[3] || '',
    #  val => $value,
    #};
    push @counts, {
      key => $key,
      counter => $value,
      '@timestamp' => $timestamp,
    };
    $numStats++;
  }

  for my $key (keys %{ $metrics->{timers} }) {
    my @keys = split m{\.}, $key;
    my $series = $metrics->{timers}->{$key};
    if (defined $elasticFilter && $key !~ $elasticFilter) {
      next;
    }
    for my $keyTimer (keys %{ $series }) {
      my $value = $series->{$keyTimer};
      push @timers, {
        key => $key,
        timer => $value,
	'@timestamp' => $timestamp,
      };
#     push @timers, {
#	ns  => $keys[0] || '',
#	grp => $keys[1] || '',
#	tgt => $keys[2] || '',
#	act => $keys[3] || '',
#	val => $value,
#	'@timestamp' => $timestamp,
#     };
    }
  }

  for my $key (keys %{ $metrics->{timer_data} }) {
    my @keys = split m{\.}, $key;
    if (defined $elasticFilter && $key !~ $elasticFilter) {
      next;
    }
    my $value = $metrics->{timer_data}->{$key};
    $value->{'@timestamp'} = $timestamp;
    $value->{key} = $key;
    if (defined $value->{histogram}) {
      for my $keyH (keys %{ $value->{histogram} }) {
        $value->{$keyH} = $value->{histogram}->{$keyH};
      }
      delete $value->{histogram};
    }
    push @timer_data, $value;
    $numStats++;
  }

  my $es_payload = $self->bulk_insert(\@counts, \@timers, \@timer_data);

  if ($numStats > 0 && $es_payload) {
    $self->post_stats($es_payload);
    if ($debug) {
      warn "flushed ${numStats} stats to ElasticSearch\n";
    }
  }

}

#var elastic_backend_status = function graphite_status(writeCb) {
#  for (stat in elasticStats) {
#    writeCb(null, 'elastic', stat, elasticStats[stat]);
#  }
#};

sub init {
  my ($self, $startup_time, $config, $events) = @_;

  $debug = $config->{debug};
  my $configEs = $config->{elasticsearch} || {};

  $elasticHost      = $configEs->{host}          || 'localhost';
  $elasticPort      = $configEs->{port}          || 9200;
  $elasticPath      = $configEs->{path}          || '/';
  $elasticIndex     = $configEs->{indexPrefix}   || 'statsd';
  # Only sends stats that match the 'statsFilter' substring
  $elasticFilter    = $configEs->{statsFilter}   || 'vstatd',
  $elasticCountType = $configEs->{countType}     || 'counter';
  $elasticTimerType = $configEs->{timerType}     || 'timer';
  $elasticTimerType = $configEs->{timerDataType} || 'timer_data';
  $flushInterval    = $config->{flushInterval};

  $elasticStats->{last_flush} = $startup_time;
  $elasticStats->{last_exception} = $startup_time;

  #events.on('flush', flush_stats);
  #events.on('status', elastic_backend_status);

  return 1;
}

1;
