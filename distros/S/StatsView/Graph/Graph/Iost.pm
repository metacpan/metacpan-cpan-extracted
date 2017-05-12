################################################################################

use strict;
use POSIX qw(mktime);
use StatsView::Graph;
package StatsView::Graph::Iost;
@StatsView::Graph::Iost::ISA = qw(StatsView::Graph);
   
################################################################################

sub new($$$)
{
my ($class, $file, $fh) = @_;
$class = ref($class) || $class;

# Look for the header line
my $line;
while (defined($line = $fh->getline()) && $line =~ /^\s*$/) { }
$line =~ /iost\+ started on/ || return(undef);

my $self = $class->SUPER::init($file);
return($self);
}

################################################################################

sub read($)
{
my ($self) = @_;
$self->SUPER::read();

# Open the file
my $iost = IO::File->new($self->{file}, "r")
   || die("Can't open $self->{file}: $!\n");
$self->{title} = "Iost+ Statistics";

# Look for the header line & get the date
my $line;
while (defined($line = $iost->getline()) && $line =~ /^\s*$/) { }
$line =~ /iost\+\ started\ on\ 
          (\d\d)\/(\d\d)\/(\d\d\d\d)\ 
          (\d\d):(\d\d):(\d\d)\ on\ (\S+),\ 
          sample\ interval\ (\d+)\ seconds/x
   || die("$self->{file} is not an iost+ file (1)\n");
my ($D, $M, $Y, $h, $m, $s, $host, $interval) = ($1, $2, $3, $4, $5, $6);
$self->{interval} = $8;
$M--; $Y -= 1900;
my $last_t = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1);
$self->{start} = $last_t + $self->{interval};

# Define the column types - N = numeric, % = percentage
$self->define_cols(['Read op/sec', 'Write op/sec',
                    'Read Kb/sec', 'Write Kb/sec',
                    'WaitQ/qlen', 'WaitQ/res_t', 'WaitQ/svc_t', 'WaitQ/%ut',
                    'ActiveQ/qlen', 'ActiveQ/res_t', 'ActiveQ/svc_t',
                    'ActiveQ/%ut'],
                   [ qw(N N N N N N N % N N N %) ]);

my $no_data = [ (0) x 12 ];
while (defined($line = $iost->getline()))
   {
   # Look for the start of the next sample point (a timestamp)
   next if ($line !~ /^(\d\d):(\d\d):(\d\d)/);
   ($h, $m, $s) = ($1, $2, $3);
   my $tstamp = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1);

   # Look for day rollover & save timestamp
   if ($tstamp < $last_t)
      {
      $D++;
      $tstamp = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1);
      }
   $last_t = $tstamp;

   # Skip the next header line
   $iost->getline();

   # Read the data & save away
   my %seen_insts;
   while (defined($line = $iost->getline()) && $line !~ /^\s*$|TOTAL|:\//)
      {
      my (@value) = split(' ', $line);
      my $inst = pop(@value);

      $self->define_inst($inst);
      push(@{$self->{data}{$inst}}, { tstamp => $tstamp, value => [ @value ] });
      $seen_insts{$inst} = 1;
      }

   # Add entries for any devices that were idle
   foreach my $inst (grep(! exists($seen_insts{$_}), $self->get_instances()))
      {
      push(@{$self->{data}{$inst}}, { tstamp => $tstamp, value => $no_data });
      }
   }
$self->{finish} = $last_t;
$iost->close();
}

################################################################################

sub get_data_type($;$)
{
return("3d");
}

################################################################################
1;
