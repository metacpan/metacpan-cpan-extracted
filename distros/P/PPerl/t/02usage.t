use Test;
BEGIN { plan tests => 1 }
ok(`./pperl` =~ /Usage:/);

