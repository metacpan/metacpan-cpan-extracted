#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok 'Socialtext::Resting::Utils';
    use_ok 'Socialtext::EditPage';
}

diag( "Testing Socialtext::Resting::Utils $Socialtext::Resting::Utils::VERSION, Perl $], $^X" );
