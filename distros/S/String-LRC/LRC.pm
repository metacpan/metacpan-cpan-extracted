############################################################
# 
#  Perl Extension for LRC computations
#  Author...: Ralph Padron (whoelse@elitedigital.net)
#  Revised..: 01-May-2002
# 
#  The Longitudinal Redundancy Check (LRC) is a one byte character,
#  commonly used as a field in data transmission over analog systems.
# 
#  Most commonly, in STX-ETX bounded strings sent in financial protocols.
# 
#  Following some previous experience with such protocols, I wrote
#  an LRC function in perl and later decided to re-write in C
#  for efficiency.  The result is this module String::LRC
# 
#  NOTE:
#       Included sv_type comparison and lrcinit in v1.01
#       following the idea by Soenke J. Peters and others
#       that someone perhaps can use the LRC of a file.
# 
# 
############################################################

package String::LRC;

require Exporter;
require DynaLoader;

@String::LRC::ISA = qw(Exporter DynaLoader);
$String::LRC::VERSION = 1.01;
@String::LRC::EXPORT = qw(lrc); # Export lrc() by default
# Export the default and the old LRC function I had as a simple perl subroutine 
# from v1.00 of this package
@String::LRC::EXPORT_OK = qw(lrc getPerlLRC);

sub getPerlLRC
{
 my $buffer = shift(@_);
 my @str = split(//,$buffer);
 my $len = 0;
 $len = length($buffer) if (defined $buffer && $buffer ne "");
 no warnings; # for XOR on non-numeric (sometimes shows for me)
 my $check;
 for (my $i = 0; $i < $len ; $i++) {
	$check = $check ^ $str[$i];
 }
 return $check;
}

bootstrap String::LRC;


1;
