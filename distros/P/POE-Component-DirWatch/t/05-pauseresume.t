use strict;

use POE;
use FindBin     qw($Bin);
use File::Path;
use Path::Class qw/dir file/;
use Test::More  tests => 5;
use Time::HiRes;
use POE::Component::DirWatch;

my %FILES = (foo => 1);
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

  $kernel->alias_set("CharlieCard");
  # create a test directory with some test files
  File::Path::rmtree("$DIR");
  mkdir("$DIR", 0755) or die "can't create $DIR: $!\n";
  for my $file (keys %FILES) {
    my $path = file($DIR, $file);
    open FH, ">$path" or die "can't create $path: $!\n";
    close FH;
  }

  my $watcher =  POE::Component::DirWatch->new
    (
     alias      => 'dirwatch_test',
     directory  => $DIR,
     file_callback  => \&file_found,
     interval   => 1,
    );
}

sub _tstop{
  ok(File::Path::rmtree("$DIR"), 'Proper cleanup detected');
}

my $time;
sub file_found{
  if(++$state == 1){
    $time = time + 4;
    $poe_kernel->post(dirwatch_test => '_pause', $time);
  } elsif($state == 2){
    ok($time <= time, "Pause Until Works");
    $time = time + 4;
    $poe_kernel->post(dirwatch_test => '_pause');
        $poe_kernel->post(dirwatch_test => '_resume',$time);
  } elsif($state == 3){
    ok($time <= time, "Pause - Resume When Works");
    $time = time + 4;
    $poe_kernel->post(dirwatch_test => '_pause');
    $poe_kernel->post(dirwatch_test => '_resume',$time);
  } elsif($state == 4){
    ok($time <= time, "Resume When Works");
    $poe_kernel->post(dirwatch_test => 'shutdown');
  } else {
    File::Path::rmtree("$DIR");
    die "Something is wrong, bailing out!\n";
  }
}

__END__
