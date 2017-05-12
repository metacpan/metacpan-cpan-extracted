use strict;
use utf8;
use Test::More;
use Parse::JCONF;

my $parser = Parse::JCONF->new();
my $res = $parser->parse_file('t/files/string.jconf');

is_deeply($res, {
	simple_string    => 'This is a test',
	utf_string       => 'Это тест (αυτή είναι μια δοκιμή)',
	multiline_string =>
'Я узнал, что у меня
Есть огромная семья
И тропинка и лесок
В поле каждый колосок
Речка, небо голубое
Это все мое родное
Это Родина моя,
Всех люблю на свете я!',
	string_with_escapes => 
'I have no idea	(is this works somehow)
So, try it yourself on disc C:\\
(Or just "go away")',
	string_with_utf_escapes => "\0Available payment methods are: \$, ¢, €"
}, "parse strings");

done_testing;
