#!/usr/bin/perl -w

# Try to find examples of when codec.pl fails
#
# Basically, just run it a bunch of times and save any seeds that
# don't produce the correct output. It prints out the seed for any
# failed runs so that can be passed into codec.pl later to debug it.


my $blocksize=20;		# default block size argument
$blocksize = shift if @ARGV;	# or allow override

my $prog = './codec.pl';
$prog   = './codec' if -x './codec';

die "No codec.pl or codec in this directory!\n" unless -x $prog;

# Use the same message string and padding algorithm from codec.pl to
# figure out the expected output.

my $message    = 'The quick brown fox jumps over a lazy dog';
my $pad_length =  ($blocksize - length($message)) % $blocksize;
my $padding    = "x" x $pad_length;

my $expected = "Decoded text: '$message$padding'";

my $fails = 0;
my $trials = 1000;
for (1..$trials) {

  $op = `$prog $blocksize 2>/dev/null | perl -nle 'print if eof or /SEED/'`;

  my @lines = split "\n", $op;

  my $seed = shift @lines;
  chomp $seed; 
  $seed =~ s/.*SEED:\w+//;

  my $text = shift @lines; chomp $text;

  if ($text ne $expected) {
    ++$fails;
    # print "$seed\n$text\n";
    print "$seed\n";
  }
}

print "Failed $fails/$trials times (" . ((100 * $fails / $trials)) . "%)\n";
