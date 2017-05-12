#!perl
package SubRunTest;
use Test::More;

BEGIN {
    use_ok 'Sub::Mage', 'Loaded Sub::Mage';
}

our $X = 0;

__PACKAGE__->sub_run(['setit']);
sub setit { $X = 5; }
is $X, 5, 'Check we defined X as 5';

done_testing();
