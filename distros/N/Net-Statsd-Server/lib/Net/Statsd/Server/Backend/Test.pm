#
# Test statsd backend to write Graphite-like
# flushed statistics to a given file.
#
# To enable this backend, include 'test' in the backends
# configuration array:
#
#   "backends": ["test"],
#
# This backend supports the following config options:
#
#   outputFile: file where to flush statistics (in append mode)
#

package Net::Statsd::Server::Backend::Test;
$Net::Statsd::Server::Backend::Test::VERSION = '0.20';
use 5.008;
use strict;
use warnings;
use base qw(Net::Statsd::Server::Backend::Graphite);

sub post_stats {
  my ($self, $stat_list) = @_;

  my $dump_file = $self->{config}->{outputFile};
  if (! $dump_file or (-e $dump_file && ! -w $dump_file)) {
    die "Can't write to dump file '$dump_file': $!";
  }

  my $stat_string = $self->stats_to_string($stat_list);

  eval {
    open my $dump_fh, '>>', $dump_file;
    say $dump_fh join(" ", "#", time, "stats flush");
    say $dump_fh $stat_string;
    close $dump_fh;
    $self->{lastFlush} = [Time::HiRes::gettimeofday];
  }
  or do {
    if ($self->{debug}) {
      # TODO use logger!
      warn("Exception while posting stats to file $dump_file: $@");
    }
    $self->{lastException} = [Time::HiRes::gettimeofday];
  };

}

1;
