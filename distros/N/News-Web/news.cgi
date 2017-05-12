#!/usr/local/bin/perl
use warnings;
use vars qw( $DEBUG $TITLE $STYLESHEET $HTMLFOOT $HTMLHEAD $VERSION %OPTIONS 
		%DEFAULT );
$VERSION = "0.021a";

###############################################################################
### CONFIGURATION + PRIVATE DATA ##############################################
###############################################################################

$TITLE = $SERVER;

$DEBUG = 0;

%OPTIONS = ( 'user' => $USER || "", 'pass' => $PASS || "" );

## These are references to code that will output the headers and footers
## for the messages.  If you want to change these, you can either modify
## the code (which is below) or create a new set of functions and change 
## the below code references appropriately.

$STYLESHEET ||= "stylesheet.css";
$HTMLHEAD   = \&html_head || \&html_head_base;      
$HTMLFOOT   = \&html_foot || \&html_foot_base;

%DEFAULT = (
	'sort'	=>  "thread", 	'count' => 500,
	'first' =>  0, 	 	'last'  => -1,
	'overview' => [ qw( Number From Subject Date ) ],
	   );

###############################################################################
### main() ####################################################################
###############################################################################

BEGIN { 
  use vars qw( $SERVER $USER $PASS $PORT $HTMLHEAD $HTMLFOOT );
  our $DEFAULTS = "defaults";
  do $DEFAULTS;
}

use vars qw( $HTML );

use CGI;
use strict;

use News::Web;
use News::Web::CookieAuth;

use Text::Wrap;

$0 =~ s%.*/%%g;         # Lose the annoying path information
my $cgi = new CGI || die "Couldn't open CGI";
my $params = {};
foreach ($cgi->param) { $$params{$_} = $cgi->param($_); }

my $authinfo = News::Web::CookieAuth->new( $cgi->cookie('nntpauthinfo') || "");

$OPTIONS{'user'} = $authinfo->nntpuser if $authinfo->nntpuser;
$OPTIONS{'pass'} = $authinfo->nntppass if $authinfo->nntppass;

my $realname = $authinfo->realname; 
my $emailadd = $authinfo->emailadd;

my $from;
if ($emailadd) { 
  $from = $realname ? "$realname <$emailadd>" 
		    : $emailadd;
} else { $from = $realname || "" }

my $newsgroup = $$params{'group'} || "";
my $reference = $$params{'mid'}   || "";
my $pattern   = $$params{'pattern'} || "";

my $first = $$params{'first'} || $DEFAULT{first}  || 0;
my $count = $$params{'count'} || $DEFAULT{count}  || 0;
my $last  = $$params{'last'}  || $DEFAULT{last}   || -1;
my $sort  = $$params{'sort'}  || $DEFAULT{thread} || 'thread'; 

my $article = $$params{'article'};

my %opts;  foreach (keys %DEFAULT) { $opts{$_} = $DEFAULT{$_} }

$opts{'params'}    = $params;
$opts{'reference'} = $reference;
$opts{'group'}	   = $newsgroup;
$opts{'pattern'}   = $pattern;
$opts{'mid'}       = $reference;
$opts{'signature'} = $authinfo->signature || "";
$opts{'author'}    = $from || "";
$opts{'fullhead'}  = $$params{'fullhead'} || 0;
$opts{'plaintext'} = $$params{'plaintext'} || 0;
$opts{'first'}	   = $first;	
$opts{'last'}	   = $last;
$opts{'count'}	   = $count;
$opts{'sort'}      = $sort;
$opts{'prefix' }   = $OPTIONS{'user'} . '.';
$opts{'domain' }   = $SERVER;
$opts{'columns'}   = 78; 	# Low to deal with Mozilla's current problems
$opts{'wraptype'}  = 'wrap';
$opts{'trace'}     = join(', ', $OPTIONS{user} || 'default',
				 $ENV{REMOTE_ADDR} || "running locally",
				 scalar localtime );
$opts{'clean'}     = $$params{'clean'} || 0;
$opts{'default'}   = \%DEFAULT, 
$opts{'options'}   = \%OPTIONS ;
$opts{'fields'}    = $DEFAULT{'overview'};

Error("No news server offered") unless $SERVER;
my $nntp = new Net::NNTP($SERVER, %OPTIONS)
	or Error("Couldn't open connection to $SERVER: $!");
$nntp->authinfo($OPTIONS{user}, $OPTIONS{pass}) 
	or Error("Couldn't authenticate with $SERVER: $!");

( print $cgi->header(), &$HTMLHEAD($TITLE), "\n" ) && $HTML++;


# Should do something if we can't connect
my $NNTP = News::Web->new($nntp);

unless ($$params{'clean'}) {
  print "<table width=100%>\n";
  print " <tr>\n"; 
  print "  <td align=center>", join(" | ", $NNTP->html_hierarchies() ), "</td>";
  print " </tr>\n";
  print "</table>";
  print "<hr />\n";
}

if ( $$params{'post'} ) { 

  if    ($$params{'header_Message-ID'})  { print $NNTP->html_post(%opts) } 
  else                            { print $NNTP->html_makearticle(%opts) }

} else { 
  if    ($reference) { print $NNTP->html_article( 'mid' => $reference, %opts), "\n"; } 
  elsif ($newsgroup) { 
    my $number = $$params{'number'}; 
    print $number 
	? $NNTP->html_article('group' => $newsgroup, 'number' => $number, %opts)
	: $NNTP->html_overview('group' => $newsgroup, 
				fields => $DEFAULT{'overview'}, %opts), "\n" }
  elsif ($pattern)   { print $NNTP->html_grouplist($pattern), "\n"; }
  else               { print $NNTP->html_grouplist($pattern), "\n"; }
}

$nntp->quit;

print &$HTMLFOOT($OPTIONS{user}) unless $$params{'clean'};
exit(0);

###############################################################################
### Functions #################################################################
###############################################################################

sub Error {
  print CGI->header(), &$HTMLHEAD("Error in '$0'") unless $HTML;

  print "This script failed for the following reasons: <p>\n<ul>\n";
  foreach (@_) { next unless $_; print "<li>", canon($_), "<br>\n"; }
  print "</ul>\n";

  print &$HTMLFOOT();
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

sub html_head_base {}
sub html_foot_base {}

# Version History
## v0.01a	Thu Sep 25 16:??:?? CDT 2003
# First working version
## v0.02a	Fri Sep 26 16:56:31 CDT 2003 
# Allows for new version of News::Web, ie lets you arbitrarily choose the 
# type of connection.
## v0.021a	Fri Nov 07 15:51:03 CST 2003 
# Fixed a typo.
