SYNOPSIS
========

        use Regexp::Common qw( Apache2 );
        use Regexp::Common::Apache2 qw( $ap_true $ap_false );

        while( <> )
        {
            my $pos = pos( $_ );
            /\G$RE{Apache2}{Word}/gmc      and  print "Found a word expression at pos $pos\n";
            /\G$RE{Apache2}{Variable}/gmc  and  print "Found a variable $+{varname} at pos $pos\n";
        }

        # Override Apache2 expressions by the legacy ones
        $RE{Apache2}{-legacy => 1}
        # or use it with the Legacy prefix:
        if( $str =~ /^$RE{Apache2}{LegacyVariable}$/ )
        {
            print( "Found variable $+{variable} with name $+{varname}\n" );
        }

VERSION
=======

        v0.1.0

DESCRIPTION
===========

This is the perl port of [Apache2
expressions](https://httpd.apache.org/docs/trunk/en/expr.html){.perl-module}

The regular expressions have been designed based on Apache2 Backus-Naur
Form (BNF) definition as described below in [\"APACHE2
EXPRESSION\"](#apache2-expression){.perl-module}

You can also use the extended pattern by calling
[Regexp::Common::Apache2](https://metacpan.org/pod/Regexp::Common::Apache2){.perl-module}
like:

        $RE{Apache2}{-legacy => 1}

All of the regular expressions use named capture. See [\"%+\" in
perlvar](https://metacpan.org/pod/perlvar#%+){.perl-module} for more
information on named capture.

APACHE2 EXPRESSION
==================

comp
----

BNF:

        stringcomp
        | integercomp
        | unaryop word
        | word binaryop word
        | word "in" listfunc
        | word "=~" regex
        | word "!~" regex
        | word "in" "{" list "}"

        $RE{Apache2}{Comp}

For example:

        "Jack" != "John"
        123 -ne 456
        # etc

This uses other expressions namely
[\"stringcomp\"](#stringcomp){.perl-module},
[\"integercomp\"](#integercomp){.perl-module},
[\"word\"](#word){.perl-module},
[\"listfunc\"](#listfunc){.perl-module},
[\"regex\"](#regex){.perl-module}, [\"list\"](#list){.perl-module}

The capture names are:

*comp*

:   Contains the entire capture block

*comp\_binary*

:   Matches the expression that uses a binary operator, such as:

            ==, =, !=, <, <=, >, >=, -ipmatch, -strmatch, -strcmatch, -fnmatch

*comp\_binaryop*

:   The binary op used if the expression is a binary comparison. Binary
    operator is:

            ==, =, !=, <, <=, >, >=, -ipmatch, -strmatch, -strcmatch, -fnmatch

*comp\_integercomp*

:   When the comparison is for an integer comparison as opposed to a
    string comparison.

*comp\_list*

:   Contains the list used to check a word against, such as:

            "Jack" in {"John", "Peter", "Jack"}

*comp\_listfunc*

:   This contains the *listfunc* when the expressions contains a word
    checked against a list function, such as:

            "Jack" in listMe("some arguments")

*comp\_regexp*

:   The regular expression used when a word is compared to a regular
    expression, such as:

            "Jack" =~ /\w+/

    Here, *comp\_regexp* would contain `/\w+/`

*comp\_regexp\_op*

:   The regular expression operator used when a word is compared to a
    regular expression, such as:

            "Jack" =~ /\w+/

    Here, *comp\_regexp\_op* would contain `=~`

*comp\_stringcomp*

:   When the comparison is for a string comparison as opposed to an
    integer comparison.

*comp\_unary*

:   Matches the expression that uses unary operator, such as:

            -d, -e, -f, -s, -L, -h, -F, -U, -A, -n, -z, -T, -R

*comp\_word*

:   Contains the word that is the object of the comparison.

*comp\_word\_in\_list*

:   Contains the expression of a word checked against a list, such as:

            "Jack" in {"John", "Peter", "Jack"}

*comp\_word\_in\_listfunc*

:   Contains the word when it is being compared to a
    [listfunc](https://metacpan.org/pod/listfunc){.perl-module}, such
    as:

            "Jack" in listMe("some arguments")

*comp\_word\_in\_regexp*

:   Contains the expression of a word checked against a regular
    expression, such as:

            "Jack" =~ /\w+/

    Here the word `Jack` (without the parenthesis) would be captured in
    *comp\_word*

*comp\_worda*

:   Contains the first word in comparison expression

*comp\_wordb*

:   Contains the second word in comparison expression

cond
----

BNF:

        "true"
        | "false"
        | "!" cond
        | cond "&&" cond
        | cond "||" cond
        | comp
        | "(" cond ")"

        $RE{Apache2}{Cond}

For example:

        use Regexp::Common::Apache qw( $ap_true $ap_false );
        ($ap_false && $ap_true)

The capture names are:

*cond*

:   Contains the entire capture block

*cond\_and*

:   Contains the expression like:

            ($ap_true && $ap_true)

*cond\_false*

:   Contains the false expression like:

            ($ap_false)

*cond\_neg*

:   Contains the expression if it is preceded by an exclamation mark,
    such as:

            !$ap_true

*cond\_or*

:   Contains the expression like:

            ($ap_true || $ap_true)

*cond\_true*

:   Contains the true expression like:

            ($ap_true)

expr
----

BNF: cond \| string

        $RE{Apache2}{Expr}

The capture names are:

*expr*

:   Contains the entire capture block

*expr\_cond*

:   Contains the expression of the condition

*expr\_string*

:   Contains the expression of a string

function
--------

BNF: funcname \"(\" words \")\"

        $RE{Apache2}{Function}

For example:

        base64("Some string")

The capture names are:

*function*

:   Contains the entire capture block

*function\_args*

:   Contains the list of arguments. In the example above, this would be
    `Some string`

*function\_name*

:   The name of the function . In the example above, this would be
    `base64`

integercomp
-----------

BNF:

        word "-eq" word | word "eq" word
        | word "-ne" word | word "ne" word
        | word "-lt" word | word "lt" word
        | word "-le" word | word "le" word
        | word "-gt" word | word "gt" word
        | word "-ge" word | word "ge" word

        $RE{Apache2}{IntegerComp}

For example:

        123 -ne 456
        789 gt 234
        # etc

The hyphen before the operator is optional, so you can say `eq` instead
of `-eq`

The capture names are:

*stringcomp*

:   Contains the entire capture block

*integercomp\_op*

:   Contains the comparison operator

*integercomp\_worda*

:   Contains the first word in the string comparison

*integercomp\_wordb*

:   Contains the second word in the string comparison

join
----

BNF:

        "join" ["("] list [")"]
        | "join" ["("] list "," word [")"]

        $RE{Apache2}{Join}

For example:

        join({"word1" "word2"})
        # or
        join({"word1" "word2"}, ', ')

This uses [\"list\"](#list){.perl-module} and
[\"word\"](#word){.perl-module}

The capture names are:

*join*

:   Contains the entire capture block

*join\_list*

:   Contains the value of the list

*join\_word*

:   Contains the value for word used to join the list

list
----

BNF:

        split
        | listfunc
        | "{" words "}"
        | "(" list ")

        $RE{Apache2}{List}

For example:

        split( /\w+/, "Some string" )
        # or
        {"some", "words"}
        # or
        (split( /\w+/, "Some string" ))
        # or
        ( {"some", "words"} )

This uses [\"split\"](#split){.perl-module},
[\"listfunc\"](#listfunc){.perl-module},
[words](https://metacpan.org/pod/words){.perl-module} and
[\"list\"](#list){.perl-module}

The capture names are:

*list*

:   Contains the entire capture block

*list\_func*

:   Contains the value if a [\"listfunc\"](#listfunc){.perl-module} is
    used

*list\_list*

:   Contains the value if this is a list embedded within parenthesis

*list\_split*

:   Contains the value if the list is based on a
    [split](https://metacpan.org/pod/split){.perl-module}

*list\_words*

:   Contains the value for a list of words.

listfunc
--------

BNF: listfuncname \"(\" words \")\"

        $RE{Apache2}{Function}

For example:

        base64("Some string")

This is quite similar to the [\"function\"](#function){.perl-module}
regular expression

The capture names are:

*listfunc*

:   Contains the entire capture block

*listfunc\_args*

:   Contains the list of arguments. In the example above, this would be
    `Some string`

*listfunc\_name*

:   The name of the function . In the example above, this would be
    `base64`

regany
------

BNF: regex \| regsub

        $RE{Apache2}{Regany}

For example:

        /\w+/i
        # or
        m,\w+,i

This regular expression includes [\"regany\"](#regany){.perl-module} and
[\"regsub\"](#regsub){.perl-module}

The capture names are:

*regany*

:   Contains the entire capture block

*regany\_regex*

:   Contains the regular expression. See
    [\"regex\"](#regex){.perl-module}

*regany\_regsub*

:   Contains the substitution regular expression. See
    [\"regsub\"](#regsub){.perl-module}

regex
-----

BNF:

        "/" regpattern "/" [regflags]
        | "m" regsep regpattern regsep [regflags]

        $RE{Apache2}{Regex}

For example:

        /\w+/i
        # or
        m,\w+,i

The capture names are:

*regex*

:   Contains the entire capture block

*regflags*

:   The regula expression modifiers. See
    [perlre](https://metacpan.org/pod/perlre){.perl-module}

    This can be any combination of:

            i, s, m, g

*regpattern*

:   Contains the regular expression. See
    [perlre](https://metacpan.org/pod/perlre){.perl-module} for example
    and explanation of how to use regular expression. Apache2 uses PCRE,
    i.e. perl compliant regular expressions.

*regsep*

:   Contains the regular expression separator, which can be any of:

            /, #, $, %, ^, |, ?, !, ', ", ",", ;, :, ".", _, -

regsub
------

BNF: \"s\" regsep regpattern regsep string regsep \[regflags\]

        $RE{Apache2}{Regsub}

For example:

        s/\w+/John/gi

The capture names are:

*regflags*

:   The modifiers used which can be any combination of:

            i, s, m, g

    See [perlre](https://metacpan.org/pod/perlre){.perl-module} for an
    explanation of their usage and meaning

*regstring*

:   The string replacing the text found by the regular expression

*regsub*

:   Contains the entire capture block

*regpattern*

:   Contains the regular expression which is perl compliant since
    Apache2 uses PCRE.

*regsep*

:   Contains the regular expression separator, which can be any of:

            /, #, $, %, ^, |, ?, !, ', ", ",", ;, :, ".", _, -

split
-----

BNF:

        "split" ["("] regany "," list [")"]
        | "split" ["("] regany "," word [")"]

        $RE{Apache2}{Split}

For example:

        split( /\w+/, "Some string" )

This uses [\"regany\"](#regany){.perl-module},
[\"list\"](#list){.perl-module} and [\"word\"](#word){.perl-module}

The capture names are:

*split*

:   Contains the entire capture block

*split\_regex*

:   Contains the regular expression used for the split

*split\_list*

:   The list being split. It can also be a word. See below

*split\_word*

:   The word being split. It can also be a list. See above

string
------

BNF: substring \| string substring

        $RE{Apache2}{String}

For example:

        URI accessed is: %{REQUEST_URI}

The capture names are:

*string*

:   Contains the entire capture block

stringcomp
----------

BNF:

        word "==" word
        | word "!=" word
        | word "<"  word
        | word "<=" word
        | word ">"  word
        | word ">=" word

        $RE{Apache2}{StringComp}

For example:

        "John" == "Jack"
        sub(s/\w+/Jack/i, "John") != "Jack"
        # etc

The capture names are:

*stringcomp*

:   Contains the entire capture block

*stringcomp\_op*

:   Contains the comparison operator

*stringcomp\_worda*

:   Contains the first word in the string comparison

*stringcomp\_wordb*

:   Contains the second word in the string comparison

sub
---

BNF: \"sub\" \[\"(\"\] regsub \",\" word \[\")\"\]

        $RE{Apache2}{Sub}

For example:

        sub(s/\w/John/gi,"Peter")

The capture names are:

*sub*

:   Contains the entire capture block

*sub\_regsub*

:   Contains the substitution expression, i.e. in the example above,
    this would be:

            s/\w/John/gi

*sub\_word*

:   The target for the substitution. In the example above, this would be
    \"Peter\"

substring
---------

BNF: cstring \| variable

        $RE{Apache2}{Substring}

For example:

        Jack
        # or
        %{REQUEST_URI}
        # or
        %{:sub(s/\b\w+\b/Peter/, "John"):}

See [\"variable\"](#variable){.perl-module} and
[\"word\"](#word){.perl-module} regular expression for more on those.

The capture names are:

*substring*

:   Contains the entire capture block

variable
--------

BNF:

        "%{" varname "}"
        | "%{" funcname ":" funcargs "}"
        | "%{:" word ":}"
        | "%{:" cond ":}"
        | rebackref

        $RE{Apache2}{Variable}
        # or
        $RE{Apache2}{LegacyVariable}

For example:

        %{REQUEST_URI}
        # or
        %{md5:"some string"}
        # or
        %{:sub(s/\b\w+\b/Peter/, "John"):}
        # or a reference to previous regular expression capture groups
        $1, $2, etc..

See [\"word\"](#word){.perl-module} and [\"cond\"](#cond){.perl-module}
regular expression for more on those.

The capture names are:

*variable*

:   Contains the entire capture block

*var\_cond*

:   If this is a condition inside a variable, such as:

            %{:$ap_true == $ap_false}

*var\_func\_args*

:   Contains the function arguments.

*var\_func\_name*

:   Contains the function name.

*var\_word*

:   A variable containing a word. See [\"word\"](#word){.perl-module}
    for more information about word expressions.

*varname*

:   Contains the variable name without the percent sign or dollar sign
    (if legacy regular expression is enabled) or the possible
    surrounding accolades

word
----

BNF:

        digits
        | "'" string "'"
        | '"' string '"'
        | word "." word
        | variable
        | sub
        | join
        | function
        | "(" word ")"

        $RE{Apache2}{Word}

This is the most complex regular expression used, since it uses all the
others and can recurse deeply

For example:

        12
        # or
        "John"
        # or
        'Jack'
        # or
        %{REQUEST_URI}
        # or
        %{HTTP_HOST}.%{HTTP_PORT}
        # or
        %{:sub(s/\b\w+\b/Peter/, "John"):}
        # or
        sub(s,\w+,Paul,gi, "John")
        # or
        join({"Paul", "Peter"}, ', ')
        # or
        md5("some string")
        # or any word surrounded by parenthesis, such as:
        ("John")

See [\"string\"](#string){.perl-module},
[\"word\"](#word){.perl-module},
[\"variable\"](#variable){.perl-module}, [\"sub\"](#sub){.perl-module},
[\"join\"](#join){.perl-module}, [\"function\"](#function){.perl-module}
regular expression for more on those.

The capture names are:

*word*

:   Contains the entire capture block

*word\_digits*

:   If the word is actually digits, thise contains those digits.

*word\_dot\_word*

:   This contains the text when two words are separated by a dot.

*word\_enclosed*

:   Contains the value of the word enclosed by single or double quotes
    or by surrounding parenthesis.

*word\_function*

:   Contains the word containing a
    [\"function\"](#function){.perl-module}

*word\_join*

:   Contains the word containing a [\"join\"](#join){.perl-module}

*word\_quote*

:   If the word is enclosed by single or double quote, this contains the
    single or double quote character

*word\_sub*

:   If the word is a substitution, this contains tha substitution

*word\_variable*

:   Contains the word containing a
    [\"variable\"](#variable){.perl-module}

words
-----

BNF:

        word
        | word "," list

        $RE{Apache2}{Words}

For example:

        "Jack"
        # or
        "John", {"Peter", "Paul"}
        # or
        sub(s/\b\w+\b/Peter/, "John"), {"Peter", "Paul"}

See [\"word\"](#word){.perl-module} and [\"list\"](#list){.perl-module}
regular expression for more on those.

The capture names are:

*words*

:   Contains the entire capture block

*words\_word*

:   Contains the word

*words\_list*

:   Contains the list

LEGACY
======

There are 2 expressions that can be used as legacy:

*comp*

:   See [\"comp\"](#comp){.perl-module}

*variable*

:   See [\"variable\"](#variable){.perl-module}

CHANGES & CONTRIBUTIONS
=======================

Feel free to reach out to the author for possible corrections,
improvements, or suggestions.

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x557b8c355d30)"}\>

SEE ALSO
========

<https://httpd.apache.org/docs/trunk/en/expr.html>

COPYRIGHT & LICENSE
===================

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
