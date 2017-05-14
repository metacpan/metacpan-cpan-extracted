# Install this in your perl source or installation tree as lib/Term/Info.pm

# Call using the following syntax:
#   $clear = Tput("clear");
#   print $clear;
#   print Tput("cup",$row,$col);
#
# Note that the tput command is required to be in your path somewhere.

package Term::Info;
require 5.000;
require Exporter;
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(&Tput);

%cachetput = ();

sub Tput  {
	my(@params) = @_;
	my($cmd) = "tput";
	foreach (@params)
	{
		$cmd .= " \"\Q$_\E\"";
	} 
	if( defined($cachetput{$cmd}) )
		{ $cachetput{$cmd} }
	else
		{ $cachetput{$cmd} = `$cmd` }
}


1;
