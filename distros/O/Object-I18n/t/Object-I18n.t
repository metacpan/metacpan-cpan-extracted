# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Object-I18n.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package ObjectI18n::Test0;
use Test::More tests => 18;
BEGIN { 
    use_ok('Object::I18n');
};

sub one;
sub two;
sub id { shift->[0] }

#########################
my $i18n = __PACKAGE__->i18n;
isa_ok($i18n, 'Object::I18n');

eval { $i18n->register('one', 'two') };
is($@, "", "register");
eval { $i18n->register('no_such') };
like($@, qr/no such/i, "Will not register non-existant methods");

my @registered = __PACKAGE__->i18n->registered_methods;
ok(eq_array(\@registered, [qw(one two)]), "registered_methods");

ok($i18n == __PACKAGE__->i18n, "class i18n");

my ($o1, $o2);
my ($i18n_1, $i18n_2);
$o1 = bless [1];
$i18n_1 = $o1->i18n;

ok($i18n_1 != $i18n, "instance 1 i18n different from class");
ok($i18n_1 == $o1->i18n, "instance 1 i18n same second time");
{
    my $o2 = bless [2];
    $i18n_2 = $o2->i18n;

    ok($i18n_2 != $i18n_1, "instance 2 i18n different from instance 1");
    ok($i18n_2 == $o2->i18n, "instance 2 i18n same second time");
}

$o2 = bless [2];
ok($i18n_2 != $o2->i18n, "instance 2 i18n different for new object");

__PACKAGE__->i18n->language("fr");
$o2->i18n->language("de");

is($i18n->language, "fr", "Class-wide language");
is($o1->i18n->language, "fr", "instance 1 uses class-wide language");
is($o2->i18n->language, "de", "instance 2 uses localized language");

my $o3 = bless [3];
is($o3->i18n->language, "fr", "new instance 3 uses class-wide language");

__PACKAGE__->i18n->language("en");
is($i18n->language, "en", "Reset class-wide language");
is($o1->i18n->language, "en", "instance 1 uses reset class-wide language");
is($o3->i18n->language, "en", "new instance 3 uses reset class-wide language");
