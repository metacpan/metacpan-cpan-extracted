Spp -- String Prepare Parser

Spp is a powerful tool parse string.

Spp Could use Parse text to AST according its grammar.

You could use Spp parse text with grammar define and get Json.

INSTALLATION

To install this tool, please install Perl5 in your computer.

    > cpan
    > install Spp
    > spp

    This is Spp REPL, type enter to exit.
    >> str = 'abcde'; text = 'abcdefg'
    'abcde'

    > cat rule.spp
    door    = ^ declare Expr+ $;
    declare = (set @type ['int']);
    Expr    = 'type' \s Mytype (push @type $Mytype) \s Type \s*;
    Mytype  = \w+ ;
    Type    = @type;

    > cat text.txt
    type rune int
    type str rune

    > spp rule.spp
    Lint rule.spp ok!

    > spp rule.spp text.txt
    [["Expr",[["Mytype","rune"],["Type","int"]]],
     ["Expr",[["Mytype","str"],["Type","rune"]]]]

DESCRIPTION

## branch

if have more than one rule could match the text, then use branch.

    | branch-one branch-two branch-three |

branch would return first rule which matched.

## longest branch

longest branch would return longest-matching-string.

    || branch-one branch-two branch-three ||

## Token

Token is name defined with Spp specification.

    Token = 'define more rule';

Token could include itself, if its have different border. just like:

    array = '[' |int str array|+ ']'

## Token naming

if name starts with uppercase, then it is Name Token:

    >> Upper = \u+; text = 'ABCDe'
    ['Upper', 'ABCD']

if name starts with lowercase, then it would not naming:

    >> lower = \l+ ; text = 'abcdEF'
    ["abcd"]

if name starts with \_, then match would be reject after match.

    >> _true = 'true' ; text = 'true'
    ['true']

## Not

The <end> of EBNF is defined: if next line starts with blank then is not end.
    
    rule = some-rule end
    end   = \n ! [^\s]

## Char Class

    \a  alpha  a..z A..Z 'a' 'b' 'A'
    \d  digit  0..9
    \h  hspace
    \l  lowercase a..z
    \s  space or enter
    \u  uppercase A..Z
    \v  vspace
    \w  words  [\a_-]
    \x  xdigit 0..9 a..f A..F

## Chars Class

    [\sab]
    [^ab]

## string

    str = :abcd
    str = 'abcd'

## Char

    char = \n \r \f \t \" \' \\ \; ;

## Comment

    // this is comment
    comment = '//' ~ $$ ;

## branch
    >>  rule = |:abc :abcd|; text = :abcd
    ["abc"]

    >> rule = ||:abc :abcd||; text = :abcd
    ["abcd"]

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Spp

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spp

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Spp

    CPAN Ratings
        http://cpanratings.perl.org/d/Spp

    Search CPAN
        http://search.cpan.org/dist/Spp/


LICENSE AND COPYRIGHT

Copyright (C) 2012 Micheal Song

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

