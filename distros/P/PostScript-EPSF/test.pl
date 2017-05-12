
open(STDOUT, ">xxx.ps") || die;

print "%!PS-Adobe-3.0

";


use PostScript::EPSF;

cross(100, 200);
include_epsf(-file => "svpv.eps",
	     "-pos"  => "100,200",
	     -width => 100,
	     -anchor => "w",
	     -background => "white",
	     -boarder => 0,
	     -clip => 1,
	     #-height => 70,
	    );

cross(200, 500);
include_epsf(-file => "svpv.eps",
	     "-pos"  => "200,500",
	     -scale => 0.5,
	     -rotate => 45,
	     -anchor => "ne",
	     -clip => 1,
	    );

print "showpage\n";
close(STDOUT);
system("ghostview xxx.ps");


sub cross
{
    my($x, $y) = @_;
    print "gsave 0.1 setlinewidth\n";
    print "$x 0 moveto $x 1000 lineto\n";
    print "0 $y moveto 1000 $y lineto stroke\n";
    print "grestore\n";
}
