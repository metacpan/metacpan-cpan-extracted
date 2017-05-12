#!/usr/bin/env perl

use strict;
use warnings;

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Debug::Log4perl;
use Plack::Request;
use HTTP::Request::Common;

BEGIN {
  use Config;
  if (! $Config{'useithreads'}) {
    print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
    exit(0);
  }
}

# Test::More will only be aware of threads if "use threads" has been done before Test::More is loaded.
use threads;
use Test::More;

my $content_type = 'text/html'; # ('text/html', 'text/html; charset=utf8',);

# configure the basic Log4perl debug file
my $log4perl_conf = <<CONF;
log4perl.rootLogger=TRACE, DebugLog
log4perl.appender.DebugLog=Log::Log4perl::Appender::File
log4perl.appender.DebugLog.filename=log4perl_debug.log
log4perl.appender.DebugLog.mode=append
log4perl.appender.DebugLog.layout=PatternLayout
log4perl.appender.DebugLog.layout.ConversionPattern=%d [%P %r] %p %m [%c] at %F line %L%n
CONF

note "Content-Type: $content_type";

# set up a simple psgi app, that prints 'hello world' and generates some simple log lines
my $app = sub {
    my $env = shift;

	# we want to get the id from the request query string, to put in our log lines
    my $req = Plack::Request->new($env);
	my $test_id = $req->param('id') || 'x';

	my $logger = Log::Log4perl->get_logger('sample.app');
	$logger->info("Starting Up [test_id: $test_id]");

	# loop 10 times and gnerate numbered log lines
	for my $i (1..10) {
		sleep 1;
		$logger->debug("Testing .... ($i) [test_id: $test_id]");
	}

	$logger->info("All done here - thanks for visiting [test_id: $test_id]");
    return [
        200, [ 'Content-Type' => $content_type ],
        ['<body>Hello World</body>']
    ];
};

# configure the debug panel
# Debug and Log4perl middlewares are both standard psgi stuff
# but the Log4perl option in the debug line is the part added by this module
$app = builder {
    enable 'Debug', panels =>[qw/Response Memory Timer Log4perl/];
	enable 'Log4perl', category => 'plack', conf => \$log4perl_conf;
    $app;
};


# run the app using the standard plack test method
sub run_app {
	# pass in an identifier so we can check each running app is different
	my $test_id = shift;

	test_psgi $app, sub {
	    my $cb  = shift;

	    my $res = $cb->(GET "/?id=$test_id");
	    is $res->code, 200, 'response status 200';

	    # examine the html that comes back
	    # check we have the 4 panels as expected
	    for my $panel (qw/Response Memory Timer Log4perl/) {
	        like $res->content,
	          qr/<a href="#" title="$panel" class="plDebug${panel}\d+Panel">/,
	          "HTML contains $panel panel";
	    }
	    # check we have the expected log lines
	    like $res->content, qr{<td>INFO</td>\s+<td>Starting Up \[test_id: $test_id\]</td>\s+<td>sample\.app</td>}, "HTML Containts 1st log line";
	    like $res->content, qr{<td>DEBUG</td>\s+<td>Testing \.\.\.\. \(1\) \[test_id: $test_id\]</td>\s+<td>sample\.app</td>}, "HTML Containts 2nd log line";
	    like $res->content, qr{<td>DEBUG</td>\s+<td>Testing \.\.\.\. \(10\) \[test_id: $test_id\]</td>\s+<td>sample\.app</td>}, "HTML Containts n-th log line";
	    like $res->content, qr{<td>INFO</td>\s+<td>All done here - thanks for visiting \[test_id: $test_id\]</td>\s+<td>sample\.app</td>}, "HTML Containts last log line";

		# check we have the correct number of log lines
		my @panel_html = $res->content =~ /<div id="plDebugLog4perl.+?<\/table>/sg;
	    my @panel_rows = $panel_html[0] =~ /<tr class="plDebug.+?<\/tr>/sg;
	    is(scalar @panel_rows, 12, "12 Log rows found");
	};
}

my $thread1 = threads->create( \&run_app, '1' );
my $thread2 = threads->create( \&run_app, '2' );
my $thread3 = threads->create( \&run_app, '3' );

$thread1->join();
$thread2->join();
$thread3->join();

done_testing;

