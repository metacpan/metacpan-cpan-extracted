use strict;
use 5.010;
use Test::More;
use Pandoc::Filter;
use Pandoc::Elements;

my $json = '[{"unMeta":{"foo":{"c":[{"c":"bar","t":"Str"}],"t":"MetaInlines"}}},[{"c":[{"c":"doz","t":"Str"}],"t":"Para"}]]';

my $allcaps = '[{"unMeta":{"foo":{"c":[{"c":"BAR","t":"Str"}],"t":"MetaInlines"}}},[{"c":[{"c":"DOZ","t":"Str"}],"t":"Para"}]]';

my $contentcaps = '[{"unMeta":{"foo":{"c":[{"c":"bar","t":"Str"}],"t":"MetaInlines"}}},[{"c":[{"c":"DOZ","t":"Str"}],"t":"Para"}]]';

my $filter = Pandoc::Filter->new( Str => sub { Str(uc $_->content) } );

my $doc = pandoc_json($json);
$doc->transform($filter),
is $doc->to_json, $allcaps, 'transform with metadata element';

$doc = pandoc_json($json);
$filter->apply($doc->content);
is $doc->to_json, $contentcaps, 'apply document content only';

{
    open my $stdin, '<', \$json;
    local *STDIN = $stdin;
    my $doc = pandoc_walk Str => sub { Str(uc $_->content) };
    is $doc->to_json, $contentcaps, 'pandoc_walk document content only';
}

done_testing;
