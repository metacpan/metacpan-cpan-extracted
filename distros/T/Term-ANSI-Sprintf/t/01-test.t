use Test::More;

use Term::ANSI::Sprintf qw/sprintf/;

my $test = sprintf("%black_on_bright_yellow", "Hello World");

my $test2 = sprintf("%italic%black_on_yellow", "Hello World");

my $test3 = sprintf("%underline%red_on_bright_green", "Hello World");

my $test4 = sprintf("%bold%green_on_bright_black", "Hello World");

is($test, "\e[30;103mHello World\e[0m");

is($test2, "\e[3m\e[30;43mHello World\e[0m");

is($test3, "\e[4m\e[31;102mHello World\e[0m");

is($test4, "\e[1m\e[32;100mHello World\e[0m");

ok(1);

done_testing();


