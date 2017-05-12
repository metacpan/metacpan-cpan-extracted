package RRDTool::Creator::WeekPDP ;

# ============================================
# 
#           Jacquelin Charbonnel - CNRS/LAREMA
#  
#   $Id: WeekBased.pm 154 2007-04-13 16:18:43Z jaclin $
#   
# ----
#  
#   A specific creator for round robin databases (RRD)
# 
# ----
#   $LastChangedDate: 2007-04-13 18:18:43 +0200 (Fri, 13 Apr 2007) $ 
#   $LastChangedRevision: 154 $
#   $LastChangedBy: jaclin $
#   $URL: https://svn.math.cnrs.fr/jaclin/src/pm/RRDTool-Creator/WeekBased.pm $
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

  
  my $this = _new RRDTool::Creator(["s","mn","h","d"],%h) ;
  
  $this->{"rows"} = int(3600*24*7/$this->{"step"}) ;
  $this->{"allowed_RRA_duration"} = {
           "month" => 4
           , "quarter" => 13
           , "year" => 52
           } ;

  bless $this,$type ;
  return $this ;
}

=head1 RRDTool::Creator::WeekPDP

The default RRA stores primary data points for a week.
More RRA can be added for a month, a quarter and a year.
The created RRD is for an acquisition period much less than a week, typically about some hours.

=head2 new

This constructor neads an argument named C<step> which is the period of acquisition.
The natural step unit is the hour(h), although second(s), minute(mn) and day(d) are allowed.

    $creator = RRDTool::Creator::WeekPDP(-step => "4h") ;
    $creator->add_RRA(-duration => "month") ;
    $creator->add_RRA(-duration => "quarter") ;
    $creator->add_RRA(-duration => "year") ;

