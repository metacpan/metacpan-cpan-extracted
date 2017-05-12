package RRDTool::Creator::HourPDP ;

# ============================================
# 
#           Jacquelin Charbonnel - CNRS/LAREMA
#  
#   $Id: HourBased.pm 154 2007-04-13 16:18:43Z jaclin $
#   
# ----
#  
#   A specific creator for round robin databases (RRD)
# 
# ----
#   $LastChangedDate: 2007-04-13 18:18:43 +0200 (Fri, 13 Apr 2007) $ 
#   $LastChangedRevision: 154 $
#   $LastChangedBy: jaclin $
#   $URL: https://svn.math.cnrs.fr/jaclin/src/pm/RRDTool-Creator/HourBased.pm $
#  
# ============================================

require Exporter ;
@ISA = qw(Exporter RRDTool::Creator);
@EXPORT=qw() ;

use Carp ;
use RRDTool::Creator ;
use strict ;

our $VERSION = "0.2" ;

#-------------------------------
sub new
{
  my($type,%h) = @_ ;
  my ($step) ;

  
  my $this = _new RRDTool::Creator(["s","mn"],%h) ;
  
  $this->{"rows"} = int(3600/$this->{"step"}) ;
  $this->{"allowed_RRA_duration"} = {
            "day" => 24
           , "week" => 24*7
           , "month" => 24*30
           , "quarter" => 24*90
           , "year" => 24*365
           } ;

  bless $this,$type ;
  return $this ;
}

=head1 RRDTool::Creator::HourPDP

The default RRA stores primary data points for an hour.
More RRA can be added for a day, a week, a month, a quarter and a year.
The created RRD is for an acquisition period much less than an hour, typically about some seconds or a few minutes.

=head2 new

This constructor neads an argument named C<step> which is the period of acquisition
which
is second(s) or minute(mn).

    $creator = new RRDTool::Creator::HourPDP(-step => "30s") ;
    $creator->add_RRA(-duration => "day") ;
    $creator->add_RRA(-duration => "week") ;
    $creator->add_RRA(-duration => "month") ;
    $creator->add_RRA(-duration => "quarter") ;
    $creator->add_RRA(-duration => "year") ;

