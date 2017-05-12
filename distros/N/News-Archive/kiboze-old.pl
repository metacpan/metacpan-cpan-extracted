#!/usr/bin/perl -w
my $version = "1.1a";	

BEGIN {
use vars qw( $DEBUG $KIBOZE $DB_TYPE $MAXARTS %SERVERS );
### USER CONFIGURATION **#######################################################
$DEBUG     = 0;				# Use EXTREMELY verbose error messages
$KIBOZE    = "$ENV{'HOME'}/news/kiboze2";# Base directory to store files in
$DB_TYPE   = "DB_File";		# What kind of database type to use?
#$MAXARTS   = 10000;			# Maximum number of articles 
$MAXARTS   = 100000;				# Maximum number of articles 
					#   to download per invocation
%SERVERS   = (				# News servers and their Newsrcs
        "news.meat.net"           =>    "$KIBOZE/newsrc-meat",
        "news-proxy.cso.uiuc.edu" =>    "$KIBOZE/newsrc-cso"
	      );
################################################################################
}

our %ErrorCodes = (
	'CONFIG'	=> 	1,
	'SERVER'	=>	2,
		 );

=head1 NAME

kiboze.pl - a news archiving 'bot

=head1 SYNOPSIS

kiboze.pl [-hvd] [B<-V>] [B<-Q>] [B<-n> newsrcfile] [B<-s> newsserver]

=head1 DESCRIPTION

This script connects to a news server (or set of servers) and archives the
newsgroups specified in a newsrc file.  This can be used to save entire
newsgroups for later searches,  just message archiving.  

=head1 USAGE

Without any options, kiboze.pl will connect to each of the news servers
specified in turn, and attempt to download up to 1000 articles (or whatever 
the current value of $MAXARTS is).  

=over 4

=item -h

Prints a short help message and exits.

=item -v

Prints the version number and exits.

=item -d

Prints out the script defaults and exits.

=item -V

Verbose mode.  Prints out some basic status messages when they are
necessary.  More information is available in debugging mode, but you
probably don't want to read it.

=item -Q

Quiet mode.  Never prints anything out.  This is handy if you're putting
the script into a cron job and don't want to look over any logs; on the
other hand, most of what it blocks is error messages anyway, so you might
want to have them in your mailbox.  

=item -s F<newsserver>

Specifies which news server to connect to.  This may be used to connect to
just one server out of a set.  If combined with the B<-n> flag, you can also
connect to servers not present in the script.  

=item -n F<newsrcfile>

Specifies which newsrc to use.  If this newsrc is already used by a
server, then it uses that information for the server; otherwise, the B<-s>
flag is required.  

=back

=head1 REQUIREMENTS

News::Newsrc, News::Article, and News::Archive.

Requires Perl 5.?? or better, News::Newsrc, and News::Article.  All other
requirements should be included automatically with Perl5.

=cut

###############################################################################
### main() ####################################################################
###############################################################################

umask 022;		# Created files should be permissions 777
# require 5.6.1;		# Require at least Perl 5.004
use strict;		# Good programming is our friend

# use lib '/home/tskirvin/.html/news';	# Temporary, I hope.
use lib '/home/tskirvin/dev/news-archive';	# Temporary, I hope.

use Getopt::Std;	# Command line functions
use vars qw($opt_h $opt_v $opt_Q $opt_V $opt_s $opt_n $opt_d);

# Command-line configuration
$0 =~  s%.*/%%g;		# Clean up the program name
getopts('hvVqds:n:');

&Usage 		if $opt_h;	# Print a help message and exit
&Version 	if $opt_v;	# Print a version message and exit
&Default	if $opt_d;	# Prints out the defaults

our $VERBOSE = $opt_V || $DEBUG;	# Give verbose messages
our $QUIET   = $opt_Q;	# Give no output at all

my @SERVERS;
if ($opt_s) {   # Just use the server given in -s 
  push (@SERVERS, $opt_s);
  if ($opt_n) {  # Use the given newsrc for this server
    $SERVERS{$opt_s} = $opt_n;    
  } elsif ( defined($SERVERS{$opt_s}) ) {	# Just use this server
    # Nothing to do here.  
  } else {	 # Not enough information to continue, so exit
    Exit('CONFIG', "Can't find newsrc file for server $opt_s");
  }
} else {	# Use all of the servers in %SERVERS
  if ($opt_n) {	# Limit to just the server with the given newsrc

    # Get the whole name out of $opt_n
    my $newsrc = $opt_n;
       $newsrc = "$ENV{'PWD'}/$newsrc" unless ($opt_n =~ m%^/%);

    foreach (keys %SERVERS) {
      push (@SERVERS, $_) if ($newsrc eq $SERVERS{$_});
    }  

    if ( scalar(@SERVERS) > 1 ) { 	# Check the matches
      Exit('CONFIG', "Too many matches on newsrc $opt_n - @SERVERS");
    } elsif ( scalar(@SERVERS) == 0 ) {
      Exit('CONFIG', "No servers found for newsrc $opt_n");
    }
  } else {
    @SERVERS = keys(%SERVERS);
  }
}

use News::Archive;	# News functions
use News::Newsrc;	
use News::Article;
use Net::NNTP;
use Net::NNTP::Auth;

Exit('CONFIG', "No servers to scan") unless ( scalar(@SERVERS) >= 1 );

my %opts;  
$opts{ 'basedir' } = $KIBOZE ;
$opts{ 'db_type' } = $DB_TYPE ;
$opts{ 'debug'   } = $DEBUG ;
# more later
my $archive = new News::Archive ( %opts ) 
	or Exit('SERVER', "Couldn't create archive item: $!");

# die unless $archive->postok;

my ($group, $server);
foreach $server (@SERVERS) {
  my $newsrcfile = $SERVERS{$server};
  print "$server - loading $newsrcfile\n" if $VERBOSE;
  # Load the newsrc file
  my $Newsrc = new News::Newsrc $newsrcfile;
  unless ( $Newsrc ) {
    warn "Couldn't open $newsrcfile for server $server\n" unless $QUIET; 
    next; 
  }

  # Load $NNTPATH
  print "Loading NNTPAuth info for $server\n" if $DEBUG;
  my ($nntpuser, $nntppass) = Net::NNTP::Auth->nntpauth($server);
  if ($nntpuser || $nntppass) { 
    print " - User: ", $nntpuser || '', "\n" if ($nntpuser && $DEBUG); 
    print " - Pass: ", $nntppass || '', "\n" if ($nntppass && $DEBUG);
  } else { print " - No information returned; using defaults\n" if $DEBUG }
  
  # Connect to the NNTP Server
  print "Connecting to $server\n" if $DEBUG;
  my $NNTP = Net::NNTP->new($server);
  Exit('SERVER', "Couldn't connect to server $server") unless $NNTP;
  $NNTP->authinfo($nntpuser, $nntppass) if defined($nntppass);

  # Make sure we're subscribed to all of the groups we're saving from
  foreach ($Newsrc->groups) { $archive->subscribe($_) }

  # print join("\n", $archive->activefile->printable, '');

  # next;
  
  my $count = 0;
  foreach $group ($Newsrc->groups) {
    my ($articles, $firstnum, $lastnum, $name) = $NNTP->group($group);
    next unless $name;		

    print "$name: articles $firstnum - $lastnum exist on server\n" if $VERBOSE; 
  
    my $i;
    foreach ($i = $firstnum; $i <= $lastnum; $i++) {
      last if ($count >= $MAXARTS);		
      next if $Newsrc->marked($group, $i);	# Next if it's marked

      # Get the article and its information
      my $article = News::Article->new( $NNTP->article($i) );
      my $messageid = $article ? $article->header('message-id') : "";
      
      # If there is an article and it's not already in the cache, save it
      if ($article) { 
        next if $archive->article( $messageid );
        my $ret = $archive->ihave( $messageid, 
		( $article->headers, '', @{$article->body} ) );
        
        if ($ret) {	
          $count++;				# Update the count
          warn "Accepted article $messageid\n" if $DEBUG;
        } else {
          warn "Couldn't save article $messageid\n" if $DEBUG;
        }
      } elsif ( $article ) {	# It was already in the cache
        warn "Article $messageid already archived\n" if $DEBUG;
      } else {			# There was no article, for whatever reason
        warn "Didn't actually get an article, skipping...\n" if $DEBUG; 
      } 
      $Newsrc->mark($group, $i);
    }
    $Newsrc->save;
  }
  print "$count articles archived for server $server\n" if $VERBOSE;
  
  # Close the NNTP Connection
  $NNTP->quit;
}

### Function Calls ###

## Usage ()
# Prints out a short help file and exits.

sub Usage {
  warn <<EOM;

$0 v$version
A newsgroup archiver
Usage: $0 [-hvdVQ] [-s newsserver] [-n newsrcfile] 

$0 connects to a news server (or set of servers) and archives the specified 
newsgroups from a newsrc file (or files).  The defaults are stored in the 
script.  For more information, refer to the manual page.

	-h		Prints this message and exits.
	-v		Prints the version number and exits.
	-d		Prints out the script defaults and exits.  
	-V		Verbose mode.  Gives some basic status messages.
	-Q		Quiet mode.  Doesn't print any messages.  Useful for
			  cron jobs, but otherwise not recommended.
	-s newsserver   Specifies which server to connect to, instead of 
			  the whole list.  May be combined with -n to connect
			  to servers not present in the script.
	-n newsrcfile	Specifies which newsrc to use.  Requires that the
			  file is already mentioned in the script, or that
			  the -s flag is used.

EOM

  Exit();
}

## Version ()
# Prints out the version number and exits

sub Version {
  warn "$0 v$version\n";
  Exit();
}

## Default()
# Prints out the program defaults and exits

sub Default {
  unless ($QUIET) {
    warn "Debugging mode on\n" if $DEBUG;
    warn "Base directory:		$KIBOZE\n";
    warn "Maximum articles: 	$MAXARTS\n";
    warn "\n       Servers and Newsrcs\n";
    foreach (keys %SERVERS) {
      warn "  Server: $_\n  Newsrc: $SERVERS{$_}\n\n";
    }
  }
  Exit();
}

## Exit ( CODE, REASON )
# Exits the program cleanly with a proper error message


sub Exit {
  my ($code, @reason) = @_;
  warn "@reason\n" if (!$QUIET && @reason);
  exit $ErrorCodes{$code};
}

=head1 TODO

Make some default newsrc files if one doesn't exist.  Start using an 
active-file type dealie, to increase efficiency by a whole lot and allow
the various servers to work together.  Make some more scripts to search 
the cache file by message-id.  Add locking stuff.  

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 COPYRIGHT

Copyright 1999-2000 Tim Skirvin <tskirvin@killfile.org>

This code may be used and/or distributed under the same terms as Perl
itself.  Oh, and it's beta code, so use it at your own risk.

=cut

###############################################################################
### Version History ###########################################################
###############################################################################

# v1.1a	
### Starting a new version, based on News::Archive.
# v1.0 		Thu Nov 16 15:05:08 CST 2000
### Made an install script, fixed the documentation a bit, started
### running with warnings, submitted it to freshmeat.
# v0.6b 	Wed Aug 30 10:21:15 CDT 2000
### Added basic support for NNTPAUTH stuff - it works, at least.  Not
### documented yet, and it probably ought to be standardized.
# v0.51b 	Thu Feb  3 12:10:46 CST 2000
### Added "use Net::NNTP", since it's not included with News::Article
### anymore.
# v0.5b 	Tue Dec 21 17:19:57 CST 1999
### First version that I actually wrote up some documentation and such for.
### It's been working (and running) for a long time before this, but it
### was about time I got around to making it useful.  Let's see how long
### it'll take me to start distributing it.
