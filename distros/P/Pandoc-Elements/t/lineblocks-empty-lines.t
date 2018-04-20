use Test::More 0.96;
use Test::Warnings qw(warnings :no_end_test);

use Pandoc::Elements;
use Pandoc;

plan skip_all => 'pandoc >= 1.18 not available'
    unless (pandoc and pandoc->version >= '1.18');

my $lineblock = <<'END_OF_MD';
| Sven Svensson
|
|
|
| Tel: 0123-45 67 89
|
| Adress:
|
| Storgatan 42
| 123 45 Storstad
| Sverige
END_OF_MD

my $doc = pandoc->parse(markdown => $lineblock);

my $json;

is_deeply [
    warnings {
        $json = $doc->to_json;
    }
], [], 'uninitialized';

is_deeply [
    warnings {
        my $doc = pandoc->parse( json => $json );
    }
], [], 'parse json';

done_testing;

