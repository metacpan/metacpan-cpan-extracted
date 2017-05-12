use strict;
use IO::File;
use IO::Dir;
use File::Basename;
use POSIX qw(strftime);

package StatsView::Graph;
use vars qw($VERSION @Constructors);
$VERSION="1.15";

################################################################################
# Terminology:
#    sample     - All data collected at a given point in tstamp
#    column     - A time-series of data, eg percentage busy 
#    instance   - An entity for which data is collected,
#                 eg disk drive, network interface, user, Oracle tablespace
#    data point - An individual numeric statistic value
#
# Data of 2 types can be held - 2-d or 3-d.  2-d data does not have any
# instance information, eg for CPU usage, total idle,usr,sys,wio.  3-d data has
# instance information, eg for CPU usage, idle,usr,sys by CPU.
#
# 2-d data is held as 
#    $self->{data}[0]{tstamp}
#    $self->{data}[0]{value}[0]
#                            :
#    $self->{data}[0]{value}[n]
#                  :
#    $self->{data}[m]{tstamp}
#    $self->{data}[m]{value}[0]
#                            :
#    $self->{data}[m]{value}[n]
#
# 3-d data is held as
#    $self->{data}{$i}[0]{tstamp}
#    $self->{data}{$i}[0]{value}[0]
#                                :
#    $self->{data}{$i}[0]{value}[n]
#                  :
#    $self->{data}{$i}[m]{tstamp}
#    $self->{data}{$i}[m]{value}[0]
#                                :
#    $self->{data}{$i}[m]{value}[n]
#
# where
#    $i = instance
#    m  = number of samples
#    n  = number of data points per sample

################################################################################
# PRIVATE

sub BEGIN
{
# Initialise the tmpfile index
$StatsView::Graph::tmpfile = 1;

# Search for and load in parser subclasses at run-time
foreach my $dir (@INC)
   {
   my $gd = "$dir/StatsView/Graph";
   next if (! -d $gd);
   next if (! defined(my $dh = IO::Dir->new($gd)));
   foreach my $g (grep(/\.pm$/, $dh->read()))
      {
      $g =~ s/\.pm//;
      $g = "StatsView::Graph::$g";
      my $ctor;
      eval "require $g; \$ctor = sub { ${g}->new(\@_); };" || die($@);
      push(@Constructors, $ctor);
      }
   $dh->close();
   }
}

################################################################################
# PRIVATE

sub reinit($;$)
{
my ($self, $cat) = @_;

# Set via define_cols method, called by child read method
$self->{colindex}    = undef; # Hash of col name => data index
$self->{coltype}     = undef; # Hash of col name => col type
                              #    D=date, T=text, N=number, %=percentage, 0-100

# Set by define_inst method, called by child read method
$self->{instance}    = undef; # For 3-d data - hash of instance => gnuplot index
$self->{index_3d}    = 0;     # A counter used to number 3d datasets

# Set by child read method
$self->{data}        = undef; # 2-d or 3-d array of data (see above for format)
$self->{start}       = 0;     # Start time of samples
$self->{interval}    = 0;     # Interval between samples
$self->{finish}      = 0;     # Finish time of samples
$self->{title}       = "";    # Title of graph

# Set by define method
$self->{plot_cat}    = $cat ? $cat : "none"; # Category of data to plot
$self->{plot_cols}   = undef; # Column(s) to plot (2d=arrayref, 3d=scalar)
$self->{plot_insts}  = undef; # Instance(s) to plot (2d=undef, 3d=arrayref)
$self->{plot_scale}  = undef; # Log/Normal scale to be used for plot
$self->{plot_start}  = undef; # Start time of plot
$self->{plot_finish} = undef; # Finish time of plot
}

################################################################################
# PRIVATE

sub _2d_plot($)
{
my ($self) = @_;
my ($cat, $cols) = @$self{qw(plot_cat plot_cols)};

# Output the data into a file, of this is the first time through
if (! $self->{tmpfile}{$cat})
   {
   my $fname = "/tmp/svtmp$$.$StatsView::Graph::tmpfile";
   $StatsView::Graph::tmpfile++;
   $self->{tmpfile}{$cat} = $fname;
   my $out = IO::File->new($fname, "w") || die("Can't open $fname: $!\n");
   my $last_was_blank = 1;
   foreach my $sample (@{$self->{data}})
      {
      my $val = $sample->{value};
      if (@$val > 0)
         {
         $out->print(POSIX::strftime("%d/%m/%Y %T",
                     localtime($sample->{tstamp})), "\t",
                     join("\t", @$val), "\n");
         $last_was_blank = 0;
         }
      elsif (! $last_was_blank)
         {
         $out->print("\n");
         $last_was_blank = 1;
         }
      }
   $out->close();
   }

# Clear the plot if no cols are selected
if (! @$cols)
   {
   $self->{gnuplot}->print("clear\n");
   return;
   }

# Set up the headers and scale
my $scale = $self->{plot_scale} eq "log" ? "logscale" : "nologscale";
$self->{gnuplot}->print("reset\nset title '", $self->get_title(), "'\n",
                        "set data style lines\nset $scale y\n",
                        "set xdata time\nset timefmt '%d/%m/%Y %H:%M:%S'\n",
                        "set xlabel 'Time'\nset format x '%H:%M:%S'\n");

# Figure out how many types of data we have
my %t;
@t{@{$self->{coltype}}{@$cols}} = @$cols;
my $plot_type = join('', sort(keys(%t)));
undef(%t);

if ($plot_type eq '%N')
   {
   $self->{gnuplot}->print("set y2range [0:100]\nset y2tics\n",
                           "set ytics nomirror\nset y2label '%'\n");
   }
else
   {
   $self->{gnuplot}->print("set rmargin 3\n");
   }
if ($plot_type eq '%')
   {
   $self->{gnuplot}->print("set yrange [0:100]\n");
   }

# Generate the plot command
$self->{gnuplot}->print("plot ['",
        POSIX::strftime("%d/%m/%Y %T", localtime($self->{plot_start})),
        "':'",
        POSIX::strftime("%d/%m/%Y %T", localtime($self->{plot_finish})),
        "'] ");
my $not_first = 0;
foreach my $col (@$cols)
   {
   my $index = $self->{colindex}{$col} + 3;
   $self->{gnuplot}->print(", ") if ($not_first);
   $self->{gnuplot}->print("'$self->{tmpfile}{$cat}' using 1:$index ");
   $self->{gnuplot}->print("axes x1y2 ")
      if ($plot_type ne '%' && $self->{coltype}{$col} eq '%');
   $self->{gnuplot}->print("title '$col'");
   $not_first = 1;
   }
$self->{gnuplot}->print("\n");
}

################################################################################
# PRIVATE

sub _3d_plot($)
{
my ($self) = @_;
my ($cat, $col, $insts) = @$self{qw(plot_cat plot_cols plot_insts)};

# Output the data into a file, of this is the first time through
if (! $self->{tmpfile}{$cat})
   {
   my $fname = "/tmp/svtmp$$.$StatsView::Graph::tmpfile";
   $StatsView::Graph::tmpfile++;
   $self->{tmpfile}{$cat} = $fname;
   my $out = IO::File->new($fname, "w") || die("Can't open $fname: $!\n");
   my @inst_order = sort({ $self->{instance}{$a} <=> $self->{instance}{$b} }
                         keys(%{$self->{instance}}));
   foreach my $inst_name (@inst_order)
      {
      my $last_was_blank = 1;
      foreach my $sample (@{$self->{data}{$inst_name}})
         {
         my $val = $sample->{value};
         if (@$val > 0)
            {
            $out->print(POSIX::strftime("%d/%m/%Y %T",
                        localtime($sample->{tstamp})),
                        "\t", join("\t", @$val), "\n");
            $last_was_blank = 0;
            }
         elsif (! $last_was_blank)
            {
            $out->print("\n");
            $last_was_blank = 1;
            }
         }
      $out->print("\n\n");
      }
   $out->close();
   }

# Clear the plot if no instances are selected
if (! @$insts)
   {
   $self->{gnuplot}->print("clear\n");
   return;
   }

# Set up the headers and scale
my $scale = $self->{plot_scale} eq "log" ? "logscale" : "nologscale";
$self->{gnuplot}->print("reset\nset title '", $self->get_title(), "'\n",
                        "set data style lines\nset ylabel '$col'\n",
                        "set xdata time\nset timefmt '%d/%m/%Y %H:%M:%S'\n",
                        "set $scale y\nset rmargin 3\n",
                        "set xlabel 'Time'\nset format x '%H:%M:%S'\n");

if ($self->{coltype}{$col} eq '%')
   {
   $self->{gnuplot}->print("set yrange [0:100]\n");
   }

# Generate the plot command
$self->{gnuplot}->print("plot ['",
        POSIX::strftime("%d/%m/%Y %T", localtime($self->{plot_start})),
        "':'",
        POSIX::strftime("%d/%m/%Y %T", localtime($self->{plot_finish})),
        "'] ");
my $not_first = 0;
foreach my $inst (@$insts)
   {
   my $index = $self->{colindex}{$col} + 3;
   $self->{gnuplot}->print(", ") if ($not_first);
   $self->{gnuplot}->print("'$self->{tmpfile}{$cat}' ",
                           "index $self->{instance}{$inst} ",
                           "using 1:$index title '$inst'");
   $not_first = 1;
   }
$self->{gnuplot}->print("\n");
}

################################################################################
# PRIVATE

sub _save_gnuplot($$$$)
{
my ($self, $file, $format, $orientation, $color) = @_;

my $cmd = "set terminal ";
CASE:
   {
   $format eq "postscript" and do
      {
      $cmd .= "postscript eps enhanced $color 10";
      last CASE;
      };
   $format eq "cgm" and do
      {
      $cmd .= "cgm $orientation $color 10";
      last CASE;
      };
   $format eq "mif" and do
      {
      $color = $color eq "color" ? "colour" : "monochrome";
      $cmd .= "mif $color polyline";
      last CASE;
      };
   $format eq "gif" and do
      {
      $cmd .= "gif medium";
      last CASE;
      };
   # default
      die("Unknown file format $format\n");
      last CASE;
   }

$self->{gnuplot}->print("$cmd\nset output '$file'\n");
$self->plot();
$self->{gnuplot}->print("set output\nset terminal x11\n");
}

################################################################################
# PRIVATE

sub _save_csv($$)
{
my ($self, $file) = @_;

my $csv = IO::File->new($file, "w") || die("Can't open $file: $!\n");
my ($cols, $start, $finish) = @$self{qw(plot_cols plot_start plot_finish)};

# 2-d data
if (! defined($self->{instance}))
   {
   $csv->print($self->get_title(), "\n\n");
   $csv->print("Time,", join(",", @$cols), "\n");
   my $fmt = join(',', @{$self->{coltype}}{@$cols});
   $fmt =~ s/%/%s%%/g;
   $fmt =~ s/[DTN]/%s/g;
   my @indices = @{$self->{colindex}}{@$cols};
   foreach my $sample (@{$self->{data}})
      {
      next if ($sample->{tstamp} < $start);
      last if ($sample->{tstamp} > $finish);
      $csv->printf("%s,$fmt\n",
                   POSIX::strftime("%d/%m/%Y %T", localtime($sample->{tstamp})),
                   @{$sample->{value}}[@indices]) if (@{$sample->{value}});
      }
   }
# 3-d data
else
   {
   my $insts = $self->{plot_insts};
   my $fmt = join(',', ($self->{coltype}{$cols}) x @$insts);
   $fmt =~ s/%/%s%%/g;
   $fmt =~ s/[DTN]/%s/g;

   # Invert the data so that all data for a given time is accessible
   my $first = 1;
   my %data;
   my $index = @{$self->{colindex}}{$cols};
   foreach my $inst_name (@{$self->{plot_insts}})
      {
      foreach my $sample (@{$self->{data}{$inst_name}})
         {
         my $tstamp = $sample->{tstamp};
         next if ($tstamp < $start);
         last if ($tstamp > $finish);
         $data{$tstamp}{$inst_name} = $sample->{value}[$index]
            if (@{$sample->{value}});
         }
      $first = 0;
      }

   # Print out the data
   $csv->print($self->get_title(), " - $cols\n\n");
   $csv->print("Time,", join(",", @$insts), "\n");
   foreach my $tstamp (sort(keys(%data)))
      {
      $csv->print(POSIX::strftime("%d/%m/%Y %T", localtime($tstamp)));
      foreach my $inst_name (@$insts)
         {
         my $value = $data{$tstamp}{$inst_name};
         $csv->print(",", $value ? $value : "0");
         }
      $csv->print("\n");
      }
   }
$csv->close();
}

################################################################################
# PRIVATE

sub DESTROY($)
{
my ($self) = @_;
if ($self->{gnuplot})
   {
   $self->{gnuplot}->print("quit\n");
   $self->{gnuplot}->close();
   }
foreach my $file (values(%{$self->{tmpfile}})) { unlink($file); }
$self->{tmpfile} = undef;
}

################################################################################
# PROTECTED

sub init($)
{
my ($class, $file) = @_;
$class = ref($class) || $class;
my $self =
   {
   # Set by base class
   file      => $file,      # Filename the data is stored in
   gnuplot   => undef,      # Filehandle of gnuplot session
   tmpfile   => undef,      # Names of gnuplot data files

   # Set by child new method
   category    => undef,    # List of data categories in file, undef = none
   };
bless($self, $class);
$self->reinit();
return($self);
}

################################################################################
# PROTECTED

sub read($;$)
{
my ($self, $cat) = @_;
my $class = ref($self) || $self;
$self->reinit($cat);
}

################################################################################
# PROTECTED

sub define_cols($\@\@)
{
my ($self, $colname, $coltype) = @_;
die("Mismatching col name/type lists\n") if (@$colname != @$coltype);
$self->{colindex} = {};
$self->{coltype} = {};
my ($col, $index);
$index = 0;
foreach $col (@$colname) { $self->{colindex}{$col} = $index++; }
foreach $col (@$colname) { $self->{coltype}{$col} = shift(@$coltype); }
}

################################################################################
# PROTECTED

sub define_inst($$)
{
my ($self, $inst) = @_;
$self->{instance}{$inst} = $self->{index_3d}++
   if (! exists($self->{instance}->{$inst}));
}

################################################################################
# PUBLIC Static method

sub new($)
{
my ($class, $file) = @_;
$class = ref($class) || $class;

# Check for nonexistent or empty files
die("$file doesn't exist\n") if (! -e $file);
die("$file is empty\n") if (-z $file);
my $fh = IO::File->new($file, "r") || die("Can't open $file: $!\n");

# Call each constructor in turn until one returns an object
my $self;
foreach my $ctor (@Constructors)
   {
   if ($self = &$ctor($file, $fh))
      {
      $fh->close();
      return($self);
      }
   $fh->seek(0, 0);
   }
$fh->close();
die("Unrecognised file $file\n");
}

################################################################################
# PUBLIC

sub define($;)
{
my ($self, %arg) = @_;

# Sort out the required scale
$self->{plot_scale} = $arg{scale} || "normal";
delete($arg{scale});

# Sort out the range of the plot
$self->{plot_start} = $arg{start} || $self->{start};
$self->{plot_finish} = $arg{finish} || $self->{finish};
die("Plot start time later than or equal to start time\n")
   if ($self->{plot_start} >= $self->{plot_finish}); 
delete(@arg{qw(start finish)});

# Check we are plottable
die("No data to plot\n") if (! defined($self->{data}));
die("No columns defined\n")
   if (! (defined($self->{colindex}) && defined($self->{coltype})));

# 2d data - expect a set of columns
if (! $self->{instance})
   {
   die("No columns to plot\n") if (! defined($arg{columns}));
   $self->{plot_cols}  = $arg{columns};
   delete($arg{columns});
   $self->{plot_insts} = undef;
   }
# 3d data - expect 1 column and a set of instances
else
   {
   die("No column to plot\n") if (! defined($arg{column}));
   die("No instances to plot\n") if (! @{$arg{instances}});
   $self->{plot_cols}  = $arg{column};
   $self->{plot_insts} = $arg{instances};
   delete(@arg{qw(column instances)});
   }

# Check there are no invalid arguments left
die("Invalid arguments " . join(", ", keys(%arg)) . "\n") if (keys(%arg));

# Start gnuplot, if required
if (! $self->{gnuplot})
   {
   $self->{gnuplot} = IO::File->new("| exec gnuplot -title '" .
                                    $self->get_title() . "' >/dev/null 2>&1")
#                                   $self->get_title() . "'")
      || die("Can't run gnuplot: $!\n");
   $self->{gnuplot}->autoflush(1);
   }
}

################################################################################
# PUBLIC

sub plot($)
{
my ($self) = @_;
$self->{instance} ? $self->_3d_plot() : $self->_2d_plot();
}

################################################################################
# PUBLIC

sub print($;)
{
my ($self, %arg) = @_;

# Default args
$arg{orientation} ||= "landscape";
$arg{color} ||= "color";

# Validate args
die("Illegal orientation $arg{orientation}\n")
   if ($arg{orientation} ne "landscape" && $arg{orientation} ne "portrait");
die("Illegal color $arg{color}\n")
   if ($arg{color} ne "monochrome" && $arg{color} ne "color");
die("No printer specified\n") if (! $arg{printer});
die("No printer type specified\n") if (! $arg{type});

my $cmd = "set terminal ";
my $type = $arg{type};
CASE:
   {
   $type eq "postscript" and do
      {
      $cmd .= "postscript $arg{orientation} enhanced $arg{color} 10";
      last CASE;
      };
   $type eq "laserjet ii" and do
      {
      $cmd .= "hpljii 300";
      last CASE;
      };
   $type eq "laserjet iii" and do
      {
      $cmd .= "pcl5 $arg{orientation} univers 10";
      last CASE;
      };
   # default
      die("Unknown printer type $type\n");
      last CASE;
   }

$self->{gnuplot}->print("$cmd\nset output '|$arg{printer}'\n");
$self->plot();
$self->{gnuplot}->print("set output\nset terminal x11\n");
}

################################################################################
# PUBLIC

sub save($;)
{
my ($self, %arg) = @_;

# Default args
$arg{orientation} ||= "landscape";
$arg{color} ||= "color";

# Validate args
die("Illegal orientation $arg{orientation}\n")
   if ($arg{orientation} ne "landscape" && $arg{orientation} ne "portrait");
die("Illegal color $arg{color}\n")
   if ($arg{color} ne "monochrome" && $arg{color} ne "color");
die("No file specified\n") if (! $arg{file});
die("No format type specified\n") if (! $arg{format});

if ($arg{format} eq 'csv')
   {
   $self->_save_csv($arg{file});
   }
else
   {
   $self->_save_gnuplot($arg{file}, $arg{format},
                        $arg{orientation}, $arg{color});
   }
}

################################################################################
# PUBLIC

sub get_data_type($;$)
{
my $self = shift;
my $class = ref($self) || $self;
die("No get_data_type method defined for class $class\n");
}

################################################################################
# PUBLIC

sub get_columns($)
{
my ($self) = @_;
return(sort({ $self->{colindex}{$a} <=> $self->{colindex}{$b} }
            keys(%{$self->{colindex}})));
}

################################################################################
# PUBLIC

sub get_instances($)
{
my ($self) = @_;
return() if (! $self->{instance});
return(sort(keys(%{$self->{instance}})));
}

################################################################################
# PUBLIC

sub get_times($)
{
my ($self) = @_;
return(@{$self}{qw(start interval finish)});
}

################################################################################
# PUBLIC

sub get_title($)
{
my ($self) = @_;
return($self->{title} . "  " .
       File::Basename::basename($self->{file}) . "  " .
       POSIX::strftime("%d/%m/%Y", localtime($self->{start})));
}

################################################################################
# PUBLIC

sub get_categories($)
{
my ($self) = @_;
if (! defined($self->{category})) { return(); }
else { return(@{$self->{category}}); }
}

################################################################################
# PUBLIC

sub get_file($)
{
my ($self) = @_;
return($self->{file});
}

################################################################################
1;
__END__

=head1 NAME

StatsView - Solaris performance data collection and graphing package

=head1 SYNOPSIS

   use StatsView::Graph;
   my $graph = StatsView::Graph->new("sar.txt");
   $graph->read("CPU usage");
   $graph->define(columns => [ "%idle" ]);
   $graph->save(file => "sar_idle_cpu.gif", format => "gif");

=head1 DESCRIPTION

StatsView::Graph is a package that was originally written for internal use
within the Sun UK Performance Centre.  It allows the display of the output of
the standard Solaris utilities sar, iostat, mpstat and vmstat, as well as the
output of vxstat if Veritas Volume Manager is in use.  It also supports the
iost+ utility (available as part of the CPAN Solaris::Kstat package), and the
output of the Oracle monitoring provided by the sv script. The sv script is
merely a GUI front-end around this pakage.

=head1 PREREQUISITES

This package requires gnuplot, at least version beta 340.  If you wish to
produce GIF plots you will also need a gnuplot that is built with support for
the GD GIF library.

=head1 TERMINOLOGY

 category   - A class of related data, for applications that
              collect more than one type of data at a time
              eg for sar, CPU utilisation, Disk IO etc
 column     - A time-series of data, eg %busy 
 instance   - An entity for which data is collected
              eg disk drive, Oracle tablespace
 sample     - All data collected at a given point in time
 data point - An individual statistic value
              eg reads/sec for disk c0t0d0 at 10:35:04

Data of 2 types can be displayed by StatsView - 2d or 3d.  2d data does not
have any instance information, eg for CPU usage, total idle, usr, sys, wio.
3d data has instance information, eg for Disk usage, reads/sec, writes/sec by
disk.

=head1 METHODS

=head2 new()

This takes a single argument, the name of a statistics file to open.  This can
be the output of one of the following commands:

   iost+                      - see the Solaris::Kstats module
   iostat -x                  - extended device statistics format
   Built-in Oracle monitoring - collected via sv
   sar                        - binary or text format
   vmstat                     - standard format
   mpstat                     - standard format
   vxstat                     - Veritas VM statistics

Note that iostat, mpstat and vmstat don't put timestamps in their output, thus
making it impossible to decide hown the data should be graphed.  To circumvent
this problem it is necessary to add a header line to the start of the data
files of the form:

   Start: 01/01/1998 12:00:00 Interval: 10

Giving the start of the sampling period in dd/mm/yyyy hh:mm:ss format and the
interval between samples in seconds.  This is done automatically if the data is
collected via the sv script.

=head2 read()

This reads in the data from the file.  For data files that contain more than
one category of data, the name of the category to read should be given as an
argument, eg for sar "CPU usage" or "Disk IO".  The get_categories() method can
be used to find out all the available categories - see below.

=head2 define()

This defines the parameters of the graph that is to be drawn.  It takes a list
of key-value parameter pairs.  Different parameters are supported depending on
whether the data is 2d or 3d.  Parameters allowed for both 2d and 3d data are:

   scale => "normal" | "logarithmic"

The default is "normal".

For 2d data the expected parameter is:

   columns => [ <list of columns to plot> ]

For 3d data the expected parameters are:

   column    => <column name>
   instances => [ <list of instances to plot> ]

The available columns and instances can be retrieved via the get_columns() and
get_instances() methods - see below.

=head2 plot()

This takes no arguments, and plots the currently defined graph to the screen.

=head2 print()

This prints the currently defined graph. It takes a list of key-value parameter
pairs.  Allowed parameters are:

   orientation => "landscape" | "portrait"   default: landscape
   color       => "monochrome" | "color"     default: color
   printer     => <printer command>          Eg "lp", "lp -d myprinter"
   type        => "postscript" | "laserjet ii" | "laserjet iii"

=head2 save()

This saves the currently defined graph to a file.  It takes a list of key-value
parameter pairs.  Allowed parameters are:

   orientation => "landscape" | "portrait"   default: landscape
   color       => "monochrome" | "color"     default: color
   file        => <output filename>
   format      => "csv"          comma-separated text
                | "postscript"   postscript format
                | "cgm"          Computer Graphics Metafile
                                 - For M$ Word, etc
                | "mif"          Framemaker
                | "gif"          requires gnuplot built with GD support

=head2 get_data_type()

This returns the type of the data in the file - either "2d" or "3d" (see 
TERMINOLOGY above).  For data files that contain more than obe category of
data, the name of a catogory should be supplied as an argument.

=head2 get_columns()

This returns a list of the available columns.

=head2 get_instances()

This returns a list of the available instances, for 3d data.  For 2d data it 
will return an empty list.

=head2 get_times()

This returns a 3 element list of (start time, sampling interval, end time).
Start and end time are expressed as a standard Unix 32-bit time value, and
the sampling interval is expressed in seconds.

=head2 get_title()

This returns the title that will be displayed at the top of the graph.

=head2 get_categories()

This will return a list of all the available categories, for files that contain
several categories of data.  For files that only contain 1 category of data it
will return an empty list.

=head2 get_file()

This returns the name of the data file that has been read in.

=head1 AUTHOR

Support questions and suggestions can be directed to Alan.Burlison@uk.sun.com

=head1 COPYRIGHT AND DISCLAIMER

Copyright (c) 1998 Alan Burlison

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the Perl README file, with the
exception that it cannot be placed on a CD-ROM or similar media for commercial
distribution without the prior approval of the author.

This code is provided with no warranty of any kind, and is used entirely at
your own risk.

This code was written by the author as a private individual, and is in no way
endorsed or warrantied by Sun Microsystems.

=cut
