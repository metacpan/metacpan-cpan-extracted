package RRDTool::Creator::QuarterPDP ;

# ============================================
# 
#           Jacquelin Charbonnel - CNRS/LAREMA
#  
#   $Id: QuarterBased.pm 154 2007-04-13 16:18:43Z jaclin $
#   
# ----
#  
#   A specific creator for round robin databases (RRD)
# 
# ----
#   $LastChangedDate: 2007-04-13 18:18:43 +0200 (Fri, 13 Apr 2007) $ 
#   $LastChangedRevision: 154 $
#   $LastChangedBy: jaclin $
#   $URL: https://svn.math.cnrs.fr/jaclin/src/pm/RRDTool-Creator/QuarterBased.pm $
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

  
  my $this = _new RRDTool::Creator(["s","mn","h","d","w","m"],%h) ;
  
  $this->{"rows"} = int(3600*24*90/$this->{"step"}) ;
  $this->{"allowed_RRA_duration"} = {
           "year" => 4
           } ;

  bless $this,$type ;
  return $this ;
}

=head1 RRDTool::Creator::QuarterPDP

The default RRA stores primary data points for a month.
More RRA can be added for a quarter and a year.
The created RRD is for an acquisition period much less than a month, typically about some hours or a few days.

=head2 new

This constructor neads an argument named C<step> which is the period of acquisition.
The natural step units are hour(h) and day(d), although second(s), minute(m) and week(w) are allowed.

    $creator = RRDTool::Creator::MonthPDP(-step => "1d") ;
    $creator->add_RRA(-duration => "quarter") ;
    $creator->add_RRA(-duration => "year") ;


