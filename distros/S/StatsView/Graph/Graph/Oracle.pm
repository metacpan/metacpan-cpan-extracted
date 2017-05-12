################################################################################

use strict;
use POSIX qw(mktime);
use StatsView::Graph;
package StatsView::Graph::Oracle;
@StatsView::Graph::Oracle::ISA = qw(StatsView::Graph);
   
################################################################################

sub new()
{
my ($class, $file, $fh) = @_;
$class = ref($class) || $class;

# Look for the header line
my $line;
while (defined($line = $fh->getline()) && $line =~ /^\s*$/) { }
$line =~ /Oracle Statistics File/ || return(undef);

# Read in all the categories
my $title;
my $self = $class->SUPER::init($file);
while (defined($line = $fh->getline()) && $line !~ /^\s*Data\s+/)
   {
   if ($line =~ /^Title:\s*(.*)/)
      {
      $title = $1;
      $line = $fh->getline();
      my ($tag, $type) = $line =~ /Statistics:\s*(\w+)\s+(\w+)/;
      $type = ($type eq 'singlerow') ? '2d' : '3d';
      $self->{info}->{$title} = { tag => qr/^$tag\s+(.*)/, type => $type};
      push(@{$self->{category}}, $title)
      }
   }

# Check the data tag line
die("$file is not a Oracle Statistics file (1)\n")
   if ($line !~ /^\s*Data\s+rate:\s+\d+/);

return($self);
}

################################################################################

sub read($$)
{
my ($self, $category) = @_;
$self->SUPER::read($category);

# Open the file
my $oracle = IO::File->new($self->{file}, "r")
   || die("Can't open $self->{file}: $!\n");
$self->{title} = "Oracle $category";

# Look for the banner line
my $line;
while (defined($line = $oracle->getline()) && $line =~ /^\s*$/) { }
$line =~ /Oracle Statistics File created on (\d\d\/\d\d\/\d\d(?:\d\d)?)/
   || die("$self->{file} is not a Oracle Statistics file (2)\n");

# Look for the header for the category
my ($tag, $type) = @{$self->{info}->{$category}}{qw(tag type)};
my ($headings, $formats);
while (defined($line = $oracle->getline()) && $line !~ /^\s*Data\s+/)
   {
   if ($line =~ /Title:\s*$category/)
      {
      $line = $oracle->getline();   # Skip Statistics: line
      $line = $oracle->getline();
      ($headings) = $line =~ /Headings:\s*(.*)/;
      $line = $oracle->getline();
      ($formats) = $line =~ /Formats:\s*(.*)/;
      }
   }

# Define the column types - N = numeric, % = percentage
my @colname = split(',', $headings);
my @coltype = split('', $formats);
$self->define_cols(\@colname, \@coltype);

# Store the interval information
$line =~ /^\s*Data\s+rate:\s+(\d+)\s*$/
   || die("$self->{file} is not a Oracle Statistics file (3)\n");
$self->{interval} = $1;

# Read in the data values
my $tstamp;
my $first_ts = 1;
while (defined($line = $oracle->getline()))
   {
   chomp($line);
   if ($line =~ $tag)
      {
      my ($D, $M, $Y, $h, $m, $s) = split(/[\/: ]/, $1);
      $M--; $Y -= 1900;
      $tstamp = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1);
      push(@{$self->{tstamps}}, $tstamp);
      if ($first_ts) { $self->{start} = $tstamp; $first_ts = 0; }
      if ($type eq '2d')
         {
         $line = $oracle->getline(); chomp($line);
         my @value = split(',', $line);
         push(@{$self->{data}}, { tstamp => $tstamp, value => [ @value ] });
         }
      else
         {
         while (defined($line = $oracle->getline()) && $line !~ /^\s*$/)
            {
            chomp($line);
            my ($inst, @value) = split(',', $line);
            $self->define_inst($inst);
            push(@{$self->{data}{$inst}},
                 { tstamp => $tstamp, value => [ @value ] });
            }
         }
      }
   }

# Save the finish time
$self->{finish} = $tstamp;

$oracle->close();
}

################################################################################

sub get_data_type($;$)
{
my($self, $category) = @_;
return($self->{info}->{$category}->{type});
}

################################################################################
1;
