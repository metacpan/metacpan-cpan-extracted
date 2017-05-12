#!/usr/local/bin/perl -w

#use Tk;
#use Tk::HList;
#use Tk::ItemStyle;
use Tcl::pTk;
use Tcl::pTk::ItemStyle;
use Test;

$top = MainWindow->new;

# This will skip if Tix not present
my $retVal = $top->interp->pkg_require('Tix');

unless( $retVal){
	plan tests => 1;
        skip("Tix Tcl package not available", 1);
        exit;
}

plan tests => 1;

$redstyle  = $top->ItemStyle('text',
			     -foreground => 'red',
			     -font => '10x20',
			     -background => 'green');

#print $redstyle,"\n";

$bluestyle = $top->ItemStyle('text',
			     -foreground => 'blue',
			     -background => 'white',
			    );
$hl = $top->HList->pack(-expand=> 'y', -fill => 'both');

$hl->add(0, -itemtype => 'text', -text => 'Changed from Green to Cyan', -style => $redstyle);
$hl->add(1, -itemtype => 'text', -text => 'blue', -style => $bluestyle);


#$redstyle->configure(-background => 'cyan');
$top->after(2000, [ configure => $redstyle, -background => 'cyan' ]);
$top->after(3000, sub{
                $hl->entryconfigure(0, -text => 'Changed to Cyan');
}
);

$top->after(4000, sub{
                $top->destroy;
}
);

MainLoop;

ok(1);

