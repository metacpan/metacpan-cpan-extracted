BEGIN { $|=1; $^W=1; }
use strict;
use Test;
use Tcl::pTk;

my $mw = MainWindow->new;

if (!$mw->interp->pkg_require('Img')) {
    print "1..0 # skip: no Img extension available\n";
    exit;
}

plan tests => 14;

my $xpm;
my $photo;

{
   $xpm = './t/folder.xpm';
   eval { $photo = $mw->Photo(-file=>$xpm); };
   ok($@, '', 'Problem creating Photo widget');
}
##
## configure('-data') returned '-data {} {} {} {}' up and incl. Tk800.003
##
{
   my @opts;
   my $opts;
   foreach my $opt ( qw/-data -format -file -gamma -height -width/ )
     {
       eval { @opts = $photo->configure($opt); };
       ok($@, '', "can't do configure $opt");
       ok(scalar(@opts), 5, "configure $opt returned not 5 elements");
     }
}

# check to see that the Pixmap (alias for Photo) method works
{
   $xpm = './t/folder.xpm';
   eval { $photo = $mw->Pixmap(-file=>$xpm); };
   ok($@, '', 'Problem creating Pixmap widget');
}


1;
__END__
