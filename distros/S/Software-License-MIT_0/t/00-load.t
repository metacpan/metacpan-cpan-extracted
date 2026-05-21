#!perl

use v5.12.0;

use strict;
use warnings;

use Test2::V1;

use ok 'Software::License::MIT_0';

foreach my $mod ( qw< Software::License::MIT_0 > ) {
    my $mod_ver = '$' . $mod . '::VERSION';

    T2->diag(
        sprintf "Testing $mod %s, Perl %s, %s",
        $mod_ver, $], $^X,
    );
}

T2->done_testing;
