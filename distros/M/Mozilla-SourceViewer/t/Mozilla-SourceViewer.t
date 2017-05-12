use strict;
use warnings FATAL => 'all';

use Test::More tests => 54;
use Mozilla::Mechanize;
use URI::file;
use File::Slurp;
use File::Temp qw(tempdir);
use File::Path qw(rmtree);

BEGIN { use_ok('Mozilla::SourceViewer') };

my $td = tempdir("/tmp/moz_src_XXXXXX");
$ENV{HOME} = $td;

my $pid = fork;
exec('perl t/one_time_http.pl t/test.html') if !$pid;

my $url = URI::file->new_abs("t/test.html")->as_string;
my $moz = Mozilla::Mechanize->new(quiet => 1, visible => 0);

ok($moz->get($url));
is($moz->title, "Test-forms Page");

# temporary ScrollTo implementation. Real one should get into Mozilla::DOM
Mozilla::SourceViewer::Scroll_To($moz->get_window, 20, 20);
ok 1;

my $e = $moz->agent->{embed};
my $vs = Get_Page_Source($e);
like($vs, qr#<input type="hidden" name="dummy2" value="empty" />#);

$url = read_file($ENV{HOME} . "/oth.url");
ok($moz->get($url . "?djdjdjde"));
is($moz->title, "Test-forms Page");
$vs = Get_Page_Source($e);
like($vs, qr#<input type="hidden" name="dummy2" value="empty" />#);

ok($moz->get('http://www.google.com'));
is($moz->title, "Google");
$vs = Get_Page_Source($moz->agent->{embed});
like($vs, qr#Google#);
unlike($vs, qr#<input type="hidden" name="dummy2" value="empty" />#);

ok($moz->get($url . "?932932293"));
is($moz->title, "Test-forms Page");
waitpid($pid, 0);

SKIP: {
	skip "RUN_FAST is given", 40 if $ENV{RUN_FAST};
write_file("$td/invoke.pl", <<'ENDS');
use Mozilla::Mechanize;
use Mozilla::SourceViewer;

my $moz = Mozilla::Mechanize->new(quiet => 1, visible => 0);
$moz->get($ARGV[0]);
print Get_Page_Source($moz->agent->{embed});
ENDS

for (1 .. 40) {
	# All of these nonsense is needed to reproduce empty string bug
	my $test = read_file("t/test.html");
	write_file("$td/$_.html", $test);
	$url = URI::file->new_abs("t/test.html")->as_string;
	my $res = `perl $td/invoke.pl $url 2>&1`;
	like($res, qr#<input type="hidden" name="dummy2" value="empty" />#);
}
};
