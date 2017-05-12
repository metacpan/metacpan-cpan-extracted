#!/usr/local/bin/perl 
# -*- Perl -*- 		# Mon Apr 26 14:09:21 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2004, Tim Skirvin. 
# Redistribution terms are below.
###############################################################################
our $VERSION = "0.11";

###############################################################################
### User Configuration ########################################################
###############################################################################
use vars qw( $LOCALCONF $KIBOZEDIR $DB_TYPE $ARCHIVEGROUP $DEBUG $QUIET
	      $VERBOSE );

## Rather than having everything in this shared configuration, load this
## file to get additional configuration.  This file contains additional
## perl.  

$LOCALCONF = "$ENV{'HOME'}/.kibozerc";

## Where should we store all of our files?  This needs to be set or 
## nothing will run; also, the directory must already exist.

$KIBOZEDIR = "";

## What kind of database should we use to store history information?

$DB_TYPE  = "DB_File";

## If we're storing everything to an archive group, you can set it here.

$ARCHIVEGROUP = "";

## Do we want to print debugging information?  Use verbose status messages?
## Be entirely silent?  Set these things here.

$DEBUG    = 0;
$VERBOSE  = 0;
$QUIET    = 0;

## If the modules are set up in a non-standard place, edit this line 
## as appropriate.
BEGIN { use lib '/home/tskirvin/dev/news-archive'; }

###############################################################################
### main() ####################################################################
###############################################################################

use strict;		# Good programming is our friend
use warnings;		

use Getopt::Std;	# Command line functions
use News::Archive;	# News functions
use News::Article;	
use News::Article::Mbox;

# Error Codes
our %ERROR = ( 'SUCCESS' => 0, 'CONFIG' => 1, 'SERVER' => 2 );

# Command-line configuration
use vars qw( %OPTS );
getopts('hvVQdc:a:', \%OPTS);

# Load local configuration from local configuration file
$LOCALCONF = $OPTS{'c'} if $OPTS{'c'};
if ( $LOCALCONF && -r $LOCALCONF ) { do $LOCALCONF }

&Usage 	 if $OPTS{'h'};		# Print usage information and exit
&Version if $OPTS{'v'};		# Print version information and exit

# Other command-line parsing; overrides localconf
$DEBUG   = $OPTS{'d'} if defined $OPTS{'d'};
$VERBOSE = $OPTS{'V'} || $DEBUG || $VERBOSE || 0;	# Give verbose messages?
$QUIET   = $OPTS{'Q'} 	        || $QUIET   || 0;
$ARCHIVEGROUP = $OPTS{'A'} if defined $OPTS{'A'};

# Create the options hash to start a News::Archive object
our %OPTHASH;  
$OPTHASH{ 'basedir' } = $KIBOZEDIR  if $KIBOZEDIR;
$OPTHASH{ 'db_type' } = $DB_TYPE    if $DB_TYPE;
$OPTHASH{ 'debug'   } = $DEBUG      if $DEBUG;

# Create the News::Archive object
my $archive = new News::Archive ( %OPTHASH ) 
	or Exit('SERVER', "Couldn't create/load archive item: ",
					     	News::Archive->error);

# If we've got $ARCHIVEGROUP set, then make sure we're subscribed to it.
$archive->subscribe($ARCHIVEGROUP) if ($ARCHIVEGROUP);

# Read from STDIN
my @articles = News::Article::Mbox->read_mbox( \*STDIN );

my $count = 0;
foreach my $article (@articles) { 
  next unless $article;
  my $messageid = $article->header('message-id');

  # If this article has already been processed, skip it
  next unless $messageid;
  if ( $archive->article( $messageid ) ) {
    warn "Already processed '$messageid'\n" if $VERBOSE; 
    next;
  }

  # We need at least this many more headers to do anything with it
  next unless $article->header('from');
  next unless $article->header('newsgroups');
  next unless $article->header('subject');
  next unless $article->header('date');
  
  # Debugging hook; don't worry about this in general.
  # $article->write(\*STDOUT);

  # Get the list of groups we're supposed to be saving the article into
  my @groups = split('\s*,\s*', $article->header('newsgroups') );
  map { s/\s+//g } @groups;

  # Make sure we're subscribed to all these groups
  foreach (@groups) { $archive->subscribe($_) }
  push @groups, $ARCHIVEGROUP if $ARCHIVEGROUP;	# We're subscribed already

  # Actually save the article.
  my $ret = $archive->save_article( 
	[ @{$article->rawheaders}, '', @{$article->body} ], @groups );
  $count++ if $ret;
  if ($VERBOSE) { warn $ret ? "Accepted article $messageid\n"
			    : "Couldn't save article $messageid\n" }
}

$archive->close;

Exit('SUCCESS', "$count articles archived");

###############################################################################
### Subroutines ###############################################################
###############################################################################

## Usage ()
# Prints out a short help file and exits.
sub Usage {
  my $prog = $0; $prog =~ s%.*/%%g;		# Clean up the program name
  Exit('CONFIG', version($VERSION), <<EOM);
Archives news articles for later use with News::Archive

$prog is part of the News::Archive package, which is used to archive 
news articles in a reasonably efficient manner.  This particular script
is meant for use for personal archives, loading articles from an mbox-style
archie on STDIN and loading them into @{[ $KIBOZEDIR || "(unset)" ]}.

Configuration information is stored in the below configuration file;
please read the manual pages for more information on its configuration.

Usage: $prog [-hvVQd] [-c configfile] [-a groupname] < ARTICLE
	-h		Print this usage information and exit.
	-v		Print version information and exit.
	-c configfile	Load this configuration file instead of default.
			  Default: $LOCALCONF
	-a groupname	Add this group to all articles we download, so
			that they can be accessed uniformly.  
			  Default: @{[ $ARCHIVEGROUP || "Not Set" ]}
	-V		Verbose; print information on every article.
			  Default: @{[ $VERBOSE ? "On" : "Off" ]}
	-Q		Quiet mode; only print that which is absolutely
			  necessary (and even then think about it).
			  Default: @{[ $QUIET ? "On" : "Off" ]}
	-d		Debug; print debugging information (implies -V)
			  Default: @{[ $DEBUG ? "On" : "Off" ]}
EOM
}

## Version ()
# Prints out the version number and exits
sub Version { Exit('CONFIG', version($VERSION)) }

## Exit ( CODE, REASON )
# Exits the program cleanly with a proper error message
sub Exit {
  my ($code, $reason, @details) = @_;
  exit $ERROR{$code} unless $reason;
  # map { $_ = " - $_" } @details;
  $reason = join("\n", $reason, @details, '');
  warn $reason if (!$QUIET && $reason);
  exit $ERROR{$code};
}

## version ( [VERSION] )
# Returns the program name and version number
sub version {
  my $version = shift || $VERSION || "unknown";
  my $prog = $0; $prog =~  s%.*/%%g;		# Clean up the program name
  "$prog v$VERSION"
}

###############################################################################
### Documentation #############################################################
###############################################################################

=head1 NAME

mbox2news.pl - Archives news articles for later use with News::Archive

=head1 SYNOPSIS

mbox2news.pl [-hvVQd] [-c configfile] [-a groupname] < ARTICLE

=head1 DESCRIPTION

mbox2news.pl is a part of the News::Archive package, which is used to
archive news articles in a reasonably efficient manner.  This particular
script is meant for use for personal archives, loading articles (or
mbox-style archives) on STDIN and loading them into $KIBOZEDIR.

Without any options, mbox2news.pl will look for input from STDIN. 
Configuration information is stored in the configuration file
(B<kibozerc>).  Command-line options are as follows:

=over 4

=item -h

Print this usage information and exit.

=item -v

Print version information and exit.

=item -d	

Debug; print debugging information (implies -V)

=item -c configfile	

Load this configuration file instead of default (~/.kibozerc).

=item -a groupname

Add this group to all articles we download, so that they can be accessed
uniformly.  

=item -V

Verbose; print information on every article.

=item -Q

Quiet mode; only print that which is absolutely necessary (and even then
think about it).

=back

=head1 NOTES

This is essentially a counterpart to kiboze.pl; while that program goes to
news servers and downloads new messages, mbox2news.pl uses existing
messages.  It is primarily meant to convert from old kiboze archives, or
anything similar.

This script was meant to work with mbox-style archives; this is compatible
with some single articles, however, so you can feed them in directly as well.

You may well need a helper script to make some programs give you
mbox-compatible archives.  This distribution comes with 'nnparse', which
is used to fix the 'sentnews' items from the nn news reader; you can use
it as an example if you wish.

=head1 REQUIREMENTS

B<News::Archive>, B<News::Article::Mbox>

=head1 SEE ALSO

B<kibozerc>, B<newsarchive.pl>, B<kiboze.pl>

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 LICENSE

This code may be redistributed under the same terms as Perl itself.

=head1 HOMEPAGE

http://www.killfile.org/~tskirvin/software/news-archive/

=head1 COPYRIGHT

Copyright 2003-2004, Tim Skirvin <tskirvin@killfile.org>

=cut

###############################################################################
### Version History ###########################################################
###############################################################################
# v0.1a		Mon Oct 06 15:49:16 CDT 2003 
### Just starting out.
# v0.10		Mon Apr 26 13:46:01 CDT 2004 
### Actually calling this program something, documenting it, making it pretty.
# v0.11		Thu Apr 29 12:51:22 CDT 2004 
### Small bugfixes.
