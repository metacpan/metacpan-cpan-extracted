use strict;
use Test::More;
use String::Stomp;
use syntax 'qs';

is stomp("thing"), 'thing', 'Nothing empty';
is stomp("\nthing"), 'thing', 'Empty leading line';
is stomp("\n \nthing"), 'thing', 'Empty leading lines, with space';

is stomp("thing\n"), 'thing', 'Empty trailing line';
is stomp("thing\n \n"), 'thing', 'Empty trailing lines, with space';

is stomp("\n \n\t\n thing \n \nthing \n \t\n"), " thing \n \nthing ", 'Empty lines within, and leading+trailing lines';

my $qs = stomp qs{
        This is
        a multi line

        string.
};

my $plain = q{This is
a multi line

string.};

    (my $heredoc = <<"        END") =~ s{^ {8}}{}gm;
        This is
        a multi line

        string.
        END
$heredoc =~ s{\v\z}{};

is $plain,  $qs, 'qs equals plain';
is $heredoc, $qs, 'qs equals heredoc';

done_testing;
