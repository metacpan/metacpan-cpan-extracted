#!/usr/bin/env perl
# Test printp rewrite

use warnings;
use strict;

use Test::More tests => 102;

use String::Print;

sub rewrite($$$)
{   my ($pargs, $i, $iargs) = @_;
    my $p = $pargs->[0];
    my ($goti, $gota) = String::Print::_printp_rewrite($pargs);
#use Data::Dumper;
#warn Dumper $goti, $gota;

    ok(defined $goti, "rewrite $p");
    is($goti, $i, "into $i");
    cmp_ok(scalar @$iargs, '==', scalar @$gota, 'check returned arg length');
    foreach(my $i=0; $i<@$iargs; $i++)
    {   cmp_ok($iargs->[$i], 'eq', $gota->[$i], "param $i = $iargs->[$i]");
    }
}

rewrite(['aap'], 'aap', []);
rewrite(['a%db', '42'], 'a{_1%d}b', [_1 => 42] );
rewrite(['a%sb', '43'], 'a{_1}b', [_1 => 43] );
rewrite(['a%5sb', '44'], 'a{_1%5s}b', [_1 => 44] );
rewrite(['a%.3sb', '45'], 'a{_1%.3s}b', [_1 => 45] );
rewrite(['a%2.3sb', '46'], 'a{_1%2.3s}b', [_1 => 46] );
rewrite(['a%2.3{T}sb', '47'], 'a{_1 T%2.3s}b', [_1 => 47] );
rewrite(['a%-2sb', '48'], 'a{_1%-2s}b', [_1 => 48] );
rewrite(['a%-.3sb', '49'], 'a{_1%-.3s}b', [_1 => 49] );
rewrite(['a%sb c%sd', '50', 51], 'a{_1}b c{_2}d', [_1 => 50, _2 => 51] );

rewrite(['a%*db c%*sd', 3, 4, 5, 6, x => 5]
       , 'a{_2%3d}b c{_4%5s}d'
       , [_2 => 4, _4 => 6, x => 5] );

rewrite(['a%2.*db c%.*sd', 3, 4, 5, 6, y => 6]
       , 'a{_2%2.3d}b c{_4%.5s}d'
       , [_2 => 4, _4 => 6, y => 6] );

rewrite(['a%*.*sb', 11, 12, 13, r => 42], 'a{_3%11.12s}b', [_3 => 13, r => 42]);

rewrite(['a%1$sb c%2$dd', 14, 15, z => 13], 'a{_1}b c{_2%d}d'
       , [_1 => 14, _2 => 15, z => 13] );

rewrite(['a%2$-1.6sb c%1$dd', 16, 17, z => 18], 'a{_2%-1.6s}b c{_1%d}d'
       , [_2 => 17, _1 => 16, z => 18] );

rewrite(['a%2$*.*sb c%1$dd', 1, 2, 4, 5, r => 19], 'a{_4%2.4s}b c{_1%d}d'
       , [_4 => 5, _1 => 1, r => 19 ] );
