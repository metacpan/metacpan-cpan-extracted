$| = 1; # autoflush

$DEBUG = 0;

# uncomment the following line if you want to run these tests from the command
# line using the local version of Parallel::UserAgent (otherwise perl will take
# the already installed version):
# use lib ('./lib');

print "1..4\n";

require LWP::Parallel::UserAgent;
require HTTP::Request;
my $ua = new LWP::Parallel::UserAgent;
$ua->agent("Mozilla/0.01 " . $ua->agent);
$ua->from('marclang@cpan.org');

use Cwd;
my $pwd = getcwd;

#---------------------------------------------------------------
print "\nLWP::Parallel::UserAgent interface...";
print "\nSingle bad request..\n";
$req = new HTTP::Request GET => "file:$pwd/not_found";
$req->header(X_Foo => "Bar");

print STDERR "\tRegistering '".$req->url."'\n" if $DEBUG;
if ( $res = $ua->register ($req) ) { 
    print STDERR $res->error_as_HTML;
    print "not";
} 
print "ok 1\n";

my $entries = $ua->wait(5);
foreach (keys %$entries) {
    # each entry available under the url-string of their request contains
    # a number of fields. The most important are $entry->request and
    # $entry->response. 
    $res = $entries->{$_}->response;
    print STDERR "Answer for '",$res->request->url, "' was \t", 
          $res->code,": ", $res->message,"\n" if $DEBUG;

    print "not " unless $res->is_error
                        and $res->code == 404
                        and $res->message =~ /not\s+exist/i;

    print "ok 2\n";
}

#----------------------------------------------------------------
print "\nMultiple Requests...\n";

# first five files from directory for testing
opendir (DIR, $pwd) or die "Can't open $pwd: $!";
my %files;
while (defined ($file = readdir(DIR))) {
   next unless (-f "$pwd/$file");
   open (FILE, "$pwd/$file") or die "Can't open $pwd/$file: $!";
   $files{$file} = join ('', <FILE>);
   close (FILE);
}

$ua->initialize;
for (0..10) { # read every file 10 times
  foreach (keys %files) {
    $req = new HTTP::Request GET => "file:$pwd/$_";
    print STDERR "\tRegistering '".$req->url."'\n" if $DEBUG;
    if ( $res = $ua->register ($req) ) { 
	print STDERR $res->error_as_HTML;
	print "not";
	last;
    } 
  }
}
print "ok 3\n";

$entries = $ua->wait(5);
foreach (keys %$entries) {
    $res = $entries->{$_}->response;
    my $url = $res->request->url;
    my $file = $url->as_string;
    $file =~ s/^.*\///;

    print STDERR "Answer for '$url' was \"", 
          $res->code,": ", $res->message,"\"\n"
	      if $DEBUG;

    unless ( $res->content eq $files{$file} ) {
	print "not ";
	last;
    }
}
print "ok 4\n";

__END__
#----------------------------------------------------------------
print "\nLarger number of requests (40)..\n";

$ua->initialize;

for (0..40) {
    my $page = $i % 3;
    $req = new HTTP::Request GET => url("/page$page", $base);
    print STDERR "\tRegistering '".$req->url."'\n" if $DEBUG;
    if ( $res = $ua->register ($req) ) { 
	print STDERR $res->error_as_HTML;
	print "not";
	last;
    } 
}
print "ok 6\n";
$i=0;
$entries = $ua->wait(5);
foreach (keys %$entries) {
    $res = $entries->{$_}->response;
    my $url = $res->request->url;
    $url =~ /([0-9]+)$/;
    my $num = $1;

    print STDERR "Answer for '$url' was \n\t", 
          $res->code,": ", $res->message," \"", $res->content, "\"\n"
	      if $DEBUG;
    unless ($res->content =~ /This is page $num/) 
    {
	print STDERR "Oops: Answer ($i) for '$url' was \n\t", 
	$res->code,": ", $res->message," \"", $res->content, "\"\n";
	          
	print ("not ");
	last;
    }
    $i++;
}
print "ok 7\n";

#----------------------------------------------------------------
sub httpd_get_echo
{
    my($c, $req) = @_;
    $c->send_basic_header(200);
    print $c "Content-Type: text/plain\015\012";
    $c->send_crlf;
    print $c $req->as_string;
}

sub httpd_get_redirect
{
   my($c) = @_;
   $c->send_redirect("/echo/redirect");
}

print "\nCheck redirect on/off...\n";

$ua->initialize;
$ua->redirect(1);

$req = new HTTP::Request GET => url("/redirect/foo", $base);
print STDERR "\tRegistering '".$req->url."'\n" if $DEBUG;
if ( $res = $ua->register ($req) ) { 
    print STDERR $res->error_as_HTML;
    print "not ok 8\nnot ok 9\n";
} else {
    $entries = $ua->wait(5);
    foreach (keys %$entries) {
	$res = $entries->{$_}->response;
	print "not " unless $res->is_success
	    and $res->content =~ m|/echo/redirect|;
	print "ok 8\n";
	print "not " unless $res->previous 
                        and $res->previous->is_redirect
          	        and $res->previous->code == 301;
	print "ok 9\n";
	last;
    }
}

$ua->initialize;
$ua->redirect(0);

print STDERR "\tRegistering '".$req->url."'\n" if $DEBUG;
if ( $res = $ua->register ($req) ) { 
    print STDERR $res->error_as_HTML;
    print "not ok 10\nnot ok 11\n";
} else {
    $entries = $ua->wait(5);
    foreach (keys %$entries) {
	$res = $entries->{$_}->response;
	print "not " if $res->is_success
	    and $res->content =~ m|/echo/redirect|;
	print "ok 10\n";
	print "not " unless $res->code == 301;
	print "ok 11\n";
	last;
    }
}

#----------------------------------------------------------------
print "\nTesting ordered connections...\n";

my $order_num = 0;
my @order_history = ();
sub httpd_get_num
{
    my($c, $req) = @_;
    my $num = $req->url->fragment;
    push @order_history, $num;
    my $msg = "Request History: ". join (", ", @order_history) . "\n"; 

    $c->send_basic_header(200);
    print $c "Content-Type: text/plain\015\012";
    $c->send_crlf;
}

package main;

my $uao = new myPUA { 'handle_in_order' => 0 };

for (0..40) {
  $req = new HTTP::Request GET => url("/num?$_", $base);
  print STDERR "\tRegistering '".$req->url."'\n" if $DEBUG;
  if ( $res = $uao->register ($req) ) { 
    print STDERR $res->error_as_HTML;
    print "not";
  } 
}
print "ok 12\n";

$entries = $uao->wait(5);



#----------------------------------------------------------------
print "\nTerminating server...\n";
sub httpd_get_quit
{
    my($c) = @_;
    $c->send_error(503, "Bye, bye");
    exit;  # terminate HTTP server
}
$ua->initialize;
$req = new HTTP::Request GET => url("/quit", $base);
print STDERR "\tRegistering '".$req->url."'\n" if $DEBUG;
if ( $res = $ua->register ($req) ) { 
    print STDERR $res->error_as_HTML;
    print "not";
} 
print "ok 13\n";

$entries = $ua->wait(5);
foreach (keys %$entries) {
    # each entry available under the url-string of their request contains
    # a number of fields. The most important are $entry->request and
    # $entry->response. 
    $res = $entries->{$_}->response;
    print STDERR "Answer for '",$res->request->url, "' was \t", 
          $res->code,": ", $res->message,"\n" if $DEBUG;

    print "not " unless $res->code == 503 and $res->content =~ /Bye, bye/;
    print "ok 14\n";
}

