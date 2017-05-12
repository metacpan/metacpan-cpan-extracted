use strict;
use Test::More;
use Pandoc::Elements;
use Pandoc::Filter::HeaderIdentifiers;
use utf8;

my $ids={};
is header_identifier('Hello, nice world!'), 'hello-nice-world', 'header_identifier';
is header_identifier('1ẞ𝟼#6Ä_.-$'), 'ß6ä_.-', 'header_identifier strips characters';
is header_identifier('123#',$ids), 'section', 'header_identifier fallback';
is header_identifier('123#',$ids), 'section-1', 'header_identifier with numbering';
is_deeply $ids, { section => 2 }, 'identifier counts';

is header_identifier('a + + b +'), 'a-b', 'avoid too many hyphens';
is header_identifier('a, + }'), 'a', 'avoid too many hyphens';
is header_identifier('a -+-'), 'a---', 'but not more then allowed';

my $inlines = [ Str "A", Note [ Para [ Str "b" ] ], Str "C" ];
is header_identifier($inlines), 'ac', 'header_identifier without footnotes';

ok "abc123-" =~ /^\p{InPandocHeaderIdentifier}+$/, 'InPandocHeaderIdentifier';
ok "A+ǅ" =~ /^\p{^InPandocHeaderIdentifier}+$/, 'InPandocHeaderIdentifier';

my $doc = Document {}, [ map {
        my ($title, $id) = split '=', $_;
        Header 1, attributes { id => $id }, [ Str $title ]
    } ('foo=','test=','test=test-2','test=','123=') ];

my $ids = { foo => 1 };
Pandoc::Filter::HeaderIdentifiers->new->apply($doc, $ids);
is_deeply $ids, { foo => 2, test => 5, section => 1 }, 'apply';

is_deeply $doc->query( Header => sub { $_->id } ),
    [qw(foo-1 test-3 test-2 test-4 section)], 'identifiers added';

done_testing;
