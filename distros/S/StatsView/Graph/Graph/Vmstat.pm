################################################################################

use strict;
use POSIX qw(mktime);
use StatsView::Graph;
package StatsView::Graph::Vmstat;
@StatsView::Graph::Vmstat::ISA = qw(StatsView::Graph);
   
################################################################################

sub getline($$)
{
my ($self, $fh) = @_;
my $line;
while (defined($line = $fh->getline()) && $line =~ /<<State change>>/i) { }
return($line);
}

################################################################################

sub new($$$)
{
my ($class, $file, $fh) = @_;
$class = ref($class) || $class;

# Look for the start/interval line
my $line;
while (defined($line = $class->getline($fh)) && $line =~ /^\s*$/) { }
$line =~ /start:/i  && $line =~ /interval:/i || return(undef);

# Look for the first header line
while (defined($line = $class->getline($fh)) && $line =~ /^\s*$/) { }
$line =~ /^\s*procs\s+memory\s+page\s+disk\s+faults\s+cpu\s*$/i
   || return(undef);

my $self = $class->SUPER::init($file);
return($self);
}

################################################################################

sub read($)
{
my ($self) = @_;
$self->SUPER::read();

# Open the file
my $vmstat = IO::File->new($self->{file}, "r")
   || die("Can't open $self->{file}: $!\n");
$self->{title} = "Vmstat Statistics";
my ($line1, $line2);

# Look for the start/interval line
while (defined($line1 = $self->getline($vmstat)) && $line1 =~ /^\s*$/) { }
$line1 =~ /start:/i  && $line1 =~ /interval:/i
   || die("$self->{file} is not an vmstat file (1)\n");
$line1 =~ m!interval:\s+(\d+)!i;
$self->{interval} = $1;
$line1 =~ m!start:\s+(\d\d/\d\d/\d\d(?:\d\d)?)\s+(\d\d:\d\d:\d\d)!i;
my ($D, $M, $Y) = split(/\//, $1);
my ($h, $m, $s) = split(/:/, $2);
$M--;
if ($Y >= 100) { $Y -= 1900; }
elsif ($Y <= 50) { $Y += 100; }
$self->{start} = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1)
               + $self->{interval};

# Look for the first header lines
while (defined ($line1 = $self->getline($vmstat))
       && $line1 !~ /^\s*procs\s+memory\s+page\s+disk\s+faults\s+cpu\s*$/i) { }
die("$self->{file} is not a vmstat file (2)\n") if (! $line1);
$line2 = $self->getline($vmstat);
die("$self->{file} is not a vmstat file (3)\n") if (! $line2);

# How many headers on line2 share a header from line1
my (@one2two) = (3, 2, 7, 4, 3, 3);

# Register the column types
my (@colname, @coltype);
my @h2 = split(' ', $line2);
foreach my $h1 (split(' ', $line1))
   {
   foreach my $h (splice(@h2, 0, shift(@one2two)))
      {
      push(@colname, "$h1:$h");
      push(@coltype, $h1 eq 'cpu' ? '%' : 'N');
      }
   }
$self->define_cols(\@colname, \@coltype);

# Skip the first data line, which is the values since the last reboot
$self->getline($vmstat);

# Work out the timestamp initial values
my $tstamp = $self->{start};
my $interval = $self->{interval};

# Read the data
while (defined($line1 = $self->getline($vmstat)))
   {
   # Skip header lines
   next if ($line1 =~ /^\s*procs/ || $line1 =~ /^\s*r b w/);

   # Save the data
   my (@value) = split(' ', $line1);
   push(@{$self->{data}}, { tstamp => $tstamp, value => [ @value ] });
   $tstamp += $interval;
   }
$self->{finish} = $tstamp;
$vmstat->close();
}

################################################################################

sub get_data_type($;$)
{
return("2d");
}

################################################################################
1;
