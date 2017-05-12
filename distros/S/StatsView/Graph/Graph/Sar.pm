################################################################################

use strict;
use POSIX qw(mktime);
use StatsView::Graph;
package StatsView::Graph::Sar;
@StatsView::Graph::Sar::ISA = qw(StatsView::Graph);
   
%StatsView::Graph::Sar::info =
   (
   'Filesystem activity' => { flag    => '-a',
                              type    => '2d',
                              pattern =>  qr/iget/, },
   'Buffer activity'     => { flag    => '-b',
                              type    => '2d',
                              pattern =>  qr/bread/, },
   'System calls'        => { flag    => '-c',
                              type    => '2d' ,
                              pattern =>  qr/scall/, },
   'Disk IO'             => { flag    => '-d',
                              type    => '3d' ,
                              pattern =>  qr/device/, },
   'Paging (2)'          => { flag    => '-g',
                              type    => '2d' ,
                              pattern =>  qr/pgout/, },
   'Kernel memory'       => { flag    => '-k',
                              type    => '2d' ,
                              pattern =>  qr/sml_mem/, },
   'IPC'                 => { flag    => '-m',
                              type    => '2d' ,
                              pattern =>  qr/msg/, },
   'Paging (1)'          => { flag    => '-p',
                              type    => '2d' ,
                              pattern =>  qr/atch/, },
   'Run queue'           => { flag    => '-q',
                              type    => '2d' ,
                              pattern =>  qr/runq/, },
   'Free memory'         => { flag    => '-r',
                              type    => '2d' ,
                              pattern =>  qr/freemem/, },
   'CPU usage'           => { flag    => '-u',
                              type    => '2d' ,
                              pattern =>  qr/%usr/, },
   'Kernel table sizes'  => { flag    => '-v',
                              type    => '2d' ,
                              pattern =>  qr/proc-sz/, },
   'Swapping/Switching'  => { flag    => '-w',
                              type    => '2d' ,
                              pattern =>  qr/swpin/, },
   'TTY activity'        => { flag    => '-y',
                              type    => '2d' ,
                              pattern =>  qr/rawch/, },
   );


################################################################################
# Figure out what sort of data this line is a header for

sub classify_header($$)
{
my ($self, $line) = @_;
my ($desc, $inf);
while (($desc, $inf) = each(%StatsView::Graph::Sar::info))
   {
   last if ($line =~ $inf->{pattern});
   }
scalar(keys(%StatsView::Graph::Sar::info));   # reset the each() iterator
return($desc);
}

################################################################################
# Get the next line, ignoring state change lines

sub getline($$)
{
my ($self, $fh) = @_;
my $line;
while (defined($line = $fh->getline()) &&
       index($line, "<<State change>>") != -1)
   { }
return($line);
}

################################################################################

sub new($$$)
{
my ($class, $file, $fh) = @_;
$class = ref($class) || $class;

# Assume binary files are binary sar output
if (-B $file)
   {
   my $self = $class->SUPER::init($file);
   @{$self->{category}} = keys(%StatsView::Graph::Sar::info);
   $self->{reader} = sub { shift(@_)->read_binary(@_); };
   return($self);
   }
# Otherwise, check for the two possible text formats
else
   {
   # Look for the first header line
   my ($line, $type);
   while (defined($line = $class->getline($fh)) && $line !~ /^\d\d:\d\d:\d\d/)
      { }
   return(undef) if (! $line);

   # Not a sar file if the line is not a header
   $type = $class->classify_header($line) || return(undef);

   # Save the header type
   my $self = $class->SUPER::init($file);
   push(@{$self->{category}}, $type);
          
   # Peek at the next line.  If it too is a header, the format is hhdd
   $line = $self->getline($fh);
   if ($type = $self->classify_header($line))
      {
      push(@{$self->{category}}, $type);
      $self->{reader} = sub { shift(@_)->read_text_hhdd(@_); };

      # All the headers will be between here and the next blank line
      while (defined($line = $self->getline($fh)) && $line !~ /^\s*$/)
         {
         $type = $self->classify_header($line) || return(undef);
         push(@{$self->{category}}, $type);
         }
      }
   # Otherwise the format is hdhd
   else
      {
      $self->{reader} = sub { shift(@_)->read_text_hdhd(@_); };

      # Headers will be scattered throughout the file
      while (defined($line = $self->getline($fh)))
         {
         # Look for timestamp lines
         next if ($line !~ /^\d\d:\d\d:\d\d/);
         if ($type = $self->classify_header($line))
            {
            push(@{$self->{category}}, $type);
            }
         }
      }
   return($self);
   }
}

################################################################################

sub store_sample($$$$;$)
{
my ($self, $type, $tstamp, $line, $sar) = @_;

# Remove any timestamp
$line =~ s/^\d\d:\d\d:\d\d//;
push(@{$self->{tstamps}}, $tstamp) if ($line !~ /unix restarts/);

# 2d samples just live on one line
if ($type eq '2d')
   {
   # save no data for a restart line, otherwise save the fields
   my @value = $line =~ /unix restarts/ ? () : split(' ', $line);
   push(@{$self->{data}}, { tstamp => $tstamp, value => [ @value ] });
   }

# 3d samples live on multiple lines.  We have to guess where they end :-(
else
   {
   # If the line is a restart line, push an empty sample onto each instance
   if ($line =~ /unix restarts/)
      {
      foreach my $inst ($self->get_instances())
         {
         push(@{$self->{data}{$inst}}, { tstamp => $tstamp, value => [ ] });
         }
      return;
      }

   # Otherwise, process the first line of the sample point
   my ($inst, @value) = split(' ', $line);
   # Ignore slice and NFS data
   if ($inst !~ /,\w$|s\d$|^\w+:|^nfs/)
      {
      $self->define_inst($inst);
      push(@{$self->{data}{$inst}}, { tstamp => $tstamp, value => [ @value ] });
      }

   # Process all the subsequent lines of the sample point
   while (defined($line = $self->getline($sar)) && $line =~ /^\s*[a-z]/i)
      {
      ($inst, @value) = split(' ', $line);
      # Ignore slice and NFS data
      if ($inst !~ /,\w$|s\d$|^\w+:|^nfs/)
         {
         $self->define_inst($inst);
         push(@{$self->{data}{$inst}}, { tstamp => $tstamp,
                                         value  => [ @value ] });
         }
      }
   }
}

################################################################################
# Run queue stats use blanks instead of zeros, so split won't work

sub horrid_run_queue_hack($$$)
{
my ($self, $tstamp, $line) = @_;

# Remove any timestamp
$line =~ s/^\d\d:\d\d:\d\d//;
push(@{$self->{tstamps}}, $tstamp) if ($line !~ /unix restarts/);

my @value;
foreach my $v (unpack('A8A8A8A8', $line))
   {
   $v =~ s/\s+//g;
   $v = 0 if ($v eq '');
   push(@value, $v);
   }
push(@{$self->{data}}, { tstamp => $tstamp, value => [ @value ] });
}

################################################################################

sub scan_hdhd($$$)
{
my ($self, $sar, $category) = @_;
my ($type, $pattern) =
   @{$StatsView::Graph::Sar::info{$category}}{qw(type pattern)};
my $line;

# Look for the banner
while (defined ($line = $self->getline($sar)) && $line !~ /^SunOS/) { }
die("$self->{file} is not a sar file (1)\n") if (! $line);
my ($M, $D, $Y) = split(/\//, (split(' ', $line))[5]);
if ($Y >= 100) { $Y -= 1900; }
elsif ($Y <= 50) { $Y += 100; }
$M--;

# Look for the header line & get a list of column names
while (defined($line = $self->getline($sar)))
   {
   last if ($line =~ /^\d\d:\d\d:\d\d/ && $line =~ $pattern);
   }
die("$self->{file} is not a sar file (2)\n") if (! $line);
my @colname = split(' ', $line);
shift(@colname);                      # lose the timestamp
shift(@colname) if ($type eq '3d');   # and the instance for 3d data

# Figure out their types - N = numeric, % = percentage
my @coltype;
foreach my $c (@colname)
   { push(@coltype, $c =~ /%/ ? '%' : 'N'); }
$self->define_cols(\@colname, \@coltype);

# Read the data block up to the Averages part
my $last_tstamp = POSIX::mktime(0, 0, 0, $D, $M, $Y, 0, 0, -1);
my $tstamp;
my $sample = 1;
while (defined($line = $self->getline($sar)) && $line !~ /^Average/)
   {
   # Look for the start of the next sample point (a timestamp)
   next if ($line !~ /^(\d\d):(\d\d):(\d\d)/);
   my ($h, $m, $s) = ($1, $2, $3);
   $tstamp = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1);

   # Look for day rollover
   if ($tstamp < $last_tstamp)
      {
      $D++;
      $tstamp = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1);
      }

   # If this is the first sample, store the start time
   if ($sample == 1)
      { $self->{start} = $tstamp; $sample++; }
   # If this is the second sample, store the interval
   elsif ($sample == 2)
      { $self->{interval} = $tstamp - $last_tstamp; $sample++; }

   # Store the sample
   if ($category eq 'Run queue')
      { $self->horrid_run_queue_hack($tstamp, $line); }
   else
      { $self->store_sample($type, $tstamp, $line, $sar); }

   $last_tstamp = $tstamp;
   }
$self->{finish} = $tstamp;
}

################################################################################

sub read_binary($$)
{
my ($self, $category) = @_;

$self->{title} = "Sar $category";
my $sar =
   IO::File->new("sar $StatsView::Graph::Sar::info{$category}{flag} " .
                 "-f $self->{file} |")
   || die("Can't run sar: $!\n");
$self->scan_hdhd($sar, $category);
$sar->close();
die("$self->{file} is not a sar file\n") if (! defined($self->{data}));
return(1);
}

################################################################################

sub read_text_hdhd($$)
{
my ($self, $category) = @_;

$self->{title} = "Sar $category";
my $sar = IO::File->new($self->{file}, "r")
   || die("Can't open $self->{file}: $!\n");
$self->scan_hdhd($sar, $category);
$sar->close();
return(1);
}

################################################################################

sub read_text_hhdd($$)
{
my ($self, $category) = @_;
my $type = $StatsView::Graph::Sar::info{$category}{type};

$self->{title} = "Sar $category";
my $sar = IO::File->new($self->{file}, "r")
   || die("Can't open $self->{file}: $!\n");
my $line;

# Look for the banner
while (defined ($line = $self->getline($sar)) && $line !~ /^SunOS/) { }
die("$self->{file} is not a sar file (3)\n") if (! $line);
my ($M, $D, $Y) = split(/\//, (split(' ', $line))[5]);
if ($Y >= 100) { $Y -= 1900; }
elsif ($Y <= 50) { $Y += 100; }
$M--;

# Look for the headers
while (defined($line = $self->getline($sar)) && $line !~ /^\d\d:\d\d:\d\d/) { }
die("$self->{file} is not a sar file (4)\n") if (! $line);

# All the headers are in a block, terminated by a blank line.
# Find how far down the one we want is
my @skip;
while (defined($line) && $line !~ /^\s*$/)
   {
   # Classify the header & get it's type
   my $type = $self->classify_header($line);
   die("$self->{file} is not a sar file (5)\n") if (! $type);
   last if ($type eq $category);
   push(@skip, $StatsView::Graph::Sar::info{$type}{type});
   $line = $self->getline($sar);
   }

# Get a list of column names
die("$self->{file} is not a sar file (6)\n") if (! $line);
$line =~ s/^\d\d:\d\d:\d\d//;         # lose any timestamp
my @colname = split(' ', $line);
shift(@colname) if ($type eq '3d');   # lose the instance for 3d data

# Figure out their types - N = numeric, % = percentage
my @coltype;
foreach my $c (@colname)
   { push(@coltype, $c =~ /%/ ? '%' : 'N'); }
$self->define_cols(\@colname, \@coltype);

# Scan the file, up to the Averages block
my $last_tstamp = POSIX::mktime(0, 0, 0, $D, $M, $Y, 0, 0, -1);
my $tstamp;
my $sample = 1;
while (defined($line = $self->getline($sar)) && $line !~ /^Average/)
   {
   # Look for the start of the next sample point (a timestamp)
   next if ($line !~ /^(\d\d):(\d\d):(\d\d)/);
   my ($h, $m, $s) = ($1, $2, $3);
   $tstamp = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1);

   # Look for day rollover
   if ($tstamp < $last_tstamp)
      {
      $D++;
      $tstamp = POSIX::mktime($s, $m, $h, $D, $M, $Y, 0, 0, -1);
      }

   # If this is the first sample, store the start time
   if ($sample == 1) { $self->{start} = $tstamp; }
   # If this is the second sample, store the interval
   elsif ($sample == 2) { $self->{interval} = $tstamp - $last_tstamp; }

   # Skip lines up to the start of the info we want
   foreach my $hdr (@skip)
      {
      if ($hdr eq '2d')
         {
         $line = $self->getline($sar);
         }
      else
         {
         # Read up to the end of the data block.  Have to guess this :-(
         while (defined($line = $self->getline($sar))
                && $line =~ /^\s*[a-z]/i) { }
         }
      }
   # Deal gracefully with truncated files
   last if (! $line);

   # Store the sample
   if ($category eq 'Run queue')
      { $self->horrid_run_queue_hack($tstamp, $line); }
   else
      { $self->store_sample($type, $tstamp, $line, $sar); }

   $sample++;
   $last_tstamp = $tstamp;
   }
$self->{finish} = $tstamp;
$sar->close();
return(1);
}

################################################################################

sub read($$)
{
my ($self, $category) = @_;
die("Illegal category type $category\n")
   if (! exists($StatsView::Graph::Sar::info{$category}));
$self->SUPER::read($category);
return(&{$self->{reader}}($self, $category));
}

################################################################################

sub get_data_type($;$)
{
my ($self, $category) = @_;
return($StatsView::Graph::Sar::info{$category}{type});
}

################################################################################

1;
