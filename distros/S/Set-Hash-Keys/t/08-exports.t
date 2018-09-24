use Test::Most;

use Set::Hash::Keys ':all';

subtest 'Compiles OK' => sub {
    
    union        { foo => 'boat' }, { bar => 'just' };
    intersection { foo => 'boat' }, { bar => 'just' };
    difference   { foo => 'boat' }, { bar => 'just' };
    exclusive    { foo => 'boat' }, { bar => 'just' };
    symmetrical  { foo => 'boat' }, { bar => 'just' };
    
    pass "passed compiling";
    
};

done_testing();
