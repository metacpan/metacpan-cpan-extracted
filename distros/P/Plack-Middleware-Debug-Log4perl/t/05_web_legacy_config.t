#!/usr/bin/env perl

use strict;
use warnings;

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Debug::Log4perl;
use HTTP::Request::Common;
use Test::More;

my $content_type = 'text/html';

# configure the basic Log4perl debug file
my $log4perl_conf = <<CONF;
log4perl.rootLogger=TRACE, DebugLog, DebugPanel

log4perl.appender.DebugLog=Log::Log4perl::Appender::File
log4perl.appender.DebugLog.filename=log4perl_debug.log
log4perl.appender.DebugLog.mode=append
log4perl.appender.DebugLog.layout=PatternLayout
log4perl.appender.DebugLog.layout.ConversionPattern=[%r] %F %L %c - %m%n

log4perl.appender.DebugPanel              = Log::Log4perl::Appender::TestBuffer
log4perl.appender.DebugPanel.name         = psgi_debug_panel
log4perl.appender.DebugPanel.mode         = append
log4perl.appender.DebugPanel.layout       = PatternLayout
log4perl.appender.DebugPanel.layout.ConversionPattern = %r >> %p >> %m >> %c >> at %F line %L%n
log4perl.appender.DebugPanel.Threshold = TRACE

CONF

note "Content-Type: $content_type";

# set up a simple psgi app, that prints 'hello world' and generates some simple log lines
my $app = sub {
	# logger is initialised in the app, AFTER the middleware setup phase
	Log::Log4perl::init( \$log4perl_conf );
	my $logger = Log::Log4perl->get_logger('sample.app');
	$logger->info("Starting Up");

	# loop 10 times and gnerate numbered log lines
	for my $i (1..10) {
		$logger->debug("Testing .... ($i)");
	}

	$logger->info("All done here - thanks for visiting");
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
    $app;
};

# run the app using the standard plack test method
test_psgi $app, sub {
    my $cb  = shift;

    my $res = $cb->(GET '/');
    is $res->code, 200, 'response status 200';

    # examine the html that comes back
    # check we have the 4 panels as expected
    for my $panel (qw/Response Memory Timer Log4perl/) {
        like $res->content,
          qr/<a href="#" title="$panel" class="plDebug${panel}\d+Panel">/,
          "HTML contains $panel panel";
    }
    # check we have the expected log lines
    like $res->content, qr{<td>INFO</td>\s+<td>Starting Up</td>\s+<td>sample\.app</td>}, "HTML Containts 1st log line";
    like $res->content, qr{<td>DEBUG</td>\s+<td>Testing \.\.\.\. \(1\)</td>\s+<td>sample\.app</td>}, "HTML Containts 2nd log line";
    like $res->content, qr{<td>DEBUG</td>\s+<td>Testing \.\.\.\. \(10\)</td>\s+<td>sample\.app</td>}, "HTML Containts n-th log line";
    like $res->content, qr{<td>INFO</td>\s+<td>All done here - thanks for visiting</td>\s+<td>sample\.app</td>}, "HTML Containts last log line";

	# check we have the correct number of log lines
	my @panel_html = $res->content =~ /<div id="plDebugLog4perl.+?<\/table>/sg;
    my @panel_rows = $panel_html[0] =~ /<tr class="plDebug.+?<\/tr>/sg;
    is(scalar @panel_rows, 12, "12 Log rows found");

	# repeat a few more times to ensure we're resetting log each time
	for my $i (1..3) {

        my $res = $cb->(GET '/');

	    my @panel_html = $res->content =~ /<div id="plDebugLog4perl.+?<\/table>/sg;
        my @panel_rows = $panel_html[0] =~ /<tr class="plDebug.+?<\/tr>/sg;
        is(scalar @panel_rows, 12, "12 Log rows found");
    }
};

done_testing;

