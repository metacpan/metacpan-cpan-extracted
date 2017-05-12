use Test::More  'no_plan';
use Telephone::Mnemonic::US::Number qw/ beautify /;


is beautify('7031234567'), '(703) 123 4567';
is beautify('703-123-4567'), '(703) 123 4567';
is beautify('703.123-4567'), '(703) 123 4567';
is beautify('1234567'), '123 4567';
ok ! beautify('13'), 'ill formed';
ok ! beautify('1234'), 'ill formed';
ok ! beautify('22 1234'), 'ill formed';
is   beautify('322 1234'),'322 1234', 'well formed';

TODO: {
	$TODO = 'some ill formed';
	ok !  beautify('1 2313');
}
