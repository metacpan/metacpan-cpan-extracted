use strict;
use Test::More;
use String::Nudge;
use syntax 'qi';

is nudge('basic'), '    basic', 'handles one liners, with default nudge';
is nudge(2, 'basic'), '  basic', 'handles custom nudge';
is nudge_wp(), '   basic', 'without parenthesis';
is nudge_fa(), '   basic', 'called with fat arrow';
is nudge(2, qi{    nudge}), '  nudge', 'qi: single line';

{
    local $SIG{__WARN__} = sub {};
    is nudge(-1, 'nudge'), '    nudge', 'nudge default if indent is negative';
    is nudge('a', 'nudge'), '    nudge', 'nudge default if indent is a non-integer';
}

is  nudge(2, qq{   This
          is
        multi line})
    =>
    qq{     This
            is
          multi line}
    =>
    'qq: multi line, text on all lines';

is  nudge(2, qi{    This
          is
        multi line})
    =>
    q{  This
        is
      multi line}
    =>
    'qi: multi line, text on all lines';



is  nudge(qq{
        sub name {
            return 'bob';
        }
    })
    =>
    qq{
            sub name {
                return 'bob';
            }
}
    =>
    'qq: multi line, empty first/last line';


is  nudge(qqi{
        sub name {
            return 'bob';
        }
    })
    =>
    q{
    sub name {
        return 'bob';
    }
}
    =>
    'qi: multi line, empty first/last line';


done_testing;

sub nudge_wp {
    return nudge 3, 'basic';
}
sub nudge_fa {
    return nudge 3 => 'basic';
}
