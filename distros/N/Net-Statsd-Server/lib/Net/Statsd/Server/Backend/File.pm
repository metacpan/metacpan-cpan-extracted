# ABSTRACT: File backend for Net::Statsd::Server

package Net::Statsd::Server::Backend::File;
$Net::Statsd::Server::Backend::File::VERSION = '0.20';
use strict;
use warnings;
use base qw(Net::Statsd::Server::Backend);
use Time::HiRes ();

sub init {
  my ($self, $startup_time, $config) = @_;

  $self->{out_file} = $config->{file} && $config->{file}->{name};
  $self->{enabled} = defined $self->{out_file} ? 1 : 0;

  return;
}

sub flush {
  my ($self, $timestamp, $metrics) = @_;

  return unless $self->{enabled};

  my $str = "";

  for (keys %{ $metrics->{counters} }) {
    next if m{^statsd\.};
    $str .= sprintf "c\t%s\t%d\n", $_, $metrics->{counters}->{$_};
  }

  for (keys %{ $metrics->{timers} }) {
    next if m{^statsd\.};
    $str .= sprintf "t\t%s\t%.6f\n", $_, $metrics->{timers}->{$_};
  }

  for (keys %{ $metrics->{gauges} }) {
    next if m{^statsd\.};
    $str .= sprintf "g\t%s\t%.6f\n", $_, $metrics->{gauges}->{$_};
  }
  
  for (keys %{ $metrics->{sets} }) {
    next if m{^statsd\.};
    my $set_as_string = join(";", keys %{ $metrics->{sets}->{$_} });
    $str .= sprintf "s\t%s\t%s\n", $_, $set_as_string;
  }

  if ($str) {
    if (open my $fh, '>>', $self->{out_file}) {
      $fh->printflush($str) or do {
        $self->{lastException} = [Time::HiRes::gettimeofday];
      };
      $fh->close;
    }
  }

  $self->{lastFlush} = [Time::HiRes::gettimeofday];

}

sub status {
  my ($self) = @_;
  return {
    last_flush     => $self->since($self->{lastFlush}),
    last_exception => $self->since($self->{lastException}),
  };
}

1;
