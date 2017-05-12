use Test::More tests => 12;
use lib qw(t/lib);
BEGIN { 
    use_ok('OI18nTest::Greeting');
};

my $obj = OI18nTest::Greeting->new("Hello, world");
is($obj->greeting, "Hello, world", "language unset");
$obj->greeting("Hey");
is($obj->greeting, "Hey", "language unset");

$obj->i18n->language('en');
is($obj->i18n->language, 'en', "language set");
is(eval { $obj->greeting }, undef, "undefined greeting for language=en");
is($@, "", "greeting undefined but no exception");

$obj->greeting("hello");
is($obj->greeting, "hello", "english greeting");
$obj->i18n->language(undef);
is($obj->greeting, "Hey", "original greeting");
OI18nTest::Greeting->i18n->language("fr");
is(eval { $obj->greeting }, undef, "undefined greeting for language=fr");
is($@, "", "greeting undefined but no exception");
$obj->greeting("bonjour");
is($obj->greeting, "bonjour", "french greeting");
$obj->i18n->language('en');
is($obj->greeting, "hello", "english greeting again");



