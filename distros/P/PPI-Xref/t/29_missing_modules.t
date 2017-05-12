use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";

use File::Temp qw[tempdir];
my ($xref, $lib) = get_xref();

is($xref->missing_modules, 0, "no missing modules yet");
is($xref->missing_module_count('NeverHeardModule'), 0, "never heard");

local $SIG{__WARN__} = \&warner;

my $code1 = "use NoSuchModule";
my $code2 = "use NoSuchModuleEither";

undef $@;
ok($xref->process(\$code1), "no such module");
like($@, qr/Failed to find module 'NoSuchModule'/, "expected warning");

is_deeply([$xref->missing_modules], ['NoSuchModule'], "missing modules");

ok($xref->process(\$code2), "no such module either");

is_deeply([$xref->missing_modules], ['NoSuchModule',
                                     'NoSuchModuleEither'], "one more module");

ok($xref->process(\$code1), "no such module again");

is($xref->missing_module_count('NoSuchModule'), 2, "heard twice");
is($xref->missing_module_count('NoSuchModuleEither'), 1, "heard once");
is($xref->missing_module_count('NeverHeardModule'), 0, "never heard again");

is_deeply([$xref->missing_module_files('NoSuchModule')], ['-'],
          "referring file");
is_deeply([$xref->missing_module_lines('NoSuchModule')], ['-:1'],
          "referring lines");

done_testing();
