use Test::More tests => 2 + 1;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';

require_ok($module);
use_ok($module, 'exhaustive');

{
    my $str = 'abcde';
    my $re = qr/(?<=.).(.)(?{'^R'})/;
    my $vars = [qw(
        $PREMATCH
        $MATCH
        $POSTMATCH
        $LAST_PAREN_MATCH
        $LAST_REGEXP_CODE_RESULT
        @LAST_MATCH_START
        @LAST_MATCH_END
    )];
    my ($result) = exhaustive($str => qr/$re/, @$vars);
    my @facit = (
        'a',
        'bc',
        'de',
        'c',
        '^R',
        [ 1, 2 ],
        [ 3, 3 ],
    );
    is_deeply($result, \@facit);
}
