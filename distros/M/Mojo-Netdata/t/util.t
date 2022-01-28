use Test2::V0;
use Mojo::Netdata::Util qw(safe_id);

subtest safe_id => sub {
  is safe_id('aBC'),        'aBC',        'aBC';
  is safe_id('abc.-%{}_X'), 'abc______X', 'abc______X';
};

done_testing;
