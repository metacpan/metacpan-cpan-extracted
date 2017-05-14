#!/usr/bin/perl

system("clear");
use Benchmark;

# declare array
$howmany = 1250000;

my @array = ();
$array[$howmany] = 0;

# start timer
$start = new Benchmark;


for ($x=0; $x<=$howmany; $x++)
{
      my $val = $array[$x];
}

# end timer
$end = new Benchmark;

# calculate difference
$diff = timediff($end, $start);

# report
print "for howmany:: Time taken was ", timestr($diff, 'all'), " seconds\n";


# declare array
$howmany = 1250000;

my @array = ();
$array[$howmany] = 0;

# start timer
$start = new Benchmark;


for ($x=0; $x<=$#array; $x++)
{
      my $val = $array[$x];
}

# end timer
$end = new Benchmark;

# calculate difference
$diff = timediff($end, $start);

# report
print "for \$#array:: Time taken was ", timestr($diff, 'all'), " seconds\n";



# declare array
$howmany = 1250000;

my @array = ();
$array[$howmany] = 0;

# start timer
$start = new Benchmark;


foreach (@array)
{
      my $val = $array[$x];
}

# end timer
$end = new Benchmark;

# calculate difference
$diff = timediff($end, $start);

# report
print "foreach array:: Time taken was ", timestr($diff, 'all'), " seconds\n";



# declare array
$howmany = 1250000;

my @array = ();
$array[$howmany] = 0;

# start timer
$start = new Benchmark;

my $count = 0;
while ($count<$#array)
{
  my $val = $array[$count];
 $count++;
}

# end timer
$end = new Benchmark;

# calculate difference
$diff = timediff($end, $start);

# report
print "while \$#array:: Time taken was ", timestr($diff, 'all'), " seconds\n";




# declare array
$howmany = 1250000;

my @array = ();
$array[$howmany] = 0;

# start timer
$start = new Benchmark;

my $count = 0;
while ($count<$howmany)
{
  my $val = $array[$count];
 $count++;
}

# end timer
$end = new Benchmark;

# calculate difference
$diff = timediff($end, $start);

# report
print "while howmany was Time taken was ", timestr($diff, 'all'), " seconds\n";




