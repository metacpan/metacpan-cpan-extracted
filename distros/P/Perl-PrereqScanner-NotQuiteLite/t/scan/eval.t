use strict;
use warnings;
use t::scan::Util;

test(<<'TEST'); # AMW/ConfigReader-0.5/DirectiveStyle.pm
        return eval '"\\' . $1 . '"';
TEST

test(<<'TEST'); # MARKSTOS/Data-FormValidator-4.66/lib/Data/FormValidator/Results.pm
            if (defined *{qualify_to_ref($routine)}{CODE}) {
                local $SIG{__DIE__}  = \&confess;
                $c->{constraint} = eval 'sub { no strict qw/refs/; return defined &{"match_'.$c->{constraint}.'"}(@_)}';
            }
TEST

done_testing;