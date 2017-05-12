package QWizard::Generator::Tk;

#
# TODO:
#  - better layout; currently ugly
#  - bar support
#  - left/right side support

use strict;
my $VERSION = '3.15';
use Tk;
use Tk::Table;
use Tk::Pane;
use Tk::FileSelect;
require Exporter;
use QWizard::Generator;

@QWizard::Generator::Tk::ISA = qw(Exporter QWizard::Generator);

my $have_gd_graph = eval { require GD::Graph::lines; };
my $have_tk_tree = eval { require Tk::Tree; };
my $have_tk_png = eval { require Tk::PNG; };

sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my $self = {'keep_working_hook' => \&QWizard::Generator::backup_params};
    for (my $i = 0; $i <= $#_; $i += 2) {
	$self->{$_[$i]} = $_[$i+1];
    }
    bless($self, $class);
    $self->add_handler('text',\&QWizard::Generator::Tk::do_entry,
		       [['single','name'],
			['default'],
			['forced','0'],
			['single','size'],
			['single','maxsize'],
			['single','submit'],
			['single','refresh_on_change']]);
    # XXX: we need to do a real text box
    $self->add_handler('textbox',\&QWizard::Generator::Tk::do_textbox,
		       [['single','name'],
			['default'],
			['single','size'],
			['single','width'],
			['single','height']]);
    $self->add_handler('hidetext',\&QWizard::Generator::Tk::do_entry,
		       [['single','name'],
			['default'],
			['forced','1'],
			['single','size'],
			['single','maxsize'],
			['single','submit'],
			['single','refresh_on_change']]);
    $self->add_handler('checkbox',\&QWizard::Generator::Tk::do_checkbox,
		       [['multi','values'],
			['default'],
			['single','button_label']]);
    $self->add_handler('multi_checkbox',
		       \&QWizard::Generator::Tk::do_multicheckbox,
		       [['multi','default'],
			['values,labels']]);
    $self->add_handler('menu',
		       \&QWizard::Generator::Tk::do_menu,
		       [['values,labels'],
			['default'],
			['single','name']]);
    $self->add_handler('radio',
		       \&QWizard::Generator::Tk::do_radio,
		       [['values,labels', "   "],
			['default'],
			['single','name']]);
    $self->add_handler('label',
		       \&QWizard::Generator::Tk::do_label,
		       [['multi','values']]);
    $self->add_handler('paragraph',
		       \&QWizard::Generator::Tk::do_paragraph,
		       [['multi','values'],
			['single','preformatted'],
			['single','width']]);
    $self->add_handler('button',
		       \&QWizard::Generator::Tk::do_button,
		       [['single','values'],
			['default']]);
    $self->add_handler('table',
		       \&QWizard::Generator::Tk::do_table,
		       [['norecurse','values'],
			['norecurse','headers']]);
    $self->add_handler('graph',
		       \&QWizard::Generator::Tk::do_graph,
		       [['norecurse','values'],
			['norecursemulti','graph_options']]);
    $self->add_handler('image',
		       \&QWizard::Generator::Tk::do_image,
		       [['norecurse','imgdata'],
			['norecurse','image'],
			['single','imagealt']]);
    $self->add_handler('fileupload',
		       \&QWizard::Generator::Tk::do_fileupload,
		       [['default','values']]);
    $self->add_handler('filedownload',
		       \&QWizard::Generator::Tk::do_filedownload,
		       [['default','values']]);

    $self->add_handler('unknown',
		       \&QWizard::Generator::Tk::do_unknown,
		       []);

    $self->init_default_storage();
    return $self;
}

sub goto_top {
    my $self = shift;
    my $wiz = shift;
    $self->unmake_top();
    $wiz->reset_qwizard();
}

sub goto_next {
#     print STDERR "-----\n";
#     for (my $i = 0; $i <= $#_; $i++) {
# 	print STDERR "next $i: $_[$i]\n";
#     }
#     my @stuff = caller(1);
#     print STDERR "$stuff[1] $stuff[2] -> $stuff[3]\n";
#     my @stuff = caller(2);
#     print STDERR "$stuff[1] $stuff[2] -> $stuff[3]\n";
#     my @stuff = caller(3);
#     print STDERR "$stuff[1] $stuff[2] -> $stuff[3]\n";
#     my @stuff = caller(4);
#     print STDERR "$stuff[1] $stuff[2] -> $stuff[3]\n";
#     print STDERR "-----\n";
    shift if (ref($_[0]) ne 'QWizard::Generator::Tk');
    my ($self, $ignorefirst_or_varname, $refresh_on_change, $val) = @_;
    if ($ignorefirst_or_varname &&
	ref($ignorefirst_or_varname) eq 'SCALAR' && $$ignorefirst_or_varname) {
	$$ignorefirst_or_varname--;
	return;
    } elsif (ref($ignorefirst_or_varname) ne 'SCALAR') {
	if ($ignorefirst_or_varname) {
	    $self->qwparam($ignorefirst_or_varname, $val);
	}
    }
    if ($refresh_on_change) {
	$self->qwparam('redo_screen',1);
    }

    $self->unmake_top();
#    print STDERR "-----x\n";
}

sub goto_prev {
    my ($self) = @_;
    $self->revert_params();
    $self->unmake_top();
}

sub our_mainloop {
    my $self = shift;
    while ($self->{'qtable'} && Tk::MainWindow->Count) {
	if ($self->{'nextf'}) {
	    $self->{'nextf'}->focus();
	    $self->{'nextf'} = undef;
	}
	DoOneEvent(0);
    }
}

sub unmake_top {
    my $self = shift;
    $self->{'qtable'}->destroy() if ($self->{'qtable'});
    $self->{'qtable'} = undef;
}

sub make_top {
    my $self = shift;
    $self->unmake_top();

    if (!$self->{'top'}) {
	$self->{'top'} = $self->{'window'}->Frame();
	$self->{'top'}->pack(-expand => 1, -fill => 'both');
	my $haveballoon = eval {require Tk::Balloon;};
	if ($haveballoon) {
	    $self->{'balloon'} = $self->{'top'}->Balloon();
	}
    }

    my $px = $self->{'top'}->width();
    my $py = $self->{'top'}->height();
    $px = $self->{'qwidth'} || 600 if ($px < 600);
    $py = $self->{'qheight'} || 500 if ($py < 500);

    if (!$self->{'qtitle'}) {
	$self->{'qtitle'} = $self->{'top'}->Label();
	$self->{'qtitle'}->pack(-side => 'top');
    }
    if (!$self->{'qintro'}) {
	$self->{'qintro'} = $self->{'top'}->Scrolled('Text',
						     -scrollbars => 'w',
						     -width => $px, 
						     -height => 200,
						     -wrap => 'word',
						     -relief => 'flat');
	$self->{'qintro'}->pack(-side => 'top', -expand => 1, -fill => 'both');
    }
    if (!$self->{'qpane'}) {
	$self->{'qpane'} = $self->{'top'}->Scrolled('Pane', -width => $px, 
						    -height => $py,
						    -sticky => 'nsew');
	$self->{'qpane'}->pack(-expand => 1, -fill => 'both');
    }
    $self->{'qtable'} = $self->{'qpane'}->Table(-rows => 200,
						-columns => 10,
						-scrollbars => '');
    $self->{'qtable'}->pack(-expand => 1, -fill => 'both');

    # we make some decisions based on which table we're currently
    # pointing at; thus remember the original.
    $self->{'origqtable'} = $self->{'qtable'};
}

sub init_screen {
    my ($self, $wiz, $title) = @_;
    if (!$self->{'window'}) {
	$self->{'window'} = new MainWindow(
					-title => $title,
					#-background => $self->{'bgcolor'} || $wiz->{'bgcolor'} || "#ffffff"
				       );
	$self->{'tktitle'} =
	  $self->{'window'}->Label(-text => $title,
				   -relief => 'raised',
				   -foreground => '#ffa26c',
				   -background => $self->{'bgcolor'} ||
				                  $wiz->{'bgcolor'} ||
				                  "#ffffff");
	$self->{'tktitle'}->pack(-expand => 1, -fill => 'x', -side => 'top');
    }
    $self->make_top();
    $self->{'qadd'} = 0;
}

sub do_ok_cancel {
  my ($self, $nexttext, $wiz, $dontdocan) = @_;
  if (!$self->{'bot'}) {
      $self->{'bot'} = $self->{'top'}->Frame(-relief => 'raised',
					     -borderwidth => 3);
      if (!$self->{'prevbut'}) {
	  $self->{'prevbut'} = 
	    $self->{'bot'}->Button(-text => ($wiz->{'back_text'} || 
						 'Back'),
				   -command => [\&goto_prev, 
						$self]);
	  $self->{'prevbut'}->pack(-side => 'left');
      }
      if (!$self->{'nextbut'}) {
	  my $text =
	    QWizard::Generator::remove_accelerator($nexttext  ||
						   $wiz->{'next_text'} || 
						   'Next');
	  $self->{'nextbut'} = 
	    $self->{'bot'}->Button(-text => $text,
				   -command => [\&goto_next, 
						$self]);
	  $self->{'nextbut'}->pack(-side => 'left');
      }
      if (! $dontdocan) {
	  if (!$self->{'canbut'}) {
	      $self->{'canbut'} = 
		$self->{'bot'}->Button(-text => ($wiz->{'cancel_text'} || 
						 'Cancel'),
				       -command => [\&goto_top, $self, $wiz]);
	      $self->{'canbut'}->pack(-side => 'right');
	  }
      }
      $self->{'bot'}->pack(-expand => 1, -fill => 'x');
  } else {
      my $text =
	QWizard::Generator::remove_accelerator($nexttext || 'Ok');
      $self->{'nextbut'}->configure(-text => $text);
  }

  # see if we have backup places to get to.  If not, grey out the button
  if ($#{$self->{'backupvars'}} > -1) {
      $self->{'prevbut'}->configure(-state => 'normal');
  } else {
      $self->{'prevbut'}->configure(-state => 'disabled');
  }
}


# put stuff at a particular spot in the current table
sub put_it {
    my ($self, $w, $row, $col) = @_;
    if (!$row) {
	if (exists($self->{'currentrow'}) && defined($self->{'currentrow'})) {
	    $row = $self->{'currentrow'};
	} else {
	    $row = $self->{'currentq'};
	}
    }
    if (!$col) {
	if (exists($self->{'currentcol'}) && defined($self->{'currentcol'})) {
	    $col = $self->{'currentcol'};
	} else {
	    $col = 2;
	}
    }

    # remove the temp assignments

    if (ref($w) eq '') {
	$w = $self->{'qtable'}->Label(-text => $w,
				      -anchor => 'w');
    }

    # place the item in the table
    $self->{'qtable'}->put($row, $col, $w);

    # bind the tab and alt-tab key presses to forward and backward widgets
    if (ref($w) =~ /Entry|Menu|Text|Button|Checkbutton|Radio|Optionmenu/) {
	if ($self->{'lastw'}) {
	    $self->{'lastw'}->bind('<Tab>',[\&tab_next, $w, $self]);
	    $w->bind('<Alt-Key-Tab>',[\&tab_next, $self->{'lastw'}, $self]);
	}
	$self->{'lastw'} = $w;
    }
}

sub tab_next {
    # forcing the focus here doesn't work (I suspect because the top
    # level tab binding gets called after us and takes precidence and
    # focuses away from our containing table.  Thus we save our focus
    # call for even later)
    $_[2]->{'nextf'} = $_[1];
}

sub set_default {
    my ($self, $q, $def) = @_;
    $self->qwparam($q->{'name'}, $def) if ($def && $self->qwparam($q->{'name'}) ne $def);
}

######################################################################
# QWizard functions for doing stuff.

sub wait_for {
  my ($self, $wiz, $next) = @_;
  $self->do_ok_cancel($next, $wiz);
  $self->our_mainloop();
  return 1;
}

sub do_error {
    my ($self, $q, $wiz, $p, $err) = @_;
    $self->{'currentq'}++;
    $self->{'qadd'}++;
    $self->put_it($self->{'qtable'}->Label(-text => $err, 
					   -foreground => 'red'),
		  undef, 1);

}

sub do_question {
    my ($self, $q, $wiz, $p, $text, $qcount) = @_;
    my $top = $self->{'qtable'};

    $self->{'currentq'} = $qcount + $self->{'qadd'};
    return if (!$text && $self->{'qtable'} != $self->{'origqtable'});

    #
    # Get the actual help text, in case this is a subroutine.
    #
    my $helptext = $q->{'helpdesc'};
    if (ref($helptext) eq "CODE") {
	$helptext = $helptext->();
    }

    $text = "    $text" if ($q->{'indent'});
    if ($helptext && !$self->qwpref('usehelpballons')) {
	my $f = $top->Frame();
	$f->Label(-text => $text, -anchor => 'nw')->pack(-anchor => 'w');
	$helptext = "    $helptext" if ($q->{'indent'});
	$helptext = " $helptext";
	my $height = int(length($helptext)/40)+1;
	my $t = $f->Text(-width => 40,
			 -height => $height,
			 -relief => 'flat',
			 -wrap => 'word',
			 -font => 'Helvetica 12 italic')
	  ->pack(-anchor => 'w');
	$t->insert('end', $helptext);
	$self->put_it($f, undef, 1);
    } else {
	my $l = $top->Label(-text => $text, -anchor => 'nw');
	$self->put_it($l, undef, 1);
	if ($self->{'balloon'} && $helptext) {
	    $self->{'balloon'}->attach($l, -balloonmsg => $helptext);
	    # XXX: change the "help" window text, which doesn't exist yet.
	}
    }
}

sub start_questions {
    my ($self, $wiz, $p, $title, $intro) = @_;
    if ($title) {
	$self->{'qtitle'}->configure(-text => $title);
    }
	
    $self->{'qintro'}->delete('1.0','end');
    if ($intro) {
	$self->{'qintro'}->configure(-height => (length($intro)/80 + 1));
	$self->{'qintro'}->insert('end',$intro);
    } else {
	$self->{'qintro'}->configure(-height => 0);
    }
}

sub end_questions {
    my $self = shift;
    # this makes us keep adding new table rows during a merge
    $self->{'qadd'} = $self->{'currentq'} + 1;
    $self->{'lastw'} = undef;
}


##################################################
# widgets
##################################################

sub get_extra_args {
    my ($self, $q, $wiz) = @_;

    my @args;

    if (($q->{'submit'} || $q->{'refresh_on_change'}) &&
      $q->{type} ne 'text') {
	my $ignorefirst = 0;
	if ($q->{'type'} eq 'menu') {
	    # menus do an initial call immediately after being created.
	    # we use this hack to ignore the first call to the function.
	    # (did I mention "sigh"?)
#	    my $wehere = $self->qwparam('redo_screen');
#	    print "setting ignoring first: $wehere\n";
#	    $ignorefirst = 1 unless($wehere eq '') ;
	    $ignorefirst = 1;
	}
	push @args, '-command', [\&goto_next, $self, \$ignorefirst,
				 $q->{'refresh_on_change'}];
    }
    return \@args;
}

sub make_check {
    my ($self, $name, $text, $on, $off, $top, $defval) = @_;

    my $x = "hi";
    $top = $self->{'qf'} if (!$top);
    $top->Checkbutton(-textvariable => \$text,
		      -variable => \$self->{'datastore'}{'vars'}{$name},
		      -anchor => 'w')
      ->pack(-side => 'top', -expand => 1, -fill => 'x');
}


sub do_button {
    my ($self, $q, $wiz, $p, $vals, $def) = @_;
    my $but = $self->{'qtable'}->Button(-text => $vals,
					-command => [\&goto_next, 
						     $self, $q->{'name'},
						     $q->{'refresh_on_change'},
						     $def]);
    $self->put_it($but);
}

sub do_checkbox {
    my ($self, $q, $wiz, $p, $vals, $def, $button_label) = @_;
    $vals = [1, 0] if ($#$vals == -1);
    my $chk = $self->{'qtable'}->Checkbutton(-anchor => 'w',
  					     -onvalue => $vals->[0],
  					     -offvalue => $vals->[1],
					     -text => $button_label,
					     -variable => 
					     \$self->{'datastore'}{'vars'}{$q->{'name'}},
					     @{$self->get_extra_args($q, $wiz,
								     $p)}
					    );
    $self->put_it($chk);
    $self->set_default($q, $def);
}

sub do_multicheckbox {
    my ($self, $q, $wiz, $p, $defs, $vals, $labels) = @_;
    my $tf = $self->{'qtable'}->Frame();
    my $count = -1;
    foreach my $v (@$vals) {
	$count++;
	my $l = (($labels->{$v}) ? $labels->{$v} : "$v");
	make_check($self, $q->{'name'} . $l, $l, $v, '', $tf);
	push @{$wiz->{'passvars'}},$q->{'name'} . $v;
	$self->{'datastore'}->set($v, $defs->[$count]);
    }
    $self->put_it($tf);
}

sub do_radio {
    my ($self, $q, $wiz, $p, $vals, $labels, $def, $name) = @_;
    my $tf = $self->{'qtable'}->Frame();

    my $widargs = $self->get_extra_args($q, $wiz, $p);

    foreach my $val (@$vals) {
	my $text = (($labels->{$val}) ? $labels->{$val} : "$val");
	$tf->Radiobutton(-value => $val, -textvariable => \$text,
			 -variable => \$self->{'datastore'}{'vars'}{$name},
			 -anchor => 'w',
			 @{$self->get_extra_args($q, $wiz, $p)})
	  ->pack(-side => 'top', -fill => 'x', -expand => 1);
    }
    $self->put_it($tf);

    $self->set_default($q, $def);
}

sub do_label {
    my ($self, $q, $wiz, $p, $vals, $def) = @_;
    if (defined ($vals)) {
	foreach my $i (@$vals) {
	    $self->put_it($i);
	}
    }
}

sub do_paragraph {
    my ($self, $q, $wiz, $p, $vals, $preformatted, $width) = @_;
    my $w = $width || 80;
    foreach my $i (@$vals) {
	my $t;
	if ($preformatted) {
	    my $c = $i;
	    $c =~ s/[^\n]//g;  # XXX: must be a better and more efficient way
	    $t = $self->{'qtable'}->Scrolled('Text', -width => $w, 
					     -height => length($c) || 24,
					     -wrap => 'none',
					     -relief => 'flat');
	} else {
	    $t = $self->{'qtable'}->Text(-width => $w,
					 -height => 
					 int(length($i)/40) + 1,
					 -wrap => 'word',
					 -relief => 'flat');
	}
	$t->insert('end',$i);
	$self->put_it($t);
    }
}

sub do_menu {
    my ($self, $q, $wiz, $p, $vals, $labels, $def, $name) = @_;

    my @items;
    foreach my $v (@$vals) {
	if ($labels->{$v}) {
	    push @items, [ $labels->{$v} => $v ];
	} else {
	    push @items, $v;
	    $labels->{$v} = $v;
	}
	if (defined($def) && $v eq $def) {
	    # Tk::Optionmenu sucks badly when it comes to default; the
	    # default value must be the first in the list because that
	    # is what is shown.  ugh.  XXX: maybe use a Tk::BrowseEntry?
	    unshift @items, (pop @items);
	}
    }

    $self->set_default($q, $def);
    $self->put_it($self->{'qtable'}->Optionmenu(-options => \@items,
						-variable => \$self->{'datastore'}{'vars'}{$name},
						-relief => 'raised',
						@{$self->get_extra_args($q, $wiz, $p)}));
}

sub select_openfile {
    my ($self, $name, $widget) = @_;

    my $file = $self->{'qtable'}->getOpenFile();
    $widget->configure(-text => 'Select File: ' . $file);
    $self->qwparam($name, $file) if ($file ne '');
}

sub do_fileupload {
    my ($self, $q, $wiz, $p, $def) = @_;

    my $openbutton = 
      $self->{'qtable'}->Button(-text => 'Select File...');
    $openbutton->configure(-command => [\&select_openfile,
					$self, $q->{'name'}, $openbutton]);
    $self->put_it($openbutton);
    $self->set_default($q, $def);
}

sub select_savefile {
    my ($self, $name, $data, $datafn, $qw, $q, $p, $widget) = @_;
    my $file = $self->{'qtable'}->getSaveFile();
    $widget->configure(-text => 'Select File: ' . $file);
    my $fileh = new IO::File;
    $fileh->open('>' . $file);

    # save the question data field
    if ($data) {
	print $fileh $data;
    }

    # call the datafn routine as well
    if ($datafn && ref($datafn) eq 'CODE') {
	$datafn->($fileh, $file, $qw, $q, $p);
    }

    # close the output file
    $fileh->close();

    $self->qwparam($name, $file) if ($file ne '');
}

sub do_filedownload {
    my ($self, $q, $wiz, $p, $def) = @_;

    my $openbutton = 
      $self->{'qtable'}->Button(-text => 'Select File...');
    $openbutton->configure(-command => [\&select_savefile,
					$self, $q->{'name'},
					$q->{'data'}, $q->{'datafn'},
					$wiz, $q, $p, $openbutton]);
    $self->put_it($openbutton);
    $self->set_default($q, $def);
}

sub do_entry {
    my ($self, $q, $wiz, $p, $name, $def, $hide) = @_;
    $self->{'datastore'}->set($q->{'name'}, $def);

    #
    # Set up a value to use if the text shouldn't be echoed to the screen.
    #
    my $hideval;
    if ($hide) {
	$hideval = '*';
    }

    $self->put_it($self->{'qtable'}->Entry(-textvariable => \$self->{'datastore'}{'vars'}{$name}, -show => $hideval, @{$self->get_extra_args($q, $wiz, $p)}));
    $self->set_default($q, $def);
}

sub do_textbox {
    my ($self, $q, $wiz, $p, $vals, $def) = @_;
    my ($self, $q, $wiz, $p, $name, $def, $size, $width, $height) = @_;
    my $tb =
      $self->{'qtable'}->Text(-width => ($size || $width || 80),
			      -height => ($height || 8),
			      -wrap => 'none',
#			      -relief => 'flat',
			      @{$self->get_extra_args($q, $wiz, $p)});

    $tb->bind('<Any-Leave>',
	      sub { $self->{'datastore'}{'vars'}{$name} =
		      $_[0]->get('0.0','end'); });
    $tb->insert('end',$def || "",'geoqotext');
    $self->set_default($q, $def);
    $self->put_it($tb);
}

sub do_separator {
    my ($self, $q, $wiz, $p, $text) = @_;
    my $where = $self->{'qf'};
    $self->{'currentq'}++;
    $self->{'qadd'}++;
    if (!$where) {
	$where = $self->{'top'}->Frame();
	$where->pack(-expand => 1, -fill => 'x');
    }
    $self->put_it($text);
}

##################################################
# Display
##################################################

sub do_a_table {
    my ($self, $table, $parentt, $rowc, $wiz, $q, $p) = @_;

    foreach my $row (@$table) {
	my $col = 0;
	$rowc++;
	foreach my $column (@$row) {
	    if (ref($column) eq "ARRAY") {
		# sub table
		my $newt = $parentt->Table(-rows => 200,
					   -columns => 100,
					   -scrollbars => '');
		$self->do_a_table($column, $newt, -1, $wiz, $q, $p);
		$parentt->put($rowc, $col++, $newt);
	    } elsif (ref($column) eq "HASH") {
		my $oldqt = $self->{'qtable'};
		$self->{'qtable'} = $parentt;

		my $oldq = $self->{'currentq'};

		my $oldrow = $self->{'currentrow'};
		$self->{'currentrow'} = $rowc;

		my $oldc = $self->{'currentcol'};
		$self->{'currentcol'} = $col;
		$col++;
		
		my $subname = $wiz->ask_question($p, $column);
		push @{$wiz->{'passvars'}}, $subname if ($subname);

		$self->{'qtable'} = $oldqt;
		$self->{'currentq'} = $oldq;
		if ($oldc) {
		    $self->{'currentcol'} = $oldc;
		} else {
		    delete $self->{'currentcol'};
		}
		if ($oldrow) {
		    $self->{'currentrow'} = $oldrow;
		} else {
		    delete $self->{'currentrow'};
		}

	    } else {
		$parentt->put($rowc, $col++, 
			      $parentt->Label(-text =>
					      $self->make_displayable($column),
					      -anchor => 'w'));
	    }
	}
    }
}

sub do_table {
    my ($self, $q, $wiz, $p, $table, $headers) = @_;

    my $fixed = ($headers) ? 1 : 0;
    my $f = $self->{'qtable'}->Frame(-relief => 'raised', -border => 3);
    my $tab = $f->Table(-rows => 1000, #($#$table + $fixed + 1),
			-columns => 1000, #($#{$table->[0]} + 1),
			-fixedrows => $fixed,
			-scrollbars => '');
    $tab->pack();
    if ($headers) {
	my $col = 0;
	foreach my $column (@$headers) {
	    $tab->put(0, $col++, $tab->Label(-text => $column,
					     -relief => 'raised',
					     -anchor => 'w',
					     -border => 3));
	}
    }

    $self->do_a_table($table, $tab, $fixed-1, $wiz, $q, $p);

    $self->put_it($f);
}

sub do_graph {
    my $self = shift;
    my ($q, $wiz, $p, $data, $gopts) = @_;

    if ($have_gd_graph) {
	require MIME::Base64;
	# grrr...  photo requires data to be in base64 or a file.  Why???
	my $photo = $self->{'qtable'}->Photo(
					     -data => 
					     MIME::Base64::encode_base64(
						    $self->do_graph_data(@_)
									),
					    );
	$self->put_it($self->{'qtable'}->Label(-image => $photo,
					       -anchor => 'w'));
    } else {
	$self->put_it("Graphing support not available.");
    }
}

##############################################
#
sub do_image {
	my $self = shift;
	my ($q, $wiz, $p, $datastr, $filestr, $imgalt) = @_;

	my $ph;
	if ($have_tk_png) {
	    if ($datastr) {
		require MIME::Base64;
		$ph = $self->{'qtable'}->Photo(
					       -format => 'png',
					       -data =>
					       MIME::Base64::encode_base64($datastr));

	    } else {
		# image file
		$ph = $self->{'qtable'}->Photo(-format => 'png',
					       -file => $wiz->{'generator'}{'imagebase'} . $filestr);
	    }
	}
	if ($ph) {
	    $self->put_it($self->{'qtable'}->Label(-image => $ph,
						   -anchor => 'w'));
	} else {
	    $self->put_it($self->{'qtable'}->Label(-text => $imgalt || "Broken Image"));
	}
}

##################################################
# Trees
##################################################

sub do_tree {
    my ($self, $q, $wiz, $p, $labels) = @_;

    if (!$have_tk_tree) {
	print STDERR "Tree support not available.  Install the Tk::Tree perl module\n";
    }

    my $top = $self->{'qtable'} || $self->{'top'};
    my $tree = $self->{'qtable'}->ScrlTree(-width => 40,  #size that looked good to me
					   -height => 14,
					   -scrollbars => 'osoe');

    my @expand;
    if ($q->{'default'}) {
	#ensure that the default is initially visible
	my $cur = $q->{'default'};
	until ($cur eq $q->{'root'}) {
	    $cur = get_name($q->{'parent'}->($wiz, $cur));
	    unshift @expand, $cur;
	}
	$self->{'datastore'}->set($q->{'name'},$q->{'default'}) if $q->{'name'};
    }

    add_node($wiz, $tree, $q->{'root'}, $q, "", $labels, @expand);

    $tree->configure( -opencmd => sub { my $branch = shift;
					open_branch($wiz, $tree, $branch,
						    $q, $labels) } );
    $tree->configure( -browsecmd => sub { if ($q->{'name'}) {
	                                     my @sel = $tree->infoSelection();
					     my $node = ($#sel > -1 ? 
							  $tree->infoData($sel[0]) : "");
					     $self->{'datastore'}->set($q->{'name'}, $node);
					 } } );

    $self->put_it($tree);
}

sub get_name {
    my $node = shift;

    if (ref($node) eq 'HASH') {
	return $node->{'name'};
    } else {
	return $node;
    }
}

sub add_node {
    my ($wiz, $tree, $node, $q, $parent, $labels, @expand) = @_;

    my $label;
    my $exp = shift @expand;
    my $name = get_name($node);
    if (ref($node) eq 'HASH') {
	$label = $node->{'label'};
    }
    $label = $label || $labels->{$name} || $name;

    #text of the node is the label. data is the identifier.
    my $child = $tree->addchild($parent, -text => $label,
				-data => $name);
    my $ans = $q->{'children'}->($wiz, $node);
    $tree->setmode($child, ($ans && $#$ans > -1) ? 'open' : 'none');

    $tree->selectionSet($child) if ($name eq $q->{'default'});
    if ($name eq $exp) {
	$tree->open($child);
	open_branch($wiz, $tree, $child, $q, $labels, @expand);
    }
}

sub open_branch {
    my ($wiz, $tree, $branch, $q, $labels, @expand) = @_;

    if (my @children = $tree->infoChildren($branch)) {
	#we've already opened this branch, so just reopen it
	foreach my $child (@children) {
	    $tree->show( -entry => $child);
	}
	return;
    }

    my $children = $q->{'children'}->($wiz, $tree->infoData($branch));
    return if (!$children || $#$children == -1);
    foreach my $child (@$children) {
	add_node($wiz, $tree, $child, $q, $branch, $labels, @expand);
    }
}

##################################################
#
# Automatic updating for monitors.
#

sub do_autoupd
{
	#
	# Dummy routine for now!
	#
	warn "Tk.do_autoupd:  currently no automatic updating is defined for Tk.  This should be fixed RSN.\n"
}

##################################################
# unknown type errors
#
sub do_unknown {
    my ($self, $q, $wiz, $p) = @_;
    $self->{'currentq'}++;
    $self->{'qadd'}++;
    $self->put_it($self->{'qtable'}->Label(-text => "Unknown question type '$q->{type}' not handled in primary '$p->{module_name}'.  It is highly likely this application will no longer function properly beyond this point.",
					   -foreground => 'red'));
}


##################################################
# action confirm
##################################################

sub start_confirm {
    my ($self, $wiz) = @_;

    $self->make_top();
    $self->put_it('Wrapping up.',1,1);
    $self->put_it('Do you want to commit the following changes:',2,1);
    $self->{'resultf'} = $self->{'qtable'}->Frame(-relief => 'sunken',
						  -border => 3);
    $self->put_it($self->{'resultf'},3,1);
}

sub end_confirm {
    my ($self, $wiz) = @_;
    # this will be deleted by the cancel button if they press it.
    $self->do_hidden($wiz, 'wiz_confirmed', 'Commit');
    $self->do_ok_cancel("Commit", $wiz);
    $self->our_mainloop();
    return 1;
}

sub do_confirm_message {
    my ($self, $wiz, $msg) = @_;
    $self->{'resultf'}->Label(-justify => 'left', -text => $msg, -anchor => 'w')
      ->pack(-expand => 1, -fill => 'x');
}

sub canceled_confirm {
    my ($self, $wiz) = @_;
    goto_top();
}

##################################################
# actions
##################################################

sub start_actions {
    my ($self, $wiz) = @_;
    $self->make_top();
    $self->put_it('Processing your request...',1,1);
    $self->{'resultf'} = $self->{'qtable'}->Frame(-relief => 'sunken',
						  -border => 3);
    $self->put_it($self->{'resultf'},2,1);
}

sub end_actions {
    my ($self, $wiz) = @_;
    $self->put_it('Done',3,1);
    $self->do_ok_cancel("Finish", $wiz);
    $self->clear_params();
    $self->our_mainloop();
    return 1;
}

sub do_action_output {
    my ($self, $wiz, $action) = @_;
    $self->{'resultf'}->Label(-text => $action, -anchor => 'w')->pack(-expand => 1, -fill => 'x');
}

sub do_action_error {
    my ($self, $wiz, $errstr) = @_;
    $self->{'resultf'}->Label(-text => $errstr, -foreground => 'red',
			  -anchor => 'w')
      ->pack(-expand => 1, -fill => 'x');
}

1;
