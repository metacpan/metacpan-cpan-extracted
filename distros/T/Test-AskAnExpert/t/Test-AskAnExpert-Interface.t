use Test::More tests => 8;

BEGIN { use_ok('Test::AskAnExpert::Interface') };

my $interface = Test::AskAnExpert::Interface->load();
ok(defined($interface) && $interface->isa('Test::AskAnExpert::Interface'),'Interface loads properly');

my $Qobj = $interface->submit('Test','Test');
ok(defined($Qobj) && $Qobj->isa('Test::AskAnExpert::Question'),	'Questions submit properly');
ok($Qobj->skip,							'Defaults to skipping');

ok($interface->has_answer,'Always has an answer');

ok($interface->answer($Qobj),	'Answer does not fail');
ok($Qobj->skip,			'Defaults to skipping after answer');

$interface->err('Testing Err');
is($interface->err,'Testing Err','err function behaves properly');
