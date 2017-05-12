## edit_styles.pl
##
## demonstrates different edit styles within cells
##
## ewaldhei@idd.com

## This script uses tags and some logic to simulate check
##  buttons, browseEntries, etc in cells. This approach is 
##  faster than using embedded windows, especially for large
##  tables.

use Tcl::pTk (qw/ :perlTk /);
use Tcl::pTk::TableMatrix::Spreadsheet;

$| = 1; # Pipes hot
main();

sub main
{
	my $top = MainWindow->new;

	my $_data = {};
	my ($rows,$cols) = (12,7); # number of rows/cols

	# create the table
	my $t = $top->Scrolled
		(TableMatrix =>
		 -rows => $rows, -cols => $cols,
		 -titlerows =>  1, -titlecols => 1,
		 -width => 8, -height => 8 ,
		 -colwidth => 11,
		 -variable => $_data,
		 -cursor => 'top_left_arrow' ,
		 -borderwidth => 2 ,
		 -ipadx => 15,
		 -scrollbars => 'se',
		)->pack(qw/-expand 1 -fill both/);
	
	my $tm = $t->Subwidget('scrolled');

	$tm->{columneditstyles} = {qw(1 readonly
											2 editable
											3 button
											4 optionmenu
											5 browseentry
											6 checkbutton
										  )};

	# set up tags for the various states of the buttons
	$t->tagConfigure('OFF', -bg => 'gray60', -relief => 'raised');
	$t->tagConfigure('ON', -bg => 'gray80', -relief => 'sunken');
	$t->tagConfigure('sel', -bg => 'gray70', -relief => 'flat');
	$t->tagConfigure('readonly', -relief => 'groove');
	
	my %images = define_bitmaps($top);
	$t->tagConfigure('optionmenu', -image => $images{optionmenu},
						  -anchor => 'e', -showtext => 1,
						 );
	$t->tagConfigure('browseentry', -image => $images{browseentry},
						  -anchor => 'e', -showtext => 1);
	$t->tagConfigure('checkbutton0', -image => $images{checkbutton0});
	$t->tagConfigure('checkbutton1', -image => $images{checkbutton1});

	$t->bind('<Key-Escape>' => \&end_edit);

	# clean up if mouse leaves the widget
	$t->bind('<FocusOut>',sub
	{
		my $w = shift;
		$w->selectionClear('all');
		$w->configure(-state => 'disabled');
	});
	
	# highlight the cell under the mouse
	$t->bind('<Motion>', sub
	{
		my $w = shift;
		my $Ev = $w->XEvent;
		if( $w->selectionIncludes('@' . $Ev->x.",".$Ev->y)){
			Tcl::pTk->break;
		}
		$w->selectionClear('all');
		$w->selectionSet('@' . $Ev->x.",".$Ev->y);
		Tcl::pTk->break;
		## "break" prevents the call to TableMatrixCheckBorder
	});
	
	# mousebutton 1 edits the cell (or not) appropriately
	$t->bind('<1>', sub
	{
		my ($w) = @_;
		withdraw_edit_widgets($w);
		my $Ev = $w->XEvent;
		my ($x, $y) = ($Ev->x, $Ev->y);
		my $rc = $w->index("\@$x,$y");
		my $var = $w->cget(-var);
		my ($r, $c) = split(/,/, $rc);
		$r && $c || return;
		$w->{_b1_row_col} = "$r,$c";
		set_style_state($w);
		my $style= $w->{columneditstyles}{$c} || 'editable';
		if ($style eq 'optionmenu' || $style eq 'browseentry')
		{
			setup_toplevel_lbox($w, $r, $c);
		}
		elsif ($style eq 'button')
		{
			my $newval = $var->{$rc} =~ /ON/ ? 'OFF' : 'ON';
			$var->{$rc} = $newval;
			$w->tagCell($newval, $rc);
		}
		elsif ($style eq 'checkbutton')
		{
			$var->{$rc} = !$var->{$rc};
			my $tag = $var->{$rc} ? 'checkbutton1' : 'checkbutton0';
			$w->tagCell($tag, $rc);
		}
	});
	
	# replace std b1-release
	$t->bind('Tcl::pTk::TableMatrix' => '<ButtonRelease-1>', \&set_style_state);
	
	# inititialize the array, titles, and celltags
	for (my $r = 0; $r < $rows; $r++)
	{
		for (my $c = 0; $c < $cols; $c++)
		{
			my $rc = "$r,$c";
			if (!$r || !$c)
			{
				$_data->{$rc} = $r || $tm->{columneditstyles}{$c} || "";
			}
			else
			{
				$_data->{$rc} = $rc;
				my $style = $tm->{columneditstyles}{$c} || 'editable';
				if ($style eq 'readonly')
				{
					$t->tagCell('readonly', $rc);
				}
				if ($style eq 'optionmenu')
				{
					$_data->{$rc} = "$r options";
					$t->tagCell('optionmenu', $rc);
				}
				elsif ($style eq 'browseentry')
				{
					$_data->{$rc} = "browse$r";
					$t->tagCell('browseentry', $rc);
				}
				elsif ($style eq 'button')
				{
					$_data->{$rc} = $r % 4 ? 'ON' : 'OFF';
					$t->tagCell($_data->{$rc}, $rc);
				}
				elsif ($style eq 'checkbutton')
				{
					$_data->{$rc} = $r % 3 ? 0 : 1;
					$t->tagCell('checkbutton' . $_data->{$rc}, $rc);
				}
			}
		}
	}
	
	
	MainLoop;
}

sub set_style_state
{
	my ($w) = @_;
	my ($r, $c) = split(/,/, $w->{_b1_row_col});
	if (grep(!$w->{columneditstyles}{$c} || $_ eq $w->{columneditstyles}{$c},
				qw(optionmenu readonly button checkbutton)))
	{
		$w->selectionClear('all');
		$w->configure(-state => 'disabled');
	}
	else
	{
		$w->configure(-state => 'normal');
		$w->activate($w->{_b1_row_col});
	}
}

sub end_edit
{
	my ($w) = @_;
	$w->configure(-state => 'disabled');
	$w->selectionClear('all');
}

sub setup_toplevel_lbox
{
	my ($w, $r, $c) = @_;

	my $toplevel = $w->{toplevel} ||=
		$w->Toplevel(-bd => 2, -relief => 'raised');
	my $lbox = $toplevel->{lbox};
	$lbox->destroy() if $lbox;
	$toplevel->overrideredirect(1);
	
	my @options = map(chr(ord('A') + $_ - 1) x $_, 1..$r);
	my $height = @options > 8 ? 8 : (@options || 1);
	my $width = 2;
	foreach (@options) { $width = length($_) if length($_) > $width; }
	$lbox = $toplevel->{lbox} =
		$toplevel->Scrolled
			(Listbox =>
			 -height => $height,
			 -width => $width + 1,
			 -relief => 'raised',
			 -borderwidth => 1,
			 -highlightthickness => 0,
			 -bg => $w->cget('bg'),
			 -scrollbars => 'oe',
			)->pack(-side => 'left');
	
	$lbox->Subwidget('scrolled')->{_table_matrix} = $w;

	$lbox->delete(0, 'end');
	$lbox->insert(0, @options);
	
	my ($gx, $gy) = ($w->rootx(), $w->rooty());
	my @bbox = $w->bbox("$r,$c");
	my ($mx, $my) = (int($gx + $bbox[0] + $bbox[2]), int($gy + $bbox[1]));

	my $toplevel_ypixels = $height * $bbox[3]
		+ $toplevel->cget("-bd") * 2 +
				$toplevel->cget("-highlightthickness");
	
	my $y2 = $my + $toplevel_ypixels;
	$my = $w->vrootheight - $toplevel_ypixels if ($y2 > $w->vrootheight);

	$toplevel->transient($w->toplevel());
	$toplevel->geometry("+$mx+$my");
	$toplevel->deiconify();
	$toplevel->raise();

	$lbox->bind('<ButtonRelease-1>',
					sub {
						my ($lbox) = @_;
						my $i = $lbox->curselection();
						my $val = $lbox->get($i);
						my $w = delete $lbox->{_table_matrix};
						my $rc = delete $w->{_b1_row_col};
						my $var = $w->cget(-var);
						$var->{$rc} = $val;
                                                $w->configure(-state => 'normal'); # Set to normal so we can set the value.
						$w->set($rc => $val);
						$w->selectionClear('all');
						$w->configure(-state => 'disabled');
						withdraw_edit_widgets($w);
					}
				  );
}

sub withdraw_edit_widgets
{
	my ($w) = @_;
	my $toplevel = $w->{toplevel};
	if ($toplevel && $toplevel->state eq 'normal')
	{
		$toplevel->withdraw();
	}
}

#--------------------------------------------------------------

sub define_bitmaps
{
	my ($w) = @_;

my $optionmenu =
'/* XPM */
static char * xpm[] = {
"11 5 3 1",
" 	c None",
"+	c #D0D0D0",
"@	c #555555",
"+++++++++++",
"++++++++++@",
"++       @@",
"++@@@@@@@@@",
"+@@@@@@@@@@"};
';



my $browseentry =
'/* XPM */
static char * xpm[] = {
"11 7 3 1",
" 	c None",
"+	c #D0D0D0",
"@	c #555555",
"+++++++++++",
"++++++++++@",
"+++     @@@",
" +++   @@@ ",
"  +++ @@@  ",
"   ++@@@   ",
"    @@@    ",
};

';



my $cbutton0 =
'/* XPM */
static char * xpm[] = {
"9 8 3 1",
" 	c None",
"@	c #B8B8B8",
"+	c #555555",
"+++++++++",
"++++++++@",
"++     @@",
"++     @@",
"++     @@",
"++     @@",
"++@@@@@@@",
"+@@@@@@@@"};
};

';



my $cbutton1 =
'/* XPM */
static char * xpm[] = {
"9 8 4 1",
" 	c None",
"@	c #B8B8B8",
"+	c #555555",
".	c #FF0000",
"+++++++++",
"++++++++@",
"++.....@@",
"++.....@@",
"++.....@@",
"++.....@@",
"++@@@@@@@",
"+@@@@@@@@"};
};

';


	my %images;
	$images{optionmenu} = $w->Photo('optionmenu',  -data => $optionmenu);
	$images{browseentry} = $w->Photo('browseentry', -data => $browseentry);
	$images{checkbutton0} = $w->Photo('cbutton0', -data => $cbutton0);
	$images{checkbutton1} = $w->Photo('cbutton1', -data => $cbutton1);
	%images;
}

