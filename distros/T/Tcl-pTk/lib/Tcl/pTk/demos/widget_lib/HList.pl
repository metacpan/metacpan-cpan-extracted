# HList, a hierarchial listbox widget.

use Cwd;
use subs qw/show_dir/;
use vars qw/$TOP $FILEIMG $FOLDIMG/;

sub HList {
    my($demo) = @_;
    $TOP = $MW->WidgetDemo(
        -name => $demo,
        -text => 'HList - A hierarchial listbox widget.',
	-geometry_manager => 'grid',
    );

    my $h = $TOP->Scrolled(qw\HList -separator / -selectmode extended -width 30
			   -height 20 -indent 35 -scrollbars se
			   -itemtype imagetext \
			   )->grid(qw/-row 0 -sticky nsew/);
    $h->configure(-command => sub {
	print "Double click $_[0], size=", $h->info('data', $_[0]) ,".\n";
    });

    $FILEIMG = $TOP->Bitmap(-file => Tcl::pTk->findINC('file.xbm'));
    $FOLDIMG = $TOP->Bitmap(-file => Tcl::pTk->findINC('folder.xbm'));

    my $root = Tcl::pTk->findINC('demos');
    my $olddir = cwd;
    chdir $root;
    show_dir '.', $root, $h;
    chdir $olddir;
    my $b = $TOP->Button(-text => 'Select All', -command => [\&select_all, $h]);
    $b->grid(-row, 1);
}

sub select_all
{
 my $h = shift;
 my @list = $h->infoChildren(@_);
 if (@list)
  {
   $h->focusForce();
   $h->selectionSet($list[0],$list[-1]);
   foreach my $e (@list)
    {
     select_all($h,$e);
    }
  }
}

sub show_dir {
    my($entry_path, $text, $h) = @_;
    opendir H, $entry_path;
    my(@dirent) = grep ! /^\.\.?$/, sort(readdir H);
    closedir H;
    $h->add($entry_path,  -text => $text, -image => $FOLDIMG, -data => 'DIR');
    while ($_ = shift @dirent) {
	my $file = "$entry_path/$_";
	if (-d $file) {
	    show_dir $file, $_, $h;
	} else {
	    my $size = -s $file;
	    $h->add($file,  -text => $_, -image => $FILEIMG, -data => $size);
	}
    }
} # end show_dir
