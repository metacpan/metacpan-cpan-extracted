use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $delimited         = qr{ <delim=(['"`])> <content=(.*?)> <\_delim> }xms;
my $delimited_cap     = qr{ <delim=(['"`])> <content=(.*?)> <rdel=\_delim> }xms;
my $delimited_listcap = qr{ <delim=(['"`])> <content=(.*?)> <[rdel=\_delim]> }xms;

no Regexp::Grammars;

while (my $input = <DATA>) {
    chomp $input;
    my $input_copy = $input;
    my ($input, $expected_outcome) = split /\s*:\s*/, $input;

    if ($expected_outcome eq 'succeed') {
        ok +($input =~ $delimited) => "Match of $input ${expected_outcome}ed";
        is $/{delim},   substr($input,0,1)  => "Captured delimiter";
        is $/{content}, substr($input,1,-1) => "Captured content";

        ok +($input =~ $delimited_cap) => "Match and capture of $input ${expected_outcome}ed";
        is $/{delim},   substr($input,0,1)  => "Captured delimiter";
        is $/{content}, substr($input,1,-1) => "Captured content";
        is $/{rdel},    substr($input,0,1)  => "Captured backreference";

        ok +($input =~ $delimited_listcap) => "Match and list capture of $input ${expected_outcome}ed";
        is $/{delim},        substr($input,0,1)  => "Captured delimiter";
        is $/{content},      substr($input,1,-1) => "Captured content";
        is_deeply $/{rdel}, [substr($input,0,1)] => "Captured backreference";
    }
    else {
        ok +($input !~ $delimited)         => "Match of $input ${expected_outcome}ed";
        ok +($input !~ $delimited_cap)     => "Match and capture of $input ${expected_outcome}ed";
        ok +($input !~ $delimited_listcap) => "Match and list of $input ${expected_outcome}ed";
    }
}


__DATA__
'a'     :succeed
"abc"   :succeed
``      :succeed
'abc"   :fail
`abc'   :fail
