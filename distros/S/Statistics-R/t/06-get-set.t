#! perl

use strict;
use warnings;
use Test::More;
use Statistics::R;

my ($R, $input, $output);


ok $R = Statistics::R->new();


$input = undef;
ok $R->set('x', $input), 'undef';
is $R->get('x'), undef;


$input = 123;
ok $R->set('x', $input);
ok $output = $R->get('x'), 'integer';
is ref($output), '';
is $output, 123;


# R default number of digits is 7
$input = 0.93945768644;
ok $R->set('x', $input), 'real number';
ok $output = $R->get('x');
is ref($output), '';
is $output, sprintf("%.7f", $input);


$input = "apocalypse";
ok $R->set('x', $input), 'string';
ok $output = $R->get('x');
is ref($output), '';
is $output, "apocalypse";


$input = "a string";
ok $R->set('x', $input), 'string with witespace';
ok $output = $R->get('x');
is ref($output), '';
is $output, "a string";


$input = 'gi|57116681|ref|NC_000962.2|';
ok $R->set('x', $input), 'number-containing string';
ok $output = $R->get('x');
is ref($output), '';
is $output, 'gi|57116681|ref|NC_000962.2|';


# Mixed arrays are considered as string arrays by R, thus there is no digit limit
$input = [123, "a string", 'two strings', 0.93945768644];
ok $R->set('x', $input), 'mixed array';
ok $output = $R->get('x');
is ref($output), 'ARRAY';
is $$output[0], 123;
is $$output[1], "a string";
is $$output[2], "two strings";
is $$output[3], 0.93945768644;


# RT bug #71988
$input = [ q{statistics-r-0.22}, "abc 123 xyz", 'gi|57116681|ref|NC_000962.2|'];
ok $R->set('x', $input), 'array of number-containing strings';
ok $output = $R->get('x');
is ref($output), 'ARRAY';
is $$output[0], q{statistics-r-0.22};
is $$output[1], "abc 123 xyz";
is $$output[2], 'gi|57116681|ref|NC_000962.2|';


$input = [123,142,147,153,145,151,165,129,133,150,142,154,131,146,151,136,147,156,141,155,147,165,168,146,148,146,142,145,161,157,154,137,130,161,130,156,140,145,154];
ok $R->set('x', $input), 'large array of integers';
ok $output = $R->get('x');
is ref($output), 'ARRAY';
for (my $i = 0; $i < scalar @$input; $i++) {
    is $$output[$i], $$input[$i];
}


$input = [1, 2, 3];
ok $R->set('x', $input), 'data frame';
is $R->run(q`a <- data.frame(first=x)`), '';
ok $output = $R->get('a$first');
is ref($output), 'ARRAY';
is $$output[0], 1;
is $$output[1], 2;
is $$output[2], 3;


# Bug reported by Manuel A. Alonso Tarajano
is $R->run(q`mydat = seq(1:4)`), '';
ok $output = $R->get('mydat');
is $$output[0], 1;
is $$output[1], 2;
is $$output[2], 3;
is $$output[3], 4;


# Strings containing quotes and escaped quotes
$input = q{He said: "Let's go \"home\" now!\n"};
ok $R->set('x', $input), 'string';
ok $output = $R->get('x');
is ref($output), '';
is $output, q{He said: "Let's go \"home\" now!\n"};


$input = q{He said: "Let's go \\\\\\\\\\\\\"home\\\\\\\\\\\\\" now!\n"};
# because \ is a special char that needs to be escaped, this string really is:
#          He said: "Let's go \\\\\\\"home\\\\\\\" now!\n
ok $R->set('x', $input), 'string';
ok $output = $R->get('x');
is ref($output), '';
is $output, q{He said: "Let's go \\\\\\\\\\\\\"home\\\\\\\\\\\\\" now!\n"};


ok $R->stop();

done_testing;
