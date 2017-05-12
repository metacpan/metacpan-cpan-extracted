################################################################################

use strict;
use POSIX qw(mktime);
use StatsView::Graph;
package StatsView::Graph::Iostat;
@StatsView::Graph::Iostat::ISA = qw(StatsView::Graph);

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
$line =~ /^\s*extended\s+(device|disk)\s+statistics\s*$/i || return(undef);

my $self = $class->SUPER::init($file);
return($self);
}

################################################################################

sub read($)
{
my ($self) = @_;
$self->SUPER::read();

# Open the file
my $iostat = IO::File->new($self->{file}, "r")
   || die("Can't open $self->{file}: $!\n");
$self->{title} = "Iostat Statistics";

# Look for the start/interval line
my $line;
while (defined($line = $self->getline($iostat)) && $line =~ /^\s*$/) { }
$line =~ /start:/i  && $line =~ /interval:/i
   || die("$self->{file} is not an iostat file (1)\n");
$line =~ m!interval:\s+(\d+)!i;
$self->{interval} = $1;
$line =~ m!start:\s+(\d\d/\d\d/\d\d(?:\d\d)?)\s+(\d\d:\d\d:\d\d)!i;
my ($D, $M, $Y) = split(/\//, $1);
my ($h, $m, $s) = split(/:/, $2); 
$M--;
if ($Y >= 100) { $Y -= 1900; }
elsif ($Y <= 50) { $Y += 100; }
$self->{start} = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1)
               + $self->{interval};

# Look for the first header line
while (defined($line = $self->getline($iostat)) && $line =~ /^\s*$/) { }
$line =~ /^\s*extended\s+(device|disk)\s+statistics\s*$/i
   || die("$self->{file} is not an iostat file (2)\n");
$line = $self->getline($iostat);
die("$self->{file} is not a iostat file (3)\n") if (! $line);

# Figure out where the device name is & get rid of it
my @colname = split(' ', $line);
my $dev_pos;
if ($colname[0] eq 'device' || $colname[0] eq 'disk')
   {
   shift(@colname);
   $dev_pos = "first";
   }
else
   {
   pop(@colname);
   $dev_pos = "last";
   }

# Figure out the column types - N = numeric, % = percentage
my @coltype;
foreach my $c (@colname)
   { push(@coltype, $c =~ /%/ ? '%' : 'N'); }
$self->define_cols(\@colname, \@coltype);

# Skip to the start of the second header -
# the data after the first is info from the last reboot to the present
while (defined ($line = $self->getline($iostat))
       && $line !~ /extended\s+(device|disk)\s+statistics/i) { }
die("$self->{file} is not a iostat file (3)\n") if (! $line);

# Work out the timestamp initial values
my $tstamp = $self->{start};
my $interval = $self->{interval};
while (defined($line = $self->getline($iostat)))
   {
   # Read the data
   while (defined($line = $self->getline($iostat))
          && $line !~ /extended/ && $line !~ /^\s*$/)
      {
      my (@value) = split(' ', $line);
      my $inst = $dev_pos eq "first" ? shift(@value) : pop(@value);

      # Ignore slice and NFS data
      if ($inst !~ /,\w$|s\d$|:|^nfs/)
         {
         $self->define_inst($inst);
         push(@{$self->{data}{$inst}}, { tstamp => $tstamp,
                                         value => [ @value ] });
         }
      }
   $tstamp += $interval;
   }
$self->{finish} = $tstamp - $interval;
$iostat->close();
}

################################################################################

sub get_data_type($;$)
{
return("3d");
}

################################################################################
1;
