use strict;

use POE;
use FindBin qw($Bin);
use File::Path;
use Path::Class qw/dir file/;
use Test::More tests => 4;
use POE::Component::DirWatch::New no_aio => 1;

my %FILES = (foo => 1, bar => 1);
my $DIR   = dir($Bin, 'watch');
my $state = 0;
my %seen;

POE::Session->create
  (
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

my $watcher;
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

  $watcher =  POE::Component::DirWatch::New->new
    (
     alias      => 'dirwatch_test',
     directory  => $DIR,
     file_callback   => \&file_found,
     interval   => 2,
    );
}

sub _tstop{
  ok(File::Path::rmtree("$DIR"), 'Proper cleanup detected');
}

sub file_found{
  my ($file) = @_;
  ok(exists $FILES{$file->basename}, 'correct file');
  ++$seen{$file->basename};

  # don't loop
  if (++$state == keys %FILES) {
    is_deeply(\%FILES, \%seen, 'seen all files');
    $poe_kernel->state("endtest",  sub{ $_[KERNEL]->post(CharlieCard => '_endtest') });
    $poe_kernel->delay("endtest", 3);
  } elsif ($state > keys %FILES) {
    #File::Path::rmtree("$DIR");
    #die "We seem to be looping, bailing out\n";
  }
}

__END__
