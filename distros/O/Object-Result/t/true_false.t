use 5.014;
use Test::More;
use Object::Result;

sub get_truth {
    result {
        value { 'truth' }
    };
}

sub get_falsity {
    result {
        <FAIL>
        value { 'falsity' }
    };
}

my $truth = get_truth();
ok $truth                   => 'default is true';
is $truth->value, 'truth'   => 'Method works';

my $falsity = get_falsity();
ok !$falsity                  => '<FAIL> is false';
is $falsity->value, 'falsity' => 'Method works';

done_testing();


