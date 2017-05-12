use strict;
use Test::More;
use Pandoc::Elements;

my $doc = Document { }, [
    Header(1,attributes {},[ Str 'hello', Code attributes {}, ', ' ]),
    BulletList [ [ Plain [ Str 'world', Space, Str '!' ] ] ],
];

$doc->meta->{foo} = MetaInlines [ Emph [ Str "FOO" ] ];
$doc->meta->{bar} = MetaString "BAR";
$doc->meta->{doz} = MetaMap { x => MetaList [ MetaInlines [ Str "DOZ" ] ] };

is $doc->meta->{foo}->string, 'FOO', 'stringify MetaInlines';
is $doc->meta->{bar}->string, 'BAR', 'stringify MetaString';
is $doc->meta->{doz}->string, 'DOZ', 'stringify MetaMap>MetaList>MetaInlines';

is $doc->string, 'hello, world !', 'stringify Document with metadata';

is LineBreak->string, ' ', 'LineBreak to space';
is RawBlock('html','<b>hi</hi>')->string,  '', 'RawBlock has no string';
is RawInline('html','<b>hi</hi>')->string,  '', 'RawInline has no string';
is Code(attributes {},'#!$')->string,  '#!$', 'Code has string';

is CodeBlock({}, 'Hi')->string, 'Hi', 'CodeBlock has string';

done_testing;

__DATA__
# hello`,`

* world !
