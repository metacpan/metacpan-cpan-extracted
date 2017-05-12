#!/usr/local/bin/perl -w
my $RCS_Id = '$Id: nsindex.pl,v 1.1 1998/08/13 12:59:46 eserte Exp $ ';

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Thu Aug 13 13:57:52 1998
# Update Count    : 177
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
# Tack '*' if it is not checked in into RCS.
$my_version .= '*' if length('$Locker:  $ ') > 12;

################ Command line parameters ################

use Getopt::Long 2.13;

# Location of Netscape cache
my $cachedir;

# Output options, e.g. 'site' or 'date'.
my @output;

sub app_options();

my $verbose = 0;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test (no actual processing)

app_options();

# Options post-processing.
@output = qw(site date) unless @output;
$trace |= ($debug || $test);

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || '/usr/tmp';

################ The Process ################

# Register time stamp.
my $ts = localtime;

# Open the cache index file.
use Netscape::Cache;
# If cachedir is not defined, will use default from .netscape/preferences.
my $cache = new Netscape::Cache (-cachedir => $cachedir);

# Indexes for dates/sites seen.
my %dates = ();
my %sites = ();
my $entries = 0;

# Create temp file.
my $tmp = $TMPDIR."/tp$$";
open (TMP, ">$tmp");

# Gathering phase.
{
    my $i=-1;			# entry number
    my $entry;			# value
    while ( defined ($entry = $cache->next_object) ) {
	my $url = $entry->{URL};
	$entries++;

	$url =~ s|^wysiwyg://\d+/||;

	# Decompose.
	my $site = '';
	my $proto = '';
	($proto,$site,$url) = $url =~ m|(^[^:]+)://([^/]+)(.*)$|;
	$sites{$site} = 1;	# register site


	my $file = $entry->{CACHEFILE};
	my @t = localtime ($entry->{LAST_VISITED}); # access time
	my $date = sprintf ("%4d/%02d/%02d", 1900+$t[5], 1+$t[4], $t[3]);
	$dates{$date} = 1;	# register date

	# type, e.g. text/html.
	#my $type = $entry->{MIME_TYPE};

	my $sz = $entry->{CONTENT_LENGTH};
	# Write sort record.
	print TMP ("$proto\t$site\t$url\t$file\t$date\t$sz\n");
    }
}

close (TMP);

# Output preamble.
print STDOUT ("<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML//EN\">\n",
	      "<html> <head>\n",
	      "<title>Netscape Cache</title>\n",
	      "</head>\n\n",
	      "<body bgcolor=\"white\">\n",
	      "<h1>Netscape Cache ($entries entries)</h1>\n");

# Generate output index, if needed.
if ( @output > 1 ) {
    print STDOUT ("<ul>\n");
    foreach ( @output ) {
	print STDOUT ("<li><a href=\"#srtsite\">Sorted on site</a>\n")
	  if $_ eq 'site' || $_ eq 'sitetbl';
	print STDOUT ("<li><a href=\"#srtdate\">Sorted on access date</a>\n")
	  if $_ eq 'date';
    }
    print STDOUT ("</ul>\n<p>\n");
}

# Generate output.
foreach ( @output ) {
    gen_sitesort_plain (), next if $_ eq 'site';
    gen_datesort (), next       if $_ eq 'date';
}

# Trailer.
print STDOUT ("<hr>\n",
	      "Generated [$my_name $my_version]: $ts\n",
	      "</body></html>\n");

# Remove temp file.
unlink ($tmp);

exit 0;

################ Subroutines ################

sub gen_sitesort_plain {
    my $i = -1;
    print STDOUT ("<hr>\n",
		  "<a name=\"srtsite\"><h2>Sorted on site</h2></a>\n",
		  "<p>\n<ul>\n");

    foreach ( sort(keys(%sites)) ) {
	my $d = $_;
	#$d =~ tr/\.//d;
	print STDOUT ("<li><a href=\"#x$d\">$_</a>\n");
	$sites{$_} = $d;
    }
    print STDOUT ("</ul>\n");

    open (SRT, "sort '-t	' +1 -2 +2 -3 $tmp |")
      or die ("Sort $!\n");
    my $cursite = '';
    while ( <SRT> ) {
	chomp;
	my ($proto, $site, $url, $file, $date, $size) = split (/\t/);
	if ( $cursite ne $site ) {
	    print STDOUT ("<h3><a name=\"x", $sites{$site}, 
			  "\">$site</a></h3>\n");
	    $cursite = $site;
	}
	if ( $size > 10000 ) {
	    $size = int (($size + 512) / 1024) . "K";
	}
	print STDOUT ("$date <a href=\"$file\">$url</a> ($size)<br>\n");
	$i++;
    }
    print STDERR ("sitesort: $i entries\n") if $verbose;
    close (SRT);
}

sub gen_datesort {
    my $i = -1;
    print STDOUT ("<hr>\n",
		  "<a name=\"srtdate\"><h2>Sorted on access date</h2></a>\n",
		  "<p>\n<ul>\n");

    foreach ( reverse(sort(keys(%dates))) ) {
	my $d = $_;
	$d =~ tr/\///d;
	print STDOUT ("<li><a href=\"#d$d\">$_</a>\n");
	$dates{$_} = $d;
    }
    print STDOUT ("</ul>\n");

    open (SRT, "sort +4r -5 +1 -2 +2 -3 '-t	' $tmp |")
      or die ("Sort $!\n");
    my $curdate = '';
    while ( <SRT> ) {
	chomp;
	my ($proto, $site, $url, $file, $date, $size) = split (/\t/);
	if ( $curdate ne $date ) {
	    print STDOUT ("<h3><a name=\"d", $dates{$date}, 
			  "\">$date</a></h3>\n");
	    $curdate = $date;
	}
	if ( $size > 10000 ) {
	    $size = int (($size + 512) / 1024) . "K";
	}
	print STDOUT ("<a href=\"$file\">$proto://$site$url</a> ($size)<br>\n");
	$i++;
    }
    print STDERR ("datesort: $i entries\n") if $verbose;
    close (SRT);
}

sub app_ident;
sub app_usage($);

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;
    
    if ( !GetOptions(
		     'cache=s' => \$cachedir,
		     'output=s@' => \@output,
		     'ident'	=> \$ident,
		     'verbose'	=> \$verbose,
		     'trace'	=> \$trace,
		     'help|?'	=> \$help,
		     'debug'	=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident if $ident;
    @output = split (/,/, join (',', @output));
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage($) {
    my ($exit) = @_;
    app_ident;
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    -cache XXX		cache directory, e.g. \$HOME/.netscape/ns_cache
    -output XXX		select output (site, date or both)
    -help		this message
    -ident		show identification
    -verbose		verbose information
EndOfUsage
    exit $exit if $exit != 0;
}


