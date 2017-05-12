use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";

use File::Temp qw[tempdir];
my ($xref, $lib) = get_xref();

local $SIG{__WARN__} = \&warner;

is($xref->parse_errors_files, 0, "no parse errors yet");

my $code = '{';

undef $@;
ok($xref->process(\$code), "parse errors");
like($@, qr/PPI::Document incomplete in -/, "expected warning");

is_deeply([$xref->parse_errors_files],
          ['-'],
          "parse errors files");

is_deeply({$xref->file_parse_errors('-')},
          {'-' => 'PPI::Document incomplete'},
          "file parse errors");

done_testing();
