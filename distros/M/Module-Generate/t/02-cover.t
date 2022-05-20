use Test::More;
no warnings;

use Module::Generate;

mkdir 't/lib/unable';
subtest "start" => sub  {
	ok(my $start = Module::Generate->start());
	is(ref $start, 'Module::Generate');
	ok($start = $start->start());
	is(ref $start, 'Module::Generate');
};

subtest "dist" => sub {
	ok(my $dist = Module::Generate->dist('Test'));
	is(ref $dist, 'Module::Generate');
	my %class = %Module::Generate::CLASS;
	is($class{DIST}, 'Test');
	ok($dist = $dist->dist('Testing'));
	is(ref $dist, 'Module::Generate');
	%class = %Module::Generate::CLASS;
	is($class{DIST}, 'Testing');
};

subtest "class" => sub {
	ok(my $class = Module::Generate->class('Test'));
	is(ref $class, 'Module::Generate');
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}, {NAME => 'Test'});
	ok($class = $class->class('Testing'));
	is(ref $class, 'Module::Generate');
	%class = %Module::Generate::CLASS;
	is_deeply($class{Testing}, {NAME => 'Testing'});
};

subtest "lib" => sub {
	ok(my $lib = Module::Generate->lib('t/'));
	is(ref $lib, 'Module::Generate');
	my %class = %Module::Generate::CLASS;
	is($class{LIB}, 't/');
	ok($lib = $lib->lib('t/lib'));
	is(ref $lib, 'Module::Generate');
	%class = %Module::Generate::CLASS;
	is($class{LIB}, 't/lib');
};

subtest "author" => sub {
	ok(my $author = Module::Generate->author('lnation'));
	is(ref $author, 'Module::Generate');
	my %class = %Module::Generate::CLASS;
	is($class{AUTHOR}, 'lnation');
	ok($author = $author->author('LNATION'));
	is(ref $author, 'Module::Generate');
	%class = %Module::Generate::CLASS;
	is($class{AUTHOR}, 'LNATION');
};

subtest "email" => sub {
	ok(my $email = Module::Generate->email('thisusedtobeanemail@gmail.com'));
	is(ref $email, 'Module::Generate');	
	my %class = %Module::Generate::CLASS;
	is($class{EMAIL}, 'thisusedtobeanemail@gmail.com');
	ok($email = $email->email('email@lnation.org'));
	is(ref $email, 'Module::Generate');
	%class = %Module::Generate::CLASS;
	is($class{EMAIL}, 'email@lnation.org');
};

subtest "version" => sub {
	ok(my $version = Module::Generate->version('0.01'));
	is(ref $version, 'Module::Generate');
	my %class = %Module::Generate::CLASS;
	is($class{VERSION}, '0.01');
	ok($version = $version->version('0.02'));
	is(ref $version, 'Module::Generate');
	%class = %Module::Generate::CLASS;
	is($class{VERSION}, '0.02');
};

subtest 'synopsis' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->synopsis('This is a synopsis'));
	my %class = %Module::Generate::CLASS;
	is($class{Test}->{SYNOPSIS}, 'This is a synopsis');
};

subtest 'abstract' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->abstract('This is a abstract'));
	my %class = %Module::Generate::CLASS;
	is($class{Test}->{ABSTRACT}, 'This is a abstract');
};

subtest 'use' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->use('Foo'));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{USE}, ['Foo']);	
	ok($class->use('Bar'));	
	%class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{USE}, ['Foo', 'Bar']);	
};

subtest 'base' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->base('Foo'));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{BASE}, ['Foo']);	
	ok($class->base('Bar'));
	%class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{BASE}, ['Foo', 'Bar']);	
};

subtest 'parent' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->parent('Foo'));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{PARENT}, ['Foo']);	
	ok($class->parent('Bar'));
	is_deeply($class{Test}->{PARENT}, ['Foo', 'Bar']);	
};

subtest 'require' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->require('Foo'));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{REQUIRE}, ['Foo']);	
	ok($class->require('Bar'));	
	%class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{REQUIRE}, ['Foo', 'Bar']);	
};

subtest 'our' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->our('$foo'));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{GLOBAL}, ['$foo']);	
	ok($class->our('$bar'));
	%class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{GLOBAL}, ['$foo', '$bar']);	
};

subtest 'begin' => sub {
	ok(my $class = Module::Generate->class('Test'));
	my $ref = sub { 1; };
	ok($class->begin($ref));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{BEGIN}, $ref);	
};

subtest 'unitcheck' => sub {
	ok(my $class = Module::Generate->class('Test'));
	my $ref = sub { 1; };
	ok($class->unitcheck($ref));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{UNITCHECK}, $ref);	
};

subtest 'check' => sub {
	ok(my $class = Module::Generate->class('Test'));
	my $ref = sub { 1; };
	ok($class->check($ref));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{CHECK}, $ref);	
};

subtest 'init' => sub {
	ok(my $class = Module::Generate->class('Test'));
	my $ref = sub { 1; };
	ok($class->init($ref));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{INIT}, $ref);	
};

subtest 'end' => sub {
	ok(my $class = Module::Generate->class('Test'));
	my $ref = sub { 1; };
	ok($class->end($ref));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{END}, $ref);	
};

subtest 'new' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->new);
	my $ref = sub { 1; };
	ok($class->new($ref));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{SUBS}->{new}->{CODE}, $ref);	
};

subtest 'accessor' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->accessor('foo'));
	my $ref = sub { 1; };
	ok($class->accessor('foo', $ref));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{SUBS}->{foo}->{CODE}, $ref);	
};

subtest 'macro' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->macro('test', '{ 1 }'));
	ok($class->macro('test', sub { 1 }));
};

subtest 'sub' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->sub('bar'));
	my %class = %Module::Generate::CLASS;
	is_deeply($class{Test}->{SUBS}->{bar}, {INDEX => 5, TEST => [['can_ok', '$obj', "'bar'"]]});
};

subtest 'code' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->code('{ 1 }'));
	ok($class->code('test', sub { 1 }));
};

subtest 'pod' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->pod('add some pod'));	
	my %class = %Module::Generate::CLASS;
	is($class{Test}->{SUBS}->{CURRENT}->{POD}, 'add some pod');
};

subtest 'example' => sub {
	ok(my $class = Module::Generate->class('Test'));
	ok($class->example('$example'));
	my %class = %Module::Generate::CLASS;
	is($class{Test}->{SUBS}->{CURRENT}->{EXAMPLE}, '$example');
};

subtest 'generate_dist' => sub {
	%Module::Generate::CLASS = ();
	ok(my $dist = Module::Generate->dist('Test'));
	ok($dist->lib('./t/lib'));
	eval { $dist->generate };
};

subtest 'generate_use' => sub {
	%Module::Generate::CLASS = ();
	ok(my $mod = Module::Generate->class('Test'));
	ok($mod->lib('./t/lib'));
	ok($mod->use('Foo'));
	ok($mod->parent('Bar'));
	ok($mod->require('Bang'));
	$mod->generate();
};

subtest '_make_path' => sub {
	ok(Module::Generate::_make_path('./t/lib/path'));
	rmdir('./t/lib/path');
};

subtest '_build_phase' => sub {
	ok(my $code = Module::Generate::_build_phase({
		BEGIN => '{ 1 }'
	}));
	is($code, 'BEGIN { 1 };');
};

subtest '_build_subs' => sub {
	ok(my $sub = Module::Generate::_build_subs({
		SUBS => {
			test => {}
		}
	}));
	is($sub, 'sub test {


}');
	ok($sub = Module::Generate::_build_subs({
		SUBS => {
			test => {
				CODE => '{ 1 }'
			}
		}
	}));
	is($sub, 'sub test {1 }');
};

subtest '_build_pod' => sub {
	ok(my $pod = Module::Generate->_build_pod({
		VERSION => '1.0',
		SYNOPSIS => 'JUST A TEST',
		SUBS => {
			test => {}
		}
	}));
};

subtest 'generate' => sub {
	%Module::Generate::CLASS = ();
	Module::Generate->generate();
	eval { 
		Module::Generate->lib('./t/lib')
			->dist('Bar')
			->author('LNATION')
			->email('email@lnation.org')
			->version('0.01')
			->macro('self', sub {
				my ($self, $value) = @_;
			})
			->class('Bar')
				->abstract('A Testing Module')
				->our('$one')
				->begin(sub {
					$one = 'abc';
				})
				->new
		->generate;
	};
	ok(1);
};

subtest _perl_tidy => sub {
	local $SIG{__WARN__} = sub { };
	eval { my $kaput = Module::Generate::_perl_tidy(q|kaput[{]}|) };
	like ($@, qr/Exiting because of serious errors/);
};

done_testing;
