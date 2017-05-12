use strict;
use Test::More;
use Test::Exception;
use Pandoc;

plan skip_all => 'pandoc executable >= 1.12.1 required'
    unless pandoc and pandoc->version('1.12.1');
plan skip_all => 'pandoc executable < 1.18 required' # FIXME in Pandoc::Elements
    if pandoc->version('1.18');
plan skip_all => 'Pandoc::Elements required'
    unless eval { require Pandoc::Elements; 1 }; 

my $expect = '{"c":[{"c":[{"c":"--","t":"Str"}],"t":"Emph"}],"t":"Para"}';

my $doc = pandoc->parse( markdown => '*--*' );
isa_ok $doc, 'Pandoc::Document', 'parse markdown';
is $doc->content->[0]->to_json, $expect, 'parse markdown';

$doc = pandoc->parse( html => '<p><em>--</em></p>', '--normalize' );
is $doc->content->[0]->to_json, $expect, 'parse html';

use utf8;
$doc = pandoc->parse( markdown => '*--*', '--smart' );
is $doc->string, '–', 'parse with addition arguments';

is_deeply $doc, pandoc->parse( json => $doc->to_json ), 'parse json';

my $ex = pandoc->file('t/example.md', '--smart');
is_deeply $ex, $doc, 'parse_file';

if ($Pandoc::Elements::VERSION >= 0.29) {
    my $html = pandoc->parse( 'markdown' => '# A *section*' )->to_html;
    ok $html =~ qr{<h1[^>]*>A <em>section</em></h1>}, 'parse->to_html';
}

done_testing;
