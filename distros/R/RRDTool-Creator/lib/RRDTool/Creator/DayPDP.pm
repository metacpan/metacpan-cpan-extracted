package RRDTool::Creator::DayPDP ;

# ============================================
# 
#           Jacquelin Charbonnel - CNRS/LAREMA
#  
#   $Id: DayBased.pm 154 2007-04-13 16:18:43Z jaclin $
#   
# ----
#  
#   A specific creator for round robin databases (RRD)
# 
# ----
#   $LastChangedDate: 2007-04-13 18:18:43 +0200 (Fri, 13 Apr 2007) $ 
#   $LastChangedRevision: 154 $
#   $LastChangedBy: jaclin $
#   $URL: https://svn.math.cnrs.fr/jaclin/src/pm/RRDTool-Creator/DayBased.pm $
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

  
  my $this = _new RRDTool::Creator(["s","mn","h"],%h) ;
  
  $this->{"rows"} = int(3600*24/$this->{"step"}) ;
  $this->{"allowed_RRA_duration"} = {
           "week" => 7
           , "month" => 30
           , "quarter" => 90
           , "year" => 365
           } ;

  bless $this,$type ;
  return $this ;
}

=head1 RRDTool::Creator::DayPDP

The default RRA stores primary data points for a day.
More RRA can be added for a week, a month, a quarter and a year.
The created RRD is for an acquisition period much less than a day, typically about some minutes or a few hours.

=head2 new

This constructor neads an argument named C<step> which is the period of acquisition.
The natural step units are the minute(mn) and hour(h), although second(s) is allowed.

    $creator = RRDTool::Creator::DayPDP(-step => "10mn") ;
    $creator->add_RRA(-duration => "week") ;
    $creator->add_RRA(-duration => "month") ;
    $creator->add_RRA(-duration => "quarter") ;
    $creator->add_RRA(-duration => "year") ;


