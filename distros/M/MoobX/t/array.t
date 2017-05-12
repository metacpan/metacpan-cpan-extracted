use Test::More;

use 5.20.0;

use MoobX;

observable my @things;

my $list = observer { 
    join ' ', map @$_, @things 
};

is $list => '', "begins empty";

@things = ( [1],[2],[3]);

is $list => '1 2 3';

push @things, [4];

is $list => '1 2 3 4', 'shallow change';

$things[0][0] = 5;

is $list => '5 2 3 4', 'deep change';

done_testing;
