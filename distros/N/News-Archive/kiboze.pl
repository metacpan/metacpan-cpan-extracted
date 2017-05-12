#!/usr/local/bin/perl 
# -*- Perl -*- 		# Thu Apr 29 10:15:37 CDT 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2004, Tim Skirvin. 
# Redistribution terms are below.
###############################################################################
our $VERSION = "1.11";

###############################################################################
### User Configuration ########################################################
###############################################################################
use vars qw( $LOCALCONF $KIBOZEDIR $DB_TYPE $DEBUG $QUIET $VERBOSE 
	     %SERVERS $MAXARTS $LOCALNAME );

## Rather than having everything in this shared configuration, load this
## file to get additional configuration.  This file contains additional
## perl.  

$LOCALCONF = "$ENV{'HOME'}/.kibozerc";

## Where should we store all of our files?  This needs to be set or 
## nothing will run; also, the directory must already exist.

$KIBOZEDIR = "$ENV{'HOME'}/kiboze";

## What kind of database should we use to store history information?

$DB_TYPE  = "DB_File";

## Where are we getting our news content?  By raid^H^H^Heading it from
## other servers, of course!  These are the servers and newsrc we will 
## be using.

%SERVERS   = ( 
	$ENV{'NNTPSERVER'} 	=> "$KIBOZEDIR/newsrc",
	     ); 

## How many articles should we invoke in a single run?  This shouldn't be
## that high unless you invoke the script very rarely.  Set to '-1' to 
## ignore this entirely.

$MAXARTS   = 1000;

## Local "machine" name, which will appear in the Xref and Path headers.

$LOCLNAME  = "archive";

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
use News::Newsrc;
use Net::NNTP::Auth;	
use Net::NNTP;

# Error Codes
our %ERROR = ( 'SUCCESS' => 0, 'CONFIG' => 1, 'SERVER' => 2 );

# Command-line configuration
use vars qw( %OPTS );
getopts('hvVQdc:s:n:', \%OPTS);

# Load local configuration from local configuration file
$LOCALCONF = $OPTS{'c'} if $OPTS{'c'};
if ( $LOCALCONF && -r $LOCALCONF ) { do $LOCALCONF }

&Usage 	 if $OPTS{'h'};		# Print usage information and exit
&Version if $OPTS{'v'};		# Print version information and exit

# Other command-line parsing; overrides localconf
$DEBUG   = $OPTS{'d'} if defined $OPTS{'d'};
$VERBOSE = $OPTS{'V'} || $DEBUG || $VERBOSE || 0;	# Give verbose messages?
$QUIET   = $OPTS{'Q'} 	        || $QUIET   || 0;

our $server = $OPTS{'s'} || "";
our $newsrc = $OPTS{'n'} || "";

# Figure out which servers and newsrcs we want to use.
our @SERVERS;

# Did we get a specific server on the command-line?  Use it.
if ($server) { 	
  push @SERVERS, $server;
  if    ($newsrc) { $SERVERS{$server} = $newsrc; } # Use the -n for this server
  elsif (defined($SERVERS{$server})) {           } # We've already got one.
  else { Exit('CONFIG', "Couldn't find newsrc file for $server") }

# Use everything in %SERVERS 
} else {	
  # Limit to just the server with the given newsrc
  if ($newsrc) { 	
    $newsrc = "$ENV{'PWD'}/$newsrc" unless ($newsrc =~ m%^/%);

    foreach (keys %SERVERS) {
      push (@SERVERS, $_) if ($newsrc eq $SERVERS{$_});
    }  

    if ( scalar(@SERVERS) > 1 ) {       # Check the matches
      Exit('CONFIG', "Too many matches on newsrc $newsrc (@SERVERS)");
    } elsif ( scalar(@SERVERS) == 0 ) {
      Exit('CONFIG', "No servers found for newsrc $newsrc");
    }

  } else { @SERVERS = keys %SERVERS }
}

Exit('CONFIG', "No servers to scan") unless ( scalar(@SERVERS) >= 1 );
Exit('CONFIG', "LOCALNAME not set")  unless $LOCALNAME;

mkdir($KIBOZEDIR) unless (-d $KIBOZEDIR);

# Create the options hash to start a News::Archive object
our %OPTHASH;  
$OPTHASH{ 'basedir' } = $KIBOZEDIR  if $KIBOZEDIR;
$OPTHASH{ 'db_type' } = $DB_TYPE    if $DB_TYPE;
$OPTHASH{ 'debug'   } = $DEBUG      if $DEBUG;
$OPTHASH{ 'hostname' } = $LOCALNAME if $LOCALNAME;

# Create the News::Archive object
my $archive = new News::Archive ( %OPTHASH ) 
	or Exit('SERVER', "Couldn't create/load archive item: ",
					     	News::Archive->error);

my $overcount = 0;
my (@articles, %COUNT);
foreach $server (@SERVERS) {

  # Load the newsrc file
  my $newsrcfile = $SERVERS{$server};
  print "$server - loading $newsrcfile\n" if $VERBOSE;
  my $Newsrc = new News::Newsrc;
  unless ( $Newsrc->load($newsrcfile) ) {
    warn "Couldn't open $newsrcfile for server $server\n" unless $QUIET; 
    next; 
  }

  # Connect to the NNTP Server
  my $NNTP = Net::NNTP->new($server);
  Exit('SERVER', "Couldn't connect to server $server") unless $NNTP;

  my ($nntpuser, $nntppass) = Net::NNTP::Auth->nntpauth($server);
  $NNTP->authinfo($nntpuser, $nntppass) if defined($nntppass);

  # Make sure we're subscribed to all of the groups we're saving from
  foreach ($Newsrc->groups) { $archive->subscribe($_) }

  my $count = 0;
  foreach my $group ($Newsrc->groups) {
    my ($articles, $firstnum, $lastnum, $name) = $NNTP->group($group);
    next unless $name;          

    print "$name: articles $firstnum - $lastnum exist on server\n" if $VERBOSE; 
  
    my $i;
    foreach ($i = $firstnum; $i <= $lastnum; $i++) {
      next unless $i > 0;
      last if ($count >= $MAXARTS);             
      next if $Newsrc->marked($group, $i);      # Next if it's marked

      # Get the article and its information
      my $article = News::Article->new( $NNTP->article($i) );
      $Newsrc->mark($group, $i);

      unless ($article) { 
        warn "No article received ($i from $group on $server)\n" if $DEBUG; 
        next; 
      }
      my $msgid = $article ? $article->header('message-id') : "";
      unless ($msgid) { warn "No message-id on article\n" if $DEBUG; next; }

      if ($archive->article( $msgid )) {
        print "Article $msgid was already archived, skipping...\n" if $VERBOSE;
        next;
      }
      my $ret = $archive->ihave( $msgid, 
                ( $article->rawheaders, '', @{$article->body} ) );
      $count++ if $ret;
      # Would like to get the reason back out here...
      if ($VERBOSE) { print $ret ? "Accepted article $msgid\n"
                                 : "Didn't save article $msgid\n" }
    }
    $Newsrc->save;
  }
  print "$count articles archived for server $server\n" if $VERBOSE;
  
  # Close the NNTP Connection
  $NNTP->quit;
  $COUNT{$server} += $count if $count;
  $overcount += $count;
}

$archive->close;

Exit('SUCCESS', "$overcount articles archived from " 
					. ( scalar keys %COUNT ) . " servers");

###############################################################################
### Subroutines ###############################################################
###############################################################################

## Usage ()
# Prints out a short help file and exits.
sub Usage {
  my $prog = $0; $prog =~ s%.*/%%g;		# Clean up the program name
  Exit('CONFIG', version($VERSION), <<EOM);
Archives news articles for later use with News::Archive

[...]
$prog is part of the News::Archive package, which is used to archive 
news articles in a reasonably efficient manner.  This particular script
is meant for use for personal archives, loading articles (or mbox-style
archives) on STDIN and loading them into @{[ $KIBOZEDIR || "(unset)" ]}.

Configuration information is stored in the below configuration file;
please read the manual pages for more information on its configuration.

Usage: $prog [-hvVQd] [-c configfile] [-a groupname] < ARTICLE
	-h		Print this usage information and exit.
	-v		Print version information and exit.
	-c configfile	Load this configuration file instead of default.
			  Default: $LOCALCONF
	-a groupname	Add this group to all articles we download, so
			that they can be accessed uniformly.  
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

kiboze.pl - a news archiving 'bot

=head1 SYNOPSIS

kiboze.pl [-hvd] [B<-V>] [B<-Q>] [B<-n> newsrcfile] [B<-s> newsserver]

=head1 DESCRIPTION

[...]

=over 4

=item -h

Prints a short help message and exits.

=item -v

Prints the version number and exits.

=back

=head2 Recommended Usage

After configuration, set up your crontab to run the script periodically.
A sample crontab line, which runs every four hours:

  # Run kiboze.pl
  0 0,4,8,12,16,20 * * * /home/tskirvin/news/kiboze/kiboze.pl

Disk space requirements will vary depending on how many groups you're
archiving; I've been archiving a local hierarchy (cmi.*) for about four
years now and have saved a few hundred megabytes worth of articles, but it
would be a lot worse to get a large hierarchy.  

=head2 NNTP Authentication

NNTP Authentication is taken care of with B<Net::NNTP::Auth>, part of the
B<NewsLib> package.  More information is there.

=head1 NOTES

=head1 TODO

Make some default newsrc files if one doesn't exist.  Locking
capabilities, perhaps.

Trap ^C and such so that we can close nicely.

=head1 REQUIREMENTS

B<News::Archive>, B<News::Newsrc>

=head1 SEE ALSO

B<News::Archive>, B<kibozerc>

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 LICENSE

This code may be redistributed under the same terms as Perl itself.

=head1 HOMEPAGE

http://www.killfile.org/~tskirvin/software/kiboze/

http://www.killfile.org/~tskirvin/software/news-archive/

=head1 COPYRIGHT

Copyright 1997-2004, Tim Skirvin <tskirvin@killfile.org>

=cut

###############################################################################
### Version History ###########################################################
###############################################################################
# v1.0		Thu Nov 16 15:05:08 CST 2000
### Initial release.
# v1.0.1	Fri Jan 09 19:20:32 CST 2004
### Minor bugfixes, documentation fixes.  Updated to use Makefile.PL system.
# v1.10		Mon Apr 26 16:16:03 CDT 2004 
### Rewrite to use News::Archive.  Working towards v2.0.
# v1.11		Thu Apr 29 10:06:48 CDT 2004 
### Keeps track of how many servers we've downloaded from.
