use strict;
use warnings;
use utf8;
use Test::Base::SubTest;

filters {
    input => ['eval', sub { $_[0]->{x} *= 2; $_[0] }],
    expected => ['eval'],
};

run_is_deeply 'input' => 'expected';

done_testing;

__END__

===
--- input
+{
    x => 2,
}
--- expected
+{
    x => 4,
}
