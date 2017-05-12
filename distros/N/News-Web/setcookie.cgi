#!/usr/bin/env perl

BEGIN { 
  use vars qw( $SERVER $USER $PASS $PORT );
  my $DEFAULTS = "defaults";
  do $DEFAULTS;
}

use warnings;
use strict;
use CGI;
use CGI::Cookie;
use News::Web::CookieAuth;

use vars qw( $HTMLHEAD $HTMLFOOT $TITLE );

$TITLE = "Set NNTP information";
$HTMLHEAD = \&html_head;      
$HTMLFOOT = \&html_foot;

my $cgi = new CGI;

my $cookie = $cgi->cookie('nntpauthinfo') || "";

my $authinfo = News::Web::CookieAuth->new($cookie);

my %fields = News::Web::CookieAuth->fields;

# Should we set a new cookie?
my $set = 0;
foreach ( keys %fields ) { 
  next unless $cgi->param($_);
  $authinfo->set($_, $cgi->param($_)) ;
  $set++;
}

if ( $cgi->param('delete')) { 
  my $value = "";
  my $domain = $ENV{SERVER_NAME} || $ENV{HOSTNAME};  
  $domain =~ s%^([^.]*)\.(.*)$%$2%g;
  my $cookie = new CGI::Cookie( -name => 'nntpauthinfo', -value => $value,
        -expires => '+30d', -domain => $domain );
  print $cgi->header(-cookie=>$cookie);
} elsif ( $set ) { 
  my $value = $authinfo->make_cookie();
  my $domain = $ENV{SERVER_NAME} || $ENV{HOSTNAME};  
  $domain =~ s%^([^.]*)\.(.*)$%$2%g;
  my $cookie = new CGI::Cookie( -name => 'nntpauthinfo', -value => $value,
        -expires => '+30d', -domain => $domain );
  print $cgi->header(-cookie=>$cookie);
} else { print $cgi->header }

print &$HTMLHEAD( $TITLE );

my $url = $0;  $url =~ s%.*/%%g;

my $nntpuser = $authinfo->nntpuser  || $cgi->param('NNTPUser')  || $USER;

print "<h2> Set News Information </h2>\n"; 
print "<i>Currently logged in as <b>$nntpuser</b></i>\n";
print "<FORM action='$url' method=post>\n";
print "<table>\n <tr>\n";
foreach ( keys %News::Web::CookieAuth::HTMLFIELDS ) { 
  my $value = $fields{$_};
  if ($value) { 
    print "  <td>$value</td>\n";
    print "  <td> ", $authinfo->html($_, $authinfo->value($_)), "</td>\n";
  }
  print "</tr><tr>\n";
}
print "  <td colspan=2 align=right>", $cgi->submit, "</td>\n";
print " </tr>\n</table>\n";
print "</FORM>\n";

print "<a href='./'>Return to main interface</a>\n";

print &$HTMLFOOT($nntpuser);
exit(0);
# Should be using more stylesheet parts; maybe later
