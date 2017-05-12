################################################################################

use strict;
use POSIX qw(mktime);
use StatsView::Graph;
package StatsView::Graph::Vxstat;
@StatsView::Graph::Vxstat::ISA = qw(StatsView::Graph);
   
%StatsView::Graph::Vxstat::m2n =
   ( Jan =>  0, Feb =>  1, Mar =>  2, Apr =>  3, May =>  4, Jun =>  5,
     Jul =>  6, Aug =>  7, Sep =>  8, Oct =>  9, Nov => 10, Dec => 11 );

################################################################################

sub new($$$)
{
my ($class, $file, $fh) = @_;
$class = ref($class) || $class;

# Look for the header lines
my $line;
while (defined($line = $fh->getline()) && $line =~ /^\s*$/) { }
$line =~ /OPERATIONS\s+BLOCKS\s+AVG TIME\(ms\)/ || return(undef);
$line = $fh->getline();
$line =~ /TYP NAME\s+READ\s+WRITE\s+READ\s+WRITE\s+READ\s+WRITE/
   || return(undef);

# Find the first timestamp & figure out the format
my $self = $class->SUPER::init($file);
while (defined($line = $fh->getline()) && $line !~ /\d\d:\d\d:\d\d/) { }
my @l = split(/\s+|:/, $line);
if (@l == 7)
   {
   $self->{parsedate} = sub
      {
      my @d = split(/\s+|:/, $_[0]);
      $d[1] = $StatsView::Graph::Vxstat::m2n{substr($d[1], 0, 3)};
      $d[6] -= 1900;
      return(POSIX::mktime(@d[5,4,3,2,1,6], 0, 0, -1));
      };
   }
elsif (@l == 9)
   {
   $self->{parsedate} = sub
      {
      my @d = split(/\s+|:/, $_[0]);
      $d[2] = $StatsView::Graph::Vxstat::m2n{substr($d[2], 0, 3)};
      $d[3] -= 1900;
      if ($d[4] == 12) { $d[4] -= 12 if ($d[7] =~ /AM/i); }
      else { $d[4] += 12 if ($d[7] =~ /PM/i); }
      return(POSIX::mktime(@d[6,5,4,1,2,3], 0, 0, -1));
      };
   }
else
   { return(undef); }

return($self);
}

################################################################################

sub read($)
{
my ($self) = @_;
$self->SUPER::read();

# Open the file
my $vxstat = IO::File->new($self->{file}, "r")
   || die("Can't open $self->{file}: $!\n");
$self->{title} = "Veritas Statistics";

# Look for the header lines
my $line;
while (defined($line = $vxstat->getline()) && $line =~ /^\s*$/) { }
$line =~ /OPERATIONS\s+BLOCKS\s+AVG TIME\(ms\)/
   || die("$self->{file} is not a vxstat file (1)\n");
$line = $vxstat->getline();
$line =~ /TYP NAME\s+READ\s+WRITE\s+READ\s+WRITE\s+READ\s+WRITE/
   || die("$self->{file} is not a vxstat file (2)\n");

# Define the column types - N = numeric, % = percentage
$self->define_cols(['Read op/sec', 'Write op/sec',
                    'Read blk/sec', 'Write blk/sec',
                    'Avg read (ms)', 'Avg write (ms)' ],
                   [ qw(N N N N N N) ]);

# Skip to the start of the second timestamp -
# the data after the first is info from the last reboot to the present
my $parsedate = $self->{parsedate};
while (defined ($line = $vxstat->getline()) && $line !~ /\d\d:\d\d:\d\d/) { }
die("$self->{file} is not a vxstat file (3)\n") if (! $line);
my $first_ts = &$parsedate($line);

while (defined ($line = $vxstat->getline()) && $line !~ /^\s*$/) { }
die("$self->{file} is not a vxstat file (4)\n") if (! $line);

my $interval;
my $tstamp;
my $first = 1;
while (defined($line = $vxstat->getline()))
   {
   # Parse the timestamp
   $tstamp = &$parsedate($line);

   # If this is the first sample, store the start time
   if ($first)
      {
      $self->{start} = $tstamp;
      $interval = $self->{interval} = $tstamp - $first_ts;
      $first = 0;
      }

   # Read the data
   while (defined($line = $vxstat->getline()) && $line !~ /^\s*$/)
      {
      my (@value) = split(' ', $line);
      my $inst = shift(@value) . " " . shift(@value);

      # Scale values to be in units of a second
      @value[0..3] = map({ $_ / $interval } @value[0..3]);

      # Save the data
      push(@{$self->{data}{$inst}}, { tstamp => $tstamp, value => [ @value ] });
      $self->{instance}{$inst} = $self->{index_3d}++
         if (! exists($self->{instance}->{$inst}));
      }
   }
$self->{finish} = $tstamp;
$vxstat->close();
}

################################################################################

sub get_data_type($;$)
{
return("3d");
}

################################################################################
1;
