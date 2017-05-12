package QBit::TestClass;

use qbit;

use base qw(QBit::Class);

__PACKAGE__->mk_accessors(qw(rw_accessor1 rw_accessor2));
__PACKAGE__->mk_ro_accessors(qw(ro_accessor1 ro_accessor2));
__PACKAGE__->abstract_methods(qw(abstract_method1 abstract_method2));

package main;

use qbit;

use Test::More;

my $obj = new_ok('QBit::TestClass' => [f1 => 10, ro_accessor1 => TRUE]);

ok(blessed($obj), 'Checking blessing');

is($obj->{'f1'}, 10, 'Checking data from constructor');

$obj->rw_accessor1(100);
is($obj->rw_accessor1, 100, 'Checking r/w accessor');

$obj->{'ro_accessor1'} = 200;
$obj->ro_accessor1(200);
is($obj->ro_accessor1, 200, 'Checking ro accessor');

my $error = '';
try {
    $obj->abstract_method1();
}
catch {
    $error = shift->message();
};
is($error, 'Abstract method: abstract_method1');

done_testing();
