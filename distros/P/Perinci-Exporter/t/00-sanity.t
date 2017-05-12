#!perl

# test that the basic 'use Perinci::Exporter' works

use 5.010;
use strict;
use warnings;
use lib "t/lib";

use Test::More 0.96;

{
    package Importer1;
    use TestExporter;
    main::is_deeply(bar, [200, "OK", "bar"], "bar"); # works without ()
}

{
    package Importer2;
    use TestExporter foo => {result_naked=>0};
    main::is_deeply(foo(), [200, "OK", "foo"], "foo");
}

{
    package Importer3;
    use TestExporter qw(baz);
    main::is_deeply(baz(), [200, "OK", "baz"], "baz");
}

done_testing();

