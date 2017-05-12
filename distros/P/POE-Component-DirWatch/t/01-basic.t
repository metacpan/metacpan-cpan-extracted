use strict;

use POE;
use FindBin qw($Bin);
use File::Path;
use Path::Class qw/dir file/;
use Test::More  tests => 7;
use POE::Component::DirWatch;

my %FILES = (foo => 1, bar => 1);
my $DIR   = dir($Bin, 'watch');
my $state = 0;
my %seen;

POE::Session->create(
     inline_states =>
     {
      _start       => \&_tstart,
      _stop        => \&_tstop,
      _child       => sub {},
     },
    );

$poe_kernel->run();
ok(1, 'Proper shutdown detected');

exit 0;

sub _tstart {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  # create a test directory with some test files
  File::Path::rmtree("$DIR");
  mkdir("$DIR", 0755) or die "can't create $DIR: $!\n";
  for my $file (keys %FILES) {
    my $path = file($DIR, $file);
    open FH, ">$path" or die "can't create $path: $!\n";
    close FH;
  }

  my $callback = sub {
    my $file = shift;
    ok(exists $FILES{$file->basename}, 'correct file');
    ++$seen{$file->basename};

    # don't loop
    if (++$state == keys %FILES) {
      is_deeply(\%FILES, \%seen, 'seen all files');
      $poe_kernel->call(dirwatch_test => 'shutdown');
    } elsif ($state > keys %FILES) {
      File::Path::rmtree("$DIR");
      die "We seem to be looping, bailing out\n";
    }
  };

  my $watcher =  POE::Component::DirWatch->new
    (
     alias     => 'dirwatch_test',
     interval  => 1,
     file_callback => $callback,
     directory => $DIR,
    );

  ok($watcher->alias eq 'dirwatch_test', 'Alias successfully set');
  is($watcher->can('has') , undef , 'Is Moose has function exported? ');
}

sub _tstop{
  ok(File::Path::rmtree("$DIR"), 'Proper cleanup detected');
}

__END__
