use strict;
use warnings;
use utf8;

use Test::More;

##########
BEGIN { use_ok('Object::String'); }

##########
can_ok('Object::String', 'str');
is(
    str("toto")->to_upper->string,
    "TOTO",
    "Test a helper to create the object"
);
is(
    str('this', 'is', 'a', 'test')->string,
    'this is a test',
    'Test object buildings with multiple sting'
);

##########
can_ok('Object::String', ('new'));

##########
can_ok('Object::String', ('string'));
is(str('test')->string, 'test', 'test the "string" getter');

can_ok('Object::String', ('to_string'));
is(str('test')->to_string, 'test', 'test the "to_string" getter');

##########
can_ok('Object::String', ('to_lower'));
is(str('TEST')->to_lower->string, 'test', 'lower case "TEST" string');
is(str('test')->to_lower->string, 'test', 'lower case "test" string');

##########
can_ok('Object::String', ('to_upper'));
is(str('test')->to_upper->string, 'TEST', 'upper case "test" string');
is(str('TEST')->to_upper->string, 'TEST', 'upper case "TEST" string');

##########
can_ok('Object::String', ('to_lower_first'));
is(
    str('TEST')->to_lower_first->string, 
    'tEST', 
    'lower case first letter of "TEST" string'
);
is(
    str('test')->to_lower_first->string, 
    'test', 
    'lower case first letter of "test" string'
);

##########
can_ok('Object::String', ('to_upper_first'));
is(
    str('test')->to_upper_first->string, 
    'Test', 
    'upper case first letter of "test"'
);
is(
    str('Test')->to_upper_first->string, 
    'Test', 
    'upper case first letter of "Test"'
);

##########
can_ok('Object::String', ('capitalize'));
is(str('test')->capitalize->string, 'Test', 'capitalize "test" string');
is(str('Test')->capitalize->string, 'Test', 'capitalize "Test" string');
is(str('TEST')->capitalize->string, 'Test', 'capitalize "TEST" string');
is(str('tEST')->capitalize->string, 'Test', 'capitalize "tEST" string');

##########
can_ok('Object::String', ('chomp_left'));
is(str(' test')->chomp_left->string, 'test', 'Chomp left the string " test"');
is(str("\ttest")->chomp_left->string, 'test', 'Chomp left the string " test"');
is(str('test')->chomp_left->string, 'test', 'Chomp left the string "test"');

##########
can_ok('Object::String', ('chomp_right'));
is(str('test ')->chomp_right->string, 'test', 'Chomp right the string "test "');
is(
    str("test\t")->chomp_right->string,
    'test',
    'Chomp right the string "test "'
);
is(
    str('test')->chomp_right->string,
    'test',
    'Chomp right the string "test"'
);

##########
can_ok('Object::String', ('chop_left'));
is(str(' test')->chop_left->string, 'test', 'Chop left the string " test"');
is(str('test')->chop_left->string, 'est', 'Chop left the string "test"');

##########
can_ok('Object::String', ('chop_right'));
is(str('test')->chop_right->string, 'tes', 'chop right the string "test"');
is(str('test ')->chop_right->string, 'test', 'hop right the string "test "');

##########
can_ok('Object::String', ('collapse_whitespace'));
is(
    str("   this \t  is  a \t  test   \t")->collapse_whitespace->string, 
    'this is a test', 
    'capitalize "   this \t  is  a \t  test   \t" string'
);
is(
    str("this is a test")->collapse_whitespace->string, 
    'this is a test', 
    'capitalize "this is a test" string'
);

##########
can_ok('Object::String', ('clean'));
is(
    str("   this \t  is  a \t  test   \t")->clean->string, 
    'this is a test', 
    'capitalize "   this \t  is  a \t  test   \t" string'
);
is(
    str("this is a test")->clean->string, 
    'this is a test', 
    'capitalize "this is a test"'
);

##########
can_ok('Object::String', ('contains'));
ok(
    str("this is a test")->contains("is"),
    'check if a string contains another one'
);
ok(
    str('this is a test')->contains('hello'),
    'check if a string not containing another one'
);

##########
can_ok('Object::String', ('include'));
ok(
    str("this is a test")->include("is"),
    'check if a string contains another one'
);
ok(
    str('this is a test')->include('hello'),
    'check if a string not containing another one'
);

##########
can_ok('Object::String', ('count'));
is(
    str('this is a test')->count('is'),
    2,
    'count the repetitions of "is" in the string'
);

##########
can_ok('Object::String', ('ends_with'));
ok(
    str("this is a test")->ends_with("est"),
    'check if a string ends with another one'
);
ok(
    !str('this is a test')->ends_with('hello'),
    'check if a string not ends with another one'
);

##########
can_ok('Object::String', ('starts_with'));
ok(
    str("this is a test")->starts_with("thi"),
    'check if a string starts with another one'
);
ok(
    !str('this is a test')->starts_with('hello'),
    'check if a string not starts with another one'
);

##########
can_ok('Object::String', ('ensure_left'));
is(str('dir')->ensure_left('/')->string, '/dir', 'ensure left "/dir"');
is(str('/dir')->ensure_left('/')->string, '/dir', 'ensure left "/dir"');

##########
can_ok('Object::String', ('ensure_right'));
is(str('/dir')->ensure_right('/')->string, '/dir/', 'ensure right "/dir/"');
is(str('/dir/')->ensure_right('/')->string, '/dir/', 'ensure right "/dir/"');

##########
can_ok('Object::String', ('is_alpha'));
ok(!str('1234')->is_alpha, 'test a numeric string');
ok(str('abc')->is_alpha, 'test an alpha string');
ok(!str('a1b2c3')->is_alpha, 'test an alpha numeric string');
ok(!str('aui"»)(«')->is_alpha, 'test a non alpha numeric string');

##########
can_ok('Object::String', ('is_numeric'));
ok(str('1234')->is_numeric, 'test a numeric string');
ok(!str('abc')->is_numeric, 'test an alpha string');
ok(!str('a1b2c3')->is_numeric, 'test an alpha numeric string');
ok(!str('aui"»)(«')->is_numeric, 'test a non alpha numeric string');

##########
can_ok('Object::String', ('is_alpha_numeric'));
ok(str('1234')->is_alpha_numeric, 'test a numeric string');
ok(str('abc')->is_alpha_numeric, 'test an alpha string');
ok(str('a1b2c3')->is_alpha_numeric, 'test an alpha numeric string');
ok(!str('aui"»)(«')->is_alpha_numeric, 'test a non alpha numeric string');

##########
can_ok('Object::String', ('is_empty'));
ok(!str('abc')->is_empty, 'test if the string "test" is empty');
ok(str()->is_empty, 'test if undef is empty');
ok(str('')->is_empty, 'test if "" is empty');
ok(str('   ')->is_empty, 'test if "   " is empty');
ok(str("\t\t\t")->is_empty, 'test if "\t\t\t" is empty');
ok(str("\t \t \t ")->is_empty, 'test if "\t \t \t " is empty');

##########
can_ok('Object::String', ('is_lower'));
ok(str('test')->is_lower, 'test if the string "test" is lower case');
ok(!str('TEST')->is_lower, 'test if the string "TEST" is lower case');
ok(!str('tEST')->is_lower, 'test if the string "tEST" is lower case');
ok(str(';test .')->is_lower, 'test if the string ";test ." is lower case');

##########
can_ok('Object::String', ('is_upper'));
ok(!str('test')->is_upper, 'test if the string "test" is upper case');
ok(str('TEST')->is_upper, 'test if the string "TEST" is upper case');
ok(!str('Test')->is_upper, 'test if the string "tEST" is upper case');
ok(str(';TEST .')->is_upper, 'test if the string ";test ." is upper case');

##########
can_ok('Object::String', ('left'));
is(
    str('This is a test')->left(3)->string,
    'Thi',
    'take the 3 first characters from "This is a test"'
);
is(
    str('This is a test')->left(0)->string,
    '',
    'take 0 characters from "This is a test"'
);
is(
    str('This is a test')->left(-2)->string,
    'st',
    'take the 2 last characters from "This is a test"'
);

##########
can_ok('Object::String', ('right'));
is(
    str('This is a test')->right(3)->string,
    'est',
    'take the 3 last characters from "This is a test"'
);
is(
    str('This is a test')->right(0)->string,
    '',
    'take 0 characters from "This is a test"'
);
is(
    str('This is a test')->right(-2)->string,
    'Th',
    'take the 2 first characters from "This is a test"'
);

##########
can_ok('Object::String', ('length'));
cmp_ok(str('test')->length, '==', 4, 'length of "test" string');
cmp_ok(str('')->length, '==', 0, 'length of "" string');

##########
can_ok('Object::String', ('repeat'));
is(
    str('test')->repeat(3)->string, 
    'testtesttest', 
    'repeat the string "test" 3 times'
);

##########
can_ok('Object::String', ('times'));
is(
    str('test')->times(3)->string, 
    'testtesttest', 
    'repeat the string "test" 3 times'
);

##########
can_ok('Object::String', ('strip_punctuation'));
is(
    str('My, st[ring] *full* of %punct)')->strip_punctuation->string,
    'My string full of punct',
    'strip punctuation'
);

##########
can_ok('Object::String', ('to_boolean'));
ok(str('on')->to_boolean, 'test the string "on", returns true');
ok(!str('off')->to_boolean, 'test the string "off", returns false');
ok(str('yes')->to_boolean, 'test the string "yes", returns true');
ok(!str('no')->to_boolean, 'test the string "no", returns false');
ok(str('true')->to_boolean, 'test the string "true", returns true');
ok(!str('false')->to_boolean, 'test the string "false", returns false');
ok(str('ON')->to_boolean, 'test the string "ON", returns true');
ok(!str('OFF')->to_boolean, 'test the string "OFF", returns false');
ok(str('YES')->to_boolean, 'test the string "YES", returns true');
ok(!str(' NO ')->to_boolean, 'test the string "NO", returns undef');
ok(!str(' TRUE ')->to_boolean, 'test the string " TRUE ", returns undef');
ok(!str('FALSE')->to_boolean, 'test the string "FALSE", returns false');
ok(!str('test')->to_boolean, 'test the string "test", returns undef');

##########
can_ok('Object::String', ('to_bool'));
ok(str('on')->to_bool, 'test the string "on", returns true');
ok(!str('off')->to_bool, 'test the string "off", returns false');
ok(str('yes')->to_bool, 'test the string "yes", returns true');
ok(!str('no')->to_bool, 'test the string "no", returns false');
ok(str('true')->to_bool, 'test the string "true", returns true');
ok(!str('false')->to_bool, 'test the string "false", returns false');
ok(str( 'ON')->to_bool, 'test the string "ON", returns true');
ok(!str( 'OFF')->to_bool, 'test the string "OFF", returns false');
ok(str('YES')->to_bool, 'test the string "YES", returns true');
ok(!str(' NO ')->to_bool, 'test the string "NO", returns undef');
ok(!str(' TRUE ')->to_bool, 'test the string "TRUE", returns undef');
ok(!str('FALSE')->to_bool, 'test the string "FALSE", returns false');
ok(!str('test')->to_bool, 'test the string "test", returns undef');

##########
can_ok('Object::String', ('trim_left'));
is(str('test')->trim_left->string, 'test', 'trim from left "test"');
is(str('   test ')->trim_left->string, 'test ', 'trim from left "   test "');
is(str("\ttest\t")->trim_left->string, "test\t", 'trim from left "\ttest\t"');
is(
    str("\t \t test\t \t ")->trim_left->string, 
    "test\t \t ", 
    'trim from left "\t \t test\t \t "'
);
is(
    str("\t a test!\t \t ")->trim_left->string, 
    "a test!\t \t ", 
    'trim from left "\t a test!\t \t "'
);

##########
can_ok('Object::String', ('trim_right'));
is(str('test')->trim_right->string, 'test', 'trim from right "test"');
is(str('  test ')->trim_right->string, '  test', 'trim from right "  test "');
is(str("\ttest\t")->trim_right->string, "\ttest", 'trim from right "\ttest\t"');
is(
    str("\t a test!\t \t ")->trim_right->string, 
    "\t a test!", 
    'trim from right "\t a test!\t \t "'
);

##########
can_ok('Object::String', ('trim'));
is(
    str('test')->trim->string, 
    'test', 
    'trim from left and from right "test" string'
);
is(
    str('   test ')->trim->string, 
    'test',
    'trim from left and from right "   test " string'
);
is(
    str("\ttest\t")->trim->string, 
    "test", 
    'trim from left and from right "\ttest\t" string'
);
is(
    str("\t \t test\t \t ")->trim->string, 
    "test", 
    'trim from left and from right "\t \t test\t \t " string'
);
is(
    str("\t a test!\t \t ")->trim->string,
    "a test!", 
    'trim from left and from right "\t a test!\t \t " string'
);

##########
can_ok('Object::String', ('concat'));
is(str("test")->concat("test")->string, 'testtest', 'concat two strings');
is(
    str('test')->concat('test', 'test')->string,
    'testtesttest',
    'concat three strings'
);

##########
can_ok('Object::String', ('suffix'));
is(str('test')->suffix('hello')->string, 'testhello', 'suffix a string to another one');
is(
    str('test')->suffix('hello', 'world')->string,
    'testhelloworld',
    'suffix two strings to another one'
);

##########
can_ok('Object::String', ('prefix'));
is(str('test')->prefix('hello')->string, 'hellotest', 'prefix a string to another one');
is(
    str('test')->prefix('hello', 'world')->string,
    'helloworldtest',
    'prefix two strings to another one'
);

##########
can_ok('Object::String', ('reverse'));
is(str('test')->reverse->string, 'tset', 'reverse a string');

##########
can_ok('Object::String', ('swapcase'));
is(str('TeSt')->swapcase->string, 'tEsT', 'swapcase a string');

##########
can_ok('Object::String', ('underscore'));
is(
    str('thisIsATest')->underscore->string,
    'this_is_a_test',
    'underscore "thisIsATest"'
);
is(
    str('ThisIsATest')->underscore->string,
    '_this_is_a_test',
    'underscore "ThisIsATest"'
);
is(
    str('This is a Test')->underscore->string,
    '_this_is_a_test',
    'underscore "This is a Test"'
);
is(
    str('this is a test')->underscore->string,
    'this_is_a_test',
    'underscore "this is a test"'
);
is(
    str('this_is_a_test')->underscore->string,
    'this_is_a_test',
    'underscore "this_is_a_test"'
);
is(
    str('This_Is_A_Test')->underscore->string,
    '_this_is_a_test',
    'underscore "This_Is_A_Test"'
);
is(
    str('this-is-a-test')->underscore->string,
    'this_is_a_test',
    'underscore "this-is-a-test"'
);
is(
    str('This-Is-A-Test')->underscore->string,
    '_this_is_a_test',
    'underscoree "This-Is-A-Test"'
);
is(
    str('This::Is::ANewTest')->underscore->string,
    '_this/is/a_new_test',
    'underscore "This::Is::ANewTest"'
);
is(
    str('innerHTML')->underscore->string,
    'inner_html',
    'underscore "innerHTML"'
);

##########
can_ok('Object::String', ('underscored'));
is(
    str('thisIsATest')->underscored->string,
    'this_is_a_test',
    'underscore "thisIsATest"'
);
is(
    str('ThisIsATest')->underscored->string,
    '_this_is_a_test',
    'underscore "ThisIsATest"'
);
is(
    str('This is a Test')->underscored->string,
    '_this_is_a_test',
    'underscore "This is a Test"'
);
is(
    str('this is a test')->underscored->string,
    'this_is_a_test',
    'underscore "this is a test"'
);
is(
    str('this_is_a_test')->underscored->string,
    'this_is_a_test',
    'underscore "this_is_a_test"'
);
is(
    str('This_Is_A_Test')->underscored->string,
    '_this_is_a_test',
    'underscore "This_Is_A_Test"'
);
is(
    str('this-is-a-test')->underscored->string,
    'this_is_a_test',
    'underscore "this-is-a-test"'
);
is(
    str('This-Is-A-Test')->underscored->string,
    '_this_is_a_test',
    'underscoree "This-Is-A-Test"'
);
is(
    str('This::Is::ANewTest')->underscored->string,
    '_this/is/a_new_test',
    'underscore "This::Is::ANewTest"'
);
is(
    str('innerHTML')->underscored->string,
    'inner_html',
    'underscore "innerHTML"'
);

##########
can_ok('Object::String', ('dasherize'));
is(
    str('thisIsATest')->dasherize->string,
    'this-is-a-test',
    'dasherize "thisIsATest"'
);
is(
    str('ThisIsATest')->dasherize->string,
    '-this-is-a-test',
    'dasherize "ThisIsATest"'
);
is(
    str('This is a Test')->dasherize->string,
    '-this-is-a-test',
    'dasherize "This is a Test"'
);
is(
    str('this is a test')->dasherize->string,
    'this-is-a-test',
    'dasherize "this is a test"'
);
is(
    str('this_is_a_test')->dasherize->string,
    'this-is-a-test',
    'dasherize "this-is-a-test"'
);
is(
    str('This_Is_A_Test')->dasherize->string,
    '-this-is-a-test',
    'dasherize "This-Is-A-Test"'
);
is(
    str('this-is-a-test')->dasherize->string,
    'this-is-a-test',
    'dasherize "this-is-a-test"'
);
is(
    str('This-Is-A-Test')->dasherize->string,
    '-this-is-a-test',
    'dasherizee "This-Is-A-Test"'
);
is(
    str('This::Is::ANewTest')->dasherize->string,
    '-this/is/a-new-test',
    'dasherize "This::Is::ANewTest"'
);
is(
    str('innerHTML')->dasherize->string,
    'inner-html',
    'dasherize "innerHTML"'
);

##########
can_ok('Object::String', ('camelize'));
is(
    str('this-is-a-test')->camelize->string,
    'thisIsATest',
    'camelize "this-is-a-test"'
);
is(
    str('this is a test')->camelize->string,
    'thisIsATest',
    'camelize "this is a test"'
);
is(
    str('_this_is_a_test')->camelize->string,
    'ThisIsATest',
    'camelize "_this_is_a_test"'
);
is(
    str('-this-is-a-test')->camelize->string,
    'ThisIsATest',
    'camelize "-this-is-a-test"'
);
is(
    str('_this/is/a_test')->camelize->string,
    'This::Is::ATest',
    'camelize "_this/is/a_test"'
);
is(
    str('this is a test')->camelize->string,
    'thisIsATest',
    'camelize "this is a test"'
);

##########
can_ok('Object::String', ('escape_html'));
is(
    str("<h1>l'été sera beau & chaud</h1>")->escape_html->string,
    "&lt;h1&gt;l&#39;été sera beau &amp; chaud&lt;/h1&gt;",
    "escape HTML from <h1>l'été sera beau & chaud</h1>"
);
is(
    str('<h1>entre "guillemets"</h1>')->escape_html->string,
    '&lt;h1&gt;entre &quot;guillemets&quot;&lt;/h1&gt;',
    'escape HTML from <h1>entre "guillemets"</h1>'
);

##########
can_ok('Object::String', ('unescape_html'));
is(
    str("&lt;h1&gt;l&#39;été sera beau &amp; chaud&lt;/h1&gt;")->unescape_html->string,
    "<h1>l'été sera beau & chaud</h1>",
    "escape HTML from &lt;h1&gt;l&#39;été sera beau &amp; chaud&lt;/h1&gt;"
);
is(
    str('&lt;h1&gt;entre &quot;guillemets&quot;&lt;/h1&gt;')->unescape_html->string,
    '<h1>entre "guillemets"</h1>',
    'escape HTML from &lt;h1&gt;entre &quot;guillemets&quot;&lt;/h1&gt;'
);

##########
can_ok('Object::String', ('index_left'));
is(str('this is a test')->index_left('is'), 2, 'index from left');
is(str('this is a test')->index_left('is',3),5,'index from left from position');

##########
can_ok('Object::String', ('index_right'));
is(str('this is a test')->index_right('is'), 5, 'index from right');
is(
    str('this is a test')->index_right('is', 5),
    5,
    'index from right from position'
);

##########
can_ok('Object::String', ('replace_all'));
is(
    str('this is a test')->replace_all(' ', '_')->string,
    'this_is_a_test',
    'replace all whitespaces'
);
is(
    str('this+is+a+test')->replace_all('+', ' ')->string,
    'this is a test',
    'replace all "+"'
);

##########
can_ok('Object::String', ('humanize'));
is(
    str('this_is_a_test')->humanize->string,
    'This is a test',
    'humanize "this is a test"'
);
is(
    str('-this_is a test')->humanize->string,
    'This is a test',
    'humanize "-this_is a test"'
);
is(
    str('This is a test')->humanize->string,
    'This is a test',
    'humanize "This is a test"'
);

##########
can_ok('Object::String', ('slugify'));
is(
    str('This is a test')->slugify->string,
    'this-is-a-test',
    'slugify "This is a test"'
);
is(
    str('en été, je meurs de chaud')->slugify->string,
    'en-ete-je-meurs-de-chaud',
    'slugify "en été, je meurs de chaud"'
);
is(
    str(' This-Is_a_Test   ')->slugify->string,
    'this-is-a-test',
    'slugify " This-Is_a_Test   "'
);

##########
can_ok('Object::String', ('pad_left'));
is(str('hello')->pad_left(3)->string, 'hello', 'pad left "hello" with 3');
is(str('hello')->pad_left(5)->string, 'hello', 'pad left "hello" with 5');
is(str('hello')->pad_left(9)->string, '    hello', 'pad left "hello" with 9');
is(
    str('hello')->pad_left(10, '.')->string,
    '.....hello',
    'pad left "hello" with 10 and "."'
);

##########
can_ok('Object::String', ('pad_right'));
is(str('hello')->pad_right(3)->string, 'hello', 'pad right "hello" with 3');
is(str('hello')->pad_right(5)->string, 'hello', 'pad right "hello" with 5');
is(
    str('hello')->pad_right(10)->string,
    'hello     ',
    'pad right "hello" with 10'
);
is(
    str('hello')->pad_right(10, '.')->string,
    'hello.....',
    'pad right "hello" with 10 and "."'
);

##########
can_ok('Object::String', ('pad'));
is(str('hello')->pad(3)->string, 'hello', 'pad "hello" with 3');
is(str('hello')->pad(5)->string, 'hello', 'pad "hello" with 5');
is(str('hello')->pad(6)->string, ' hello', 'pad "hello" with 6');
is(str('hello')->pad(10)->string, '   hello  ', 'pad "hello" with 10');
is(str('hello')->pad(10, '.')->string, '...hello..', 'pad "hello" with 10 and "."');

##########
can_ok('Object::String', ('count_words'));
is(str('hello world')->count_words, 2, 'count words in "hello world"');
is(str("hello\tworld")->count_words, 2, 'count words in "hello\tworld"');
is(str("hello \t world, Perl!")->count_words, 3, 'count words in "hello \t world, Perl!"');

##########
can_ok('Object::String', ('quote_meta'));
is(
    str('hello world. (can you hear me?)')->quote_meta->string, 
    'hello\ world\.\ \(can\ you\ hear\ me\?\)', 
    'quote meta characters'
);

##########
can_ok('Object::String', ('rot13'));
is(
    str('this is a test')->rot13->string, 
    'guvf vf n grfg',
    'rot13 on "this is a test"'
);
is(
    str('this is a test')->rot13->rot13->string, 
    'this is a test',
    'rot13 2 times on "this is a test"'
);

##########
can_ok('Object::String', ('next'));
is(str('a')->next->string, 'b', 'next string after "z"');
is(str('z')->next->string, 'aa', 'next string after "z"');

##########
can_ok('Object::String', ('latinise'));
is(str('àéèôöîïçûü')->latinise->string,'aeeooiicuu','remove accents');

##########
can_ok('Object::String', ('say'));
is(str('test')->say, 1, 'say a string');

##########
can_ok('Object::String', ('titleize'));
is(
    str('this is a test')->titleize->string, 
    'This Is A Test', 
    'Titleize "this is a test"'
);
is(
    str('Oh yeah! Test: titleize')->titleize->string,
    'Oh Yeah Test Titleize',
    'titleize "Oh yeah! Test: titleize'
);

##########
can_ok('Object::String', ('titlecase'));
is(
    str('this is a test')->titlecase->string, 
    'This Is A Test', 
    'Titleize "this is a test"'
);
is(
    str('Oh yeah! Test: titleize')->titlecase->string,
    'Oh Yeah Test Titleize',
    'titleize "Oh yeah! Test: titleize'
);

##########
can_ok('Object::String', ('squeeze'));
is(
    str('woooaaaah, balls')->squeeze->string,
    'woah, bals',
    'squeeze "woooaaaah, balls"'
);
is(
    str('woooaaaah, balls')->squeeze('a')->string,
    'woaaaah, bals',
    'squeeze "woooaaaah, balls" except letter "a"'
);
is(
    str('woooaaaah, balls')->squeeze('l-o')->string,
    'woooah, balls',
    'squeeze "woooaaaah, balls" except letter "m-z"'
);

##########
can_ok('Object::String', ('shuffle'));
isnt(
    str('this is a test')->shuffle->string,
    'this is a test',
    'shuffle "this is a test"'
);

##########
can_ok('Object::String', ('transliterate'));
is(
    str('test')->transliterate('a-z', 'A-Z')->string,
    'TEST',
    'transliterate "test" into "TEST"'
);

done_testing;

