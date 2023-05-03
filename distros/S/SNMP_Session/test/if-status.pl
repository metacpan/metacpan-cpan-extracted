#!/usr/local/bin/perl -w
#
# Small sample application for table walking
#
# Given a router name and SNMP community string, traverse the RFC1213
# ifTable and write a message for each interface whose ifOperStatus
# differs from the ifAdminStatus.

require 5.003;

use strict;

use lib qw(/opt/www/cgi-bin/cug/switch/snmp);

use BER;
use SNMP_Session;
use CGI qw(:html2 :html3);

### Forward declarations
sub out_interface ($$$$$ );
sub usage ();
sub print_html_header ($ );
sub print_html_trailer ();

my $output_mode = 'text';
my $have_html_header = 0;

my ($host, $community);
my $query;
my $version;

if (defined $ENV{'REQUEST_METHOD'}) {
  $output_mode = 'html';
  $query = new CGI;

  $host = $query->param ('host');
  $community = $query->param ('community');
  print $query->header;
} else {
  my $arg;

  while (defined $ARGV[0] and $ARGV[0] =~ /^-/) {
    if ($ARGV[0] =~ /^-v/) {
	if ($ARGV[0] eq '-v') {
	    shift @ARGV;
	    usage () unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] eq '1') {
	    $version = '1';
	} elsif ($ARGV[0] eq '2c' or $ARGV[0] eq '2') {
	    $version = '2c';
	} else {
	    usage ();
	}
    } elsif ($arg eq '-html') {
      $output_mode = 'html';
    } else {
      usage ();
    }
    shift @ARGV;
  }
  $host = shift @ARGV || die;
  $community = shift @ARGV || die;
}

my $ifDescr = [1,3,6,1,2,1,2,2,1,2];
my $ifAdminStatus = [1,3,6,1,2,1,2,2,1,7];
my $ifOperStatus = [1,3,6,1,2,1,2,2,1,8];
my $locIfDescr = [1,3,6,1,4,1,9,2,2,1,1,28];

my $the_router;

sub out_interface ($$$$$) {
    my ($index, $descr, $admin, $oper, $comment) = @_;
    grep (defined $_ && ($_=pretty_print $_),
	  ($descr, $admin, $oper, $comment));

    return if defined $admin && $admin == 2;
    return if defined $admin && defined $oper && $admin == $oper;

    my $admin_string = $admin ? ($admin == 1 ? 'up' : ($admin == 2 ? 'down' : "?($admin)")) : "?";
    my $oper_string = $oper ? ($oper == 1 ? 'up' : ($oper == 2 ? 'down' : "?($oper)")) : "?";
    $comment = '' unless defined $comment;

    if ($output_mode eq 'text') {
	printf "%2d  %-20s %10s %10s %s\n",
	$index, $descr, $admin_string, $oper_string,
	defined $comment ? $comment : '';
    } elsif ($output_mode eq 'html') {
	print_html_header ($the_router), $have_html_header = 1
	    unless $have_html_header;
	print TR(th($index),
		 td(CGI->escapeHTML($descr)),
		 td({align=>'center'},$admin_string),
		 td({align=>'center'},$oper_string),
		 td(CGI->escapeHTML($comment))),"\n";
    }
}

$the_router = $host;

my $session =
    ($version eq '1' ? SNMPv1_Session->open ($host, $community, 161)
     : $version eq '2c' ? SNMPv2c_Session->open ($host, $community, 161)
     : die "Unknown SNMP version $version")
  || die "Opening SNMP_Session";
$session->map_table ([$ifDescr,$ifAdminStatus,$ifOperStatus,$locIfDescr],
		     \&out_interface);

if ($output_mode eq 'html' && $have_html_header) {
  print_html_trailer ();
}
1;

sub usage () {
  die "Usage: $0 [-html] hostname community";
}

sub print_html_header ($ ) {
  my ($router) = @_;
  print "<html>\n";
  print head(title("Interface Listing for ".$router)),"\n";
  print " <BODY BGCOLOR=\"#ffffff\">\n",
	     h1("Interface Listing for ".tt($router)),"\n",
	     "  <TABLE>\n",
	     TR(th("index"),
		th("descr"),
		th("admin"),
		th("oper"),
		th("description"));
}

sub print_html_trailer () {
  print "  </table>\n </body>\n</html>\n";
}
