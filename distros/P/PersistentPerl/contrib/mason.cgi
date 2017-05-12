#!/usr/bin/perperl -- -t600 -M8

# This is a mason driver using perperlCGI. 
# 
# Mason causes a dynamic mod_perl module to crash under RedHat.  Compiling
# a statically linked apache is a pain.  To run Mason uder RedHat, I use
# perperlCGI which is a GPL program available from freshmeat.  perperlCGI
# sets up a persistent perl interpreter.

# Library commands
use lib "/home/httpd/lib";

# General includes
use HTML::Mason;
use CGI qw(:standard);

$outbuf = "";

my($query) = new CGI;
my($page) = $ENV{'PATH_INFO'};
my($item);
my($match) = 0;

# Do directory searching.  Running mason through a perperlCGI driver
# BYPASSES normal .htaccess directives.  

foreach $item ("/catalog/", "/index.html", "/beta/", "/ads/",
	       "/lounges/", "/guides/", "/news/", "/donations.html", "/tech/", 
	       "/channels/", "/heartbeat.html") {
    if ($page =~ /^$item/) {
	$match = 1;
    }
}

if (!$match) {
    print $page;
    exit;
}

# Parser and interp are globals so that we don't have to recreate them
# each time this driver is run.

if (!defined($parser)) {
    $parser = new HTML::Mason::Parser;
}
if (!defined($interp)) {
    $interp = new HTML::Mason::Interp (parser=>$parser,
				       comp_root=>'/home/httpd/html',
				       data_dir=>'/home/httpd/html/mason/data',
				       out_method=>\$outbuf);
}
$retval = $interp->exec($page, $query->Vars);
undef $query;
print "Content-Type: text/html\n\n";
print $outbuf;

