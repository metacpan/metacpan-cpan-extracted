package RRDTool::Creator ;

# ============================================
# 
#           Jacquelin Charbonnel - CNRS/LAREMA
#  
#   $Id: Creator.pm 410 2008-03-11 21:45:09Z jaclin $
#   
# ----
#  
#   A generic abstract creator for round robin databases (RRD)
# 
# ----
#   $LastChangedDate: 2008-03-11 22:45:09 +0100 (Tue, 11 Mar 2008) $ 
#   $LastChangedRevision: 410 $
#   $LastChangedBy: jaclin $
#   $URL: https://svn.math.cnrs.fr/jaclin/src/pm/RRDTool-Creator/Creator.pm $
#  
# ============================================

require Exporter ;
@ISA = qw(Exporter);
@EXPORT=qw() ;

use Carp ;
use RRDTool::OO ;
use strict ;
use warnings ;

our $VERSION = "1.0" ; # $LastChangedRevision: 410 $
$Carp::CarpLevel = 1;

my $InSeconds = {
    "s" => 1
    , "mn" => 60
    , "h" => 60*60
    , "d" => 60*60*24
    , "w" => 60*60*24*7
    , "m" => 60*60*24*30        # supposed 30 days
    , "q" => 60*60*24*30*3      # 3 months
    , "y" => 60*60*24*30*12     # 12 months
    } ;

sub _getkey
{
  my ($key) = @_ ;
  $Carp::CarpLevel = 2 ;
  
  my @keys = grep /^$key/i,keys %$InSeconds ;
  croak "unknown '$key' unit" if scalar(@keys)==0 ;
  croak "ambigous '$key' unit (".join(",",@keys)." ?)" if scalar(@keys)>1 ;
  return lc($keys[0]) ;
}

sub _inSeconds    
{
  my($duration,$allowed) = @_ ;
  $Carp::CarpLevel = 2 ;
  
  my ($num,$unit) = $duration=~/^\s*(\d+)\s*([a-zA-Z]+)\s*$/  or return undef ;
  my %allowed = map { $_ => 1 } @$allowed ;
  
  croak "unit '$unit' not allowed" unless exists $allowed{lc($unit)} ;
  my $key = _getkey($unit) ;

  return $num * $InSeconds->{$key} ;
}

#--
sub _new
{
  my($type,$units,%h) = @_ ;

  %h = map { /^-/ ? lc(substr($_,1)) : $_ ; } %h ;
  for my $k ("step")
  {
    croak "argument '$k' is missing" unless exists $h{lc($k)} ;
  }
  my $step = $h{"step"} ;
  my $s_step = _inSeconds($step,$units) or croak "bad format for step '$step'" ;
  
  my $this = {
    "step" => $s_step
    , "DS" => []
    , "RRA" => []
	} ;

  bless $this,$type ;
  return $this ;
}

#-------------------------------
sub _set_filename
{
  my($this,$filename) = @_ ;
  $this->{"filename"} = $filename ;
}
  
#-------------------------------
sub add
{
  my($this,%h) = @_ ;

  %h = map { /^-/ ? lc(substr($_,1)) : $_ ; } %h ;

  # normalisation
  if (exists $h{"cfunc"}) { $h{"cf"} = $h{"cfunc"} ; delete $h{"cfunc"} ; }

  push(@{$this->{"CF"}},$h{"cf"}) if exists $h{"cf"} ;
}

#-------------------------------

sub add_RRA
{
  my($this,%h) = @_ ;

  %h = map { /^-/ ? lc(substr($_,1)) : $_ ; } %h ;
  
  for my $k ("duration")
  {
    croak "'$k' argument is missing" unless exists $h{lc($k)} ;
  }  

  my $duration = $h{"duration"} ;
  croak "possible duration are : "
    .join(",",keys %{$this->{"allowed_RRA_duration"}}) 
        unless exists $this->{"allowed_RRA_duration"}{$duration} ;
  
  push(@{$this->{"RRA"}},\%h) ;
}

#-------------------------------
sub add_data_source { add_DS(@_) ; }
sub add_DS
{
  my($this,%h) = @_ ;

  %h = map { /^-/ ? lc(substr($_,1)) : $_ ; } %h ;
  
  # normalisation
  if (exists $h{"name"}) { $h{"ds_name"} = $h{"name"} ; delete $h{"name"} ; }
  if (exists $h{"type"}) { $h{"dst"} = $h{"type"} ; delete $h{"type"} ; }
  
  $h{"min"} = "U" unless exists $h{"min"} ;
  $h{"max"} = "U" unless exists $h{"max"} ;
  $h{"heartbeat"} = 2*$this->{"step"} unless exists $h{"heartbeat"} ;
  
  for my $k ("ds_name","DST")
  {
    croak "'$k' argument is missing" unless exists $h{lc($k)} ;
  }  

  push(@{$this->{"DS"}},\%h) ;
}

#-------------------------------
sub add_compute_DS
{
  my($this,%h) = @_ ;

  %h = map { /^-/ ? lc(substr($_,1)) : $_ ; } %h ;
  
  # normalisation
  if (exists $h{"name"}) { $h{"ds_name"} = $h{"name"} ; delete $h{"name"} ; }
  
  for my $k ("ds_name","rpn_expression")
  {
    croak "'$k' argument is missing" unless exists $h{lc($k)} ;
  }  

  push(@{$this->{"DS"}},\%h) ;
}

#-------------------------------
sub compile
{
  my($this) = @_ ;

  my $rrd = RRDTool::OO->new("file" => $this->{"filename"});
  my @arg = () ;               
  push(@arg,("step" => $this->{"step"})) ;
  
  for my $ds (@{$this->{"DS"}})
  {
    push(@arg,("data_source", 
            { 
                "name" => $ds->{"ds_name"}
                , "type" => $ds->{"dst"}
                , "heartbeat" => $ds->{"heartbeat"}
                , "min" => $ds->{"min"}
                , "max" => $ds->{"max"}
            }
        )
    )
  }

push(@arg,("archive", 
    { 
        "cfunc" => "LAST"
        , "cpoints" => 1
        , "rows" => $this->{"rows"}
    }
    )) ;

  for my $cpoint (@{$this->{"RRA"}})
  {
      for my $cfunc (@{$this->{"CF"}})
      {
        push(@arg,("archive", 
            { 
                "cfunc" => $cfunc
                , "cpoints" => $InSeconds->{substr($cpoint->{"duration"},0,1)}/($this->{"step"}*$this->{"rows"})
                , "rows" => $this->{"rows"}
            }
            )
        )
      }
  }
  $this->{"OO_create_arg"} = \@arg ;
  return @arg ;
}

#-------------------------------
sub create
{
  my($this,%h) = @_ ;

  %h = map { /^-/ ? lc(substr($_,1)) : $_ ; } %h ;
  
  # normalisation
  if (exists $h{"file"}) { $h{"filename"} = $h{"file"} ; delete $h{"file"} ; }

  $this->{"filename"} = $h{"filename"} if exists $h{"filename"} ;
  $this->{"OO_create_arg"} = $h{"OO_create_arg"} if exists $h{"OO_create_arg"} ;
  
  $this->compile() unless defined $this->{"OO_create_arg"} ;
  my $rrd = RRDTool::OO->new("file" => $h{"filename"});
  $rrd->create(@{$this->{"OO_create_arg"}}) ;
}  
  
__END__
=head1 NAME

C<RRDTool::Creator> - Creators for round robin databases (RRD)

=head1 COMPONENTS

C<RRDTool::Creator> - A generic abstract creator for round robin databases (RRD)

C<RRDTool::Creator::HourPDP> - creates a RRD with a default archive of primary points for an hour

C<RRDTool::Creator::DayPDP> - creates a RRD with a default archive of primary points for a day

C<RRDTool::Creator::WeekPDP> - creates a RRD with a default archive of primary points for a week

C<RRDTool::Creator::MonthPDP> - creates a RRD with a default archive of primary points for a month

C<RRDTool::Creator::QuarterPDP> - creates a RRD with a default archive of primary points for a quarter

C<RRDTool::Creator::YearPDP> - creates a RRD with a default archive of primary points for a year

=head1 SYNOPSIS

  use RRDTool::Creator::DayPDP ; 

  # make a creator
  $creator = new RRDTool::Creator::DayPDP(-step => "30mn") ; 
  
  # add data sources in the specifications of the RRD
  $creator->add_DS(
            -ds_name => "cpu"
            , -DST => "GAUGE"
            , -min => 0
            , -max => 100
            ) ;
  
  $creator->add_DS(
            -ds_name => "swap"
            , -DST => "GAUGE"
            ) ;

  # add archives in the specifications of the RRD
  $creator->add_RRA(-duration => "week") ;
  $creator->add_RRA(-duration => "month") ;

  # add some consolidation functions in the specifications of the RRD
  $creator->add(-CF => "MAX") ;
  $creator->add(-CF => "AVERAGE") ;

  # create the RRD file
  $creator->create(-filename => "/var/rrdtool/vmstat.rrd") ;
    
=head1 DESCRIPTION

The C<RRDTool::Creator> objects are specific creators for different kind of RRD files. 
They are based on the Round Robin Database Tool (L<http://www.rrdtool.org>) and on the Perl module L<RRDTool::OO>.

=head1 NOTES

C<RRDTool::Creator> tries to be compatible with both the official RRDTool documentation 
and the C<RRDTool::OO> module. 
It is why some functions and some arguments have two possible names
(in this case, the main name is conform to the official documentation and the auxiliary one is for compatibility with the C<RRDTool::OO> module).

=cut

=head1 COMMON METHODS

=head2 add_data_source

See add_DS

=head2 add_DS (auxiliary name: add_data_source)

Add a data source in the RRD specifications.
Its arguments are :

=over 4

=item B<ds_name> (auxiliary name: B<name>)

(I<mandatory>) The name of the data source.

=item B<DST> (auxiliary name: B<type>)

(I<mandatory>) The data source type : C<GAUGE>, C<COUNTER>, C<DERIVE> or C<ABSOLUTE> (see L<http://www.rrdtool.org>).

=item B<heartbeat>

(I<optionnal>) The maximum number of seconds that may pass between two updates of this data source before the value of the data source is assumed to be *UNKNOWN*.
Default is 2*step.

=item B<min>

(I<optionnal>) The expected minimum value for data supplied by a data source. 
Any value outside the defined range will be regarded as *UNKNOWN*. 
Default is "U" for unknown.

=item B<max>

(I<optionnal>) The expected maximum value for data supplied by a data source. 
Any value outside the defined range will be regarded as *UNKNOWN*. 
Default is "U" for unknown.

    $creator->add_DS(
                -ds_name => "cpu"
                , -DST => "GAUGE"
                , -min => 0
                , -max => 100
                ) ;

=back

=head2 add_compute_DS (not yet implemented)

Add a data source with computed primary data points (it is a DS with DST equal to C<COMPUTE>) in the RRD specifications.
Its arguments are :

=over 4

=item B<ds_name> (auxiliary name: B<name>)

(I<mandatory>) The name of the data source.

=item B<rpn_expression>

(I<mandatory>) RPN expression that defines formula to compute PDP of this DS.

=back

=head2 B<add_RRA> (auxiliary name: B<add_archive>)

Add a round robin archive in the RRD specifications.

=over 4

=item B<duration>

(I<mandatory>) The duration of the archive.
Possible values are : "day", "week", "month", "quarter" and "year".

=item B<xff>

(I<optionnal>) The xfiles factor (see <http://www.rrdtool.org>)

    $creator->add_RRA(-duration => "day") ;

=back

=head2 add

Add some global attributes in the RRD specifications.

=over 4

=item B<CF> (auxiliary name: B<cfunc>)

Add a consolidation function (C<AVERAGE>, C<MIN>, C<MAX>, C<LAST>... - see <http://www.rrdtool.org>), 
for each RRA (except the default RRA) in the RRD specifications.

    $creator->add(-CF => "AVERAGE") ;

=back

=head2 B<compile>

Compute the argument for the function C<create> of the underlaying RRDTool::OO object.
Useful for debugging, this function also allows to customize the command passed to rrdtool.
Return this argument (a list). 

    @args = $creator->compile() ;

=head2 B<create>

Create the RRD on the disk.

=over 4

=item B<filename> (auxiliary name: B<file>)

(I<mandatory>) The name of the file to create.

=item B<OO_create_arg>

(I<optionnal>) The argument passed to the function create of the underlaying RRDTool::OO object
(this is the value returned by the previous function C<compile>).
In normal case, this argument isn't provided, and its value is compiled from the current stored data.

    $creator->create(-filename => "/tmp/15s.rrd") ;

which can be break up to :

    @args = $creator->compile() ;
    # possible manual modification on @args here...
    $creator->create(-filename => "/tmp/15s.rrd", OO_create_arg => \@args) ;

=back

=head1 SUB-OBJECTS

Each sub-objects of C<RRDTool::Creator> creates a RRD with one default archive (RRA) made of primary data points (PDP).
More RAA can then be added.
The constructor neads an argument named C<step> which is the period of acquisition. The time unit of the step depends of the sub-object.

=head2 RRDTool::Creator::HourPDP

The default RRA stores primary data points for an hour.
More RRA can be added for a day, a week, a month, a quarter and a year.
The created RRD is for an acquisition period much less than an hour, typically about some seconds or a few minutes.
So, the step unit for its constructor argument is second(s) or minute(mn).
    
    $creator = new RRDTool::Creator::HourPDP(-step => "30s") ;
    $creator->add_RRA(-duration => "day") ;
    $creator->add_RRA(-duration => "week") ;
    $creator->add_RRA(-duration => "month") ;
    $creator->add_RRA(-duration => "quarter") ;
    $creator->add_RRA(-duration => "year") ;

=head2 RRDTool::Creator::DayPDP

The default RRA stores primary data points for a day.
More RRA can be added for a week, a month, a quarter and a year.
The created RRD is for an acquisition period much less than a day, typically about some minutes or a few hours.
So, the natural step units for its constructor argument are the minute(mn) and hour(h), although second(s) is allowed.
    
    $creator = RRDTool::Creator::DayPDP(-step => "10mn") ;
    $creator->add_RRA(-duration => "week") ;
    $creator->add_RRA(-duration => "month") ;
    $creator->add_RRA(-duration => "quarter") ;
    $creator->add_RRA(-duration => "year") ;

=head2 RRDTool::Creator::WeekPDP

The default RRA stores primary data points for a week.
More RRA can be added for a month, a quarter and a year.
The created RRD is for an acquisition period much less than a week, typically about some hours.
So, the natural step unit for its constructor argument is the hour(h), although second(s), minute(mn) and day(d) are allowed.
    
    $creator = RRDTool::Creator::WeekPDP(-step => "4h") ;
    $creator->add_RRA(-duration => "month") ;
    $creator->add_RRA(-duration => "quarter") ;
    $creator->add_RRA(-duration => "year") ;

=head2 RRDTool::Creator::MonthPDP

The default RRA stores primary data points for a month.
More RRA can be added for a quarter and a year.
The created RRD is for an acquisition period much less than a month, typically about some hours or a few days.
So, the natural step unit for its constructor argument are hour(h) and day(d), although second(s), minute(m) and week(w) are allowed.
    
    $creator = RRDTool::Creator::MonthPDP(-step => "1d") ;
    $creator->add_RRA(-duration => "quarter") ;
    $creator->add_RRA(-duration => "year") ;

=head2 RRDTool::Creator::QuarterPDP

The default RRA stores primary data points for a quarter.
More RRA can be added for a year.
The created RRD is for an acquisition period much less than a quarter, typically about some days or a few weeks.
So, the natural step unit for its constructor argument are day(d) and week(w), although second(s), minute(m), hour(h) and month(m) are allowed.
    
    $creator = RRDTool::Creator::QuarterPDP(-step => "3d") ;
    $creator->add_RRA(-duration => "year") ;

=head2 RRDTool::Creator::YearPDP

The default RRA stores primary data points for a year.
No more RRA can be added.
The created RRD is for an acquisition period much less than a year, typically about some days, a few weeks or months.
So, the natural step unit for its constructor argument are day(d), week(w) and month(m), although second(s), minute(m), hour(h) and quarter(q) are allowed.
    
    $creator = RRDTool::Creator::YearPDP(-step => "1w") ;
    
=head1 EXAMPLES

=head2 EXAMPLE 1

To create a RRD to store percent cpu load and swap use, gathering every 10mn, 
with the aim of graphing average and max values daily, weekly, monthly and yearly :

    $creator = new RRDTool::Creator::DayPDP(-step => "10mn") ;
    $creator->add_DS(
                -ds_name => "cpu"
                , -DST => "GAUGE"
                , -min => 0
                , -max => 100
                ) ;
    $creator->add_DS(
                -ds_name => "swap"
                , -DST => "GAUGE"
                , -min => 0
                ) ;
    $creator->add(-CF => "AVERAGE") ;
    $creator->add(-CF => "MAX") ;
    $creator->add_RRA(-duration => "week") ;
    $creator->add_RRA(-duration => "month") ;
    $creator->add_RRA(-duration => "year") ;
    $creator->create(-filename => "vmstat.rrd") ;

=head2 EXAMPLE 2

To create a RRD to store number of spams and total mails received every days, 
with the aim of graphing average and max values quarterly and yearly :

    $creator = new RRDTool::Creator::QuarterPDP(-step => "1d") ;
    $creator->add_DS(
                -ds_name => "spams"
                , -DST => "GAUGE"
                , -min => 0
                ) ;
    $creator->add_DS(
                -ds_name => "mails"
                , -DST => "GAUGE"
                , -min => 0
                ) ;
    $creator->add(-CF => "AVERAGE") ;
    $creator->add(-CF => "MAX") ;
    $creator->add_RRA(-duration => "year") ;
    $creator->create(-filename => "mail.rrd") ;

=head2 EXAMPLE 3

To create a RRD to store disk usage every 4 hours, 
with the aim of graphing max values weekly and yearly :

    $creator = new RRDTool::Creator::WeekPDP(-step => "4h") ;
    $creator->add_DS(
                -ds_name => "/home"
                , -DST => "GAUGE"
                , -min => 0
                , -max => 100
                ) ;
    $creator->add_DS(
                -ds_name => "/var"
                , -DST => "GAUGE"
                , -min => 0
                , -max => 100
                ) ;
    $creator->add(-CF => "MAX") ;
    $creator->add_RRA(-duration => "year") ;
    $creator->create(-filename => "df.rrd") ;

=head1 SEE ALSO

L<http://www.rrdtool.org/doc>, L<RRDTool::OO>


=head1 AUTHOR

Jacquelin Charbonnel, C<< <jacquelin.charbonnel at math.cnrs.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-RRDTool-Creator at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RRDTool-Creator>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RRDTool-Creator

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RRDTool-Creator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RRDTool-Creator>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RRDTool-Creator>

=item * Search CPAN

L<http://search.cpan.org/dist/RRDTool-Creator>

=back

=head1 COPYRIGHT & LICENSE

Copyright Jacquelin Charbonnel E<lt> jacquelin.charbonnel at math.cnrs.fr E<gt>

This software is governed by the CeCILL-C license under French law and
abiding by the rules of distribution of free software.  You can  use, 
modify and/ or redistribute the software under the terms of the CeCILL-C
license as circulated by CEA, CNRS and INRIA at the following URL
"http://www.cecill.info". 

As a counterpart to the access to the source code and  rights to copy,
modify and redistribute granted by the license, users are provided only
with a limited warranty  and the software's author,  the holder of the
economic rights,  and the successive licensors  have only  limited
liability. 

In this respect, the user's attention is drawn to the risks associated
with loading,  using,  modifying and/or developing or reproducing the
software by the user in light of its specific status of free software,
that may mean  that it is complicated to manipulate,  and  that  also
therefore means  that it is reserved for developers  and  experienced
professionals having in-depth computer knowledge. Users are therefore
encouraged to load and test the software's suitability as regards their
requirements in conditions enabling the security of their systems and/or 
data to be ensured and,  more generally, to use and operate it in the 
same conditions as regards security. 

The fact that you are presently reading this means that you have had
knowledge of the CeCILL-C license and that you accept its terms.

