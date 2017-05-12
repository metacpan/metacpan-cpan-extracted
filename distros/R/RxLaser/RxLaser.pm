package RxLaser;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(form1500 formub92 form485 form486 form487 lineprinter
                lineprinter48 half_linefeed pcl_unpack reset);
$VERSION = '0.15';

sub new
{
    my $class = shift;
    return( bless{ } , $class );
}

######################## USER METHODS ################################

# ------------------------- RxLaser form1500 -------------------------
sub form1500
{
my $self = shift;
my $a = $self->_Portrait;
$a .= $self->_Form('1');
$a .= $self->lineprinter;
$a .= $self->_PerfSkip;
$a .= $self->_Horiz('12');
$a .= $self->_Vert('7.2727');
return $a;

}
# ------------------------- RxLaser formub92 -------------------------
sub formub92
{
my $self = shift;
my $a = $self->_Portrait;
   $a .= $self->_Form("2");
   $a .= $self->lineprinter;
   $a .= $self->_PerfSkip;
   $a .= $self->_Horiz('7');
#  $a .= $self->_Vert("7.2727");
return $a;
}
# ------------------------- RxLaser form485 -------------------------
sub form485
{
my $self = shift;
my $a  = $self->_Portrait;
   $a .= $self->_Form('3');
   $a .= $self->lineprinter;
   $a .= $self->_PerfSkip;
   $a .= $self->_Horiz('7');
return $a;
}

# ------------------------- RxLaser form486 -------------------------
sub form486
{
my $self = shift;
my $a  = $self->_Portrait;
   $a .= $self->_Form('4');
   $a .= $self->lineprinter;
   $a .= $self->_PerfSkip;
   $a .= $self->_Horiz('7');
return $a;
}

# ------------------------- RxLaser form487 -------------------------
sub form487
{
my $self = shift;
my $a  = $self->_Portrait;
   $a .= $self->_Form('5');
   $a .= $self->lineprinter;
   $a .= $self->_PerfSkip;
   $a .= $self->_Horiz('7');
return $a;
}

# ------------------------- pcl_unpack utility -------------------------
sub pcl_unpack
{
    my $self = shift;
    my $a = shift;
    my $l = length( $a );
    my @u = unpack('C' x $l, $a );
    return join( ' ' , @u );
}

# ------------------------- reset utility -------------------------
sub reset
{
    my $self = shift;
    return pack('CC', 27,69 );
}

# ------------------------- half linefeed -------------------------
sub half_linefeed
{
    my $self = shift;
    return pack('CC', 27,61 );
}

# ------------------------- lineprinter -------------------------
sub lineprinter
{
    # Symbol Set PC-8          27,40,49,48,85
    # Typeface lineprinter     27,40,115,48,84
    # Font Pitch 16.67         27,38,107,50,83
    # 6 lines/inch             27,38,49,54,68
    my $self = shift;
    my @a = qw(27 40 49 48 85 27 40 115 48 84 27 38 107 50 83 27 38 49 54 68);
    return pack( 'C' x @a, @a );
}

# ----------------internal lineprinter font 48 -----------------
sub lineprinter48
{
    my $self = shift;
    my @a = qw(27 40 49 48 85 27 40 115 48 84 27 38 107 50 83 27 38 49 54 68);
    return pack( 'C' x @a, @a );
}
######################## RxLaser Internals ##############################

sub _Form # param: form numbers 1 to 5
{
    my $self = shift;
    my $form = shift;
    my @ret = (27,38,102, (unpack( 'C', $form )), 121, 52, 88);
    return pack('C' x @ret, @ret );
}

sub _Horiz # param: 120ths of an inch
{
    my $self = shift;
    my $index = shift;
    return pack('CCC',27,38,107).  $index . pack('C', 72);
}

sub _Vert # param: 48ths of an inch
{
    my $self = shift;
    my $index = shift;
    return pack('CCC',27,38,108).  $index . pack('C', 67);
}

sub _VertLPI # param: lines per inch
{
    my $self = shift;
    my $index = shift;
    return pack('CCC',27,38,108).  $index . pack('C', 68);
}

sub _Portrait
{
    my $self = shift;
    return pack('CCCCC', qw/027 038 108 048 079/);
}

sub _LetterGothic
{
    my $self = shift;
    return pack('C' x 20 , qw/027 040 115 048 112 049 053 046 048 048 104 048 115 048 098 052 049 048 050 108/);
}

sub _PerfSkip
{
    my $self = shift;
    return pack('CCCCC', qw/027 038 108 048 076/ );
}

1;
#

__END__

=head1 NAME

RxLaser.pm - Perl extension for printing medical forms on HP LaserJet printers
with the RxLaser simm.

    RxLaser, Inc.
    Laser Printing Solutions
    3350 East Birch St. Suite 205
    Brea, CA 92821
    Tel: 714 986-1559
    Fax: 714 986-1568
    email: mail@rxlaser.com

=head1 SYNOPSIS

  use RxLaser;
  my $chip = new RxLaser;

=head1 DESCRIPTION

  print $chip->reset;
  print $chip->formub92,  "some text";
  print $chip->form485,   "some text";
  print $chip->form486,   "some text";
  print $chip->form487,   "some text";
  print $chip->form1500,  "some text";

  To print a list of decimal equivalents to a PCL string:
  print $chip->pcl_unpack

  To skip half of a line:
  print $chip->half_linefeed

  To turn on the lineprinter font, compressed, 6lpi:
  print $chip->lineprinter;

=head1 AUTHOR

David Martin, penguipotamous@yahoo.com

=head1 SEE ALSO

perl(1).

=cut
1;
