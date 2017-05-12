#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: gtk_todo.pl,v 1.7 2001/07/23 15:09:50 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# gtk_todo.pl - an example for how to edit TODO items with Gtk. 
# Knows how to save its items out to a file and restore them from that file.
#
# This is fundamentally a quick hack; it should be reworked for use in the
# real world. 

use strict;

use lib '../lib';

use Carp;
use Date::Parse;
use Gtk;
use Gnome;

use Net::ICal;

my $data_dir = "~/.reefknot/";	# name of the dir where we store data.
$data_dir = "./";		# override the above for demo purposes.

my $todo_file = "todo.ics";	# file we store todo info in. 
my $DEBUG = 1;			# print debugging messages?

# convenience variables for true and false
my $false = 0;
my $true = 1;



init Gnome "gtk_todo.pl";	# initialize Gnome-Perl

#==========================================================================
# MAIN ROUTINE
#==========================================================================
my $datafilename = $data_dir . $todo_file;

# read in a calendar from the todo file, or set up a default sample
# calendar.
my $cal;
$cal = new_calendar_from_file ($datafilename) or $cal = new_default_calendar();

# print the todos to the terminal.
print_todos($cal);

# set up the GTK+/Gnome objects and run the main window loop.
setup_main_window($cal);



#==========================================================================
# FUNCTIONS FOR MAIN ROUTINE
#==========================================================================


# read in a calendar. 
sub new_calendar_from_file {
	my ($filename) = @_;

	open CALFILE, "<$filename" or (carp $! and return undef);

	undef $/; # slurp mode
	# FIXME: this is currently returning "not a valid ical stream"
	# from data saved out by the program itself. 
	my $cal = Net::ICal::Component->new_from_ical (<CALFILE>) ;
	close CALFILE;

	print "Loaded calendar from $filename\n" if ($DEBUG eq 1 and $cal);
	
	return $cal;
}

# return a default calendar setup.
sub new_default_calendar {

	my $me = new Net::ICal::Attendee('me');


	my $todos = [ 
	 		new Net::ICal::Todo (organizer => $me,
							 dtstart => new Net::ICal::Time("20010207T120000Z"),
							 summary => 'get work done',
							 percent_complete => 5,
							 due => new Net::ICal::Time("20010208T090000Z"),
				),

 			new Net::ICal::Todo (organizer => $me,
							 dtstart => new Net::ICal::Time("20010207T160000Z"),
							 summary => 'talk to PHB',
				),

			new Net::ICal::Todo (organizer => $me,
							 dtstart => new Net::ICal::Time("20010207T1630000Z"),
							 summary => 'have a meeting',
				),

			new Net::ICal::Todo (organizer => $me,
							 dtstart => new Net::ICal::Time("20010207T170000Z"),
							 summary => 'recover from meeting',
							 location => {content => 'corner pub'},
				),
		];



	my $cal = new Net::ICal::Calendar (todos => $todos);

	print "Used default calendar\n" if $DEBUG eq 1;
	return $cal;

}


# Given a calendar, print the todos on it. 
sub print_todos {
	my ($cal) = @_;
	
	my $todo_list = $cal->todos;

	print "\nThings to do:\n";

	foreach my $todo (@$todo_list) {
		print " - " . $todo->summary . " - ";
	
		print scalar $todo->dtstart->as_localtime ;

		if (defined $todo->due) {
			print " : DUE: " . scalar $todo->due->as_localtime ;
		}

		print "\n";
	
	}


	#print "\n" . $cal->as_ical;

}

# sets up the data directory if it doesn't already exist.
sub setup_datadir {	
	my ($dir) = @_;

	unless (-d $dir) {
		mkdir ($dir, 0777) or (carp $! and return undef);
	}
	return $true;
}

# saves a calendar to a file for future use. 
sub save_cal_to_file {
	#use Data::Dumper; print Dumper @_;
	my ($cal, $dir, $file) = @_;

	setup_datadir($dir) or 
		(carp "couldn't set up $dir for write" and return undef) ;
	
	my $fullpath = $dir . $file;
	
	open CALFILE, ">$fullpath" or 
		(carp "couldn't open file for write" and return undef);
	print CALFILE $cal->as_ical;
	close CALFILE or 
		(carp "couldn't close file for write" and return undef);
	
	print "Saved calendar to $dir$file.\n" if $DEBUG;

	return $true;
}


# sets up the main GTK+ window and event loop.
sub setup_main_window {
	my ($cal) = @_;

	# widget creation
	my $window = new Gtk::Window( "toplevel" );
	my $vbox = new Gtk::VBox($false, 10);
	my $hbox = new Gtk::HBox($false, 5);
	$window->add($vbox);

	my $button1 = new Gtk::Button( "Quit" );
	my $button2 = new Gtk::Button( "Output iCal");
	my $button3 = new Gtk::Button( "Save");
	
	my @titles = ('Task', 'Start Date');
	my $clist = new_with_titles Gtk::CList(@titles);

	$clist->set_column_width( 0,400 );
	$clist->set_column_width( 1,300 );
	$clist->column_titles_passive();

	$vbox->pack_start($clist, $true, $true, 0);

	$vbox->pack_start($hbox, $true, $true, 0);

	$hbox->pack_start($button1, $true, $true, 0);
	$hbox->pack_start($button2, $true, $true, 0);
	$hbox->pack_start($button3, $true, $true, 0);



	# fill the clist with todo information.
	
	my $todo_list = $cal->todos;

	foreach my $todo (@$todo_list) {
		my @row =  ($todo->summary, scalar $todo->dtstart->as_localtime);
		#use Data::Dumper; print Dumper @row;
		$clist->append(@row);
	}

	# callback registration
	$window->signal_connect( "delete_event", \&CloseAppWindow );   
	$button1->signal_connect( "clicked", \&CloseAppWindow );
	$button2->signal_connect( "clicked", \&OutputICal );
	$button3->signal_connect( "clicked", \&SaveICalToFile, $cal );
	$clist->signal_connect( "select_row", \&TodoDetail, $window);



	# set window attributes and show it
	$window->border_width( 15 );
	$window->set_title("Sample Todo Editor");

	# show button
	$button1->show();
	$button2->show();
	$button3->show();
	$clist->show();
	$hbox->show();
	$vbox->show();

	#$window->pack();
	$window->show();





	# Gtk event loop
	main Gtk;

	# Should never get here
	exit( 0 );

}

#========================================================================
# CALLBACKS
#========================================================================

### Callback function to close the main window
sub CloseAppWindow {
    Gtk->exit( 0 );
    return $false;
}

### Callback function to output ical to the terminal.
sub OutputICal {

	print "\n" . $cal->as_ical . "\n";
	return $true;
}

### Callback function to output ical to a file. Mostly just a wrapper.
sub SaveICalToFile {
	#use Data::Dumper; print Dumper @_;
	
	my ($button, $cal) = @_;
	
	# use globals for dir and filename here. Maybe this should be changed.
	save_cal_to_file ($cal, $data_dir, $todo_file) 
		or print "Failed to output ical to file\n";
	
	return $true;
}



### Callback function to pop up a detail window about a particular Todo.
sub TodoDetail {
	my ($clist, $window, $row, $column, $event) = @_;
	#print "clicked the list $row .\n";
	#print $todos->[$row] . "\n";
	
	my $todo = $cal->todos->[$row];
	
	#use Data::Dumper; print Dumper $todo->{summary}->{value};

	# set up the dialog box.
	my $dialog = new Gtk::Dialog();
	$dialog->signal_connect ("delete_event", \&saveTodo, $todo, $row, $clist, $dialog);
	$dialog->set_usize(400,200);
	

	# set up the summary editor widgets.
	my $entry_summary = new Gtk::Entry (100);
	$entry_summary->set_text ($todo->{summary}->{value});
	$entry_summary->signal_connect ("activate", \&changeTodo, "summary", $todo);

	my $label_summary = new Gtk::Label ("Summary");
	

	# set up the start date editor widgets.
	my $dte_dtstart = new Gnome::DateEdit ($todo->dtstart->as_int, $true, $true);
	$dte_dtstart->signal_connect ("date_changed", \&changeTodo, "dtstart", $todo);
	$dte_dtstart->signal_connect ("time_changed", \&changeTodo, "dtstart", $todo);


	my $label_dtstart = new Gtk::Label ("Start Date");
	

	# a close button. 
	my $button_close = new Gtk::Button("Close");
	$button_close->signal_connect("clicked", \&saveTodo, $todo, $row, $clist, $dialog);

	# pack everything together in order.
	$dialog->vbox->pack_start($label_summary, $true, $true, 0);
	$dialog->vbox->pack_start($entry_summary, $true, $true, 0);
	$dialog->vbox->pack_start($label_dtstart, $true, $true, 0);
	$dialog->vbox->pack_start($dte_dtstart, $true, $true, 0);
	
	$dialog->action_area->pack_start($button_close, $true, $true, 5);


	# display the widgets.
	$entry_summary->show();
	$label_summary->show();
	$dte_dtstart->show();
	$label_dtstart->show();
	
	$button_close->show();

	$dialog->show();
}


### callback whenever we change a value in the TodoDetail box. 
sub changeTodo {
	#use Data::Dumper; print Dumper $_[1];

	my ($entry, $item, $todo) = @_;
	# $item is the name of a field in the todo. 

	# TODO: document this usage a bit better. all the properties of
	# the todos are actually methods. 
	
	if ($item eq "dtstart") {
		
		# the DateEdit widget returns a number of seconds since 1/1/1970.
		# onvert this to an array so we can make it a Net::ICal::Time.
		my @parsed_date = gmtime($entry->get_date());
		$todo->dtstart( new Net::ICal::Time ( @parsed_date ) );

	} else {
		$todo->$item( $entry->get_text() );
	}	

	#print "set temp value for  todo summary to " . $todo->summary . "\n";
}



### callback to save our changes back to the main calendar and the main window. 
sub saveTodo {
	my ($entry, $todo, $row, $clist, $popup) = @_;
	
	$cal->todos->[$row] = $todo;
	$clist->set_text($row, 0, $todo->summary);
	$clist->set_text($row, 1, scalar $todo->dtstart->as_localtime );
	$popup->destroy();
}
