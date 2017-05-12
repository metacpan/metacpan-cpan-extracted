use strict;
use warnings;
use blib;
use Test::Harness;
use File::Spec;
use File::Glob qw( bsd_glob );
use lib map { File::Spec->rel2abs($_) } qw( blib/lib blib/arch );

eval {
  require PkgConfig;
  print "\nTesting PkgConfig $PkgConfig::VERSION, Perl $], $^X\n";
};

my $cpu_count;

if(defined $ENV{NUMBER_OF_PROCESSORS})
{
  $cpu_count = $ENV{NUMBER_OF_PROCESSORS};
}
elsif(-r "/proc/cpuinfo")
{
  my $fh;
  open $fh, '<', '/proc/cpuinfo';
  $cpu_count = scalar grep /^processor\s/, <$fh>;
  close $fh;
}
elsif($^O eq 'darwin')
{
  $cpu_count = `sysctl -n hw.ncpu`;
  chomp $cpu_count;
}

if(defined $cpu_count && $cpu_count > 0)
{
  $cpu_count = 8 if $cpu_count > 8;
  print "Testing on $cpu_count CPUS\n";
  $ENV{HARNESS_OPTIONS} = "j$cpu_count";
}

Test::Harness::runtests(bsd_glob 't/*.t');
