package RRDTool::Creator::YearPDP ;

# ============================================
# 
#           Jacquelin Charbonnel - CNRS/LAREMA
#  
#   $Id: YearBased.pm 154 2007-04-13 16:18:43Z jaclin $
#   
# ----
#  
#   A specific creator for round robin databases (RRD)
# 
# ----
#   $LastChangedDate: 2007-04-13 18:18:43 +0200 (Fri, 13 Apr 2007) $ 
#   $LastChangedRevision: 154 $
#   $LastChangedBy: jaclin $
#   $URL: https://svn.math.cnrs.fr/jaclin/src/pm/RRDTool-Creator/YearBased.pm $
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
  
  $this->{"rows"} = int(3600*24*365/$this->{"step"}) ;
  $this->{"allowed_RRA_duration"} = {} ;

  bless $this,$type ;
  return $this ;
}

=head1 RRDTool::Creator::YearPDP

The default RRA stores primary data points for a year.
No more RRA can be added.
The created RRD is for an acquisition period much less than a year, typically about some days, a few weeks or months.

=head2 new

This constructor neads an argument named C<step> which is the period of acquisition.
The natural step units are day(d), week(w) and month(m), although second(s), minute(m), hour(h) and quarter(q) are allowed.

    $creator = RRDTool::Creator::YearPDP(-step => "1w") ;


