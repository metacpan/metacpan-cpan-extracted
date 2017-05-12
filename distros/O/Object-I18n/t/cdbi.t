use Test::More;
use lib qw(t/lib);
BEGIN { 
    if (eval "use Class::DBI; 1") {
        plan tests => 21;
    } else {
        plan skip_all => 'Class::DBI could not be found';
    }
    use_ok('OI18nTest::Greeting::CDBI');
};

my $obj = OI18nTest::Greeting::CDBI->new("Hello, world");
is($obj->greeting, "Hello, world", "language unset");
$obj->greeting("Hey");
is($obj->greeting, "Hey", "language unset");

$obj->i18n->language('en');
is($obj->i18n->language, 'en', "language set");
is(eval { $obj->greeting }, undef, "undefined greeting for language=en");
is($@, "", "greeting undefined but no exception");

my @translations;
@translations = OI18nTest::CDBI->retrieve_all;
is(@translations, 0, "no translations stored yet");

$obj->greeting("hello");
@translations = OI18nTest::CDBI->retrieve_all;
is(@translations, 1, "one translation stored now (en)");
is(eval{OI18nTest::CDBI->retrieve(1)->data}, "hello", "stored data (en)");
is($obj->greeting, "hello", "english greeting");

$obj->i18n->language(undef);
is($obj->greeting, "Hey", "original greeting");

OI18nTest::Greeting::CDBI->i18n->language("fr");
is(eval { $obj->greeting }, undef, "undefined greeting for language=fr");
is($@, "", "greeting undefined but no exception");

@translations = OI18nTest::CDBI->retrieve_all;
is(@translations, 1, "one translation still (en)");
$obj->greeting("bonjour");
@translations = OI18nTest::CDBI->retrieve_all;
is(@translations, 2, "two translations now (en,fr)");
is(eval{OI18nTest::CDBI->retrieve(2)->data}, "bonjour", "stored data (fr)");
is($obj->greeting, "bonjour", "french greeting");

$obj->i18n->language('en');
is($obj->greeting, "hello", "english greeting again");

@translations = OI18nTest::CDBI->retrieve_all;
is(@translations, 2, "two translations still (en,fr)");

$obj->greeting("howdy");

is(eval{OI18nTest::CDBI->retrieve(1)->data}, "howdy", "overwritten data (en)");
is(eval{OI18nTest::CDBI->retrieve(2)->data}, "bonjour", "stored data (fr)");

