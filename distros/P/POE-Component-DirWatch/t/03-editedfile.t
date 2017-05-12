use strict;

use POE;
use FindBin     qw($Bin);
use File::Path  qw(rmtree);
use Path::Class qw/dir file/;
use Test::More  tests => 8;
use Time::HiRes;
use POE::Component::DirWatch::Modified;

use File::Signature;

my %FILES = (foo => 2, bar => 1);
my $DIR   = dir($Bin, 'watch');
my $state = 0;
my %seen;

POE::Session->create(
     inline_states =>
     {
      _start   => \&_tstart,
      _stop    => \&_tstop,
      _child   => sub {},
      _endtest => sub { $_[KERNEL]->post(dirwatch_test => 'shutdown') }
     },
    );

$poe_kernel->run();
exit 0;


sub _tstart {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  $kernel->alias_set("CharlieCard");
  # create a test directory with some test files
  File::Path::rmtree("$DIR");
  mkdir("$DIR", 0755) or die "can't create $DIR: $!\n";
  for my $file (keys %FILES) {
    my $path = file($DIR, $file);
    open FH, ">$path" or die "Can't create $path: $!\n";
    close FH;
  }

  my $watcher =  POE::Component::DirWatch::Modified->new
    (
     alias      => 'dirwatch_test',
     directory  => $DIR,
     file_callback  => \&file_found,
     interval   => 1,
    );

  diag("Not using AIO extension.") unless
    $watcher->does('POE::Component::DirWatch::Role::AIO');
}

sub _tstop{
  is_deeply(\%FILES, \%seen, 'seen all files');
  ok($seen{foo} == 2," Picked up edited file");
  ok(File::Path::rmtree("$DIR"), 'Proper cleanup detected');
}

sub file_found{
  my ($file) = @_;
  ok(exists $FILES{$file->basename}, 'correct file');
  ++$seen{$file->basename};
  $state++;

  if($state == (keys %FILES) ){
    my $path = file($DIR, 'foo');
    my $sig = File::Signature->new("$path");
    is(utime(undef, undef, "$path"), 1, "Succeeded in touching $path");
    ok($sig->changed, "File signature did indeed change");
  } elsif ($state == (keys %FILES) + 1 ) {
    $poe_kernel->state("endtest",  sub{ $_[KERNEL]->post(CharlieCard => '_endtest') });
    $poe_kernel->delay("endtest", 3);
  } elsif ($state > (keys %FILES) + 1 ) {
    File::Path::rmtree("$DIR");
    die "We seem to be looping, bailing out\n";
  }
}

__END__
