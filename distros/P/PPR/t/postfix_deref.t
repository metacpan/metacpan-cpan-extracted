use warnings;
use strict;

use Test::More;

plan tests => 1;

use PPR;

my $src = q{
    {
        my @example = map { $_ => $_ } $aref->@*;
        print join '-' => @example;
    }
};

$src = q{{ $aref->@*; $href->%*; $sref->$*; $rref->$*->$*; $rref->$*->@*; }};

ok $src =~ m{ (?&PerlBlock)  $PPR::GRAMMAR}xms;


done_testing();

