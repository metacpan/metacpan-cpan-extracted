use strict;
use warnings;
use Test::More;
use Test::Fatal;

use MooX::Press (
	prefix => 'MyApp',
	class  => [
		'Foo' => { abstract => 1 },
		'Bar' => { extends  => 'Foo' },
	],
);

ok( !MyApp->can('new_foo') );
ok(  MyApp->can('new_bar') );
ok( !MyApp::Foo->can('new') );
ok(  MyApp::Bar->can('new') );

my $obj = MyApp->new_bar;

isa_ok($obj, 'MyApp::Bar');
isa_ok($obj, 'MyApp::Foo');

like(
	exception { 'MyApp::Foo'->new },
	qr/abstract class/i,
);

done_testing;

