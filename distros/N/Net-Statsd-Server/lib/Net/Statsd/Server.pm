# ABSTRACT: a Perl port of Etsy's statsd *server*

package Net::Statsd::Server;

# Use statements {{{

use strict;
#se warnings;

use JSON::XS ();
use Socket qw(SOL_SOCKET SO_RCVBUF);
use Time::HiRes ();

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Handle::UDP;
use AnyEvent::Log;
use AnyEvent::Socket;

use Net::Statsd::Server::Backend;
use Net::Statsd::Server::Metrics;

# }}}

# Constants and global variables {{{

use constant {
  DEBUG                  => 0,
  DEFAULT_CONFIG_FILE    => 'localConfig.js',
  DEFAULT_FLUSH_INTERVAL => 10_000,
  DEFAULT_LOG_LEVEL      => 'info',
  RECEIVE_BUFFER_MB      => 8,                   # 0 = setsockopt disabled
};

our $VERSION = '0.17';
our $logger;

# }}}

sub new {
  my ($class, $opt) = @_;
  $opt ||= {};
  $class = ref $class || $class;

  my $startup_time = time();

  # Initialize data structures with defaults for statsd stats
  my $self = {

    startup_time  => $startup_time,
    start_time_hi => [Time::HiRes::gettimeofday],

    server        => undef,
    mgmtServer    => undef,

    config_file   => $opt->{config_file},
    config        => undef,
    stats         => {
      messages => {
        "last_msg_seen"  => $startup_time,
        "bad_lines_seen" => 0,
      }
    },
    metrics       => undef,

    debugInt      => undef,
    flushInterval => undef,

    backends      => [],
    logger        => $logger,
  };

  $self->{$_} = $opt->{$_}
    for keys %{ $opt };

  bless $self, $class;
}

# Flatten JSON booleans to avoid calls to JSON::XS::bool
# in the performance-critical code paths
sub _flatten_bools {
  my ($self, $conf_hash) = @_;
  for (qw(dumpMessages debug)) {
    $conf_hash->{$_} = !! $conf_hash->{$_};
  }
  return $conf_hash;
}

sub _json_emitter {
  my ($self) = @_;
  my $js = JSON::XS->new()
    ->utf8(1)
    ->shrink(1)
    ->space_before(0)
    ->space_after(1)
    ->indent(0);
  return $js;
}

sub _start_time_hi {
  return $_[0]->{start_time_hi};
}

sub config_defaults {
  return {
    "debug" => 0,
    "debugInterval" => 10000,                   # ms
    "graphitePort"  => 2003,
    "port"          => 8125,
    "address"       => "0.0.0.0",
    "mgmt_port"     => 8126,
    "mgmt_address"  => "0.0.0.0",
    "flushInterval" => DEFAULT_FLUSH_INTERVAL,  # ms
    #"keyFlush" => {
    #  "interval" => 10,                        # s
    #  "percent"  => 100,
    #  "log"      => "",
    #},
    "log" => {
      "backend" => "stdout",
      "level"   => "LOG_INFO",
    },

    "prefixStats" => "statsd",
    "dumpMessages" => 0,

    "deleteIdleStats" => 0,
    #"deleteCounters"  => 0,
    #"deleteGauges"    => 0,
    #"deleteSets"      => 0,
    #"deleteTimers"    => 0,

    "percentThreshold" => [ 90 ],

    "backends" => [
      "Console",
    ],
  };
}

sub config {
  my ($self, $config_file) = @_;

  if (exists $self->{config} && defined $self->{config}) {
    return $self->{config};
  }

  $config_file ||= $self->config_file();

  if (! -e $config_file) {
    return;
  }

  my $defaults = $self->config_defaults();

  open my $conf_fh, '<', $config_file
    or return $defaults;

  my $conf_json = join("", <$conf_fh>);
  close $conf_fh;

  my $json = JSON::XS->new->relaxed->utf8;
  my $conf_hash = $json->decode($conf_json);

  $conf_hash = $self->_flatten_bools($conf_hash);

  # Poor man's Hash::Merge
  for (keys %{ $defaults }) {
    if (! exists $conf_hash->{$_}) {
      $conf_hash->{$_} = $defaults->{$_};
    }
  }

  return $self->{config} = $conf_hash;
}

sub clear_metrics {
  my ($self) = @_;

  my $conf = $self->config;

  my $del_counters = $conf->{deleteCounters};
  my $del_gauges   = $conf->{deleteGauges};
  my $del_sets     = $conf->{deleteSets};
  my $del_timers   = $conf->{deleteTimers};

  # Metrics that are not seen in the interval won't
  # be sent anymore. Enable this with 'deleteIdleStats'
  my $del_idle = _defined_or($conf->{deleteIdleStats}, 0);

  if ($del_idle) {
    $del_counters = _defined_or($del_counters, 1);
    $del_gauges   = _defined_or($del_gauges,   1);
    $del_timers   = _defined_or($del_timers,   1);
    $del_sets     = _defined_or($del_sets,     1);
  }

  # Whether to just reset them to zero or to wipe them
  my $metrics = $self->{metrics};
  if ($del_counters) {
    $metrics->{counters} = {};
    $metrics->{counter_rates} = {};
  }
  else {
    my $counters = $metrics->{counters};
    my $counter_rates = $metrics->{counter_rates};
    $_ = 0 for
      values %{ $counters },
      values %{ $counter_rates };
  }

  if ($del_timers) {
    $metrics->{timers} = {};
    $metrics->{timer_data} = {};
  }
  else {
    my $timers = $metrics->{timers};
    my $timer_data = $metrics->{timer_data};
    $_ = [] for
      values %{ $timers },
      values %{ $timer_data };
  }

  if ($del_gauges) {
    $metrics->{gauges} = {};
  }

  if ($del_sets) {
    $metrics->{sets} = {};
  }
  else {
    my $sets = $metrics->{sets};
    $_ = {} for values %{ $sets };
  }

  return;
}

sub config_file {
  _defined_or($_[0]->{config_file}, DEFAULT_CONFIG_FILE);
}

sub flush_metrics {
  my ($self) = @_;
  my $flush_start_time = time;
  $logger->(notice => "flushing metrics");
  my $flush_interval = $self->config->{flushInterval};
  my $metrics = $self->metrics->process($flush_interval);
  $self->foreach_backend(sub {
    $_[0]->flush($flush_start_time, $metrics);
  });
  $self->clear_metrics();
  return;
}

# This is the performance-critical section of Net::Statsd::Server.
# Everything below has been optimised for performance rather than
# legibility or transparency. Be careful.

sub handle_client_packet {
  my ($self, $request) = @_;

  my $config   = $self->{config};
  my $metrics  = $self->{metrics};
  my $counters = $metrics->{counters};
  my $stats    = $self->{stats};
  my $g_pref   = $config->{prefixStats};

  $counters->{"${g_pref}.packets_received"}++;

  # TODO backendEvents.emit('packet', msg, rinfo);

  my @metrics = split("\n", $request);

  my $dump_messages = $config->{dumpMessages};
  my $must_count_keys = exists $config->{keyFlush}
    && $config->{keyFlush}->{interval};

  for my $m (@metrics) {

    $logger->(debug => $m) if $dump_messages;

    my @bits = split(":", $m);
    my $key = shift @bits;

    # Keep [,=] to allow sending of tags. Handy for Influxdb integration.
    $key =~ y{/ }{_-}s;
    $key =~ y{a-zA-Z0-9_\-\.,=}{}cd;

    # Not very clear here. Etsy's code was doing this differently
    if ($must_count_keys) {
      my $key_counter = $metrics->{keyCounter};
      $key_counter->{$key}++;
    }

    push @bits, "1" if 0 == @bits;

    for my $i (0..$#bits) {

      my $sample_rate = 1;
      my @fields = split(/\|/, $bits[$i]);

      if (! defined $fields[1] || $fields[1] eq "") {
        $logger->(warn => "Bad line: $bits[$i] in msg \"$m\"");
        $counters->{"${g_pref}.bad_lines_seen"}++;
        $stats->{"messages"}->{"bad_lines_seen"}++;
        next;
      }

      my $value = $fields[0] || 0;
      my $unit = $fields[1];
      for ($unit) {
        s{^\s*}{};
        s{\s*$}{};
      }

      # Timers
      if ($unit eq "ms") {
        my $timers = $metrics->{timers};
        $timers->{$key} ||= [];
        push @{ $timers->{$key} }, $value;
      }

      # Gauges
      elsif ($unit eq "g") {
        my $gauges = $metrics->{gauges};
        $gauges->{$key} = $value;
      }

      # Sets
      elsif ($unit eq "s") {
        # Treat set as a normal hash with undef keys
        # to minimize memory consumption *and* insertion speed
        my $sets = $metrics->{sets};
        $sets->{$key} ||= {};
        $sets->{$key}->{$value} = undef;
      }

      # Counters
      else {
        if (defined $fields[2]) {
          if ($fields[2] =~ m{^\@([\d\.]+)}) {
            $sample_rate = $1 + 0;
          }
          else {
            $logger->(warn => "Bad line: $bits[$i] in msg \"$m\"; has invalid sample rate");
            $counters->{"${g_pref}.bad_lines_seen"}++;
            $stats->{"messages"}->{"bad_lines_seen"}++;
            next;
          }
        }
        $counters->{$key} ||= 0;
        $value ||= 1;
        $value /= $sample_rate;
        $counters->{$key} += $value;
      }
    }
  } 

  $stats->{"messages"}->{"last_msg_seen"} = time();
}

sub handle_manager_command {
  my ($self, $handle, $request) = @_;
  my @cmdline = split(" ", trim($request));
  my $cmd = shift @cmdline;
  my $reply;

  $logger->(notice => "Received manager command '$cmd' (req=$request)");

  if ($cmd eq "help") {
      $reply = (
        "Commands: stats, counters, timers, gauges, delcounters, deltimers, delgauges, quit\015\012\015\012"
      );
  }
  elsif ($cmd eq "stats") {
      my $now = time;
      my $uptime = $now - $self->{startup_time};
      $reply = "uptime: $uptime\n";

      # Loop through the base stats
      my $stats = $self->stats;

      for my $group (keys %{$stats}) {
        for my $metric (keys %{$stats->{$group}}) {
          my $val = $stats->{$group}->{$metric};
          my $delta = $metric =~ m{^last_}
            ? $now - $val
            : $val;
          $reply .= "${group}.${metric}: ${delta}\n";
        }
      }

      $self->foreach_backend(sub {
        my $backend_status = $_[0]->status;
        if ($backend_status && ref $backend_status eq "HASH") {
          for (keys %{ $backend_status }) {
            $reply .= sprintf("%s.%s: %s\n",
              lc($_[0]->name),
              $_ => $backend_status->{$_}
            );
          }
        }
      });

      $reply .= "END\n\n";
  }
  elsif ($cmd eq "counters") {
    my $counters = $self->{metrics}->{counters};
    $reply = $self->_json_emitter()->encode($counters);
    $reply .= "\nEND\n\n";
  }
  elsif ($cmd eq "timers") {
    my $timers = $self->{metrics}->{timers};
    $reply = $self->_json_emitter()->encode($timers);
    $reply .= "\nEND\n\n";
  }
  elsif ($cmd eq "gauges") {
    my $gauges = $self->{metrics}->{gauges};
    $reply = $self->_json_emitter()->encode($gauges);
    $reply .= "\nEND\n\n";
  }
  elsif ($cmd eq "sets") {
    my $sets = $self->{metrics}->{sets};
    my $sets_as_lists = {};
    # FIXME Not really happy about this...
    # if you have huge sets, it's going to suck.
    # If you have huge sets, probably statsd is not for you anyway.
    for my $set (keys %{$sets}) {
      $sets_as_lists->{$set} = [ keys %{ $sets->{$set} } ];
    }
    $reply = $self->_json_emitter()->encode($sets_as_lists);
    $reply .= "\nEND\n\n";
  }
  elsif ($cmd eq "delcounters") {
    my $counters = $self->{metrics}->{counters};
    for my $name (@cmdline) {
      delete $counters->{$name};
      $reply .= "deleted: $name\n";
    }
    $reply .= "\nEND\n\n";
  }
  elsif ($cmd eq "deltimers") {
    my $timers = $self->{metrics}->{timers};
    for my $name (@cmdline) {
      delete $timers->{$name};
      $reply .= "deleted: $name\n";
    }
    $reply .= "\nEND\n\n";
  }
  elsif ($cmd eq "delgauges") {
    my $gauges = $self->{metrics}->{gauges};
    for my $name (@cmdline) {
      delete $gauges->{$name};
      $reply .= "deleted: $name\n";
    }
    $reply .= "\nEND\n\n";
  }
  elsif ($cmd eq "quit") {
    undef $reply;
    $handle->destroy();
  }
  else {
    $reply = "ERROR\n";
  }
  return $reply;
}

sub handle_manager_connection {
  my ($self, $handle, $line) = @_;
  #$logger->(notice => "Received mgmt command [$line]");
  if (my $reply = $self->handle_manager_command($handle, $line)) {
    $logger->(notice => "Sending mgmt reply [$reply]");
    $handle->push_write($reply);
    # Accept a new command on the same connection
    $handle->push_read(line => sub {
      handle_manager_connection($self, @_)
    });
  }
  else {
    $logger->(notice => "Shutting down socket");
    $handle->push_write("\n");
    $handle->destroy;
  }
}

sub init_backends {
  my ($self) = @_;
  my $backends = $self->config->{backends};
  if (! $backends or ref $backends ne 'ARRAY') {
    die "At least one backend is needed in your configuration";
  }
  for my $backend (@{ $backends }) {

    # Nodejs statsd expects a relative path
    if ($backend =~ m{^ \./backends/ (.+) $}x) {
      $backend = $1;
    }

    my $pkg = $backend;
    if ($backend =~ m{^ (\w+) $}x) {
      $pkg = ucfirst lc $pkg;
      $pkg = "Net::Statsd::Server::Backend::${pkg}";
    }
    my $mod = $pkg;
    $mod =~ s{::}{/}g;
    $mod .= ".pm";
    eval {
      require $mod ; 1
    } or do {
      $logger->(error=>"Backend ${backend} failed to load: $@");
      next;
    };
    $self->register_backend($pkg);
  }
}

sub init_logger {
  my ($self, $config) = @_;

  $config ||= {};

  my $backend = $config->{backend} || 'stdout';
  my $level = lc($config->{level} || 'LOG_INFO');
  $level =~ s{^log_}{};

  if ($backend eq 'stdout') {
    $AnyEvent::Log::FILTER->level($level);
  }
  elsif ($backend eq 'syslog') {
    # Syslog logging works commenting out the FILTER->level line
    $AnyEvent::Log::COLLECT->attach(
      AnyEvent::Log::Ctx->new(
        level         => $level,
        log_to_syslog => "user",
      )
    );
  }
  $logger ||= sub { AE::log(shift(@_), shift(@_)) };
}

sub logger {
  return $logger;
}

sub metrics {
  $_[0]->{metrics};
}

sub register_backend {
  my ($self, $backend) = @_;
  $self->{backends} ||= [];
  my $backend_instance = $backend->new(
    $self->_start_time_hi, $self->config,
  );
  $logger->(notice => "Initializing $backend backend");
  push @{ $self->{backends} }, $backend_instance;
}

sub foreach_backend {
  my ($self, $callback) = @_;
  my $backends = $self->{backends} || [];
  for my $obj (@{ $backends }) {
    eval {
      $callback->($obj); 1;
    } or do {
      $logger->(error => "Failed callback on $obj backend: $@");
    };
  }
}

sub reload_config {
  my ($self) = @_;
  delete $self->{config};
  $logger->(warn => "Received SIGHUP: reloading configuration");
  return $self->{config} = $self->config();
}

sub setup_flush_timer {
  my ($self) = @_;

  my $flush_interval = $self->config->{flushInterval}
    || DEFAULT_FLUSH_INTERVAL;

  $flush_interval = $flush_interval / 1000;
  $logger->(notice => "metrics flush will happen every ${flush_interval}s");

  my $flush_t = AE::timer $flush_interval, $flush_interval, sub {
    $self->flush_metrics
  };

  return $flush_t;
}

sub _defined_or { defined $_[0] ? $_[0] : $_[1] }

sub setup_keyflush_timer {
  my ($self) = @_;

  my $conf_kf = $self->config->{keyFlush};
  my $kf_interval = _defined_or($conf_kf->{interval}, 0);
  return if $kf_interval <= 0;

  # Always milliseconds in the config!
  $kf_interval /= 1000;

  my $kf_pct = _defined_or($conf_kf->{percent}, 100);
  my $kf_log = $conf_kf->{log};

  $logger->(notice => "flushing top ${kf_pct}% keys to "
    . ($kf_log || "stdout")
    . " every ${kf_interval}s"
  );

  my $kf_timer = AE::timer $kf_interval, $kf_interval, sub {
    $self->flush_top_keys()
  };

  return $kf_timer;
}

sub flush_top_keys {
  my ($self) = @_;

  my $conf_kf = _defined_or($self->config->{keyFlush}, {});
  my $kf_interval = _defined_or($conf_kf->{interval}, 0);
  $kf_interval /= 1000;

  my $kf_pct = $conf_kf->{percent} || 100;
  my $kf_log = $conf_kf->{log};

  my @sorted_keys;
  my $key_counter = $self->metrics->{keyCounter};
  while (my ($k, $v) = each %{ $key_counter }) {
    push @sorted_keys, [ $k, $v ];
  }

  @sorted_keys = sort { $b->[1] <=> $a->[1] } @sorted_keys;

  my @time = localtime;
  my $time_str = sprintf "%04d-%02d-%02d %02d:%02d:%02d",
    $time[5] + 1900, $time[4] + 1, $time[3],
    $time[2], $time[1], $time[0];

  my $log_message = "";

  # Only show the top keyFlush.percent keys
  my $top_pct_limit = int(scalar(@sorted_keys) * $kf_pct / 100);
  for my $i (0 .. $top_pct_limit - 1) {
    $log_message .= sprintf "$time_str count=%d key=%s\n",
      $sorted_keys[$i][1], $sorted_keys[$i][0];
  }

  if ($kf_log) {
    if (open my $log_fh, '>>', $kf_log) {
      $log_fh->printflush($log_message);
      $log_fh->close();
    }
  } else {
    print $log_message;
  }

  # Clear the counters
  $self->metrics->{keyCounter} = {};

}

sub init_metrics {
  my ($self) = @_;
  my $config = $self->config;
  $self->{metrics} = Net::Statsd::Server::Metrics->new($config);
  return $self->{metrics};
}

sub start_server {
  my ($self, $config) = @_;

  if (! defined $config) {
    $config = $self->config();
  }

  $self->init_logger($config->{log});

  my $host = $config->{address} || '0.0.0.0';
  my $port = $config->{port}    || 8125;

  my $mgmt_host = $config->{mgmt_address} || '0.0.0.0';
  my $mgmt_port = $config->{mgmt_port}    || 8126;

  $self->init_backends();
  $self->init_metrics();

  # Statsd clients interface (UDP)
  $self->{server} = AnyEvent::Handle::UDP->new(
    bind => [$host, $port],
    on_recv => sub {
      my ($data, $ae_handle, $client_addr) = @_;
      #$logger->(debug => "Got data=$data self=$self");
      $self->handle_client_packet($data);
    },
  );

  # Bump up SO_RCVBUF on UDP socket, to buffer up incoming
  # UDP packets, to avoid significant packet loss under load.
  # Read more: http://bit.ly/10eeFoE
  if (RECEIVE_BUFFER_MB > 0) {
      # On some systems this could fail (cpantesters reports)
      # Have it emit a warning instead of throwing an exception
      setsockopt($self->{server}->fh, SOL_SOCKET,
        SO_RCVBUF, RECEIVE_BUFFER_MB * 1048576)
          or warn "Couldn't set SO_RCVBUF: $!";
  }

  # Management interface (TCP, for 'stats' command, etc...)
  $self->{mgmtServer} = AnyEvent::Socket::tcp_server $mgmt_host, $mgmt_port, sub {
    my ($fh, $host, $port) = @_
      or die "Unable to connect: $!";

    my $handle; $handle = AnyEvent::Handle->new(
      fh => $fh,
      on_error => sub {
        AE::log error => $_[2],
        $_[0]->destroy;
      },
      on_eof => sub {
        $handle->destroy;
        AE::log info => "Done.",
      },
    );

    $handle->push_read(line => sub {
      handle_manager_connection($self, @_)
    });
  };

  $logger->(notice => "statsd server started on ${host}:${port} (v${VERSION})"); 
  $logger->(notice => "manager interface started on ${mgmt_host}:${mgmt_port}");

  my $f_ti = $self->setup_flush_timer;
  my $kf_ti = $self->setup_keyflush_timer;

  # This will block waiting for
  # incoming connections (TCP) or packets (UDP)
  my $cv = AE::cv;
  $cv->recv();
}

sub stats {
  $_[0]->{stats};
}

sub trim {
  my $s = shift;
  return unless defined $s;
  $s =~ s{^\s+}{};
  $s =~ s{\s+$}{};
  return $s;
}

1;

__END__

=head1 NAME

Net::Statsd::Server - a Perl port of Flickr/Etsy's statsd metrics daemon

=head1 DESCRIPTION

For the statsd B<client> library, check out the C<Net::Statsd> module:

  https://metacpan.org/module/Net::Statsd

C<Net::Statsd::Server> is the B<server> component of statsd.
It implements a daemon that listens on a given host/port for incoming
UDP packets and dispatches them to whatever you want, including
B<Graphite> or your console. Look into the C<Net::Statsd::Server::Backend::*>
namespace to know all the possibilities, or write a backend yourself.

=head1 USES

So, what do you use a C<statsd> daemon for?
You use it to track metrics of all sorts.

Background information here:

  http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/

=head1 MOTIVATION

Why did I do this? There's already a gazillion implementations of
statsd. The original Perl one from Cal Henderson/Flickr was not released
as a complete working software AFAIK:

  https://github.com/iamcal/Flickr-StatsD

then Etsy rewrote it as Javascript to run under node.js.
Other implementations range from C to Python, etc...

I wrote one in Perl for a few reasons:

=over 4

=item *

Because I don't like adding node.js to our production stack just to run statsd.

=item *

to learn how statsd was put together

=item *

to learn AnyEvent

=item *

to learn how to build a high performance UDP server

=item *

to have some good fun

=back

Basically, to learn :-)

=head1 HOW TO USE THIS MODULE

You shouldn't need any instructions to use it.
It comes with batteries included.

There is a C<bin/statsd> script included in the CPAN
distribution, together with a bunch of example configuration
files that should get you up and running in no time.

This statsd script basically does exactly what the Etsy
statsd javascript version does. It's a drop-in replacement.

I have tried to keep compatibility with the node.js version
of statsd as much as I could, so you can literally use the
same configuration files, bar a conversion from javascript
to JSON format.

You can also consult the node-statsd documentation, up
on Github as well:

  https://github.com/etsy/statsd

=head1 CONFIGURATION

To have an idea of the compability between the Javascript
statsd server and this Perl version, you can have a look
at the example configuration file bundled with this distribution
under C<bin/localConfig.js>, or here:

  https://github.com/cosimo/perl5-net-statsd-server/blob/master/bin/localConfig.js

You will find all the Perl statsd supported (known working)
configuration keys documented there. If an option is supported
and working, it will always behave exactly as the Javascript
version of statsd, unless there's bugs of course.

B<Anything not documented there will probably not work at all>.

=head1 AUTHORS

Cosimo Streppone, E<lt>cosimo@cpan.orgE<gt>

=head1 COPYRIGHT

The Net::Statsd::Server module is Copyright (c) 2013 Cosimo Streppone.
All rights reserved.

You may distribute under the terms of either the GNU General
Public License or the Artistic License, as specified in the
Perl 5.10.0 README file.

=head1 CONTRIBUTING

If you want to send patches or contribute, the easiest
way is to pull the source code repository hosted at Github:

  https://github.com/cosimo/perl5-net-statsd-server

=head1 ACKNOWLEDGEMENTS

Many thanks to my awesome wife that coped with
me trying to write this in a single weekend,
leaving barely any time for anything else.

Many thanks to my current employer, Opera Software, for
at least partly, sponsoring development of this module.
Technically, Opera is sponsoring me trying it in production :-)

=cut
