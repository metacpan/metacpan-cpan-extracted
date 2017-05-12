
use strict;
use warnings;

use Test::More;
plan skip_all => "Not for this OS" unless $^O eq "linux";

use Net::Prometheus::ProcessCollector::linux;

sub _find_metric
{
   my ( $name, @samples ) = @_;
   ( grep { $_->fullname eq $name } @samples )[0];
}

{
   my $collector = Net::Prometheus::ProcessCollector::linux->new;
   ok( defined $collector, '$collector is defined' );

   my @samples = $collector->collect;
   ok( scalar @samples, '$collector->collect gave some samples' );

   my $metric = _find_metric( "process_cpu_seconds_total", @samples );
   ok( $metric, 'found process_cpu_seconds_total' );

   my $sample = $metric->samples->[0];
   is( $sample->varname, "process_cpu_seconds_total", 'sample varname' );
   is_deeply( $sample->labels, [], 'sample labels' );
   ok( $sample->value > 0, 'sample value above zero' );
}

# overridden names
{
   my $collector = Net::Prometheus::ProcessCollector::linux->new(
      prefix => "prefix_process",
      labels => [ label => "value" ],
   );

   my @samples = $collector->collect;
   my $metric = _find_metric( "prefix_process_cpu_seconds_total", @samples );
   ok( $metric, 'found process_cpu_seconds_total' );

   my $sample = $metric->samples->[0];
   is_deeply( $sample->labels, [ label => "value" ], 'sample labels' );
}

done_testing;
