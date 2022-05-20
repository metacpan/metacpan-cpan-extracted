use Test::More;
no warnings;

use Module::Generate;

mkdir 't/lib/unable';
subtest "tlib" => sub  {
	ok(my $start = Module::Generate->tlib('/t')->dist('Planes')->class('Planes'));	
	is(ref $start, 'Module::Generate');
	ok($start = $start->start());
	is(ref $start, 'Module::Generate');
	ok($start->tlib('t'));
};

subtest "keyword" => sub  {
	ok(my $start = Module::Generate->start());
	ok($start = $start->keyword('testing', {
		CODE => sub {
			my ($meta) = @_;
			$meta->{is} ||= q|'ro'|;
			my $attributes = join ', ', map { 
				($meta->{$_} ? (sprintf "%s => %s", $_, $meta->{$_}) : ()) 
			} qw/is required/;
			my $code = qq|
				has $meta->{has} => ( $attributes );|;
			return $code;
		}, 
		KEYWORDS => [qw/is required/], 
		POD_TITLE => 'ATTRIBUTES',
		POD_POD => 'get or set $keyword',
		POD_EXAMPLE => "\$obj->\$keyword;\n\n\t\$obj->\$keyword(\$value);"  
	}));
	ok($start = $start->keyword('testing2',
		sub {
			my ($meta) = @_;
			$meta->{is} ||= q|'ro'|;
			my $attributes = join ', ', map { 
				($meta->{$_} ? (sprintf "%s => %s", $_, $meta->{$_}) : ()) 
			} qw/is required/;
			my $code = qq|
				has $meta->{has} => ( $attributes );|;
			return $code;
		}, 
		[qw/isa req/], 
		'ATTRIBUTES',
	));
	is(ref $start, 'Module::Generate');
};

subtest "use" => sub  {
	%Module::Generate::CLASS = ();
	ok(my $start = Module::Generate->start()->class('FOO'));
	$start->use('Acme::Foo', '[qw/one two three/]');
	my $use = Module::Generate::_build_use($Module::Generate::CLASS{FOO});
	is($use, 'use Acme::Foo qw/one two three/;');
};

subtest 'stringify' => sub {
	%Module::Generate::CLASS = ();
	ok(my $start = Module::Generate->start()->class('FOO'));
	ok(my $struct = Module::Generate::_stringify_struct('', {qw/a b c d/}, {qw/1 2 3 4/}));
	ok(!Module::Generate::_stringify_struct(''));
};

subtest 'no_code' => sub {
	%Module::Generate::CLASS = ();
	ok(my $start = Module::Generate->start()->class('FOO')->sub('test')->no_code(1));
	ok(!Module::Generate::_build_subs($Module::Generate::CLASS{FOO}));
};

subtest '_build_subs_keyword' => sub {
	%Module::Generate::CLASS = ();
	ok(my $start = Module::Generate->start()->class('FOO')->keyword('tester', sub { return 1; })->tester('thing')->code([{qw/a b c d/}, {qw/1 2 3 4/}]));
	ok(Module::Generate::_build_subs($Module::Generate::CLASS{FOO}));
};

subtest '_build_subs_keyword2' => sub {
	%Module::Generate::CLASS = ();
	ok(my $start = Module::Generate->start()->class('FOO')->keyword('testers', sub { return 1; })->tester('thing')->code({qw/a b c d/}));
	ok(Module::Generate::_build_subs($Module::Generate::CLASS{FOO}));
};

subtest '_build_Test' => sub {
	%Module::Generate::CLASS = ();
	ok(my $start = Module::Generate->start()->class('FOO')->sub('test')->no_code(1));
	ok(Module::Generate::_build_test('ok(1)'));
	delete $Module::Generate::CLASS{FOO}->{SUBS}{test}{TEST};
	ok(Module::Generate::_build_tests($Module::Generate::CLASS{FOO}));
};
	
done_testing;
