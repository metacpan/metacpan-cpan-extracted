# Test to verify the ttkLabel font returns a valid font object and not just an empty string.
#   This enables 'Clone' to be called on it
#
use Tcl::pTk;

use Test;

plan tests => 3;

my $TOP = MainWindow->new();

my $label = $TOP->ttkLabel(-text => "Hey Dude")->pack();


#print "label = '$label'\n";


my $font = $label->cget(-font);

ok( "$font", 'TkDefaultFont', "Font is Text");
ok( ref($font), "Tcl::pTk::Font", "Font is blessed object");

#print "font = $font\n";

my $cloned = $font->Clone( -weight => 'bold');
ok( ref($cloned), "Tcl::pTk::Font", "Cloned Font is blessed object");


MainLoop if (@ARGV); # Pause if any args, (for debugging)

