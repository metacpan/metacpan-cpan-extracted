use Test::Most;
use Data::Printer { deparse => 1 };
use String::CamelSnakeKebab qw/:all/;

warning_is {
    lower_camel_case('_____');
    upper_camel_case('__');
    lower_snake_case('___');
    upper_snake_case('____');
    constant_case('_____');
    kebab_case('______');
    http_header_case('________');
} undef, 'No warnings thrown';

done_testing;
