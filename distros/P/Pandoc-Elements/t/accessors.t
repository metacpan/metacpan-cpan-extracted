use strict;
use Test::More;
use Pandoc::Elements;

my $e = CodeBlock attributes { class => ['perl'], id => 2 }, 'say "Hi";';

is_deeply $e->attr, $e->{c}->[0], 'CodeBlock->attr';
is $e->id, '2', 'AttributeRole->id';
is $e->class, 'perl', 'AttributeRole->class';

is $e->content, 'say "Hi";', 'CodeBlock->content';
is $e->content('foo'), 'foo', 'setter';
is $e->content, 'foo', 'setter';

$e = Quoted SingleQuote, 'x';
is $e->type->name, 'SingleQuote', 'Quoted';

{
	my $e = BulletList [];
	is_deeply $e->items, [], 'BulletList: items';
	my $items = [ [ Plain Str 'foo' ] ];
	is_deeply $e->content($items), $items, 'BulletList: content(...)';
	is_deeply $e->items, $items, 'BulletList: items set';
}

{
	my $content = 'a';
	my $attr = attributes {};
	my $e = Span $attr, $content;

	is_deeply $e->attr, $attr, 'Span: attr';
	$attr = attributes { a => 1 };
	is_deeply $e->attr($attr), $attr, 'Span: attr(...)';
	is_deeply $e->attr, $attr, 'Span: attr set';

	is_deeply $e->content, 'a', 'Span: content';
	is_deeply $e->content('b'), 'b', 'Span: content(...)';
	is_deeply $e->content, 'b', 'Span: content set';	
}

{
	my $e = DefinitionList [
    	[ [ Str 'term 1' ],
			[ [ Para Str 'definition 1' ] ] ],
		[ [ Str 'term 2' ],
			[ [ Para Str 'definition 2' ],
			  [ Para Str 'definition 3' ] ] ],
	];
	is_deeply $e->items, $e->content, 'DefinitionList: items=content';
	is scalar @{$e->items}, 2, 'DefinitionList->items';
	is_deeply $e->items->[0]->term, [ Str 'term 1' ], '...->term';
	is_deeply $e->items->[1]->definitions->[1],
		[ Para Str 'definition 3' ], '...->definitions';
}

{
    my $doc = Document { foo => 1 }, [];
    note explain $doc->to_json;
    is_deeply $doc->meta->value, { foo => 1 }, 'Document: meta';
    $doc->meta({ bar => 0 });
    is_deeply $doc->meta->value, { bar => 0 }, 'Document: meta(...)';
}

done_testing;
