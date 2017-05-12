#!/usr/bin/perl  -T -I. 
# vim:ts=8 sw=4 sts=4 ai
=head1 NAME

show.cgi - CGI script to show data from an SQLite database

=head1 VERSION

This describes version B<0.01> of show.cgi.

=cut

our $VERSION = '0.01';

=head2 SYNOPSIS

    http://www.example.com/show.cgi?Table=episodes

=head2 DESCRIPTION

CGI script to show data for an SQLite database.
If run with no arguments, will print a form with tables to select from.
Once a table is selected, it prints a form with search criteria;
when the search critera are filled in, it will print a report.

=head2 Configuration

Before the script is run, it needs to be configured.  This is done
by setting the correct values in the %InitArgs hash (just below
if you are looking at the source of this file).

The minimum requirement is to set the 'database' value; this must be
the name of the SQLite database file which this script accesses.

See L<SQLite::Work/new> and L<SQLite::Work::CGI/new> for more information
about possible arguments to give.

=cut

our %InitArgs = (
    database=>'test1.db',
);

=head2 Author

Kathryn Andersen. <perlkat@katspace.com>
Created: 2005

=cut
require 5.8.3;
$ENV{PATH} = "/bin:/usr/bin:/usr/local/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV'};

#------------------------------------------------------------------
# User-customizable Global variables

#------------------------------------------------------------------
# Includes
use SQLite::Work::CGI;
use strict;

#------------------------------------------------------------------
# Main

MAIN: {
    # this creates a new CGI object which has already parsed the query
    my	$tvdb = SQLite::Work::CGI->new(%InitArgs);

    if ($tvdb->do_connect())
    {
	if ($tvdb->{cgi}->param('Table'))
	{
	    if ($tvdb->{cgi}->param('Search'))
	    {
		$tvdb->do_select($tvdb->{cgi}->param('Table'));
	    }
	    else
	    {
		$tvdb->do_search_form($tvdb->{cgi}->param('Table'));
	    }
	}
	else
	{
	    $tvdb->do_table_form();
	}
	$tvdb->do_disconnect();
    }
}
