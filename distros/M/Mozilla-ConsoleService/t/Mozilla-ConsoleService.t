use strict;
use warnings FATAL => 'all';

use Test::More tests => 9;
use Mozilla::Mechanize;
use URI::file;
use File::Temp qw(tempdir);

BEGIN { use_ok('Mozilla::ConsoleService') };

$ENV{HOME} = tempdir("/tmp/moz_console_XXXXXX", CLEANUP => 1);

my $url = URI::file->new_abs("t/test.html")->as_string;
my $moz = Mozilla::Mechanize->new(quiet => 1, visible => 0);

my @_last_call = 'NONE';
my $reg = Mozilla::ConsoleService::Register(sub { @_last_call = @_; });
ok($reg);

ok($moz->get($url));
is($moz->title, "Test-forms Page");
like($_last_call[0], qr/missing } after function body/);
like($_last_call[0], qr/test\.html/);
like($_last_call[0], qr/line/);

Mozilla::ConsoleService::Unregister($reg);
@_last_call = ();
ok($moz->get($url));
is_deeply(\@_last_call, []);

$moz->close();
