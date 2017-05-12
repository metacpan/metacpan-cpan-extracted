use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;
use File::Slurp;
use HTTP::Daemon;
use Mozilla::Mechanize;
use File::Temp qw(tempdir);
use Mozilla::PromptService;

BEGIN { use_ok('Mozilla::SourceViewer') };

my $td = tempdir('/tmp/moz_src_XXXXXX', CLEANUP => 1);
$ENV{HOME} = $td;
my $pid = fork();
if (!$pid) {
	my $d = HTTP::Daemon->new;
	write_file("$td/url", $d->url);
	while (1) {
		my $c = $d->accept;
		while (my $r = $c->get_request) {
			if ($r->uri =~ /td\/(.*)$/) {
				$c->send_file_response("$td/$1");
				next;
			}

			my $resp = HTTP::Response->new(200);
			$resp->content("<html><body><pre>"
				. $r->as_string . "</pre></body></html>");
			$c->send_response($resp);
		}
		$c->close;
		undef($c);
	}
	exit;
}

sleep 1;
my $d_url = read_file("$td/url");
write_file("$td/a.html", <<ENDS);
<html>
<head>
<title>Test Page</title>
</head>
<body>
<form action="$d_url/submit" method="post">
<input type="text" name="a" />
<input type="submit" />
</form>
</body>
</html>
ENDS

# diag("URL: $d_url/td/a.html dir: $td, pid $$");

my $moz = Mozilla::Mechanize->new(quiet => 1, visible => 0);
ok($moz->get("$d_url/td/a.html"));
is($moz->title, "Test Page");
Mozilla::PromptService::Register({ DEFAULT => sub {} });

$moz->submit_form;
like($moz->content, qr/POST/);

my $vs = Get_Page_Source($moz->agent->{embed});
like($vs, qr/POST/);

kill(9, $pid);
waitpid($pid, 0);

