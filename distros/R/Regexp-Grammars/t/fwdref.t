use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $delimited         = qr{ <delim=([(/][*]|if|[][(){}<>«»'"`]+)> <content=(.*?)> </delim> }xms;
my $delimited_cap     = qr{ <delim=([(/][*]|if|[][(){}<>«»'"`]+)> <content=(.*?)> <rdel=/delim> }xms;
my $delimited_listcap = qr{ <delim=([(/][*]|if|[][(){}<>«»'"`]+)> <content=(.*?)> <[rdel=/delim]> }xms;

no Regexp::Grammars;

while (my $spec = <DATA>) {
    next if $spec !~ /\S/;
    chomp $spec;
    my $spec_copy = $spec;
    my ($input, $expected_outcome) = split /\s*:\s*/, $spec;
    my ($ldelim, $content, $rdelim) = split /(xxx)/, $input;

    if ($expected_outcome eq 'succeed') {
        ok +($input =~ $delimited) => "Match of $input ${expected_outcome}ed";
        is $/{delim},   $ldelim  => "Captured delimiter";
        is $/{content}, $content => "Captured content";

        ok +($input =~ $delimited_cap) => "Match and capture of $input ${expected_outcome}ed";
        is $/{delim},   $ldelim  => "Captured delimiter";
        is $/{content}, $content => "Captured content";
        is $/{rdel},    $rdelim  => "Captured closer";

        ok +($input =~ $delimited_listcap) => "Match and list capture of $input ${expected_outcome}ed";
        is $/{delim},   $ldelim        => "Captured delimiter";
        is $/{content}, $content       => "Captured content";
        is_deeply $/{rdel}, [$rdelim]  => "Captured closer";
    }
    else {
        ok +($input !~ $delimited)         => "Match of $input ${expected_outcome}ed";
        ok +($input !~ $delimited_cap)     => "Match and capture of $input ${expected_outcome}ed";
        ok +($input !~ $delimited_listcap) => "Match and list of $input ${expected_outcome}ed";
    }
}


__DATA__
"xxx"         :succeed
`xxx'         :succeed
``xxx''       :succeed

'xxx"         :fail

{xxx}         :succeed
[xxx]         :succeed
<xxx>         :succeed
(xxx)         :succeed
«xxx»         :succeed

[[xxx]]       :succeed
{{{xxx}}}     :succeed
((((xxx))))   :succeed
<<xxx>>       :succeed
««xxx»»       :succeed

}xxx{         :succeed
]xxx[         :succeed
)xxx(         :succeed
>xxx<         :succeed
»xxx«         :succeed

}}}xxx{{{     :succeed
]]xxx[[       :succeed
))))xxx((((   :succeed
>>xxx<<       :succeed
»»xxx««       :succeed

({xxx})       :succeed
(*xxx*)       :succeed
/*xxx*/       :succeed
ifxxxfi       :succeed

``            :fail
'abc"         :fail

{xxx{         :fail
[xxx[         :fail
<xxx<         :fail
(xxx(         :fail
«xxx«         :fail

[[xxx[[       :fail
{{{xxx{{{     :fail
((((xxx((((   :fail
<<xxx<<       :fail
««xxx««       :fail
