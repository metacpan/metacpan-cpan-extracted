
use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Regexp::SAR') };


{
    my $rootNode = Regexp::SAR::buildRootNode();
    my $reg = 'abc';
    my $matchRes = 0;
    Regexp::SAR::buildPath($rootNode, $reg, length $reg, sub { ++$matchRes; });
    my $matchStr = 'qabcdqqabcq';
    Regexp::SAR::lookPathAtPos($rootNode, $matchStr, 0 );
    is($matchRes, 0);
    $matchRes = 0;
    Regexp::SAR::lookPathAtPos($rootNode, $matchStr, 1 );
    is($matchRes, 1);
    $matchRes = 0;
    Regexp::SAR::lookPathAtPos($rootNode, $matchStr, 2 );
    is($matchRes, 0);
    $matchRes = 0;
    Regexp::SAR::lookPathAtPos($rootNode, $matchStr, 7 );
    is($matchRes, 1);
    $matchRes = 0;
    Regexp::SAR::lookPathAtPos($rootNode, $matchStr, 6 );
    is($matchRes, 0);
}


{
    my $rootNode = Regexp::SAR::buildRootNode();
    my $reg = 'abc';
    my ($matchStart, $matchLen);
    Regexp::SAR::buildPath($rootNode, $reg, length $reg, sub { ($matchStart, $matchLen) = @_; });
    my $matchStr = 'qabcdq';
    Regexp::SAR::lookPath($rootNode, $matchStr, 0);
    is($matchStart, 1);
    is($matchLen, 4);
}


##############################################
done_testing();
