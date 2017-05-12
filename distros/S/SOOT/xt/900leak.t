use strict;
use warnings;
use feature 'state';
use Test::More;
use SOOT;
use Time::HiRes qw/sleep/;
use List::Util 'shuffle';

use Proc::ProcessTable;
our $PTable = Proc::ProcessTable->new;

use constant DEF_LEAK_THRESHOLD => 1*1024*1024;
use constant DEF_ITERATIONS     => (@ARGV ? shift(@ARGV) : 1e5);

our %LeakTests = (
  type => {
    code       => \&leak_type,
  },
  cproto => {
    code       => \&leak_cproto,
  },
  tgraph_getn => {
    code       => \&leak_tgraph_getn,
    #iterations => 1e4,
  },
  tgraph_sethistogram => {
    code       => \&leak_tgraph_sethistogram,
  },
  newth1d => {
    code       => \&leak_newth1d,
  },
  newth1d_getaxis => {
    code       => \&leak_newth1d_getaxis,
  },
  tgraph_getx => {
    code       => \&leak_tgraph_getx,
    iterations => DEF_ITERATIONS()/2,
  },
  newtgraph_sub => {
    code       => \&leak_newtgraph_sub,
    iterations => DEF_ITERATIONS()/2,
  },
  th1d_getnbinsx => {
    code       => \&leak_th1d_getnbinsx,
  },
);

our @Tests;
BEGIN {
  @Tests = qw(
    type cproto tgraph_getn
    tgraph_sethistogram newth1d
    newth1d_getaxis tgraph_getx
    newtgraph_sub th1d_getnbinsx
  );
  #@Tests = shuffle(@Tests);
}

BEGIN { Test::More->import(tests => scalar(@Tests)+2); }
pass("alive");

foreach my $test (@Tests) {
  run_leak_test($test, $LeakTests{$test});
}

pass("alive");



sub run_leak_test {
  my $test_name = shift;
  my %test_spec = %{shift()};
  $test_spec{iterations}     ||= DEF_ITERATIONS;
  $test_spec{leak_threshold} ||= DEF_LEAK_THRESHOLD;

  diag("Running leak test '$test_name'");
  $test_spec{code}->(1); # warm up
  my $before_mem = get_mem();
  $test_spec{code}->($test_spec{iterations});
  my $after_mem = get_mem();
  my $delta_mem = $after_mem-$before_mem;

  diag(sprintf("Mem before: %.2fMB; Mem after: %.2f MB; Delta: %.2f MB; per iteration: %f bytes",
               $before_mem/1024/1024,
               $after_mem/1024/1024,
               $delta_mem/1024/1024,
               $delta_mem / $test_spec{iterations}));

  if ($delta_mem > $test_spec{leak_threshold}) {
    fail("MEMORY LEAKED IN TEST '$test_name'");
    #die "Stop: memory leak";
  }
  else {
    pass(sprintf("Not (enough) memory leaked in test '%s': %.2f MB", $test_name, $delta_mem/1024/1024));
  }
}


sub leak_type {
  my $iterations = shift;
  # doesn't leak at e19f62548881a14be485f8ed56c59a1d32f00d61 (2010-02-22)
  # doesn't leak at fe99b3f6e7ed25c3b9d4e6e388818f860445673c (GC)
  foreach (1..$iterations) {
    my $scalar;
    my $obj;
    $obj = bless(\$scalar => 'TObject');
    SOOT::API::type($obj);
    $obj = bless(\$scalar => 'TH1D');
    SOOT::API::type($obj);
    $obj = bless([] => 'TObject');
    SOOT::API::type($obj);
    $obj = bless([] => 'TH1D');
    SOOT::API::type($obj);
    $obj = bless({} => 'TObject');
    SOOT::API::type($obj);
    $obj = bless({} => 'TH1D');
    SOOT::API::type($obj);
    $obj = bless({} => 'Something::Else');
    SOOT::API::type($obj);
  }
}

sub leak_cproto {
  my $iterations = shift;
  # doesn't leak at fe99b3f6e7ed25c3b9d4e6e388818f860445673c (GC)
  foreach (1..$iterations) {
    my $scalar;
    my $obj;
    $obj = bless(\$scalar => 'TObject');
    SOOT::API::cproto($obj);
    $obj = bless(\$scalar => 'TH1D');
    SOOT::API::cproto($obj);
    $obj = bless([] => 'TObject');
    SOOT::API::cproto($obj);
    $obj = bless([] => 'TH1D');
    SOOT::API::cproto($obj);
    $obj = bless({} => 'TObject');
    SOOT::API::cproto($obj);
    $obj = bless({} => 'TH1D');
    SOOT::API::cproto($obj);
    $obj = bless({} => 'Something::Else');
    SOOT::API::cproto($obj);
  }
}



sub leak_tgraph_getn {
  my $iterations = shift;
  # doesn't leak at fe99b3f6e7ed25c3b9d4e6e388818f860445673c (GC)
  # doesn't leak at e19f62548881a14be485f8ed56c59a1d32f00d61 (2010-02-22)
  # doesn't leak 2010-02-17
  state $obj = TGraph->new(12, [(1.)x12], [(1.)x12]);
  foreach (1..$iterations) {
    my $n = $obj->GetN();
  }
}


sub leak_tgraph_sethistogram {
  my $iterations = shift;
  # doesn't leak at fe99b3f6e7ed25c3b9d4e6e388818f860445673c (GC)
  # doesn't leak at e19f62548881a14be485f8ed56c59a1d32f00d61 (2010-02-22)
  # doesn't leak 2010-02-17
  state $obj = TGraph->new(12);
  state $obj2 = TH1D->new("a","a",2,0.,1.);
  foreach (1..$iterations) {
    $obj->SetHistogram($obj2);
  }
}


sub leak_newth1d {
  my $iterations = shift;
  # FIXME LEAKS AT f89c7b85ac72a0c4381b87496d3e434352572f47
  # FIXME LEAKS AT 4a38fe3f7f59e106901c5938497dbaebd2abd691
  # FIXME LEAKS AT SOOT-0.06
  # doesn't leak at 521258e980d7fa7f34a96df4620943210121341a (GC heuristics)
  # FIXME LEAKS AT fe99b3f6e7ed25c3b9d4e6e388818f860445673c (GC)
  # FIXME LEAKS AT e19f62548881a14be485f8ed56c59a1d32f00d61 (2010-02-22)
  # doesn't leak 2010-02-17
  foreach (1..$iterations) {
    my $obj = TH1D->new("hist".$_, "hist".$_, 10, 0., 1.);
    undef $obj;
  }
}



sub leak_newth1d_getaxis {
  my $iterations = shift;
  # doesn't leak at 521258e980d7fa7f34a96df4620943210121341a (GC heuristics)
  # doesn't leak 2010-02-17
  foreach (1..$iterations) {
    my $obj = TH1D->new("hist".$_, "hist".$_, 10, 0., 1.);
    $obj->GetXaxis();
    undef $obj;
  }
}


sub leak_tgraph_getx {
  my $iterations = shift;
  # doesn't leak at 352c460d02845c0164d49443ce71154ef6c5e8ec (after GC heuristics)
  # doesn't leak at 521258e980d7fa7f34a96df4620943210121341a (GC heuristics)
  # doesn't leak 2010-02-20
  state $obj = TGraph->new(1e4, [(1.) x 1e4], [(2.) x 1e4]);
  foreach (1..$iterations) {
    my $x = $obj->GetX();
    undef $x;
  }
}


sub test_tgraph_getx {
  my $obj = TGraph->new(1e2, [(1.) x 1e2], [(2.) x 1e2]);
  undef $obj;
}
sub leak_newtgraph_sub {
  my $iterations = shift;
  # doesn't leak at 521258e980d7fa7f34a96df4620943210121341a (GC heuristics)
  # leaks like a sieve 2010-02-20 (despite the underlying object being deleted)
  # stops leaking with aada56a1b7564a4e4cdbe08fc6ec82bc3e92693c (2010-02-20)

  foreach (1..$iterations) {
    test_tgraph_getx(); 
  }
}


sub leak_th1d_getnbinsx {
  my $iterations = shift;
  # doesn't leak at 521258e980d7fa7f34a96df4620943210121341a (GC heuristics)
  # stops leaking with 4f8540b820a41eca097e8556d705f9220bd8dad7 (2010-02-20)
  state $obj = TH1D->new("blah", "blah", 10, 0., 1.);
  foreach (1..$iterations) {
    my $x = $obj->GetNbinsX();
    undef $x;
  }
}





sub get_mem {
  my $selfproc;
  foreach my $proc (@{$PTable->table}) {
    $selfproc = $proc, last if $proc->pid eq $$;
  }
  if (not defined($selfproc)) {
    die "Could not find my PID in the process table!";
  }
  return $selfproc->rss;
}

