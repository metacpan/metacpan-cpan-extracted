#!/usr/local/bin/perl 
# -*- Perl -*- 		# Thu Apr 29 13:03:57 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2004, Tim Skirvin. 
# Redistribution terms are below.
###############################################################################
our $VERSION = "0.12";

###############################################################################
### User Configuration ########################################################
###############################################################################
use vars qw( $LOCALCONF $KIBOZEDIR $DB_TYPE $ARCHIVEGROUP $DEBUG $QUIET
	      $VERBOSE $MAX );

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

## How many articles should we get, maximum?  Set to '0' to just get all
## of them.

$MAX = 0;

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
use File::Find;

use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

sub wanted;

# Error Codes
our %ERROR = ( 'SUCCESS' => 0, 'CONFIG' => 1, 'SERVER' => 2 );

# Command-line configuration
use vars qw( %OPTS );
getopts('hvVQdc:j:a:', \%OPTS);

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
our $archive = new News::Archive ( %OPTHASH ) 
	or Exit('SERVER', "Couldn't create/load archive item: ",
					     	News::Archive->error);

# If we've got $ARCHIVEGROUP set, then make sure we're subscribed to it.
$archive->subscribe($ARCHIVEGROUP) if ($ARCHIVEGROUP);

my $directory = shift @ARGV || Usage();

Exit('CONFIG', "No such directory: $directory") unless (-d $directory);

$|++; 

our $COUNT = 0;
File::Find::finddepth({wanted => \&wanted}, $directory);
my $groups = $archive->activefile;
my $hash = $groups->groups;
# foreach (keys %{$hash}) { print "$_: $$hash{$_}\n"; }
# foreach (keys %{$groups}) { print "$_: $$groups{$_}\n"; }
$archive->close;
Exit('SUCCESS', "$COUNT articles archived");

sub archive {
  my ($file) = @_;
  my $article = new News::Article;  $article->read($file);
  return undef unless $article;
  my $messageid = $article->header('message-id');

  # We need at least this many more headers to do anything with it
  foreach ( qw ( Message-ID from newsgroups subject date ) ) { 
    next if $article->header($_);
    warn "No header $_\n" if $VERBOSE;
    return undef;
  }

  # If this article has already been processed, skip it
  if ( $archive->article( $messageid ) ) {
    warn "Already processed '$messageid'\n" if $VERBOSE; 
    return undef;
  }
  
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
  $COUNT++ if $ret;
  if ($VERBOSE) { warn $ret ? "Accepted article $messageid\n"
			    : "Couldn't save article $messageid\n" }
  $ret ? 1 : 0;
}

###############################################################################
### Subroutines ###############################################################
###############################################################################

sub wanted {
  my ($dev,$ino,$mode,$nlink,$uid,$gid);
  return "" if ($MAX > 0 && $COUNT >= $MAX);
  (($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) && ! -d _ && /^[0-9]+$/s
	&& archive($name)
	&& ( print "$name\n" );
}

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

newsrecurse.pl - Recursively archives news articles with News::Archive

=head1 SYNOPSIS

newsrecurse.pl [-hvVQd] [-c configfile] [-a groupname] PATH

=head1 DESCRIPTION

newsrecurse.pl is a part of the News::Archive package, which is used to
archive news articles in a reasonably efficient manner.  This particular
script is meant for use for loading past archives, loading them
recursively from all-numeric filenames in the directory structure at PATH
and loading them into $KIBOZEDIR.  

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

This was designed to work with the output of old kiboze.pl, which in turn
was compatible with the "classic" style INN file layout.  If you've got an
old news spool sitting around, this is the script you can use to start
looking at it.

=head1 REQUIREMENTS

B<News::Archive>

=head1 SEE ALSO

B<kibozerc>, B<kiboze.pl>

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
# v0.11		Thu Apr 29 13:03:44 CDT 2004 
### First real version.
# v0.12		Tue May 25 14:40:26 CDT 2004 
### Offered some ways to only get a subset of the articles.
