#!/usr/bin/perl -w

# say no to copypasta!

use lib '../lib';
use Net::OnlineCode::GraphDecoder;


# give simple names to composite and check nodes
my @conames  = ('a' .. 'z');
my @chnames = ('A' .. 'Z');

local *colname = sub {
  my ($c,$coblocks) = @_;
  return ($c < $coblocks) ? $conames[$c] : $chnames[$c - $coblocks];
};

my @tests = (
	     {
	      t =>  "0 -- Simplest graph",
	      m =>  1,
	      a =>  1,
	      amap => [ [0] ],
	      checks => [
			 [0],
			],
	     },
	     {
	      t =>  "1 -- Random graph",
	      m =>  3,
	      a =>  1,
	      amap => [ [1] ],
	      checks => [
			 [0],
			 [1,3],
			 [1,2],
			 [2,3],
			 [0,3],
			],
	     },
	     {
	      t =>  "2 -- check auxiliary chaining",
	      m =>  1,
	      a =>  1,
	      amap => [ [0] ],
	      checks => [
			 [1],
			],
	     },
	     {
	      t =>  "3 -- simple check from notebook",
	      m =>  1,
	      a =>  1,
	      amap => [ [0] ],
	      checks => [
			 [0,1],
			 [1],
			],
	     },
	    );

for my $tref (@tests) {

  my ($t,$m,$a,$amap,$checks) = @$tref{qw(t m a amap checks)};

  print "Test # $t:\n";
  print "Message blocks: " . (join " ", @conames[0..$m-1]) . "\n";
  print "Auxiliary blocks ($a): \n";
  for my $i (1..$a) {
    my $mref=$amap->[$i-1];
    print "  $conames[$i + $m - 1] => " . (join " ", map { $conames[$_]} (@$mref)) . "\n";
  }
  print "\n";

  print "Creating object: ";

  my $o = Net::OnlineCode::GraphDecoder->new($m, $a, $amap);

  if (ref($o)) {
    print "OK\n";
  } else {
    print "(failed)\n";
    next;
  }

  print "Object dump:\n";
  print "Node\tNeighbours\n";
  for my $i (0..$m + $a -1) {
    my @array = @{$o->{neighbours}->[$i]};
    print colname($i,$m+$a) . " $i\t", join " ", @array, "\n";
  }
  print "\n";

  my ($done, @new_solved, @total_solved);

  for my $i (0..@$checks-1) {
    my $chref=$checks->[$i];

    print "Adding check block $i: ";
    print "$chnames[$i] => " . (join " ", map { $conames[$_]} (@$chref)) . "\n";

    my $index=$o->add_check_block($chref);

    print "Node\tNeighbours\n";
    for my $i (0..$index) {
      my @array = @{$o->{neighbours}->[$i]};
      print colname($i,$m+$a) . " $i\t", join " ", @array, "\n";
    }
    print "\n";

    print "Resolving: ";
    ($done, @new_solved) = $o->resolve($i + $a + $m);

    print ($done? "Done":"Not Done");
    print ", Newly Solved (".
      scalar(@new_solved) . "): " .
	join (" ", (map { $conames[$_]} (@new_solved)), 
	      (@new_solved ? '': '(none)')) . "\n";

    print "\n";


  }

  if ($done) {

    print "Solution:\n";

    for my $i (0..$m + $a - 1) {

      my $hashref = $o->xor_hash($i);
      #print "xor_hash returned a " . ref($hashref) . "\n";
      print $conames[$i] . " = ";

      print join " x ", map { colname($_,$m+$a) } sort keys %$hashref;
      #print " (" . (join " x ", sort keys %$hashref) . ")\n";
      print "\n";

    }
  }
}



