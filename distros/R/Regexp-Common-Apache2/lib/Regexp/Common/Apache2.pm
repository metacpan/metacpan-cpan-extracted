##----------------------------------------------------------------------------
## Module Generic - ~/scripts/Apache2.pm
## Version v0.2.1
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/02/14
## Modified 2021/03/07
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Regexp::Common::Apache2;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Exporter );
    use Regexp::Common qw( pattern );
    our $VERSION = 'v0.2.1';
    our $DEBUG   = 3;
    ## Ref: <http://httpd.apache.org/docs/trunk/en/expr.html>
    our $UNARY_OP   = qr/(?:(?<=\W)|(?<=^)|(?<=\A))\-[a-zA-Z]/;
    our $DIGIT      = qr/[0-9]/;
    our $REGPATTERN = qr/(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+/;
    our $REGFLAGS   = qr/[i|s|m|g]+/;
    our $REGSEP     = qr/[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-]/;
    our $FUNCNAME   = qr/[a-zA-Z_]\w*/;
    our $VARNAME    = qr/[a-zA-Z_]\w*/;
    our $TEXT       = qr/[^[:cntrl:]]/;
    ## See Regexp::Common::net
    our $IPv4       = qr/(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))/;
    our $IPv6       = qr/(?:(?|(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4})|(?::(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):)))/;
    ##our $ap_true    = do{ bless( \( my $dummy = 1 ) => "Regexp::Common::Apache2::Boolean" ) };
    ##our $ap_false   = do{ bless( \( my $dummy = 0 ) => "Regexp::Common::Apache2::Boolean" ) };
    our $ap_true    = 1;
    our $ap_false   = 0;
    our @EXPORT_OK  = qw( $ap_true $ap_false );
    our $REGEXP     = {};
    our $TRUNK      = {};
    ## Legacy regular expression
    ## <http://httpd.apache.org/docs/trunk/en/mod/mod_include.html#legacyexpr>
    our $REGEXP_LEGACY = {};

    $REGEXP =
    {
    unary_op    => $UNARY_OP,
    ## <any US-ASCII digit "0".."9">
    digit       => $DIGIT,
    ## 1*(DIGIT)
    digits      => qr/${DIGIT}{1,}/,
    ## "$" DIGIT
    ## As per Apache apr_expr documentation, regular expression back reference go from 1 to 9 with 0 containing the entire regexp
    rebackref   => qr/(?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})/,
    ## cstring ; except enclosing regsep
    regpattern  => $REGPATTERN,
    ## 1*("i" | "s" | "m" | "g")
    regflags	=> $REGFLAGS,
    ## "/" | "#" | "$" | "%" | "^" | "|" | "?" | "!" | "'" | '"' | "," | ";" | ":" | "." | "_" | "-"
    regsep	    => $REGSEP,
    ## "/" regpattern "/" [regflags]
    ## | "m" regsep regpattern regsep [regflags]
    regex	    => qr/
    (?<regex>
        (?:(?<regsep>\/)(?<regpattern>${REGPATTERN})\/(?<regflags>${REGFLAGS})?)
        |
        (?:m(?<regsep>${REGSEP})(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>${REGFLAGS})?)
    )/x,
    funcname	=> $FUNCNAME,
    varname	    => $VARNAME,
    ## <any OCTET except CTLs>
    text	    => $TEXT,
    ## 0*(TEXT)
    cstring	    => qr/[^[:cntrl:]]+/,
    true        => qr/[1]/,
    false       => qr/[0]/,
    ipaddr      => qr/(?:$IPv4|$IPv6)/,
    };
    
    $REGEXP->{is_true} = qr/
    (?:
        (?:\btrue\b)
        |
        (?:
            (?:(?<=\W)|(?<=\A)|(?<=^))$Regexp::Common::Apache2::REGEXP->{true}(?=\W|\Z|$)
        )
    )
    /x;
    
    $REGEXP->{is_false} = qr/
    (?:
        (?:\bfalse\b)
        |
        (?:
            (?:(?<=\W)|(?<=\A)|(?<=^))$Regexp::Common::Apache2::REGEXP->{false}(?=\W|\Z|$)
        )
    )
    /x;
    
    ## stringcomp
    ## | integercomp
    ## | unaryop word
    ## | word binaryop word
    ## | word "in" listfunc
    ## | word "=~" regex
    ## | word "!~" regex
    ## | word "in" "{" list "}"
    ## Ref:
    ## <http://httpd.apache.org/docs/trunk/en/expr.html#unnop>
    ## <http://httpd.apache.org/docs/trunk/en/expr.html#binop>
    $REGEXP->{comp} = qr/
    (?<comp>
        (?:
            (?<comp_stringcomp> (?&stringcomp) )
        )
        |
        (?:
            (?<comp_integercomp> (?&integercomp) )
        )
        |
        (?<comp_unary>
            (?:(?<=\W)|(?<=^)|(?<=\A))
            \-(?<comp_unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
            [[:blank:]\h]+
            (?<comp_word> (?&word) )
        )
        |
        (?<comp_binary>
            (?<comp_worda> (?&word_lax) )
            [[:blank:]\h]+
            (?:
                (?<comp_binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                |
                (?:
                    (?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<comp_binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                )
            )
            [[:blank:]\h]+
            (?<comp_wordb> (?&word_lax) )
        )
        |
        (?<comp_word_in_listfunc>
            (?<comp_word> (?&word) )
            [[:blank:]\h]+
            \-?in
            [[:blank:]\h]+
            (?<comp_listfunc> (?&listfunc) )
        )
        |
        (?<comp_word_in_regexp>
            (?<comp_word> (?&word) )
            [[:blank:]\h]+
            (?<comp_regexp_op> [\=|\!]\~ )
            [[:blank:]\h]+
            (?<comp_regexp>$Regexp::Common::Apache2::REGEXP->{regex})
        )
        |
        (?<comp_word_in_list>
            (?<comp_word> (?&word) )
            [[:blank:]\h]+
            \-?in
            [[:blank:]\h]+
            \{
                [[:blank:]\h]*
                (?<comp_list> (?&words) )
                [[:blank:]\h]*
            \}
        )
    )
    (?(DEFINE)
        (?<comp_recur>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## "true" 
    ## | "false"
    ## | "!" cond
    ## | cond "&&" cond
    ## | cond "||" cond
    ## | "(" cond ")"
    ## | comp
    $REGEXP->{cond} = qr/
    (?<cond>
        (?:
            (?<cond_true>$Regexp::Common::Apache2::REGEXP->{is_true})
        )
        |
        (?:
            (?<cond_false>$Regexp::Common::Apache2::REGEXP->{is_false})
        )
        |
        (?:
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parenthesis>
                    (?&cond_recur)
                )
                [[:blank:]\h]*
                \)
            )
        )
        |
        (?:
            (?<cond_neg>\![[:blank:]\h]*(?<cond_expr>(?&cond_recur)))
        )
        |
        (?:
            (?(?=(?:.+?)\&\&(?:.+?))
                (?<cond_and>
                    (?<cond_and_expr1>
                        (?: (?&cond_recur) )+
                    )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2>
                        (?: (?&cond_recur) )+
                    )
                )
            )
        )
        |
        (?:
            (?(?=(?:.+?)\|\|(?:.+?))
                (?<cond_or>
                    (?<cond_or_expr1>
                        (?: (?&cond_recur) )+
                    )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2>
                        (?: (?&cond_recur) )+
                    )
                )
            )
        )
        |
        (?:
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond_recur>
            (?:$Regexp::Common::Apache2::REGEXP->{is_true})
            |
            (?:$Regexp::Common::Apache2::REGEXP->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<enclosed_cond> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?(?=(?:.+?)\|\|(?:.+?))
                (?<cond_bool_and>
                        
                    (?<cond_bool_or_expr1> (?: (?-3) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_bool_or_expr2> (?: (?-3) )+ )
                )
            )
            |
            (?(?=(?:.+?)\&\&(?:.+?))
                (?<cond_bool_and>
                    (?<cond_bool_and_expr1> (?: (?-3) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_bool_and_expr2> (?: (?-3) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /xi;

    ## cond
    ## | string
    $REGEXP->{expr} = qr/
    (?<expr>
        (?:
            (?<expr_cond>(?&cond))
        )
        |
        (?:
            (?<expr_string>(?&string))
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::REGEXP->{is_true})
            |
            (?:$Regexp::Common::Apache2::REGEXP->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<enclosed_cond> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?(?=(?:.+?)\|\|(?:.+?))
                (?<cond_bool_and>
                        
                    (?<cond_bool_or_expr1> (?: (?-3) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_bool_or_expr2> (?: (?-3) )+ )
                )
            )
            |
            (?(?=(?:.+?)\&\&(?:.+?))
                (?<cond_bool_and>
                    (?<cond_bool_and_expr1> (?: (?-3) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_bool_and_expr2> (?: (?-3) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## funcname "(" words ")"
    ## -> Same as LISTFUNC
    $REGEXP->{function}	= qr/
    (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function_recur>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function_recur))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function_recur))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## word "-eq" word | word "eq" word
    ## | word "-ne" word | word "ne" word
    ## | word "-lt" word | word "lt" word
    ## | word "-le" word | word "le" word
    ## | word "-gt" word | word "gt" word
    ## | word "-ge" word | word "ge" word
    $REGEXP->{integercomp} = qr/
    (?<integercomp>
        (?<integercomp_worda>(?&word))
        [[:blank:]\h]+
        \-?(?<integercomp_op>eq|ne|lt|le|gt|ge)
        [[:blank:]\h]+
        (?<integercomp_wordb>(?&word))
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp_recur)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp_recur>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## listfuncname "(" words ")"
    ## Use recursion at execution phase for words because it contains dependencies -> list -> listfunc
    #(??{$Regexp::Common::Apache2::REGEXP->{words}})
    $REGEXP->{listfunc}	= qr/
    (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc_recur) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::REGEXP->{is_true})
            |
            (?:$Regexp::Common::Apache2::REGEXP->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<enclosed_cond> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?(?=(?:.+?)\|\|(?:.+?))
                (?<cond_bool_and>
                        
                    (?<cond_bool_or_expr1> (?: (?-3) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_bool_or_expr2> (?: (?-3) )+ )
                )
            )
            |
            (?(?=(?:.+?)\&\&(?:.+?))
                (?<cond_bool_and>
                    (?<cond_bool_and_expr1> (?: (?-3) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_bool_and_expr2> (?: (?-3) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc_recur>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## substring
    ## | string substring
    $REGEXP->{string} = qr/
    (?<string>
        (?:
            (?&substring)
        )
        |
        (?:
            (?:(?&string_recur)[[:blank:]\h]+(?&substring))
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<string_recur>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string_recur) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )/x;

    ## word "==" word
    ## | word "!=" word
    ## | word "<"  word
    ## | word "<=" word
    ## | word ">"  word
    ## | word ">=" word
    $REGEXP->{stringcomp} = qr/
    (?<stringcomp>
        (?<stringcomp_worda>(?&word))
        [[:blank:]\h]+
        (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
        [[:blank:]\h]+
        (?<stringcomp_wordb>(?&word))
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp_recur)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp_recur>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## cstring
    ## | variable
    ## | rebackref
    $REGEXP->{substring} = qr/
    (?<substring>
        (?:$Regexp::Common::Apache2::REGEXP->{cstring})
        |
        (?:
            (?<sub_variable> (?&variable) )
        )
        |
        (?:
            (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:(?-1)[[:blank:]\h]+(?&substring_recur))
            |
            (?&substring_recur)
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring_recur>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## "%{" varname "}"
    ## | "%{" funcname ":" funcargs "}"
    ## | "v('" varname "')"
    $REGEXP->{variable} = qr/
    (?<variable>
        (?:
            (?:^|\A|(?<!\\))\%\{
                (?:
                    (?<var_func>(?<var_func_name>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+))
                )
            \}
        )
        |
        (?:
            (?:^|\A|(?<!\\))\%\{
                (?:
                    (?<varname>${VARNAME})
                )
            \}
        )
        |
        (?:
            \bv\(
                [[:blank:]\h]*
                (?<var_quote>["'])
                (?:
                    (?<varname>${VARNAME})
                )
                [[:blank:]\h]*
                \g{var_quote}
            \)
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable_recur) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<variable_recur>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable_recur))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable_recur))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## digits
    ## | "'" string "'"
    ## | '"' string '"'
    ## | word "." word
    ## | variable
    ## | sub
    ## | join
    ## | function
    ## | "(" word ")"
    $REGEXP->{word} = qr/
    (?<word>
        (?:
            (?<word_ip>
                (?<word_ip4>$IPv4)
                |
                (?<word_ip6>$IPv6)
            )
        )
        |
        (?:
            (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
        )
        |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
        |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
        |
        (?:
            (?<word_dot_word>
                (?: (?&word_recur)\. )+ (?&word_recur)
            )
        )
        |
        (?:
            (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
        )
        |
        (?:
            (?<word_variable>(?&variable))
        )
        |
        (?:
            (?<word_function>(?&function))
        )
        |
        (?:
            $Regexp::Common::Apache2::REGEXP->{regex}
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word_recur) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word_recur) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word_recur) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word_recur))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word_recur))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word_recur))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word_recur))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word_recur>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word_recur)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word_recur)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word_recur) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word_recur) )
            )
        )
    )
    /x;
    
    ## word
    ## | word "," list
    $REGEXP->{words} = qr/
    (?<words>
        (?:
            (?<words_list>
                (?<words_word>(?&word))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_sublist>(?&words_recur))
            )
        )
        |
        (?:
            (?<words_word>(?&word))
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<unary_word>(?&word_lax))
                )
            )
            |
            (?:
                (?<binary_worda>(?&word_lax))
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<binary_worda>(?&word_lax))
            )
            |
            (?:
                (?<funclist_worda> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<funclist_list> (?&listfunc) )
            )
            |
            (?:
                (?<regex_word> (?&word) )
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<list_word> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?<func_name>[a-zA-Z_]\w*)?                  # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (                                    # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?:(?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_backref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits>$Regexp::Common::Apache2::REGEXP->{digits})
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word>
                    (?: (?: (?-2)\. )+ (?-2) )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function>(?&function))
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::REGEXP->{regex} )
            )
        )
        (?<words_recur>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## Trunk regular expression
    @$TRUNK{qw( unary_op digit digits rebackref regpattern regflags regsep regex funcname varname text cstring true false is_true is_false )} =
    @$REGEXP{qw( unary_op digit digits rebackref regpattern regflags regsep regex funcname varname text cstring true false is_true is_false )};
    
    ## stringcomp
    ## | integercomp
    ## | unaryop word
    ## | word binaryop word
    ## | word "in" listfunc
    ## | word "=~" regex
    ## | word "!~" regex
    ## | word "in" "{" list "}"
    ## Ref:
    ## <http://httpd.apache.org/docs/trunk/en/expr.html#unnop>
    ## <http://httpd.apache.org/docs/trunk/en/expr.html#binop>
    $TRUNK->{comp} = qr/
    (?<comp>
        (?:
            (?<comp_stringcomp>(?&stringcomp))
        )
        |
        (?:
            (?<comp_integercomp>(?&integercomp))
        )
        |
        (?<comp_unary>
            (?:(?<=\W)|(?<=^)|(?<=\A))
            \-(?<comp_unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
            [[:blank:]\h]+
            (?<comp_word>(?&word))
        )
        |
        (?<comp_binary>
            (?<comp_worda>(?&word_lax))
            [[:blank:]\h]+
            (?:
                (?<comp_binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                |
                (?:
                    (?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<comp_binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                )
            )
            [[:blank:]\h]+
            (?<comp_wordb>(?&word_lax))
        )
        |
        (?<comp_word_in_listfunc>
            (?<comp_word>(?&word))
            [[:blank:]\h]+
            \-?in
            [[:blank:]\h]+
            (?<comp_listfunc>(?&listfunc))
        )
        |
        (?<comp_word_in_regexp>
            (?<comp_word>(?&word))
            [[:blank:]\h]+
            (?<comp_regexp_op>[\=|\!]\~)
            [[:blank:]\h]+
            (?<comp_regexp>$Regexp::Common::Apache2::TRUNK->{regex})
        )
        |
        (?<comp_word_in_list>
            (?<comp_word>(?&word))
            [[:blank:]\h]+
            \-?in
            [[:blank:]\h]+
            \{
                [[:blank:]\h]*
                (?<comp_list>(?&list))
                [[:blank:]\h]*
            \}
        )
    )
    (?(DEFINE)
        (?<comp_recur>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## "true" 
    ## | "false"
    ## | "!" cond
    ## | cond "&&" cond
    ## | cond "||" cond
    ## | "(" cond ")"
    ## | comp
    $TRUNK->{cond} = qr/
    (?<cond>
        (?:
            (?<cond_true>$Regexp::Common::Apache2::TRUNK->{is_true})
        )
        |
        (?:
            (?<cond_false>$Regexp::Common::Apache2::TRUNK->{is_false})
        )
        |
        (?:
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parenthesis>
                    (?&cond_recur)
                )
                [[:blank:]\h]*
                \)
            )
        )
        |
        (?:
            (?<cond_neg>\![[:blank:]\h]*(?<cond_expr>(?&cond_recur)))
        )
        |
        (?:
            (?(?=(?:.+?)\&\&(?:.+?))
                (?<cond_and>
                    (?<cond_and_expr1>
                        (?: (?&cond_recur) )+
                    )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2>
                        (?: (?&cond_recur) )+
                    )
                )
            )
        )
        |
        (?:
            (?(?=(?:.+?)\|\|(?:.+?))
                (?<cond_or>
                    (?<cond_or_expr1>
                        (?: (?&cond_recur) )+
                    )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2>
                        (?: (?&cond_recur) )+
                    )
                )
            )
        )
        |
        (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
            (?<cond_comp> (?&comp) )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond_recur>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (cond_recur) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /xi;

    ## cond
    ## | string
    $TRUNK->{expr} = qr/
    (?<expr>
        (?:
            (?<expr_cond>(?&cond))
        )
        |
        (?:
            (?<expr_string>(?&string))
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;
    
    ## funcname "(" words ")"
    ## -> Same as LISTFUNC
    $TRUNK->{function}	= qr/
    (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function_recur>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function_recur) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function_recur) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## word "-eq" word | word "eq" word
    ## | word "-ne" word | word "ne" word
    ## | word "-lt" word | word "lt" word
    ## | word "-le" word | word "le" word
    ## | word "-gt" word | word "gt" word
    ## | word "-ge" word | word "ge" word
    $TRUNK->{integercomp} = qr/
    (?<integercomp>
        (?<integercomp_worda>(?&word))
        [[:blank:]\h]+
        \-?(?<integercomp_op>eq|ne|lt|le|gt|ge)
        [[:blank:]\h]+
        (?<integercomp_wordb>(?&word))
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp_recur)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp_recur>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;
    
    ## "join" ["("] list [")"]
    ## | "join" ["("] list "," word [")"]
    $TRUNK->{join} = qr/
    (?<join>
        join\(
            [[:blank:]\h]*
            (?:
                (?:
                    (?<join_list>(?&list))[[:blank:]]*\,[[:blank:]]*(?<join_word>(?&word))
                )
                |
                (?:
                    (?<join_list>(?&list))
                )
            )
            [[:blank:]\h]*
        \)
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join_recur>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join_recur) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join_recur) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## split
    ## | listfunc
    ## | "{" words "}"
    ## | "(" list ")"
    $TRUNK->{list} = qr/
    (?<list>
        (?:
            (?<list_func>(?&listfunc))
        )
        |
        (?:
            \{
                [[:blank:]\h]*
                (?<list_words>(?&words))
                [[:blank:]\h]*
            \}
        )
        |
        (?:
            (?<list_split>(?&split))
        )
        |
        (?:
            \(
            [[:blank:]\h]*
            (?<list_list> (?&list_recur) )
            [[:blank:]\h]*
            \)
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list_recur) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list_recur) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list_recur>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list_recur) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list_recur) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## listfuncname "(" words ")"
    ## Use recursion at execution phase for words because it contains dependencies -> list -> listfunc
    #(??{$Regexp::Common::Apache2::TRUNK->{words}})
    $TRUNK->{listfunc}	= qr/
    (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc_recur) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc_recur))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc_recur>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## regex | regsub
    $TRUNK->{regany} = qr/
    (?<regany>
        (?:
            (?<regany_regex>$Regexp::Common::Apache2::TRUNK->{regex})
            |
            (?:
                (?<regany_regsub>(?&regsub))
            )
        )
    )
    (?(DEFINE)
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
    )
    /x;

    ## "s" regsep regpattern regsep string regsep [regflags]
    $TRUNK->{regsub} = qr/
    (?<regsub>
        s(?<regsep>${REGSEP})
         (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
         \g{regsep}
         (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
         \g{regsep}
         (?<regflags>${REGFLAGS})?
    )
    /x;

    ## "split" ["("] regany "," list [")"]
    ## | "split" ["("] regany "," word [")"]
    $TRUNK->{split} = qr/
    (?<split>
        split\(
            [[:blank:]\h]*
            (?<split_regex>(?&regany))
            [[:blank:]\h]*\,[[:blank:]\h]*
            (?:
                (?:
                    (?<split_word>(?&word))
                )
                |
                (?:
                    (?<split_list>(?&list))
                )
            )
            [[:blank:]\h]*
        \)
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split_recur))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split_recur>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## substring
    ## | string substring
    $TRUNK->{string} = qr/
    (?<string>
        (?:
            (?&substring)
        )
        |
        (?:
            (?:(?&string_recur)[[:blank:]\h]+(?&substring))
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string_recur>
            (?:
                (?:(?-1)[[:blank:]\h]+(?&substring))
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string_recur) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )/x;

    ## word "==" word
    ## | word "!=" word
    ## | word "<"  word
    ## | word "<=" word
    ## | word ">"  word
    ## | word ">=" word
    $TRUNK->{stringcomp} = qr/
    (?<stringcomp>
        (?<stringcomp_worda>(?&word))
        [[:blank:]\h]+
        (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
        [[:blank:]\h]+
        (?<stringcomp_wordb>(?&word))
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp_recur)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp_recur>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## "sub" ["("] regsub "," word [")"]
    $TRUNK->{sub} = qr/
    (?<sub>
        sub\(
            [[:blank:]\h]*
            (?<sub_regsub>(?&regsub))
            [[:blank:]\h]*
            \,
            [[:blank:]\h]*
            (?:
                (?<sub_word>
                    (?&word)
                )
            )
            [[:blank:]\h]*
        \)
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub_recur>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub_recur) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub_recur) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## cstring
    ## | variable
    $TRUNK->{substring} = qr/
    (?<substring>
        (?:$Regexp::Common::Apache2::TRUNK->{cstring})
        |
        (?:
            (?<sub_variable> (?&variable) )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?:(?-1)[[:blank:]\h]+(?&substring_recur))
            )
            |
            (?:
                (?: (?&substring_recur) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring_recur>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## "%{" varname "}"
    ## | "%{" funcname ":" funcargs "}"
    ## | "%{:" word ":}"
    ## | "%{:" cond ":}"
    ## | rebackref
    $TRUNK->{variable} = qr/
    (?<variable>
        (?:
            (?:^|\A|(?<!\\))\%\{
                (?:
                    (?<var_func>(?<var_func_name>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+))
                )
            \}
        )
        |
        (?:
            (?:^|\A|(?<!\\))\%\{
                (?:
                    (?<varname>${VARNAME})
                )
            \}
        )
        |
        (?:
            \bv\(
                [[:blank:]\h]*
                (?<var_quote>["'])
                (?:
                    (?<varname>${VARNAME})
                )
                [[:blank:]\h]*
                \g{var_quote}
            \)
        )
        |
        (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
        )
        |
        (?:
            (?:^|\A|(?<!\\))\%\{\:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?<var_word> (?&word) )
                )
            \:\}
        )
        |
        (?:
            (?:^|\A|(?<!\\))\%\{\:
                (?:
                    (?<var_cond>(?&cond))
                )
            \:\}
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable_recur) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<variable_recur>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable_recur))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable_recur))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## digits
    ## | "'" string "'"
    ## | '"' string '"'
    ## | word "." word
    ## | variable
    ## | sub
    ## | join
    ## | function
    ## | "(" word ")"
    $TRUNK->{word} = qr/
    (?<word>
        (?:
            (?<word_ip>
                (?<word_ip4>$IPv4)
                |
                (?<word_ip6>$IPv6)
            )
        )
        |
        (?:
            (?<word_digits>$Regexp::Common::Apache2::TRUNK->{digits})
        )
        |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
        |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
        |
        (?:
            (?<word_parens_open>\()
                [[:blank:]\h]*
                (?<word_enclosed>(?&word_lax))
                [[:blank:]\h]*
            (?<word_parens_close>\))
        )
        |
        (?:
            (?<word_dot_word> (?: (?&word_recur)\. )+ (?&word_recur) )
        )
        |
        (?:
            (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
        )
        |
        (?:
            (?<word_variable>(?&variable))
        )
        |
        (?:
            (?<word_sub>(?&sub))
        )
        |
        (?:
            (?<word_join>(?&join))
        )
        |
        (?:
            (?<word_function>(?&function))
        )
        |
        (?:
            $Regexp::Common::Apache2::TRUNK->{regex}
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_recur) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word_recur) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word_recur) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word_recur))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word_recur))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word_recur) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word_recur) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word_recur))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word_recur))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word_recur)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word_recur) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word_recur>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word_recur) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word_recur)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word_recur)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word_recur) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word_recur) )
            )
        )
    )
    /x;
    
    ## word
    ## | word "," list
    $TRUNK->{words} = qr/
    (?<words>
        (?:
            (?:
                (?<words_list_word>
                    (?:
                        (?<words_list_word1> (?&word) )
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?<words_list_word2> (?&word) )
                )
                (?<words_list_more>
                    (?<words_list_sep>[[:blank:]\h]*\,[[:blank:]\h]*)
                    (?<words_word3> (?&word) )
                )?
                (?(<words_list_more>)
                    (?<words_list>\g{words_list_word}\g{words_list_more})
                    |
                    (?(<words_list_word1>)
                        (?<words_list>\g{words_list_word})
                    )
                )
                (?(<words_list>)
                    (?(<words_list_word1>)
                        (?<words_word> \g{words_list_word1} )
                        |
                        (?<words_word> \g{words_list_word2} )
                    )
                    |
                    (?(<words_list_word1>)
                        |
                        (?<words_word> \g{words_list_word2} )
                    )
                )
                (?(<words_list>)
                    (?(<words_list_more>)
                        (?(<words_list_word1>)
                            (?<words_sublist> \g{words_list_word2}\g{words_list_more} )
                            |
                            (?<words_sublist> \g{words_list_word1} )
                        )
                        |
                        (?<words_sublist> \g{words_list_word2} )
                    )
                )
            )
            |
            (?:
                (?<words_list>
                    (?<words_word>(?&word))
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_sublist>(?&list))
                )
            )
            |
            (?:
                (?<words_word>(?&word))
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_unary_word> (?&word_lax) )
            )
            |
            (?:
                (?<comp_binary_worda> (?&word_lax) )
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                    |
                    (?:
                        (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                )
                [[:blank:]\h]+
                (?<comp_binary_wordb> (?&word_lax) )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&list) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::TRUNK->{is_true})
            |
            (?:$Regexp::Common::Apache2::TRUNK->{is_false})
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_word> (?&word) )
            )
            |
            (?:
                (?:
                    (?<words_word> (?&word) )
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list> (?&list) )
                )
                |
                (?:
                    (?<words_list_word>
                        (?:
                            (?&word)
                            [[:blank:]\h]*\,[[:blank:]\h]*
                        )*
                        (?&word)
                    )
                    (?:
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?<words_word> (?&word) )
                    )?
                )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<join>
            \bjoin\(
                [[:blank:]\h]*
                (?:
                    (?:
                        (?<join_list> (?&list) )
                        [[:blank:]]*\,[[:blank:]]*
                        (?<join_word> (?&word) )
                    )
                    |
                    (?<join_list> (?&list) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words_recur))
                    [[:blank:]\h]*
                \}
            )
            |
            (?:
                \(
                    [[:blank:]\h]*
                    (?<list_parens> (?&list) )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?<list_func>(?&listfunc))
            )
            |
            (?:
                (?(?=\bsplit\()
                    (?<list_split>(?&split))
                )
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<regany>
            (?:
                $Regexp::Common::Apache2::REGEXP->{regex}
                |
                (?:
                    (?<regany_regsub> (?&regsub) )
                )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<regsub>
            s(?<regsep>${REGSEP})
             (?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regstring>(?>\\\g{regsep}|(?!\g{regsep}).)*+)
             \g{regsep}
             (?<regflags>${REGFLAGS})?
        )
        (?<split>
            split\(
                [[:blank:]\h]*
                (?<split_regex>(?&regany))
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?:
                    (?:
                        (?<split_word> (?&word) )
                    )
                    |
                    (?:
                        (?<split_list> (?&list) )
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?:
                (?: (?&substring) )
            )
            |
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<sub>
            \bsub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?<sub_regsub> (?&regsub) )
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?<sub_word>
                    (?<sub_word> (?>(?&word)) )
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_word> (?&word) )
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?:
                        (?<var_cond> (?&cond) )
                    )
                \:\}
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?&word_lax) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<word_parens> (?-2) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                (?(?=(?:(?>\\\.|(?!\.).)*+\.(?:.+?)))
                    (?<word_dot_word>
                        (?: (?: (?-2)\. )+ (?-2) )
                    )
                )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?(?=\bsub\b\()
                    (?<word_sub> (?&sub) )
                )
            )
            |
            (?:
                (?(?=\bjoin\b\()
                    (?<word_join> (?&join) )
                )
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                (?<word_regex> $Regexp::Common::Apache2::TRUNK->{regex} )
            )
        )
        (?<words_recur>
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?&list) )
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                [[:blank:]\h]*\K
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## Here is the addition to be compliant with expression from 2.3.12 and before,
    ## ie old fashioned variable such as $REQUEST_URI instead of the modern version %{REQUEST_URI}
    @$REGEXP_LEGACY{qw( unary_op digit digits rebackref regpattern regflags regsep regex funcname varname text cstring true false is_true is_false )} =
           @$REGEXP{qw( unary_op digit digits rebackref regpattern regflags regsep regex funcname varname text cstring true false is_true is_false )};

    ## stringcomp
    ## | integercomp
    ## | unaryop word
    ## | word binaryop word
    ## | word "in" listfunc
    ## | word "=~" regex
    ## | word "!~" regex
    ## | word "in" "{" list "}"
    ## Ref:
    ## <http://httpd.apache.org/docs/trunk/en/expr.html#unnop>
    ## <http://httpd.apache.org/docs/trunk/en/expr.html#binop>
    ## Here we allow regular expression to be writen like: expression = //, ie without the ~
    $REGEXP_LEGACY->{comp} = qr/
    (?<comp>
        (?:
            (?<comp_in_regexp_legacy>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
        )
        |
        (?:
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                (?<comp_stringcomp>(?&stringcomp))
            )
        )
        |
        (?:
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                (?<comp_integercomp>(?&integercomp))
            )
        )
        |
        (?:
            (?<comp_unary>
                (?:(?<=\W)|(?<=^)|(?<=\A))
                \-(?<comp_unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_word>(?&word_lax))
            )
        )
        |
        (?:
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?<comp_binary>
                    (?<comp_worda>(?&word_lax))
                    [[:blank:]\h]+
                    (?:
                        (?<comp_binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<comp_binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_wordb>(?&word_lax))
                )
            )
        )
        |
        (?<comp_word_in_listfunc>
            (?<comp_word> (?&word_lax) )
            [[:blank:]\h]+
            \-?in
            [[:blank:]\h]+
            (?<comp_listfunc>(?&listfunc))
        )
        |
        (?<comp_in_regexp>
            (?<comp_word>(?&word))
            [[:blank:]\h]+
            (?<comp_regexp_op>[\=|\!]\~)
            [[:blank:]\h]+
            (?<comp_regexp>$Regexp::Common::Apache2::REGEXP->{regex})
        )
        |
        (?<comp_word_in_list>
            (?<comp_word>(?&word))
            [[:blank:]\h]+
            \-?in
            [[:blank:]\h]+
            \{
                [[:blank:]\h]*
                (?<comp_list>(?&words))
                [[:blank:]\h]*
            \}
        )
    )
    (?(DEFINE)
        (?<comp_recur>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::REGEXP_LEGACY->{is_true})
            |
            (?:$Regexp::Common::Apache2::REGEXP_LEGACY->{is_false})
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp_recur))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
                (?(<cond_or_expr1>)
                    (?(<cond_or_expr2>)
                        (*ACCEPT)
                    )
                )
            )
            |
            (?:
                (?<cond_variable>(?&variable))
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## "true" 
    ## | "false"
    ## | "!" cond
    ## | cond "&&" cond
    ## | cond "||" cond
    ## | "(" cond ")"
    ## | comp
    $REGEXP_LEGACY->{cond} = qr/
    (?<cond>
        (?:
            (?<cond_true>$Regexp::Common::Apache2::REGEXP_LEGACY->{is_true})
        )
        |
        (?:
            (?<cond_false>$Regexp::Common::Apache2::REGEXP_LEGACY->{is_false})
        )
        |
        (?:
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parenthesis>
                    (?&cond_recur)
                )
                [[:blank:]\h]*
                \)
            )
        )
        |
        (?:
            (?<cond_neg>\![[:blank:]\h]*(?<cond_expr>(?&cond_recur)))
        )
        |
        (?:
            (?(?=(?:.+?)\&\&(?:.+?))
                (?<cond_and>
                    (?<cond_and_expr1>
                        (?: (?&cond_recur) )+
                    )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2>
                        (?: (?&cond_recur) )+
                    )
                )
            )
        )
        |
        (?:
            (?(?=(?:.+?)\|\|(?:.+?))
                (?<cond_or>
                    (?<cond_or_expr1>
                        (?: (?&cond_recur) )+
                    )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2>
                        (?: (?&cond_recur) )+
                    )
                )
            )
        )
        |
        (?:
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp> (?&comp) )
            )
        )
        |
        (?:
            (?<cond_variable>(?&variable))
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond_recur>
            (?:$Regexp::Common::Apache2::REGEXP_LEGACY->{is_true})
            |
            (?:$Regexp::Common::Apache2::REGEXP_LEGACY->{is_false})
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond_recur) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
                (?(<cond_or_expr1>)
                    (?(<cond_or_expr2>)
                        (*ACCEPT)
                    )
                )
            )
            |
            (?:
                (?<cond_variable>(?&variable))
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /xi;

    ## cond
    ## | string
    $REGEXP_LEGACY->{expr} = qr/
    (?<expr>
        (?:
            (?<expr_cond>(?&cond))
        )
        |
        (?:
            (?<expr_string>(?&string))
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::REGEXP_LEGACY->{is_true})
            |
            (?:$Regexp::Common::Apache2::REGEXP_LEGACY->{is_false})
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
                (?(<cond_or_expr1>)
                    (?(<cond_or_expr2>)
                        (*ACCEPT)
                    )
                )
            )
            |
            (?:
                (?<cond_variable>(?&variable))
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## funcname "(" words ")"
    ## -> Same as LISTFUNC
    $REGEXP_LEGACY->{function}	= qr/
    (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function_recur>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function_recur) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function_recur) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## word "-eq" word | word "eq" word
    ## | word "-ne" word | word "ne" word
    ## | word "-lt" word | word "lt" word
    ## | word "-le" word | word "le" word
    ## | word "-gt" word | word "gt" word
    ## | word "-ge" word | word "ge" word
    $REGEXP_LEGACY->{integercomp} = qr/
    (?<integercomp>
        (?<integercomp_worda>(?&word))
        [[:blank:]\h]+
        \-?(?<integercomp_op>eq|ne|lt|le|gt|ge)
        [[:blank:]\h]+
        (?<integercomp_wordb>(?&word))
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp_recur)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp_recur>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;
    
    ## listfuncname "(" words ")"
    ## Use recursion at execution phase for words because it contains dependencies -> list -> listfunc
    #(??{$Regexp::Common::Apache2::REGEXP_LEGACY->{words}})
    $REGEXP_LEGACY->{listfunc}	= qr/
    (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc_recur) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::REGEXP_LEGACY->{is_true})
            |
            (?:$Regexp::Common::Apache2::REGEXP_LEGACY->{is_false})
            |
            (?:
                \(
                [[:blank:]\h]*
                (?<cond_parens> (?&cond) )
                [[:blank:]\h]*
                \)
            )
            |
            (?:
                \![[:blank:]\h]*
                (?<cond_negative> (?-2) )
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b)|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?<cond_comp>(?&comp))
            )
            |
            (?:
                (?(?=(?:.+?)\&\&(?:.+?))
                    (?<cond_and_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \&\&
                    [[:blank:]\h]*
                    (?<cond_and_expr2> (?: (?-2) )+ )
                )
            )
            |
            (?:
                (?(?=(?:.+?)\|\|(?:.+?))
                    (?<cond_or_expr1> (?: (?-2) )+ )
                    [[:blank:]\h]*
                    \|\|
                    [[:blank:]\h]*
                    (?<cond_or_expr2> (?: (?-2) )+ )
                )
                (?(<cond_or_expr1>)
                    (?(<cond_or_expr2>)
                        (*ACCEPT)
                    )
                )
            )
            |
            (?:
                (?<cond_variable>(?&variable))
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc_recur>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## substring
    ## | string substring
    $REGEXP_LEGACY->{string} = qr/
    (?<string>
        (?:
            (?&substring) # Recurse on the entire substring regexp
        )
        |
        (?:
            (?:(?&string_recur)[[:blank:]\h]+(?&substring))
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<string_recur>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string_recur) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string_recur) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )/x;

    ## word "==" word
    ## | word "!=" word
    ## | word "<"  word
    ## | word "<=" word
    ## | word ">"  word
    ## | word ">=" word
    $REGEXP_LEGACY->{stringcomp} = qr/
    (?<stringcomp>
        (?<stringcomp_worda>(?&word))
        [[:blank:]\h]+
        (?<stringcomp_op>\=\=|\!\=|\<|\<\=|\>|\>\=)
        [[:blank:]\h]+
        (?<stringcomp_wordb>(?&word))
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp_recur)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<stringcomp_recur>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    $REGEXP_LEGACY->{substring} = qr/
    (?<substring>
        (?:$Regexp::Common::Apache2::REGEXP_LEGACY->{cstring})
        |
        (?:
            (?&variable)
        )
        |
        (?:
            (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring_recur)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring_recur) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring_recur>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## "%{" varname "}"
    ## | "%{" funcname ":" funcargs "}"
    ## | "v('" varname "')"
    ## | "%{:" word ":}"
    ## | "%{:" cond ":}"
    ## | rebackref
    $REGEXP_LEGACY->{variable} = qr/
    (?<variable>
        (?:
            (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
        )
        |
        (?:
            (?:^|\A|(?<!\\))\%\{
                (?:
                    (?<var_func_name>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                )
            \}
        )
        |
        (?:
            (?:^|\A|(?<!\\))\%\{
                (?:
                    (?<varname>${VARNAME})
                )
            \}
        )
        |
        (?:
            \bv\(
                [[:blank:]\h]*
                (?<var_quote>["'])
                (?:
                    (?<varname>${VARNAME})
                )
                [[:blank:]\h]*
                \g{var_quote}
            \)
        )
        |
        (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable_recur) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<variable_recur>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable_recur))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable_recur))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    ## digits
    ## | "'" string "'"
    ## | '"' string '"'
    ## | word "." word
    ## | variable
    ## | sub
    ## | join
    ## | function
    ## | "(" word ")"
    $REGEXP_LEGACY->{word} = qr/
    (?<word>
        (?:
            (?<word_ip>
                (?<word_ip4>$IPv4)
                |
                (?<word_ip6>$IPv6)
            )
        )
        |
        (?:
            (?<word_digits>$Regexp::Common::Apache2::REGEXP_LEGACY->{digits})
        )
        |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
        |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
        |
        (?:
            (?<word_dot_word>
                (?: (?&word_recur)\. )+ (?&word_recur)
            )
        )
        |
        (?:
            (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<rebackref>${DIGIT})(?(<has_accolade>)\})
        )
        |
        (?:
            (?<word_variable>(?&variable))
        )
        |
        (?:
            (?<word_function>(?&function))
        )
        |
        (?:
            $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word_recur) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word_recur))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word_recur) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word_recur))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word_recur))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word_recur))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word_recur))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word_recur>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words>
            (?:
                (?<words_word> (?&word_recur) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word_recur) )
            )
        )
    )
    /x;
    
    ## word
    ## | word "," list
    $REGEXP_LEGACY->{words} = qr/
    (?<words>
        (?:
            (?:
                (?<words_list>
                    (?<words_word>(?&word))
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_sublist>(?&words_recur))
                )
            )
            |
            (?:
                (?<words_word>(?&word))
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_stringcomp>
                        (?&stringcomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.+?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))))
                    (?<comp_integercomp>
                        (?&integercomp)
                    )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])\b))
                    (?:(?<=\W)|(?<=^)|(?<=\A))
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?<comp_unary_word> (?&word_lax) )
                )
            )
            |
            (?:
                (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{|\$\{?${VARNAME}\}?))(?:.+?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:(?:(?<comp_binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                    (?<comp_binary_worda> (?&word_lax) )
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=|(?:\b\-?(?:eq|ne|le|le|gt|ge)\b))
                        |
                        (?:
                            (?:(?<binary_is_neg>\!)[[:blank:]]*)?(?:(?<=\W)|(?<=^)|(?<=\A))\-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                        )
                    )
                    [[:blank:]\h]+
                    (?<comp_binary_wordb> (?&word_lax) )
                )
            )
            |
            (?:
                (?<comp_word_in_listfunc> (?&word_lax) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                (?<comp_word_in_listfunc_func> (?&listfunc) )
            )
            |
            (?:
                (?<comp_word_in_regex> (?&word) )
                [[:blank:]\h]+
                (?<comp_word_in_regex_re> [\=|\!]\~ )
                [[:blank:]\h]+
                $Regexp::Common::Apache2::REGEXP->{regex}
            )
            |
            (?<comp_in_regexp_legacy>
                (?=)
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=\=|\=|\!\=])
                [[:blank:]\h]+
                (?<comp_regexp>(?&regex))
            )
            |
            (?:
                (?<comp_word_in_list> (?&word) )
                [[:blank:]\h]+
                \-?in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_word_list> (?&words) )
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<integercomp>
            (?:
                (?<integercomp_worda>(?&word))
                [[:blank:]\h]+
                \-?(?<integercomp_op> (?:eq|ne|lt|le|gt|ge) )
                [[:blank:]\h]+
                (?<integercomp_wordb>(?&word))
            )
        )
        (?<listfunc>
            (?:
                (?!\bv\()(?<func_name>[a-zA-Z]\w*)
                \(
                    [[:blank:]\h]*
                    (?<func_args>
                        (?> (?&func_words) )?
                    )
                    [[:blank:]\h]*
                \)
            )
            |
            (?:
                (                                                # paren group 1 (full function)
                    (?!\bv\()                                    # Take care to avoid catching modern-style variable v()
                    (?<func_name>[a-zA-Z_]\w*)                   # possible a function with its name, or just parenthesis
                    (?<paren_group>                              # paren group 2 (parens)
                        \(
                            (?<func_args>                        # paren group 3 (contents of parens)
                                (?:
                                    (?> (?:\\[()]|(?![()]).)+ )  # escaped parens or no parens
                                    |
                                    (?&paren_group)              # Recurse to named capture group
                                )*
                            )
                        \)
                    )
                )
            )
        )
        (?<func_words>
            (?:
                (?<words_list_word>
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                    )*
                    (?&word)
                )
                (?:
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_word> (?&word) )
                )?
            )
            |
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
        (?<regex>
            (?:(?<regsep>\/)(?<regpattern>(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+)\/(?<regflags>[i|s|m|g]+)?)
            |
            (?:m(?<regsep>[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-])(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>[i|s|m|g]+)?)
        )
        (?<string>
            (?:
                (?: (?&substring)[[:blank:]\h]+(?&string) )
            )
            |
            (?:
                (?: (?&substring) )
            )
        )
        (?<stringcomp>
            (?:
                (?<stringcomp_worda>(?&word))
                [[:blank:]\h]+
                (?<stringcomp_op>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word))
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$Regexp::Common::Apache2::REGEXP->{cstring})
            )
            |
            (?:
                (?<sub_var> (?&variable) )
            )
            |
            (?:
                \$(?<has_accolade>\{)?(?<sub_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
        )
        (?<variable>
            (?:
                \$(?<has_accolade>\{)?(?<varname>[a-zA-Z\_]\w*)(?(<has_accolade>)\})
            )
            |
            (?:
                \%\{
                    (?:
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?:
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \bv\(
                    [[:blank:]\h]*
                    (?<var_quote>["'])
                    (?:
                        (?<varname>${VARNAME})
                    )
                    [[:blank:]\h]*
                    \g{var_quote}
                \)
            )
            |
            (?:
            (?:^|\A|(?<!\\))
            (?<var_backref>
                \$(?<has_accolade>\{)?
                (?<rebackref>${DIGIT})
                (?(<has_accolade>)\})
            )
            )
        )
        (?<word>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<word_lax>
            (?:
                (?<word_ip>
                    (?<word_ip4>$IPv4)
                    |
                    (?<word_ip6>$IPv6)
                )
            )
            |
            (?:
                (?<word_digits> $Regexp::Common::Apache2::REGEXP_LEGACY->{digits} )
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                    (?<word_enclosed> (?>\\\g{word_quote}|(?!\g{word_quote}).)*+ )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_quote>['"])
                (?:
                   (?<word_enclosed> (?&string) )
                )
                \g{word_quote}
            )
            |
            (?:
                (?<word_dot_word> (?: (?-2)\. )+ (?-2) )
            )
            |
            (?:
                (?:^|\A|(?<!\\))\$(?<has_accolade>\{)?(?<word_rebackref>${DIGIT})(?(<has_accolade>)\})
            )
            |
            (?:
                (?<word_variable>(?&variable))
            )
            |
            (?:
                (?<word_function> (?&function) )
            )
            |
            (?:
                $Regexp::Common::Apache2::REGEXP_LEGACY->{regex}
            )
        )
        (?<words_recur>
            (?:
                (?<words_word> (?&word) )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?<words_list> (?-2) )
            )
            |
            (?:
                (?<words_word> (?&word) )
            )
        )
    )
    /x;

    pattern name    => [qw( Apache2 -legacy=1 -trunk=1 ) ],
            create  => sub
            {
                my( $self, $flags ) = @_;
                my %re = %$REGEXP;
                ## Override vanilla regular expressions by the extended ones
                if( $flags->{'-legacy'} )
                {
                    my @k = keys( %$REGEXP_LEGACY );
                    @re{ @k } = @$REGEXP_LEGACY{ @k };
                }
                elsif( $flags->{'-trunk'} )
                {
                    my @k = keys( %$TRUNK );
                    @re{ @k } = @$TRUNK{ @k };
                }
                my $pat =  join( '|' => values( %re ) );
                return( "(?k:$pat)" );
            };

    pattern name    => [qw( Apache2 Comp )],
            create  => $REGEXP->{comp};

    pattern name    => [qw( Apache2 Cond )],
            create  => $REGEXP->{cond};

    pattern name    => [qw( Apache2 Digits )],
            create  => $REGEXP->{digits};

    pattern name    => [qw( Apache2 Expression )],
            create  => $REGEXP->{expr};

    pattern name    => [qw( Apache2 Function )],
            create  => $REGEXP->{function};

    pattern name    => [qw( Apache2 IntegerComp )],
            create  => $REGEXP->{integercomp};

    pattern name    => [qw( Apache2 ListFunc )],
            create  => $REGEXP->{listfunc};

    pattern name    => [qw( Apache2 Regexp )],
            create  => $REGEXP->{regex};

    pattern name    => [qw( Apache2 String )],
            create  => $REGEXP->{string};

    pattern name    => [qw( Apache2 StringComp )],
            create  => $REGEXP->{stringcomp};

    pattern name    => [qw( Apache2 Substring )],
            create  => $REGEXP->{substring};

    pattern name    => [qw( Apache2 Variable )],
            create  => $REGEXP->{variable};

    pattern name    => [qw( Apache2 Word )],
            create  => $REGEXP->{word};

    pattern name    => [qw( Apache2 Words )],
            create  => $REGEXP->{words};

    ## Apache2 Trunk expressions
    pattern name    => [qw( Apache2 TrunkComp )],
            create  => $TRUNK->{comp};

    pattern name    => [qw( Apache2 TrunkCond )],
            create  => $TRUNK->{cond};

    pattern name    => [qw( Apache2 TrunkDigits )],
            create  => $TRUNK->{digits};

    pattern name    => [qw( Apache2 TrunkExpression )],
            create  => $TRUNK->{expr};

    pattern name    => [qw( Apache2 TrunkFunction )],
            create  => $TRUNK->{function};

    pattern name    => [qw( Apache2 TrunkIntegerComp )],
            create  => $TRUNK->{integercomp};

    pattern name    => [qw( Apache2 TrunkJoin )],
            create  => $TRUNK->{join};

    pattern name    => [qw( Apache2 TrunkList )],
            create  => $TRUNK->{list};

    pattern name    => [qw( Apache2 TrunkListFunc )],
            create  => $TRUNK->{listfunc};

    pattern name    => [qw( Apache2 TrunkRegany )],
            create  => $TRUNK->{regany};

    pattern name    => [qw( Apache2 TrunkRegexp )],
            create  => $TRUNK->{regex};

    pattern name    => [qw( Apache2 TrunkRegsub )],
            create  => $TRUNK->{regsub};

    pattern name    => [qw( Apache2 TrunkSplit )],
            create  => $TRUNK->{split};

    pattern name    => [qw( Apache2 TrunkString )],
            create  => $TRUNK->{string};

    pattern name    => [qw( Apache2 TrunkStringComp )],
            create  => $TRUNK->{stringcomp};

    pattern name    => [qw( Apache2 TrunkSub )],
            create  => $TRUNK->{sub};

    pattern name    => [qw( Apache2 TrunkSubstring )],
            create  => $TRUNK->{substring};

    pattern name    => [qw( Apache2 TrunkVariable )],
            create  => $TRUNK->{variable};

    pattern name    => [qw( Apache2 TrunkWord )],
            create  => $TRUNK->{word};

    pattern name    => [qw( Apache2 TrunkWords )],
            create  => $TRUNK->{words};

    ## Legacy expressions
    pattern name    => [qw( Apache2 LegacyComp )],
            create  => $REGEXP_LEGACY->{comp};

    pattern name    => [qw( Apache2 LegacyCond )],
            create  => $REGEXP_LEGACY->{cond};

    pattern name    => [qw( Apache2 LegacyDigits )],
            create  => $REGEXP_LEGACY->{digits};

    pattern name    => [qw( Apache2 LegacyExpression )],
            create  => $REGEXP_LEGACY->{expr};

    pattern name    => [qw( Apache2 LegacyFunction )],
            create  => $REGEXP_LEGACY->{function};

    pattern name    => [qw( Apache2 LegacyIntegerComp )],
            create  => $REGEXP_LEGACY->{integercomp};

    pattern name    => [qw( Apache2 LegacyListFunc )],
            create  => $REGEXP_LEGACY->{listfunc};

    pattern name    => [qw( Apache2 LegacyRegexp )],
            create  => $REGEXP_LEGACY->{regex};

    pattern name    => [qw( Apache2 LegacyString )],
            create  => $REGEXP_LEGACY->{string};

    pattern name    => [qw( Apache2 LegacyStringComp )],
            create  => $REGEXP_LEGACY->{stringcomp};

    pattern name    => [qw( Apache2 LegacySubstring )],
            create  => $REGEXP_LEGACY->{substring};

    pattern name    => [qw( Apache2 LegacyVariable )],
            create  => $REGEXP_LEGACY->{variable};

    pattern name    => [qw( Apache2 LegacyWord )],
            create  => $REGEXP_LEGACY->{word};

    pattern name    => [qw( Apache2 LegacyWords )],
            create  => $REGEXP_LEGACY->{words};
};

{
    package
        Regexp::Common::Apache2::Boolean;
    BEGIN
    {
        use strict;
        use warnings;
        use overload
          "0+"     => sub{ ${$_[0]} },
          "++"     => sub{ $_[0] = ${$_[0]} + 1 },
          "--"     => sub{ $_[0] = ${$_[0]} - 1 },
          fallback => 1;
        our( $VERSION ) = '0.1.0';
    };

    sub new { return( $_[1] ? $true : $false ); }

    sub defined { return( 1 ); }

    our $true  = do{ bless( \( my $dummy = 1 ) => Regexp::Common::Apache2::Boolean ) };
    our $false = do{ bless( \( my $dummy = 0 ) => Regexp::Common::Apache2::Boolean ) };

    sub true  () { $true  }
    sub false () { $false }

    sub is_bool  ($) {           UNIVERSAL::isa( $_[0], Regexp::Common::Apache2::Boolean ) }
    sub is_true  ($) {  $_[0] && UNIVERSAL::isa( $_[0], Regexp::Common::Apache2::Boolean ) }
    sub is_false ($) { !$_[0] && UNIVERSAL::isa( $_[0], Regexp::Common::Apache2::Boolean ) }

    sub TO_JSON
    {
        ## JSON does not check that the value is a proper true or false. It stupidly assumes this is a string
        ## The only way to make it understand is to return a scalar ref of 1 or 0
        # return( $_[0] ? 'true' : 'false' );
        return( $_[0] ? \1 : \0 );
    }
}

1;

__END__
=encoding utf-8

=pod

=head1 NAME

Regexp::Common::Apache2 - Apache2 Expressions

=head1 SYNOPSIS

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

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

This is the perl port of L<Apache2 expressions|https://httpd.apache.org/docs/trunk/en/expr.html>

The regular expressions have been designed based on Apache2 Backus-Naur Form (BNF) definition as described below in L</"APACHE2 EXPRESSION">

You can also use the extended pattern by calling L<Regexp::Common::Apache2> like:

    $RE{Apache2}{-legacy => 1}

All of the regular expressions use named capture. See L<perlvar/%+> for more information on named capture.

=head1 APACHE2 EXPRESSION

=head2 comp

BNF:

    stringcomp
    | integercomp
    | unaryop word
    | word binaryop word
    | word "in" listfunc
    | word "=~" regex
    | word "!~" regex
    | word "in" "{" words "}"

    $RE{Apache2}{Comp}

For example:

    "Jack" != "John"
    123 -ne 456
    # etc

This uses other expressions namely L</stringcomp>, L</integercomp>, L</word>, L</listfunc>, L</regex>, L</words>

The capture names are:

=over 4

=item I<comp>

Contains the entire capture block

=item I<comp_binary>

Matches the expression that uses a binary operator, such as:

    ==, =, !=, <, <=, >, >=, -ipmatch, -strmatch, -strcmatch, -fnmatch

=item I<comp_binaryop>

The binary op used if the expression is a binary comparison. Binary operator is:

    ==, =, !=, <, <=, >, >=, -ipmatch, -strmatch, -strcmatch, -fnmatch

=item I<comp_integercomp>

When the comparison is for an integer comparison as opposed to a string comparison.

=item I<comp_list>

Contains the list used to check a word against, such as:

    "Jack" in {"John", "Peter", "Jack"}

=item I<comp_listfunc>

This contains the I<listfunc> when the expressions contains a word checked against a list function, such as:

    "Jack" in listMe("some arguments")

=item I<comp_regexp>

The regular expression used when a word is compared to a regular expression, such as:

    "Jack" =~ /\w+/

Here, I<comp_regexp> would contain C</\w+/>

=item I<comp_regexp_op>

The regular expression operator used when a word is compared to a regular expression, such as:

    "Jack" =~ /\w+/

Here, I<comp_regexp_op> would contain C<=~>

=item I<comp_stringcomp>

When the comparison is for a string comparison as opposed to an integer comparison.

=item I<comp_unary>

Matches the expression that uses unary operator, such as:

    -d, -e, -f, -s, -L, -h, -F, -U, -A, -n, -z, -T, -R

For example:

    -A /some/uri.html # (same as -U)
    -d /some/folder # file is a directory
    -e /some/folder/file.txt # file exists
    -f /some/folder/file.txt # file is a regular file
    -F /some/folder/file.txt # file is a regular file and is accessible to all (Apache2 does a sub query to check)
    -h /some/folder/link.txt # true if file is a symbolic link
    -n %{QUERY_STRING} # true if string is not empty (opposite of -z)
    -s /some/folder/file.txt # true if file is not empty
    -L /some/folder/link.txt # true if file is a symbolic link (same as -h)
    -R 192.168.1.1/24 # remote ip match this ip block; same as %{REMOTE_ADDR} -ipmatch 192.168.1.1/24
    -T %{HTTPS} # false if string is empty, "0", "off", "false", or "no" (case insensitive). True otherwise.
    -U /some/uri.html # check if the uri is accessible to all (Apache2 does a sub query to check)
    -z %{QUERY_STRING} # true if string is empty (opposite of -n)

=item I<comp_word>

Contains the word that is the object of the comparison.

=item I<comp_word_in_list>

Contains the expression of a word checked against a list, such as:

    "Jack" in {"John", "Peter", "Jack"}

=item I<comp_word_in_listfunc>

Contains the word when it is being compared to a L<listfunc>, such as:

    "Jack" in listMe("some arguments")

=item I<comp_word_in_regexp>

Contains the expression of a word checked against a regular expression, such as:

    "Jack" =~ /\w+/

Here the word C<Jack> (without the parenthesis) would be captured in I<comp_word>

=item I<comp_worda>

Contains the first word in comparison expression

=item I<comp_wordb>

Contains the second word in comparison expression

=back

=head2 cond

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

=over 4

=item I<cond>

Contains the entire capture block

=item I<cond_and>

Contains the expression like:

    ($ap_true && $ap_true)

=item I<cond_and_expr1>

The first expression in a ANDed condition, such as :

    $ap_true && $ap_false

=item I<cond_and_expr2>

The second expression in a ANDed condition, such as :

    $ap_true && $ap_false

=item I<cond_comp>

Contains the comparison expression. See L</comp> above.

=item I<cond_expr>

Expression that is capture after following a negatiion, such as :

    !-e /some/folder/file.txt

Here I<cond_expr> would contain C<-e /some/folder/file.txt>

=item I<cond_false>

Contains the false expression like:

    ($ap_false)
    false # as a litteral word
    0 # 0 as a standalone number not surrounded by any number or letter

=item I<cond_neg>

Contains the expression if it is preceded by an exclamation mark, such as:

    !$ap_true

=item I<cond_or>

Contains the expression like:

    ($ap_true || $ap_true)

=item I<cond_or_expr1>

The first expression in a ORed condition, such as :

    $ap_true && $ap_false

=item I<cond_or_expr2>

The second expression in a ORed condition, such as :

    $ap_true && $ap_false

=item I<cond_parenthesis>

Contains the condition when it is embedded within parenthesis.

=item I<cond_true>

Contains the true expression like:

    ($ap_true)
    true # as a litteral word
    1 # 1 as a standalone number not surrounded by any number or letter

=back

=head2 expr

BNF: cond | string

    $RE{Apache2}{Expr}

The capture names are:

=over 4

=item I<expr>

Contains the entire capture block

=item I<expr_cond>

Contains the expression of the condition

=item I<expr_string>

Contains the expression of a string

=back

=head2 function

BNF: funcname "(" words ")"

    $RE{Apache2}{Function}

For example:

    base64("Some string")
    someFunc()
    md5(  "one arg" )
    otherFunc( %{some_var}, "quoted", split( /\w+/, "John Paul" ) )

The capture names are:

=over 4

=item I<function>

Contains the entire capture block

=item I<func_args>

Contains the list of arguments. In the example above, this would be C<Some string>

=item I<func_name>

The name of the function . In the example above, this would be C<base64>

=back

=head2 integercomp

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

The hyphen before the operator is optional, so you can say C<eq> instead of C<-eq>

The capture names are:

=over 4

=item I<stringcomp>

Contains the entire capture block

=item I<integercomp_op>

Contains the comparison operator

=item I<integercomp_worda>

Contains the first word in the string comparison

=item I<integercomp_wordb>

Contains the second word in the string comparison

=back

=head2 listfunc

BNF: listfuncname "(" words ")"

    $RE{Apache2}{ListFunc}

For example:

    base64("Some string")
    someFunc()
    md5(  "one arg" )
    otherFunc( %{some_var}, "quoted", split( /\w+/, "John Paul" ) )

This is quite similar to the L</function> regular expression

The capture names are:

=over 4

=item I<listfunc>

Contains the entire capture block

=item I<func_args>

Contains the list of arguments. In the example above, this would be C<Some string>

=item I<func_name>

The name of the function . In the example above, this would be C<base64>

=back

=head2 regex

BNF:

    "/" regpattern "/" [regflags]
    | "m" regsep regpattern regsep [regflags]

    $RE{Apache2}{Regexp}

For example:

    /\w+/i
    # or
    m,\w+,i

The capture names are:

=over 4

=item I<regex>

Contains the entire capture block

=item I<regflags>

The regular expression modifiers. See L<perlre>

This can be any combination of:

    i, s, m, g

=item I<regpattern>

Contains the regular expression. See L<perlre> for example and explanation of how to use regular expression. Apache2 uses PCRE, i.e. perl compliant regular expressions.

=item I<regsep>

Contains the regular expression separator, which can be any of:

    /, #, $, %, ^, |, ?, !, ', ", ",", ;, :, ".", _, -

=back

=head2 string

BNF: substring | string substring

    $RE{Apache2}{String}

For example:

    URI accessed is: %{REQUEST_URI}

The capture names are:

=over 4

=item I<string>

Contains the entire capture block

=back

=head2 stringcomp

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

=over 4

=item I<stringcomp>

Contains the entire capture block

=item I<stringcomp_op>

Contains the comparison operator

=item I<stringcomp_worda>

Contains the first word in the string comparison

=item I<stringcomp_wordb>

Contains the second word in the string comparison

=back

=head2 substring

BNF: cstring | variable | rebackref

    $RE{Apache2}{Substring}

For example:

    Jack
    # or
    %{REQUEST_URI}

See L</variable> and L</word> regular expression for more on those.

The capture names are:

=over 4

=item I<rebackref>

Contains a regular expression back reference such as C<$1>, C<$2>, etc up to C<$9>

=item I<substring>

Contains the entire capture block

=back

=head2 variable

BNF:

    "%{" varname "}"
    | "%{" funcname ":" funcargs "}"
    | "v(" varname ")"

    $RE{Apache2}{Variable}
    # or to enable legacy variable:
    $RE{Apache2}{LegacyVariable}

For example:

    %{REQUEST_URI}
    # or
    %{md5:"some string"}
    # or
    v(REQUEST_URI)
    # legacy variable allows extended variable. See LEGACY APACHE2 EXPRESSION below

See L</word> and L</cond> regular expression for more on those.

The capture names are:

=over 4

=item I<variable>

Contains the entire capture block

=item I<var_func>

Contains the text for the function and its arguments if this is a function.

=item I<var_func_args>

Contains the function arguments.

=item I<var_func_name>

Contains the function name.

=item I<varname>

Contains the variable name without the percent sign or dollar sign (if legacy regular expression is enabled) or the possible surrounding accolades

=back

=head2 word

BNF:

    digits
    | "'" string "'"
    | '"' string '"'
    | word "." word
    | variable
    | function
    | "(" word ")"
    | rebackref

    $RE{Apache2}{Word}

This is the most complex regular expression used, since it uses all the others and can recurse deeply

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
    md5("some string")
    # or any word surrounded by parenthesis, such as:
    ("John")

See L</string>, L</word>, L</variable>, L</function> regular expression for more on those.

The capture names are:

=over 4

=item I<rebackref>

Contains a regular expression back reference such as C<$1>, C<$2>, etc up to C<$9>

=item I<word>

Contains the entire capture block

=item I<word_digits>

If the word is actually digits, ths contains those digits.

=item I<word_dot_word>

This contains the text when two words are separated by a dot.

=item I<word_enclosed>

Contains the value of the word enclosed by single or double quotes or by surrounding parenthesis.

=item I<word_function>

Contains the word containing a L</function>

=item I<word_quote>

If the word is enclosed by single or double quote, this contains the single or double quote character

=item I<word_variable>

Contains the word containing a L</variable>

=back

=head2 words

BNF:

    word
    | word "," word

    $RE{Apache2}{Words}

For example:

    "Jack"
    # or
    "John", "Peter", "Paul"

See L</word> and L</list> regular expression for more on those.

The capture names are:

=over 4

=item I<words>

Contains the entire capture block

=item I<words_word>

Contains the word

=item I<words_list>

Contains the list

=back

=head1 ADVANCED APACHE2 EXPRESSION

=head2 comp

BNF:

    stringcomp
    | integercomp
    | unaryop word
    | word binaryop word
    | word "in" listfunc
    | word "=~" regex
    | word "!~" regex
    | word "in" "{" list "}"

    $RE{Apache2}{TrunkComp}

For example:

    "Jack" != "John"
    123 -ne 456
    # etc

This uses other expressions namely L</stringcomp>, L</integercomp>, L</word>, L</listfunc>, L</regex>, L</list>

This is similar to the regular L</comp> in L</"APACHE2 EXPRESSION">, except it uses L</list> instead of L</words>

The capture names are:

=over 4

=item I<comp>

Contains the entire capture block

=item I<comp_binary>

Matches the expression that uses a binary operator, such as:

    ==, =, !=, <, <=, >, >=, -ipmatch, -strmatch, -strcmatch, -fnmatch

=item I<comp_binaryop>

The binary op used if the expression is a binary comparison. Binary operator is:

    ==, =, !=, <, <=, >, >=, -ipmatch, -strmatch, -strcmatch, -fnmatch

=item I<comp_integercomp>

When the comparison is for an integer comparison as opposed to a string comparison.

=item I<comp_list>

Contains the list used to check a word against, such as:

    "Jack" in {"John", "Peter", "Jack"}

=item I<comp_listfunc>

This contains the I<listfunc> when the expressions contains a word checked against a list function, such as:

    "Jack" in listMe("some arguments")

=item I<comp_regexp>

The regular expression used when a word is compared to a regular expression, such as:

    "Jack" =~ /\w+/

Here, I<comp_regexp> would contain C</\w+/>

=item I<comp_regexp_op>

The regular expression operator used when a word is compared to a regular expression, such as:

    "Jack" =~ /\w+/

Here, I<comp_regexp_op> would contain C<=~>

=item I<comp_stringcomp>

When the comparison is for a string comparison as opposed to an integer comparison.

=item I<comp_unary>

Matches the expression that uses unary operator, such as:

    -d, -e, -f, -s, -L, -h, -F, -U, -A, -n, -z, -T, -R

=item I<comp_word>

Contains the word that is the object of the comparison.

=item I<comp_word_in_list>

Contains the expression of a word checked against a list, such as:

    "Jack" in {"John", "Peter", "Jack"}

=item I<comp_word_in_listfunc>

Contains the word when it is being compared to a L<listfunc>, such as:

    "Jack" in listMe("some arguments")

=item I<comp_word_in_regexp>

Contains the expression of a word checked against a regular expression, such as:

    "Jack" =~ /\w+/

Here the word C<Jack> (without the parenthesis) would be captured in I<comp_word>

=item I<comp_worda>

Contains the first word in comparison expression

=item I<comp_wordb>

Contains the second word in comparison expression

=back

=head2 cond

BNF:

    "true"
    | "false"
    | "!" cond
    | cond "&&" cond
    | cond "||" cond
    | comp
    | "(" cond ")"

    $RE{Apache2}{TrunkCond}

Same as L</cond> in L</"APACHE2 EXPRESSION">

=head2 expr

BNF: cond | string

    $RE{Apache2}{TrunkExpr}

Same as L</cond> in L</"APACHE2 EXPRESSION">

=head2 function

BNF: funcname "(" words ")"

    $RE{Apache2}{TrunkFunction}

Same as L</cond> in L</"APACHE2 EXPRESSION">

=head2 integercomp

BNF:

    word "-eq" word | word "eq" word
    | word "-ne" word | word "ne" word
    | word "-lt" word | word "lt" word
    | word "-le" word | word "le" word
    | word "-gt" word | word "gt" word
    | word "-ge" word | word "ge" word

    $RE{Apache2}{TrunkIntegerComp}

Same as L</cond> in L</"APACHE2 EXPRESSION">

=head2 join

BNF:

    "join" ["("] list [")"]
    | "join" ["("] list "," word [")"]

    $RE{Apache2}{TrunkJoin}

For example:

    join({"word1" "word2"})
    # or
    join({"word1" "word2"}, ', ')

This uses L</list> and L</word>

The capture names are:

=over 4

=item I<join>

Contains the entire capture block

=item I<join_list>

Contains the value of the list

=item I<join_word>

Contains the value for word used to join the list

=back

=head2 list

BNF:

    split
    | listfunc
    | "{" words "}"
    | "(" list ")

    $RE{Apache2}{TrunkList}

For example:

    split( /\w+/, "Some string" )
    # or
    {"some", "words"}
    # or
    (split( /\w+/, "Some string" ))
    # or
    ( {"some", "words"} )

This uses L</split>, L</listfunc>, L<words> and L</list>

The capture names are:

=over 4

=item I<list>

Contains the entire capture block

=item I<list_func>

Contains the value if a L</listfunc> is used

=item I<list_list>

Contains the value if this is a list embedded within parenthesis

=item I<list_split>

Contains the value if the list is based on a L<split>

=item I<list_words>

Contains the value for a list of words.

=back

=head2 listfunc

BNF: listfuncname "(" words ")"

    $RE{Apache2}{TrunkListFunc}

Same as L</cond> in L</"APACHE2 EXPRESSION">

=head2 regany

BNF: regex | regsub

    $RE{Apache2}{TrunkRegany}

For example:

    /\w+/i
    # or
    m,\w+,i

This regular expression includes L</regany> and L</regsub>

The capture names are:

=over 4

=item I<regany>

Contains the entire capture block

=item I<regany_regex>

Contains the regular expression. See L</regex>

=item I<regany_regsub>

Contains the substitution regular expression. See L</regsub>

=back

=head2 regex

BNF:

    "/" regpattern "/" [regflags]
    | "m" regsep regpattern regsep [regflags]

    $RE{Apache2}{TrunkRegexp}

Same as L</cond> in L</"APACHE2 EXPRESSION">

=head2 regsub

BNF: "s" regsep regpattern regsep string regsep [regflags]

    $RE{Apache2}{TrunkRegsub}

For example:

    s/\w+/John/gi

The capture names are:

=over 4

=item I<regflags>

The modifiers used which can be any combination of:

    i, s, m, g

See L<perlre> for an explanation of their usage and meaning

=item I<regstring>

The string replacing the text found by the regular expression

=item I<regsub>

Contains the entire capture block

=item I<regpattern>

Contains the regular expression which is perl compliant since Apache2 uses PCRE.

=item I<regsep>

Contains the regular expression separator, which can be any of:

    /, #, $, %, ^, |, ?, !, ', ", ",", ;, :, ".", _, -

=back

=head2 split

BNF:

    "split" ["("] regany "," list [")"]
    | "split" ["("] regany "," word [")"]

    $RE{Apache2}{TrunkSplit}

For example:

    split( /\w+/, "Some string" )

This uses L</regany>, L</list> and L</word>

The capture names are:

=over 4

=item I<split>

Contains the entire capture block

=item I<split_regex>

Contains the regular expression used for the split

=item I<split_list>

The list being split. It can also be a word. See below

=item I<split_word>

The word being split. It can also be a list. See above

=back

=head2 string

BNF: substring | string substring

    $RE{Apache2}{TrunkString}

Same as L</cond> in L</"APACHE2 EXPRESSION">

=head2 stringcomp

BNF:

    word "==" word
    | word "!=" word
    | word "<"  word
    | word "<=" word
    | word ">"  word
    | word ">=" word

    $RE{Apache2}{TrunkStringComp}

Same as L</cond> in L</"APACHE2 EXPRESSION">

=head2 sub

BNF: "sub" ["("] regsub "," word [")"]

    $RE{Apache2}{TrunkSub}

For example:

    sub(s/\w/John/gi,"Peter")

The capture names are:

=over 4

=item I<sub>

Contains the entire capture block

=item I<sub_regsub>

Contains the substitution expression, i.e. in the example above, this would be:

    s/\w/John/gi

=item I<sub_word>

The target for the substitution. In the example above, this would be "Peter"

=back

=head2 substring

BNF: cstring | variable

    $RE{Apache2}{TrunkSubstring}

For example:

    Jack
    # or
    %{REQUEST_URI}
    # or
    %{:sub(s/\b\w+\b/Peter/, "John"):}

See L</variable> and L</word> regular expression for more on those.

This is different from L</substring> in L</"APACHE2 EXPRESSION"> in that it does not include regular expression back reference, i.e. C<$1>, C<$2>, etc.

The capture names are:

=over 4

=item I<substring>

Contains the entire capture block

=back

=head2 variable

BNF:

    "%{" varname "}"
    | "%{" funcname ":" funcargs "}"
    | "v('" varname "')"
    | "%{:" word ":}"
    | "%{:" cond ":}"
    | rebackref

    $RE{Apache2}{TrunkVariable}

For example:

    %{REQUEST_URI}
    # or
    %{md5:"some string"}
    # or
    %{:sub(s/\b\w+\b/Peter/, "John"):}
    # or a reference to previous regular expression capture groups
    $1, $2, etc..

See L</word> and L</cond> regular expression for more on those.

The capture names are:

=over 4

=item I<rebackref>

Contains the regular expression back reference such as C<$1>, C<$2>, etc

But without the leading dollar sign nor the enclosing accolade, if any, thus in the example of C<$1> or C<${1}> I<rebackref> would be C<1>

=item I<variable>

Contains the entire capture block

=item I<var_backref>

Contains the regular expression back reference such as C<$1>, C<$2>, etc

This includes the leadaing dollar sign and any enclosing accolade, if any, such as C<${1}>

=item I<var_cond>

If this is a condition inside a variable, such as:

    %{:$ap_true == $ap_false}

=item I<var_func>

Contains the text for the function and its arguments if this is a function.

=item I<var_func_args>

Contains the function arguments.

=item I<var_func_name>

Contains the function name.

=item I<var_word>

A variable containing a word. See L</word> for more information about word expressions.

=item I<varname>

Contains the variable name without the percent sign or dollar sign (if legacy regular expression is enabled) or the possible surrounding accolades

=back

=head2 word

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

    $RE{Apache2}{TrunkWord}

This is the most complex regular expression used, since it uses all the others and can recurse deeply

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

See L</string>, L</word>, L</variable>, L</sub>, L</join>, L</function> regular expression for more on those.

The capture names are:

=over 4

=item I<word>

Contains the entire capture block

=item I<word_digits>

If the word is actually digits, thise contains those digits.

=item I<word_dot_word>

This contains the text when two words are separated by a dot.

=item I<word_enclosed>

Contains the value of the word enclosed by single or double quotes or by surrounding parenthesis.

=item I<word_function>

Contains the word containing a L</function>

=item I<word_join>

Contains the word containing a L</join>

=item I<word_quote>

If the word is enclosed by single or double quote, this contains the single or double quote character

=item I<word_sub>

If the word is a substitution, this contains tha substitution

=item I<word_variable>

Contains the word containing a L</variable>

=back

=head2 words

BNF:

    word
    | word "," list

    $RE{Apache2}{TrunkWords}

For example:

    "Jack"
    # or
    "John", {"Peter", "Paul"}
    # or
    sub(s/\b\w+\b/Peter/, "John"), {"Peter", "Paul"}

See L</word> and L</list> regular expression for more on those.

It is different from L</words> in L</"APACHE2 EXPRESSION"> in that it uses L</list> instead of L</word>

The capture names are:

=over 4

=item I<words>

Contains the entire capture block

=item I<words_word>

Contains the word

=item I<words_list>

Contains the list

=back

=head1 LEGACY

When using legacy mode, the regular expressions are more laxed in what they accept around 3 types of expressions:

=over

=item 1. I<comp>

Same as L</comp>, and it extends it by adding support for legacy regular expression, i.e. without using the tilde (C<~>). For example :

    $HTTP_COOKIES = /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/

In current version of Apache2 expression this would rather be writen as:

    %{HTTP_COOKIES} =~ /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/

Both are supported in legacy expressions.

The additional capture groups available are:

=over 4

=item I<comp_in_regexp_legacy>

Contains the entire legacy regular expression.

=item I<comp_regexp> (unchanged)

Contains the regular expression.

=item I<comp_regexp_op>

Contains the operator, which may be C<=>, or C<==>, or C<!=>

=item I<comp_word> (unchanged)

Contains the word being compared

=back

=item 2. I<cond>

It is the same as L</cond>, except it also accepts a vanilla variable as valid condition, such as: C<$REQUEST_URI>, so that expression as below would work :

    !$REQUEST_URI

It adds the following capture groups:

=over 4

=item I<cond_variable>

Contains the variable used in the condition, including the leading dollar or percent sign and possible surrounding accolades.

=back

=item 3. I<variable>

Same as L</variable>, but is extended to accept vanilla variable such as C<$REQUEST_URI>. In current Apache2 expressions, a variable is anoted by using percent sign and potentially surounding it with accolades. For example :

    %{REQUEST_URI}

Also legacy variable includes regular expression back reference such as C<$1>, C<$2>, etc.

Its capture groups names are:

=over 8

=item I<variable>

Contains the entire variable.

=item I<varname>

Contains the variable name without dollar or percent sign no possible surrounding accolades.

=item I<var_backref>

The regular expression back reference including the dollar sign and possible surrounding accolades. For example: C<$1> or C<${1}>

=item I<rebackref>

The regular expression back reference excluding the dollar sign and possible surrounding accolades. For example: C<$1> or C<${1}> would mean I<rebackref> would contain C<1>

=item I<var_func_name>

The variable-embedded function name

=item I<var_func_args>

The variable-embedded function arguments

=back

=item 4. I<word>

I<word> is extended to also accept a regular expression back refernece such as C<$1>, C<$2>, etc.

=back

=head1 CAVEAT

Functions need to have their arguments enclosed in parenthesis. For example:

    %{REMOTE_ADDR} -in split s/.*?IP Address:([^,]+)/$1/, PeerExtList('subjectAltName')

will not work, but the following will:

    %{REMOTE_ADDR} -in split(s/.*?IP Address:([^,]+)/$1/, PeerExtList('subjectAltName'))

Maybe this will be adjusted in future versions.

=head1 CHANGES & CONTRIBUTIONS

Feel free to reach out to the author for possible corrections, improvements, or suggestions.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://httpd.apache.org/docs/current/expr.html> and 
L<https://httpd.apache.org/docs/trunk/en/expr.html>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
