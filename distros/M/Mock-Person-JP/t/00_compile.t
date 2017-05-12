use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok $_ for qw(
        Mock::Person::JP
        Mock::Person::JP::Person
        Mock::Person::JP::Person::Name
    );
}

done_testing;
