use Perl6::Rules;
use Test::Simple 'no_plan';

sub list { "A", "ZBC" }

$_ = q{Now I know my abc's};

s:globally/Now/Wow/;
ok($_ eq q{Wow I know my abc's}, 'Constant substitution');

s:globally/abc/$(list)/;
ok($_ eq q{Wow I know my ZBC's}, 'Scalar substitution');

s:g/BC/@(list)/;
ok($_ eq q{Wow I know my ZA ZBC's}, 'List substitution');
