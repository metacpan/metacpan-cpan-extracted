#
# vim:ts=2:sw=2
################################################################################
#
# Orac DBI Visual Shell.
# Versions 1.0.0a
#
# Copyright (c) 1998,1999 Andy Duncan
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License,as specified in the Perl README file,with the
# exception that it cannot be placed on a CD-ROM or similar media for commercial
# distribution without the prior approval of the author.
#
# This code is provided with no warranty of any kind,and is used entirely at
# your own risk. This code was written by the author as a private individual,
# and is in no way endorsed or warrantied.
#
# Support questions and suggestions can be directed to andy_j_duncan@yahoo.com
# Download from CPAN/authors/id/A/AN/ANDYDUNC
################################################################################
#


package orac_Shell;
@ISA = qw{Shell::Do Shell::Grid};

use Exporter;

use Tk::Pretty;
use Shell::Do;
use Shell::Grid;
use DBI::Format;
use Data::Dumper;

use strict;

my ($sql_txt, $sql_entry_txt);
my ($rslt_txt, $rslt_entry_txt);

my ($opt_row_dis_c, $opt_dis_grid);
my $entry_txt;
my %color_ball;

sub new
{
   print STDERR "orac_Shell::new\n" if ( $main::debug > 0 );

   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self  = {};

   bless($self, $class);

   # save off args...
   # or other encapsulated values, these do NOT inherit!

   $self->{mw} = $_[0];
   $self->{dbh} = $_[1];

   print STDERR "orac_Shell,   new mw  >$self->{mw}<\n" if ( $main::debug > 0 );
   print STDERR "orac_Shell,   new dbh >$self->{dbh}<\n" if ( $main::debug > 0 );
		$color_ball{green} = $self->{mw}->Photo( -file => "img/grn_ball.gif" );
		$color_ball{red}   = $self->{mw}->Photo( -file => "img/red_ball.gif" );
		$color_ball{yellow}= $self->{mw}->Photo( -file => "img/yel_ball.gif" );

   return $self;
}

# Create the top level for Orac DBI Shell.

my ($dbiwd, $dbistatus, $auto_ball, $chng_ball, $button_exe);


sub dbish_open {
	my $self = shift;
	my $mw = $self->{mw};

	#
	# Determine if the dbish window is defined.  If it isn't, define the
	# window.
	#

	if (defined($self->{dbiwd})) {
		$dbiwd->deiconify();
		$dbiwd->raise();

	} else { 
		# Create a Toplevel window under the curren main.

		$dbiwd = $self->{mw}->Toplevel();

		$dbiwd->title( "Orac DBI Shell SQL" );

                $main::swc{dbish} = $dbiwd;

		# Create status label
		my $sf = $dbiwd->Frame( -relief => 'groove',
			-bd => 2 )->pack( -side => 'bottom', -fill => 'x' );
		# This is the status bar.
		$auto_ball = $sf->Label(-image=> $color_ball{green}, -borderwidth=> 2,
			-relief=> 'flat')->pack(  -side=> 'right', -anchor=>'w');
		$self->bind_message( $auto_ball, "Auto commit" );

		$chng_ball = $sf->Label(-image=> $color_ball{red}, -borderwidth=> 2,
			-relief=> 'flat')->pack(  -side=> 'right', -anchor=>'w');
		$self->bind_message( $chng_ball, "Any changed since last save" );

		$sf->Label( -textvariable => \$dbistatus )->pack(-side => 'left');


		$dbistatus = "Creating menu bar";
		my $f = $dbiwd->Frame( -relief => 'ridge', -borderwidth => 2 );
		$f->pack( -side => 'top', -anchor => 'n', -expand => 1, -fill => 'x' );

		# Put the logo on the menu bar.
		my $orac_logo = $dbiwd->Photo(-file=>'img/orac.gif');
		$f->Label(-image=> $orac_logo, -borderwidth=> 2,
			-relief=> 'flat')->pack(  -side=> 'left', -anchor=>'w');

		# Create a menu bar.
                my @menus;
		foreach (qw/File Edit Options Help/) {
			push( @menus, $f->Menubutton( -text => $_ , -tearoff => 0 ) );
		}

		$menus[3]->pack(-side => 'right' ); # Help
		$menus[0]->pack(-side => 'left' );  # File
		$menus[1]->pack(-side => 'left' );  # Edit
		$menus[2]->pack(-side => 'left' );  # Options

		#
		# Add some options to the menus.
		#
		# File menu
		$menus[0]->AddItems(
			[ "command" => "Load", -command => sub { $self->tba } ],
			[ "command" => "Save", -command => sub { $self->tba } ],
			"-",
			[ "command" => "Properties", -command => sub { $self->tba } ],
			"-",
			[ "command" => "Exit", -command => sub { $self->tba } ],
		);

		# About menu
		$menus[3]->AddItems(
			[ "command" => "Index", -command => sub { $self->tba } ],
			"-",
			[ "command" => "About", -command => sub { $self->tba } ],
		);

		# Options menu
		my $opt_disp = $menus[2]->menu->Menu;
		foreach (qw/raw neat box grid html/) {
			$opt_disp->radiobutton( -label => $_, 
				-variable => \$opt_dis_grid,
				-value => $_,
				);
		}

		$menus[2]->cascade( -label => "Display format..."); 
		$menus[2]->entryconfigure( "Display format...", -menu => $opt_disp);
		$opt_dis_grid = 'neat';

		# Create the entries for rows returned.
		my $opt_row = $menus[2]->menu->Menu;
		foreach (qw/1 10 25 50 100 all/) {
			$opt_row->radiobutton( -label => $_, -variable => \$opt_row_dis_c,
				-value => $_ );
		}
		$menus[2]->cascade( -label => "Rows return..." );
		$menus[2]->entryconfigure( "Rows return...", -menu => $opt_row);
		$opt_row_dis_c = 'all';

		# Create a button bar.
		$dbistatus = "Creating menu button bar";

		my $bf = $dbiwd->Frame( -relief => 'ridge', -borderwidth => 2 );
		$bf->pack( -side => 'top', -anchor => 'n', -expand => 1, -fill => 'x' );

		# need to invoke the execute in other parts of the application.
		$button_exe = $bf->Button( -text=> 'Execute',
			-command=> sub{ $self->execute_sql() }
			)->pack(side=>'left');

		$bf->Button( -text=> 'Clear',
			-command=>sub{
				$self->dbish_clear();
			}
		)->pack(side=>'left');

		$bf->Button( -text=> 'Tables',
			-command=> sub{ $self->tba() }
		)->pack(side=>'left');

		$bf->Button( -text=> 'Copy Results',
			-command=> sub{ $self->tba() }
		)->pack(side=>'left');

		$dbistatus = "Creating Close button";

		$bf->Button( -text => "Close",
			-command => sub { $dbiwd->withdraw;
			$self->{mw}->deiconify();
			$main::sub_win_but_hand{dbish}->configure(-state=>'active');
     } )->pack( -side => "right" ); #'

		# Create Text widget for command entry
		$dbistatus = "Creating Text entry widget";

		$entry_txt = $dbiwd->Scrolled( "Text", 
			-relief => 'groove',
			-width => 78,
			-height => 10,
			-cursor=>undef,
			-foreground=>$main::fc,
			-background=>$main::ec,
		)->pack( -side => 'bottom' );


		# Pick up the Return key ... see return_press.
		$entry_txt->bind( "<Return>", sub { $self->return_press() } );

		$dbiwd->Label(-text => ' ',
			-relief => 'groove' )->pack( -side => 'bottom', -fill => 'x' );

		# Create Text widget for results display.
		$dbistatus = "Creating Text results widget";

		$rslt_txt = $dbiwd->Scrolled( "Text", 
                                              -relief => 'groove',
                                              -width => 78, 
                                              -height => 20,
                                              -cursor=>undef,
                                              -foreground=>$main::fc,
                                              -background=>$main::bc,
																							-wrap => "none",

			                    )->pack( -side => 'bottom' );

                $main::swc{dbish}->{text} = $rslt_txt;

		# Tie the windows to the file types:
		tie (*ENTRY_TXT, 'Tk::Text', $entry_txt);
		tie (*RSLT_TXT,  'Tk::Text', $rslt_txt);

		$self->{dbishwindow} = \$dbiwd;

                # Finallly, iconize window

                main::iconize($dbiwd);
	}

	# If the auto commit is on, set the ball to green, else red.
	# This is adjusted each time the window is entered. 

	if($self->{dbh}->{AutoCommit}) {
		$auto_ball->configure( -image => $color_ball{green} );
	} else {
		$auto_ball->configure( -image => $color_ball{red} );
	}

	# Make the Main Window and icon.
        # Disable button, calling orac_Shell

	$self->{mw}->iconify();
        $main::sub_win_but_hand{dbish}->configure(-state=>'disabled');

	$dbistatus = "Window for Tk created.";
}

#  Allows the user to change auto commit.
sub auto_commit {
	
}

#
# Because I really dislike have to move the mouse up to the execute
# button, if the only character on a line is /, execute the above
# statement.
#
sub return_press {
	my $self = shift;
	my $ind = $entry_txt->index( 'insert - 1 lines' );
	my $end = $entry_txt->index( 'current' );
	my $txt = $entry_txt->get( $ind, 'insert' );
	chomp $txt;
	# The previously entered line is only a /, exeucte.
	if ($txt =~ m:[/;]$:) {
		$button_exe->invoke();
	}
}

sub bind_message {
	my $self = shift;
	my ($widget, $msg) = @_;
	$widget->bind('<Enter>', [ sub { $dbistatus = $_[1]; }, $msg ] );
	$widget->bind('<Leave>', sub { $dbistatus = ""; } );
}

sub dbish_clear {
	my $self = shift;

	$rslt_txt->delete( "1.0", 'end' );
	$entry_txt->delete( "1.0", 'end' );
	$self->release;
}
	

sub dbish {
	my $self = shift;
   return;
}

sub opt_dis_grid {
	my $self = shift;
	if (! $opt_dis_grid ) {
		$self->release();
	}
}

# Get a file from the operating system.
sub load_query {

}

# Save a file to an operating system.
sub save_query {

}

sub red {
	$auto_ball->configure( -image => $color_ball{red} );
}
sub green {
	$auto_ball->configure( -image => $color_ball{green} );
}

sub tba {
	my $self = shift;
	print RSLT_TXT "Work in progress ...\n";
	0;
}

sub execute_sql {

   my $self = shift;

	 $dbiwd->Busy;
	 my $statement = $entry_txt->get("1.0", 'end' );
	 chomp $statement;
	 $statement =~ s:[/;](\s)+$::;  # Replace the last / with nothing.
	 
	 my $dbh = $self->{dbh};
	 unless($dbh) {
		$dbistatus = "Database handle not openned!";
	 	return;
	 }

	 my $sth = $self->do_prepare( $statement );

	$sth->execute;

	# print RSLT_TXT "Number of fields: " . $sth->{NUM_OF_FIELDS} . "\n";
	#
	# Dump return set to a grid.
	#	
	$dbh->{neat_maxlen} = 40004;
	my $class = DBI::Format->formatter($opt_dis_grid);
	my $r = $class->new($self);
	$r->header($sth, \*RSLT_TXT, ",");

	my $row;
	while( $row = $sth->fetchrow_arrayref() ) {
		$r->row($row, \*RSLT_TXT, "," );
	}
	$r->trailer(\*RSLT_TXT);
	$sth->finish;
	$dbiwd->Unbusy;
}
1;
