use Test;
BEGIN {plan tests => 5};
ok 1;
require Pod::Perldoc;
ok($Pod::Perldoc::VERSION)
 and print "# Pod::Perldoc version $Pod::Perldoc::VERSION\n";
ok 1;

require Pod::Perldocs;
ok($Pod::Perldocs::VERSION)
 and print "# Pod::Perldocs version $Pod::Perldocs::VERSION\n";
ok 1;
