use Test::Most;
use OpenERP::OOM::Class::Base;
use FindBin;
use lib "$FindBin::Bin";
use ExceptionMock;

my $t = OpenERP::OOM::Class::Base->new();

my $fail_3 = ExceptionMock->new({ transaction_fails => 3 });
$t->_with_retries($fail_3->run);
ok $fail_3->succeeded, 'Eventually worked';
is $fail_3->calls, 4;

my $fail_12 = ExceptionMock->new({ transaction_fails => 12 });
throws_ok { $t->_with_retries($fail_12->run) } qr/transaction is aborted/, 'Too many failures';
ok ! $fail_12->succeeded, 'Failed to work';
is $fail_12->calls, 10;

my $fail_other = ExceptionMock->new({ transaction_fails => 1, other_fail => 1 });
throws_ok { $t->_with_retries($fail_other->run) } qr/Some other exception/, 'Another exception';
ok ! $fail_other->succeeded, 'Failed to work';
is $fail_other->calls, 2;

$fail_other = ExceptionMock->new({ transaction_fails => 0, other_fail => 1 });
throws_ok { $t->_with_retries($fail_other->run) } qr/Some other exception/, 'Another exception';
ok ! $fail_other->succeeded, 'Failed to work';
is $fail_other->calls, 1;

done_testing;
