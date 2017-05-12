#!/usr/local/bin/perl 
use warnings;
use vars qw( $DEBUG $TITLE $HTML $HTMLFOOT $HTMLHEAD %OPTIONS %DEFAULT );
our $VERSION = "0.10";

###############################################################################
### Configuration + Private Data ##############################################
###############################################################################

use vars qw( $LOCALCONF );

$LOCALCONF = "/home/tskirvin/.kibozerc";

BEGIN { use vars qw( $server $user $pass $port $TITLE ); 
        my $DEFAULTS = "defaults"; do $DEFAULTS; }

$TITLE ||= "News::Archive";

$DEBUG ||= 0;

%OPTIONS = ( 'basedir' => $KIBOZEDIR, 'readonly' => 1 );

## These are references to code that will output the headers and footers
## for the messages.  If you want to change these, you can either modify
## the code (which is below) or create a new set of functions and change 
## the below code references appropriately.

$HTMLHEAD = \&html_head;      
$HTMLFOOT = \&html_foot;

%DEFAULT = (
	'sort'   => "Thread", 	'count' => 400,
	'first'  => 0, 		'last'  => 0,	
	'overview' => [ qw( From Lines Subject Date ) ],
	   );

###############################################################################
### main() ####################################################################
###############################################################################

use CGI;
use strict;
use CGI::SHTML;

use lib '/home/tskirvin/dev/news-archive';
use News::Archive;

use lib '/home/tskirvin/dev/news-web';
use News::Web;

use lib '/home/tskirvin/dev/news-overview';
use News::Overview;

# use Text::Wrap;

if ( $LOCALCONF && -r $LOCALCONF ) { do $LOCALCONF }

$0 =~ s%.*/%%g;         # Lose the annoying path information
my $cgi = new CGI || die "Couldn't open CGI: $!\n";
my $params = {};
foreach ($cgi->param) { $$params{$_} = $cgi->param($_); }

my $nntp = new News::Archive ( %OPTIONS )
	or Error("Couldn't open connection to $server: $!");

# Should do something if we can't connect
my $NNTP = News::Web->new($nntp);

my $newsgroup = $$params{'group'} || "";
my $article   = $$params{'mid'}   || "";
my $pattern   = $$params{'pattern'} || "";

my $first = $$params{'first'} || $DEFAULT{first} || 0;
my $count = $$params{'count'} || $DEFAULT{count} || 0;
my $last  = $$params{'last'}  || $DEFAULT{last} || 0;
my $sort  = $$params{'sort'}  || $DEFAULT{sort} || 'thread';

my %opts;  foreach (keys %DEFAULT) { $opts{$_} = $DEFAULT{$_} }
$opts{'fullhead'}  = $$params{'fullhead'} || 0;
$opts{'plaintext'} = $$params{'plaintext'} || 0;
$opts{'clean'}     = $$params{'clean'} || 0;

$opts{'nolinkback'} = 1;

=comment

The list from news.cgi, minus those I take out over time

$opts{'params'}    = $params;
$opts{'reference'} = $reference;
$opts{'group'}     = $newsgroup;
$opts{'pattern'}   = $pattern;
$opts{'mid'}       = $reference;
$opts{'first'}     = $first;    
$opts{'last'}      = $last;
$opts{'count'}     = $count;
$opts{'sort'}      = $sort;
$opts{'prefix' }   = $OPTIONS{'user'} . '.';
$opts{'domain' }   = $SERVER;
$opts{'default'}   = \%DEFAULT, 
$opts{'options'}   = \%OPTIONS ;
$opts{'fields'}    = $DEFAULT{'overview'};

=cut

( print $cgi->header(), &$HTMLHEAD($TITLE), "\n" ) && $HTML++;

unless ($opts{'clean'}) { 
  print "<div class='hierlist'>\n";
  foreach ( $NNTP->html_hierarchies() ) { 
    print " <div class='hiername'>$_</div>\n";
  }
  print "</div>\n";
}

print "<hr class='clear' />\n"; 

if    ($article)   { print $NNTP->html_article($article), "\n"; } 
elsif ($pattern)   { print $NNTP->html_grouplist($pattern), "\n"; }
elsif ($newsgroup) { 
  my $number = $$params{'number'}; 
  print $number 
        ? $NNTP->html_article('group' => $newsgroup, 'number' => $number, %opts)
        : $NNTP->html_overview('group' => $newsgroup, 
                                fields => $DEFAULT{'overview'}, %opts), "\n" }
else		   { print $NNTP->html_grouplist($pattern), "\n"; }

print "<hr class='clear' />\n"; 

# print "<p align=right>Currently logged in as <i>$OPTIONS{'user'}</i><br />\n";
# print "<a href='setcookie.cgi'>Change This</a></p>\n";

$nntp->quit;

exit(0);

###############################################################################
### Functions #################################################################
###############################################################################

sub Error {
  print CGI->header(), &$HTMLHEAD("Error in '$0'") unless $HTML;

  print "This script failed for the following reasons: <p>\n<ul>\n";
  foreach (@_) { next unless $_; print "<li>", canon($_), "<br>\n"; }
  print "</ul>\n";

  print &$HTMLFOOT($DEBUG);
  exit 0;
}

## canon ( ITEM )
# Returns a printable version of whatever it's passed.  Used by Error().

sub canon {
  my $item = shift;
  if    ( ref($item) eq "ARRAY" )   { join(' ', @$item) }
  elsif ( ref($item) eq "HASH" )    { join(' ', %$item) }
  elsif ( ref($item) eq "" )        { $item }
  else                              { $item }
}

## html_head ( TITLE [, OPTIONS] )
# Prints off a basic HTML header, with debugging information.  Extra
# options are passed through to start_html.

sub html_head { 
  my $title = shift || $TITLE;
  use CGI;   my $cgi = new CGI;
  $cgi->start_html(-title => $title, @_) .  "\n";
}

## html_foot ( DEBUG [, OPTIONS] )
# Prints off a basic HTML footer, with debugging information.

sub html_foot { 
  my $debug = shift || $DEBUG;
  use CGI;   my $cgi = new CGI;
  my @return = $cgi->end_html(@_);
  join("\n", @return, "");
}


# Version History
## v0.01a	Thu Sep 25 16:??:?? CDT 2003
# First working version
## v0.02a	Fri Sep 26 16:56:31 CDT 2003 
# Allows for new version of News::Web, ie lets you arbitrarily choose the 
# type of connection.
