##----------------------------------------------------------------------------
## Module Generic - ~/scripts/Apache2.pm
## Version v0.1.1
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/02/14
## Modified 2021/02/17
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
    our $VERSION = 'v0.1.1';
    our $DEBUG   = 1;
    our $indent;
    ## Ref: <http://httpd.apache.org/docs/trunk/en/expr.html>
    our $UNARY_OP   = qr/\-[a-zA-Z]/;
    our $DIGIT      = qr/[0-9]/;
    our $REGPATTERN = qr/(?>\\[[:cntrl:]\/]|[^[:cntrl:]\/])*+/;
    our $REGFLAGS   = qr/[i|s|m|g]+/;
    our $REGSEP     = qr/[\/\#\$\%\^\|\?\!\'\"\,\;\:\.\_\-]/;
    our $FUNCNAME   = qr/[a-zA-Z_]\w*/;
    our $VARNAME    = qr/[a-zA-Z_]\w*/;
    our $TEXT       = qr/[^[:cntrl:]]/;
    our $ap_true    = do{ bless( \( my $dummy = 1 ) => "Regexp::Common::Apache2::Boolean" ) };
    our $ap_false   = do{ bless( \( my $dummy = 0 ) => "Regexp::Common::Apache2::Boolean" ) };
    our @EXPORT_OK  = qw( $ap_true $ap_false );
    our $REGEXP     = {};
    our $TRUNK      = {};
    ## Legacy regular expression
    ## <http://httpd.apache.org/docs/trunk/en/mod/mod_include.html#legacyexpr>
    our $REGEXP_LEGACY = {};
};

INIT
{
    $REGEXP =
    {
    unary_op    => $UNARY_OP,
    ## <any US-ASCII digit "0".."9">
    digit       => $DIGIT,
    ## 1*(DIGIT)
    digits      => qr/${DIGIT}{1,}/,
    ## "$" DIGIT
    ## As per Apache apr_expr documentation, regular expression back reference go from 1 to 9 with 0 containing the entire regexp
    rebackref   => qr/\$${DIGIT}/,
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
        (?:\/(?<regpattern>${REGPATTERN})\/(?<regflags>${REGFLAGS})?)
        |
        (?:m(?<regsep>${REGSEP})(?<regpattern>(?>\\\g{regsep}|(?!\g{regsep}).)*+)\g{regsep}(?<regflags>${REGFLAGS})?)
    )/x,
    funcname	=> $FUNCNAME,
    varname	    => $VARNAME,
    ## <any OCTET except CTLs>
    text	    => $TEXT,
    ## 0*(TEXT)
    cstring	    => qr/[^[:cntrl:]]+/,
    };
    
    ## cstring
    ## | variable
    ## | rebackref
    $REGEXP->{substring} = qr/
    (?<substring>
        (?:$REGEXP->{cstring})
        |
        (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
            (?:
                (?&variable)
            )
        )
        |
        (?(?=\$\{?${DIGIT}\}?\b)
            \$${DIGIT}
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )


        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable))[[:blank:]\h]+(?:$TEXT|&variable))
                (?:(?-1)[[:blank:]\h]+(?&substring_recur))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring_recur) # Recurse on the entire substring regexp
            )
        )
        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring_recur>
            (?:$REGEXP->{cstring})
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
            )
        )

    )
    /x;
    ## substring
    ## | string substring
    $REGEXP->{string} = qr/
    (?<string>
        (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable))[[:blank:]\h]+(?:$TEXT|&variable))
            (?:(?R)[[:blank:]\h]+(?&substring))
        )
        |
        (?(?=(?:$TEXT|&variable))
            (?&substring) # Recurse on the entire substring regexp
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string_recur>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable))[[:blank:]\h]+(?:$TEXT|&variable))
                (?:(?-1)[[:blank:]\h]+(?&substring))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring) # Recurse on the entire substring regexp
            )
        )
        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string_recur))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string_recur))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )
        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
            )
        )

    )/x;

    ## "true" 
    ## | "false"
    ## | "!" cond
    ## | cond "&&" cond
    ## | cond "||" cond
    ## | "(" cond ")"
    ## | comp
    $REGEXP->{cond} = qr/
    (?<cond>
        (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
            (?:\([[:blank:]\h]*(?&cond_recur)[[:blank:]\h]*\))
        )
        |
        (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+))) # Recurse on the entire comp regexp
            (?:
                (?&comp)
            )
        )
        |
        (?(?=\![[:blank:]\h]*(?:(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))) # Recurring the entire COND expression
            (?<cond_neg>\![[:blank:]\h]*(?&cond_recur))
        )
        |
        (?(?=(?:.*?)[[:blank:]\h]*\&\&[[:blank:]\h]*(?:.*?))
            (?<cond_and>(?&cond_recur)[[:blank:]\h]*\&\&[[:blank:]\h]*(?&cond_recur))
        )
        |
        (?(?=(?:.*?)[[:blank:]\h]*\|\|[[:blank:]\h]*(?:.*?))
            (?<cond_or>(?&cond_recur)[[:blank:]\h]*\|\|[[:blank:]\h]*(?&cond_recur))
        )
        |
        (?(?=$Regexp::Common::Apache2::ap_true)
            (?<cond_true>$Regexp::Common::Apache2::ap_true)
        )
        |
        (?(?=$Regexp::Common::Apache2::ap_false)
            (?<cond_false>$Regexp::Common::Apache2::ap_false)
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond_recur>
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                (?:\([[:blank:]\h]*(?&cond_recur)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?(?=\![[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                (?:\![[:blank:]\h]*(?&cond_recur))
            )
            |
            (?(?=(?:.*?)[[:blank:]\h]*\&\&[[:blank:]\h]*(?:.*?))
                (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            )
            |
            (?(?=(?:.*?)[[:blank:]\h]*\|\|[[:blank:]\h]*(?:.*?))
                (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            )
            |
            (?(?=$Regexp::Common::Apache2::ap_true)
                (?:$Regexp::Common::Apache2::ap_true)
            )
            |
            (?(?=$Regexp::Common::Apache2::ap_false)
                (?:$Regexp::Common::Apache2::ap_false)
            )
        )
        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )
        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
            )
        )

    )
    /xi;

    ## funcname "(" words ")"
    ## -> Same as LISTFUNC
    $REGEXP->{function}	= qr/
    (?<function>
        (?(?=[a-zA-Z\_]\w+\()
            (?<function_name>[a-zA-Z\_]\w+)\([[:blank:]\h]*(?<function_args>(?&words))[[:blank:]\h]*\)
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<function_recur>
            (?(?=[a-zA-Z\_]\w+\()
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\) # R recurring on the entire words regexp
            )
        )
        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function_recur)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )
        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
            )
        )

    )
    /x;

    ## listfuncname "(" words ")"
    ## Use recursion at execution phase for words because it contains dependencies -> list -> listfunc
    #(??{$REGEXP->{words}})
    $REGEXP->{listfunc}	= qr/
    (?<listfunc>
        (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
            (?:
                (?<listfunc_name>[a-zA-Z\_]\w+)
                \(
                [[:blank:]\h]*
                (?<listfunc_args>(?&words))
                [[:blank:]\h]*
                \)
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))(?&stringcomp))
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))(?&integercomp))
            |
            (?:
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?&word) # Recurse on the entire word regexp
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?&word) # Recurse on the entire word regexp
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                    |
                    \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                )
                [[:blank:]\h]+
                (?&word) # Recurse on the entire word regexp
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?&word) # Recurse on the entire word regexp
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                (?&listfunc_recur)
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?&word) # Recurse on the entire word regexp
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $REGEXP->{regex}
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?&word) # Recurse on the entire word regexp
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc_recur>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )
        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
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
            (?<word_digits>$REGEXP->{digits})
        )
        |
        (?(?=\'(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
            (?<word_quote>\')(?<word_enclosed>(?&string))\'
        )
        |
        (?(?=\"(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
            (?<word_quote>\")(?<word_enclosed>(?&string))\"
        )
        |
        (?:
            (?<word_dot_word>[^[:cntrl:]]+\.[^[:cntrl:]]+)
        )
        |
        (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
            (?<word_function>(?&function))
        )
        |
        (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
            (?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
            (?<word_variable>(?&variable))
        )
        |
        (?(?=\$\{?${DIGIT}\}?\b)
            \$${DIGIT}
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))(?&stringcomp))
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))(?&integercomp))
            |
            (?:
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?&word_recur) # Recurse on the entire word regexp
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?&word_recur) # Recurse on the entire word regexp
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                    |
                    \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                )
                [[:blank:]\h]+
                (?&word_recur) # Recurse on the entire word regexp
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?&word_recur) # Recurse on the entire word regexp
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                (?&listfunc)
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?&word_recur) # Recurse on the entire word regexp
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $REGEXP->{regex}
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?&word_recur) # Recurse on the entire word regexp
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                \}
            )
        )
        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word_recur)) # Recurse on the entire word regexp
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word_recur)) # Recurse on the entire word regexp
                )
            )
        )
        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?<stringcomp_worda>(?&word_recur)) # Recurse on the entire word regexp
                [[:blank:]\h]+
                (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word_recur)) # Recurse on the entire word regexp
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )
        (?<word_recur>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )
        (?<words>
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?-1)
                    )
                    |
                    (?:
                        (?&word)
                    )
                )
            )
        )
    )
    /x;
    
    ## "%{" varname "}"
    ## | "%{" funcname ":" funcargs "}"
    ## | "%{:" word ":}"
    ## | "%{:" cond ":}"
    ## | rebackref
    $REGEXP->{variable} = qr/
    (?<variable>
        (?:
            \%\{
                (?(?=${FUNCNAME}\:)
                    (?<var_func_name>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                )
            \}
        )
        |
        (?:
            \%\{
                (?(?=${VARNAME})
                    (?<varname>${VARNAME})
                )
            \}
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<substring>
            (?:
                (?:$REGEXP->{cstring})
                |
                (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))(?R)) # Recurse on the entire variable regexp if it looks like one
            )
        )
        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<variable_recur>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )
        (?<word>
            (?:$REGEXP->{digits})
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?:[^[:cntrl:]]+)\.(?:[^[:cntrl:]]+)
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable_recur))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )
        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
            )
        )

    )
    /x;

    ## word
    ## | word "," list
    $REGEXP->{words} = qr/
    (?<words>
        (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
            (?:
                (?:
                    (?<words_word>(?&word))
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list>(?-1))
                )
                |
                (?:
                    (?<words_word>(?&word))
                )
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\()
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words_recur)[[:blank:]\h]*\) # R recurring on the entire words regexp
            )
        )
        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words_recur) # R recurring on the entire words regexp
                    [[:blank:]\h]*
                    \)
                )
            )
        )
        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
        )

        (?<words_recur>
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\,[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?-1)
                )
                |
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
        )
    )
    /x;

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
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp_recur) # Recurse on the entire stringcomp regexp
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )
        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp_recur>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )
        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
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
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp) # Recurse on the entire stringcomp regexp
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp_recur)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )
        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp_recur>
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )
        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
            )
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
        (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
            (?:
                (?<comp_stringcomp>(?&stringcomp))
            )
        )
        |
        (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
            (?:
                (?<comp_integercomp>(?&integercomp))
            )
        )
        |
        (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
            (?<comp_unary>
                \-(?<comp_unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_word>(?&word))
            )
        )
        |
        (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
            (?<comp_binary>
                (?<comp_worda>(?&word))
                [[:blank:]\h]+
                (?:
                    (?<comp_binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                    |
                    \-(?<comp_binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                )
                [[:blank:]\h]+
                (?<comp_wordb>(?&word))
            )
        )
        |
        (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
            (?<comp_word_in_listfunc>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                (?<comp_listfunc>(?&listfunc))
            )
        )
        |
        (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
            (?<comp_word_in_regexp>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=|\!]\~)
                [[:blank:]\h]+
                (?<comp_regexp>$REGEXP->{regex})
            )
        )
        |
        (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
            (?<comp_word_in_list>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_list>(?&words))
                    [[:blank:]\h]*
                \}
            )
        )
    )
    (?(DEFINE)
        (?<comp_recur>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp) # Recurse on the entire stringcomp regexp
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )
        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
            )
        )

    )
    /x;

    ## cond
    ## | string
    $REGEXP->{expr} = qr/
    (?<expr>
        (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
            (?:
                (?<expr_cond>(?&cond))
            )
        )
        |
        (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
            (?:
                (?<expr_string>(?&string))
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
            )
        )

    )
    /x;

    ## Trunk regular expression
    @$TRUNK{qw( unary_op digit digits rebackref regpattern regflags regsep regex funcname varname text cstring )} =
    @$REGEXP{qw( unary_op digit digits rebackref regpattern regflags regsep regex funcname varname text cstring )};
    
    ## cstring
    ## | variable
    ## | rebackref
    $TRUNK->{substring} = qr/
    (?<substring>
        (?:$TRUNK->{cstring})
        |
        (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
            (?:
                (?&variable)
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable))[[:blank:]\h]+(?:$TEXT|&variable))
                (?:(?-1)[[:blank:]\h]+(?&substring_recur))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring_recur) # Recurse on the entire substring regexp
            )
        )
        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring_recur>
            (?:$TRUNK->{cstring})
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )
        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
        )

    )
    /x;
    ## substring
    ## | string substring
    $TRUNK->{string} = qr/
    (?<string>
        (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable))[[:blank:]\h]+(?:$TEXT|&variable))
            (?:(?R)[[:blank:]\h]+(?&substring))
        )
        |
        (?(?=(?:$TEXT|&variable))
            (?&substring) # Recurse on the entire substring regexp
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string_recur>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable))[[:blank:]\h]+(?:$TEXT|&variable))
                (?:(?-1)[[:blank:]\h]+(?&substring))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring) # Recurse on the entire substring regexp
            )
        )
        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $TRUNK->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string_recur))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string_recur))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?:\((?-1)\)) # Recurse on the entire word regex
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )
        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
        )

    )/x;

    ## "true" 
    ## | "false"
    ## | "!" cond
    ## | cond "&&" cond
    ## | cond "||" cond
    ## | "(" cond ")"
    ## | comp
    $TRUNK->{cond} = qr/
    (?<cond>
        (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
            (?:\([[:blank:]\h]*(?&cond_recur)[[:blank:]\h]*\))
        )
        |
        (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+))) # Recurse on the entire comp regexp
            (?:
                (?&comp)
            )
        )
        |
        (?(?=\![[:blank:]\h]*(?:(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))) # Recurring the entire COND expression
            (?<cond_neg>\![[:blank:]\h]*(?&cond_recur))
        )
        |
        (?(?=(?:.*?)[[:blank:]\h]*\&\&[[:blank:]\h]*(?:.*?))
            (?<cond_and>(?&cond_recur)[[:blank:]\h]*\&\&[[:blank:]\h]*(?&cond_recur))
        )
        |
        (?(?=(?:.*?)[[:blank:]\h]*\|\|[[:blank:]\h]*(?:.*?))
            (?<cond_or>(?&cond_recur)[[:blank:]\h]*\|\|[[:blank:]\h]*(?&cond_recur))
        )
        |
        (?(?=$Regexp::Common::Apache2::ap_true)
            (?<cond_true>$Regexp::Common::Apache2::ap_true)
        )
        |
        (?(?=$Regexp::Common::Apache2::ap_false)
            (?<cond_false>$Regexp::Common::Apache2::ap_false)
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond_recur>
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                (?:\([[:blank:]\h]*(?&cond_recur)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?(?=\![[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                (?:\![[:blank:]\h]*(?&cond_recur))
            )
            |
            (?(?=(?:.*?)[[:blank:]\h]*\&\&[[:blank:]\h]*(?:.*?))
                (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            )
            |
            (?(?=(?:.*?)[[:blank:]\h]*\|\|[[:blank:]\h]*(?:.*?))
                (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            )
            |
            (?(?=$Regexp::Common::Apache2::ap_true)
                (?:$Regexp::Common::Apache2::ap_true)
            )
            |
            (?(?=$Regexp::Common::Apache2::ap_false)
                (?:$Regexp::Common::Apache2::ap_false)
            )
        )
        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond_recur)
                    )
                \:\}
            )
            |
            (?<var_backref>$TRUNK->{rebackref})
        )
        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
        )

    )
    /xi;

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

    ## regex | regsub
    $TRUNK->{regany} = qr/
    (?<regany>
        (?:
            (?<regany_regex>$TRUNK->{regex})
            |
            (?(?=(?:[s]${REGSEP}))
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

    ## "sub" ["("] regsub "," word [")"]
    $TRUNK->{sub} = qr/
    (?<sub>
        sub\(
            [[:blank:]\h]*
            (?<sub_regsub>(?&regsub))
            [[:blank:]\h]*
            \,
            [[:blank:]\h]*
            (?(?=(?:\([[:blank:]\h]*)?(?:[0-9]|(?:["']\w)|sub|join|${FUNCNAME}|\%\{))
                (?<sub_word>
                    (?&word)
                )
            )
            [[:blank:]\h]*
        \)
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub_recur>
            sub\(
                [[:blank:]\h]*
                (?<sub_regsub>(?&regsub))
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:[0-9]|(?:["']\w)|sub|join|${FUNCNAME}|\%\{))
                    (?<sub_word>
                        (?&word)
                    ) # Recurse on the entire word regexp
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $TRUNK->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub_recur)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?:\((?-1)\)) # Recurse on the entire word regex
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )
        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
        )

    )
    /x;

    ## funcname "(" words ")"
    ## -> Same as LISTFUNC
    $TRUNK->{function}	= qr/
    (?<function>
        (?(?=[a-zA-Z\_]\w+\()
            (?<function_name>[a-zA-Z\_]\w+)\([[:blank:]\h]*(?<function_args>(?&words))[[:blank:]\h]*\)
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function_recur>
            (?(?=[a-zA-Z\_]\w+\()
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\) # R recurring on the entire words regexp
            )
        )
        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $TRUNK->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function_recur)
                )
            )
            |
            (?:\((?-1)\)) # Recurse on the entire word regex
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )
        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
        )

    )
    /x;

    ## listfuncname "(" words ")"
    ## Use recursion at execution phase for words because it contains dependencies -> list -> listfunc
    #(??{$TRUNK->{words}})
    $TRUNK->{listfunc}	= qr/
    (?<listfunc>
        (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
            (?:
                (?<listfunc_name>[a-zA-Z\_]\w+)
                \(
                [[:blank:]\h]*
                (?<listfunc_args>(?&words))
                [[:blank:]\h]*
                \)
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))(?&stringcomp))
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))(?&integercomp))
            |
            (?:
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?&word) # Recurse on the entire word regexp
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?&word) # Recurse on the entire word regexp
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                    |
                    \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                )
                [[:blank:]\h]+
                (?&word) # Recurse on the entire word regexp
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?&word) # Recurse on the entire word regexp
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                (?&listfunc_recur)
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?&word) # Recurse on the entire word regexp
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $TRUNK->{regex}
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?&word) # Recurse on the entire word regexp
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?&list)
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<list_func>(?&listfunc_recur))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words)) # R recurring on the entire words regexp
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?-1)[[:blank:]\h]*\)
                )
            )
        )
        (?<listfunc_recur>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )
        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
        )

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
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
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
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split_recur))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?-1)[[:blank:]\h]*\)
                )
            )
        )
        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
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
        (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
            (?:
                (?<list_func>(?&listfunc))
            )
        )
        |
        (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
            (?:
                \{
                    [[:blank:]\h]*
                    (?<list_words>(?&words))
                    [[:blank:]\h]*
                \}
            )
        )
        |
        (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
            (?:
                (?<list_split>(?&split))
            )
        )
        |
        (?(?=\([[:blank:]\h]*)
            (?:
                \([[:blank:]\h]*(?<list_list>(?&list_recur))[[:blank:]\h]*\)
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list_recur)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list_recur))
                )
                [[:blank:]\h]*
            \)
        )
        (?<list_recur>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?<list_list>(?&list_recur))[[:blank:]\h]*\)
                )
            )
        )
        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list_recur)
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words>
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?&list_recur)
                    )
                    |
                    (?:
                        (?&word)
                    )
                )
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
                (?:(?<join_list>(?&list))[[:blank:]]*\,[[:blank:]]*(?<join_word>(?&word)))
                |
                (?:(?<join_list>(?&list)))
            )
            [[:blank:]\h]*
        \)
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join_recur>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $TRUNK->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join_recur)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?:\((?-1)\)) # Recurse on the entire word regex
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )
        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
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
        (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
            (?<word_sub>(?&sub))
        )
        |
        (?:
            (?<word_digits>$TRUNK->{digits})
        )
        |
        (?(?=\'(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
            (?<word_quote>\')(?<word_enclosed>(?&string))\'
        )
        |
        (?(?=\"(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
            (?<word_quote>\")(?<word_enclosed>(?&string))\"
        )
        |
        (?:
            (?<word_dot_word>[^[:cntrl:]]+\.[^[:cntrl:]]+)
        )
        |
        (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
            (?<word_join>(?&join))
        )
        |
        (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
            (?<word_function>(?&function))
        )
        |
        (?: # Recurse on the entire word regex
            \((?<word_enclosed>(?&word_recur))\)
        )
        |
        (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
            (?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
            (?<word_variable>(?&variable))
        )
        |
        (?(?=\$\{?${DIGIT}\}?\b)
            \$${DIGIT}
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))(?&stringcomp))
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))(?&integercomp))
            |
            (?:
                \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?&word_recur) # Recurse on the entire word regexp
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?&word_recur) # Recurse on the entire word regexp
                [[:blank:]\h]+
                (?:
                    (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                    |
                    \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                )
                [[:blank:]\h]+
                (?&word_recur) # Recurse on the entire word regexp
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?&word_recur) # Recurse on the entire word regexp
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                (?&listfunc)
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?&word_recur) # Recurse on the entire word regexp
                [[:blank:]\h]+
                [\=|\!]\~
                [[:blank:]\h]+
                $TRUNK->{regex}
            )
            |
            (?(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?&word_recur) # Recurse on the entire word regexp
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?&list)
                    [[:blank:]\h]*
                \}
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word_recur)) # Recurse on the entire word regexp
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word_recur)) # Recurse on the entire word regexp
                )
            )
        )
        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word_recur))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )
        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?:
                        (?&word_recur)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )
        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?<stringcomp_worda>(?&word_recur)) # Recurse on the entire word regexp
                [[:blank:]\h]+
                (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                [[:blank:]\h]+
                (?<stringcomp_wordb>(?&word_recur)) # Recurse on the entire word regexp
            )
        )
        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?<sub_regsub>(?&regsub))
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:[0-9]|(?:["']\w)|sub|join|${FUNCNAME}|\%\{))
                    (?<sub_word>
                        (?&word_recur)
                    ) # Recurse on the entire word regexp
                )
                [[:blank:]\h]*
            \)
        )
        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                        (?<var_word>(?&word_recur))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$TRUNK->{rebackref})
        )
        (?<word_recur>
            (?:
                $TRUNK->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?:\((?-1)\)) # Recurse on the entire word regex
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )
        (?<words>
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?:
                        (?&word_recur)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?&list)
                    )
                    |
                    (?:
                        (?&word_recur)
                    )
                )
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
            \%\{
                (?(?=${FUNCNAME}\:)
                    (?<var_func_name>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                )
            \}
        )
        |
        (?:
            \%\{
                (?(?=${VARNAME})
                    (?<varname>${VARNAME})
                )
            \}
        )
        |
        (?:
            \%\{\:
                (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                    (?<var_cond>(?&cond))
                )
            \:\}
        )
        |
        (?:
            \%\{\:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?<var_word>(?&word))
                )
            \:\}
        )
        |
        (?<var_backref>$TRUNK->{rebackref})
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<substring>
            (?:
                (?:$TRUNK->{cstring})
                |
                (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))(?R)) # Recurse on the entire variable regexp if it looks like one
            )
        )
        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<variable_recur>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$TRUNK->{rebackref})
        )
        (?<word>
            (?:$TRUNK->{digits})
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?:\((?-1)\))
            |
            (?:[^[:cntrl:]]+)\.(?:[^[:cntrl:]]+)
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable_recur))
                )
            )
        )
        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
        )

    )
    /x;

    ## word
    ## | word "," list
    $TRUNK->{words} = qr/
    (?<words>
        (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
            (?:
                (?:
                    (?<words_word>(?&word))
                    [[:blank:]\h]*\,[[:blank:]\h]*
                    (?<words_list>(?&list))
                )
                |
                (?:
                    (?<words_word>(?&word))
                )
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\()
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words_recur)[[:blank:]\h]*\) # R recurring on the entire words regexp
            )
        )
        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words_recur)) # R recurring on the entire words regexp
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?-1)[[:blank:]\h]*\)
                )
            )
        )
        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words_recur) # R recurring on the entire words regexp
                    [[:blank:]\h]*
                    \)
                )
            )
        )
        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words_recur>
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?:
                        (?&word)
                        [[:blank:]\h]*\,[[:blank:]\h]*
                        (?&list)
                    )
                    |
                    (?:
                        (?&word)
                    )
                )
            )
        )
    )
    /x;

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
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp_recur) # Recurse on the entire stringcomp regexp
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $TRUNK->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp_recur>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )
        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
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
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp) # Recurse on the entire stringcomp regexp
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp_recur)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $TRUNK->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp_recur>
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )
        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
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
    $TRUNK->{comp} = qr/
    (?<comp>
        (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
            (?:
                (?<comp_stringcomp>(?&stringcomp))
            )
        )
        |
        (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
            (?:
                (?<comp_integercomp>(?&integercomp))
            )
        )
        |
        (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
            (?<comp_unary>
                \-(?<comp_unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_word>(?&word))
            )
        )
        |
        (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
            (?<comp_binary>
                (?<comp_worda>(?&word))
                [[:blank:]\h]+
                (?:
                    (?<comp_binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                    |
                    \-(?<comp_binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                )
                [[:blank:]\h]+
                (?<comp_wordb>(?&word))
            )
        )
        |
        (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
            (?<comp_word_in_listfunc>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                (?<comp_listfunc>(?&listfunc))
            )
        )
        |
        (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
            (?<comp_word_in_regexp>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=|\!]\~)
                [[:blank:]\h]+
                (?<comp_regexp>$TRUNK->{regex})
            )
        )
        |
        (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
            (?<comp_word_in_list>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_list>(?&list))
                    [[:blank:]\h]*
                \}
            )
        )
    )
    (?(DEFINE)
        (?<comp_recur>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp) # Recurse on the entire stringcomp regexp
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $TRUNK->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1)) # Recurring the entire COND expression
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+))) # Recurse on the entire comp regexp
                (?:
                    (?&comp_recur)
                )
            )
            |
            (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
        )
        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
        )

    )
    /x;

    ## cond
    ## | string
    $TRUNK->{expr} = qr/
    (?<expr>
        (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
            (?:
                (?<expr_cond>(?&cond))
            )
        )
        |
        (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
            (?:
                (?<expr_string>(?&string))
            )
        )
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&list)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))
                (?:
                    (?&comp)
                )
            )
            |
            (?:\([[:blank:]\h]*(?&cond)[[:blank:]\h]*\)) # Need to call ourself rather than use (?-1), because the latter will loop without moving forward in the string
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<join>
            join\(
                [[:blank:]\h]*
                (?:
                    (?:(?&list)[[:blank:]]*\,[[:blank:]]*(?&word))
                    |
                    (?:(?&list))
                )
                [[:blank:]\h]*
            \)
        )

        (?<list>
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<list_func>(?&listfunc))
                )
            )
            |
            (?(?=\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    \{
                        [[:blank:]\h]*
                        (?<list_words>(?&words))
                        [[:blank:]\h]*
                    \}
                )
            )
            |
            (?(?=(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP}))))
                (?:
                    (?<list_split>(?&split))
                )
            )
            |
            (?(?=\([[:blank:]\h]*)
                (?:
                    \([[:blank:]\h]*(?&list)[[:blank:]\h]*\)
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<regany>
            (?:
                $REGEXP->{regex}
                |
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
            )
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
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?:
                        (?&word)
                    )
                    |
                    (?:
                        (?&list)
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<sub>
            sub\(
                [[:blank:]\h]*
                (?(?=(?:[s]${REGSEP}))
                    (?&regsub)
                )
                [[:blank:]\h]*
                \,
                [[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?<sub_word>
                        (?>(?&word))
                    )
                )
                [[:blank:]\h]*
            \)
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                        (?<var_word>(?&word))
                    )
                \:\}
            )
            |
            (?:
                \%\{\:
                    (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+)))))
                        (?&cond)
                    )
                \:\}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
            |
            (?(?=(?:\bsub\([[:blank:]\h]*(?:[s]${REGSEP})))
                (?&sub)
            )
            |
            (?(?=(?:join\([[:blank:]\h]*(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))))
                (?:
                    (?&join)
                )
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:\([[:blank:]\h]*)?(?:(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))|(?:split\([[:blank:]\h]*(?:(?:\/${REGPATTERN})|(?:[m]${REGSEP})))|(?:\{[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))))
                    (?&list)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|sub|join|${FUNCNAME}|\%\{)))
                (?&word)
            )
        )

    )
    /x;
    
    ## Here is the addition to be compliant with expression from 2.3.12 and before,
    ## ie old fashioned variable such as $REQUEST_URI instead of the modern version %{REQUEST_URI}
    $REGEXP_LEGACY->{variable} = qr/
    (?<variable>
        (?:\$(?:[a-zA-Z\_]\w*))
        |
        (?:
            \%\{
                (?(?=${FUNCNAME}\:)
                    (?<var_func_name>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                )
            \}
        )
        |
        (?:
            \%\{
                (?(?=${VARNAME})
                    (?<varname>${VARNAME})
                )
            \}
        )
        |
        (?<var_backref>$REGEXP->{rebackref})
    )
    (?(DEFINE)
        (?<comp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )

        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<substring>
            (?:$REGEXP->{cstring})
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))(?&variable_recur))
        )
        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<variable_recur>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
            |
            (?<var_backref>$REGEXP->{rebackref})
        )
        (?<word>
            (?:$REGEXP->{digits})
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?:[^[:cntrl:]]+)\.(?:[^[:cntrl:]]+)
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable_recur))
                )
            )
        )
        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
            )
        )

    )
    /x;

    ## Here we allow regular expression to be writen like: expression = //, ie without the ~
    $REGEXP_LEGACY->{comp} = qr/
    (?<comp>
        (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
            (?:
                (?<comp_stringcomp>(?&stringcomp))
            )
        )
        |
        (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
            (?:
                (?<comp_integercomp>(?&integercomp))
            )
        )
        |
        (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
            (?<comp_unary>
                \-(?<comp_unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                [[:blank:]\h]+
                (?<comp_word>(?&word))
            )
        )
        |
        (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
            (?<comp_binary>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?:
                    (?<comp_binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                    |
                    \-(?<comp_binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                )
                [[:blank:]\h]+
                (?<comp_word>(?&word))
            )
        )
        |
        (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
            (?<comp_word_in_listfunc>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                (?<comp_listfunc>(?&listfunc))
            )
        )
        |
        (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
            (?<comp_in_regexp>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                (?<comp_regexp_op>[\=|\!]\~)
                [[:blank:]\h]+
                (?<comp_regexp>$REGEXP->{regex})
            )
        )
        |
        (?<comp_in_regexp_legacy>
            (?=(?:(?:.*?)[[:blank:]\h]+[\=\=|\=|\!\=][[:blank:]\h]+))
            (?<comp_word>(?&word))
            [[:blank:]\h]+
            (?<comp_regexp_op>[\=\=|\=|\!\=])
            [[:blank:]\h]+
            (?<comp_regexp>(?&regex))
        )
        |
        (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
            (?<comp_word_in_list>
                (?<comp_word>(?&word))
                [[:blank:]\h]+
                in
                [[:blank:]\h]+
                \{
                    [[:blank:]\h]*
                    (?<comp_list>(?&words))
                    [[:blank:]\h]*
                \}
            )
        )
    )
    (?(DEFINE)
        (?<comp_recur>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&stringcomp) # Recurse on the entire stringcomp regexp
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&integercomp)
                )
            )
            |
            (?(?=(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])))
                (?:
                    \-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R])
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch)))))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    (?:
                        (?<binaryop>\=\=|\=|\!\=|\<|\<\=|\>|\>\=)
                        |
                        \-(?<binaryop>ipmatch|strmatch|strcmatch|fnmatch)
                    )
                    [[:blank:]\h]+
                    (?&word)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    (?&listfunc)
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+[\=|\!]\~[[:blank:]\h]+))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    [\=|\!]\~
                    [[:blank:]\h]+
                    $REGEXP->{regex}
                )
            )
            |
            (?:(?=(?:(?:.*?)[[:blank:]\h]+in[[:blank:]\h]+\{))
                (?:
                    (?&word)
                    [[:blank:]\h]+
                    in
                    [[:blank:]\h]+
                    \{
                        [[:blank:]\h]*
                        (?&words)
                        [[:blank:]\h]*
                    \}
                )
            )
        )
        (?<cond>
            (?:$Regexp::Common::Apache2::ap_true)
            |
            (?:$Regexp::Common::Apache2::ap_false)
            |
            (?:\![[:blank:]\h]*(?-1)) # Recurring the entire COND expression
            |
            (?:(?-1)[[:blank:]\h]*\&\&[[:blank:]\h]*(?-1))
            |
            (?:(?-1)[[:blank:]\h]*\|\|[[:blank:]\h]*(?-1))
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?\!?(?:(?:(?:$Regexp::Common::Apache2::ap_true|$Regexp::Common::Apache2::ap_false)(?!\d))|(?:(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:(?:\=\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-?(?:eq|ne|lt|le|gt|ge)))[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))|(?:\-(?<unaryop>[d|e|f|s|L|h|F|U|A|n|z|T|R]))|(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]+(?:(?:\=\=|\=|\!\=|\<|\<\=|\>|\>\=)|(?:\-(?:ipmatch|strmatch|strcmatch|fnmatch))))|(?:(?:.*?)[[:blank:]\h]+(?:in|[\=|\!]\~)[[:blank:]\h]+))))) # Recurse on the entire comp regexp
                (?:
                    (?&comp_recur)
                )
            )
            |
            (?:\([[:blank:]\h]*(?-1)[[:blank:]\h]*\))
        )
        (?<function>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                [a-zA-Z\_]\w+\([[:blank:]\h]*(?&words)[[:blank:]\h]*\)
            )
        )

        (?<integercomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*\-?(?:eq|ne|lt|le|gt|ge)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<integercomp_worda>(?&word))
                    [[:blank:]\h]+
                    \-?(?:eq|ne|lt|le|gt|ge)
                    [[:blank:]\h]+
                    (?<integercomp_wordb>(?&word))
                )
            )
        )

        (?<listfunc>
            (?(?=[a-zA-Z\_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?:
                    (?<funcname>[a-zA-Z\_]\w+)
                    \(
                    [[:blank:]\h]*
                    (?&words)
                    [[:blank:]\h]*
                    \)
                )
            )
        )

        (?<string>
            (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                (?:(?&substring)[[:blank:]\h]+(?&string))
            )
            |
            (?(?=(?:$TEXT|&variable))
                (?&substring)
            )
        )

        (?<stringcomp>
            (?(?=(?:(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))(?:.*?)[[:blank:]\h]*(?:\=\=|\!\=|\<|\<\=|\>|\>\=)[[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?<stringcomp_worda>(?&word))
                    [[:blank:]\h]+
                    (?:\=\=|\!\=|\<|\<\=|\>|\>\=)
                    [[:blank:]\h]+
                    (?<stringcomp_wordb>(?&word))
                )
            )
        )

        (?<substring>
            (?:
                (?<substring_cstring>$REGEXP->{cstring})
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?&variable)
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
        )

        (?<variable>
            (?:
                \%\{
                    (?(?=${FUNCNAME}\:)
                        (?<var_func>${FUNCNAME})\:(?<var_func_args>(?>\\\}|[^\}])*+)
                    )
                \}
            )
            |
            (?:
                \%\{
                    (?(?=${VARNAME}\})
                        (?<varname>${VARNAME})
                    )
                \}
            )
        )

        (?<word>
            (?:
                $REGEXP->{digits}
            )
            |
            (?:
                \'
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \'
            )
            |
            (?:
                \"
                (?(?=(?:(?:(?:$TEXT|&variable)[[:blank:]\h]+(?:$TEXT|&variable))|(?:$TEXT|&variable)))
                   (?<word_enclosed>(?&string))
                )
                \"
            )
            |
            (?(?=(?:[a-zA-Z_]\w+\([[:blank:]\h]*(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{))))
                (?:
                    (?&function)
                )
            )
            |
            (?(?=(?:(?:\%\{)|(?:\$\{?)${VARNAME}))
                (?:
                    (?<word_variable>(?&variable))
                )
            )
            |
            (?(?=\$\{?${DIGIT}\}?\b)
                \$${DIGIT}
            )
            |
            (?:
                (?:[^[:cntrl:]]+\.[^[:cntrl:]]+)
            )
        )

        (?<words>
            (?:
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
                [[:blank:]\h]*\,[[:blank:]\h]*
                (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                    (?&word)
                )
            )
            |
            (?(?=(?:(?:\([[:blank:]\h]*)?(?:[0-9\"\']|${FUNCNAME}\(|\%\{)))
                (?&word)
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

    pattern name    => [qw( Apache2 LegacyVariable )],
            create  => $REGEXP_LEGACY->{variable};
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

    v0.1.1

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

=item I<cond_false>

Contains the false expression like:

    ($ap_false)

=item I<cond_neg>

Contains the expression if it is preceded by an exclamation mark, such as:

    !$ap_true

=item I<cond_or>

Contains the expression like:

    ($ap_true || $ap_true)

=item I<cond_true>

Contains the true expression like:

    ($ap_true)

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

The capture names are:

=over 4

=item I<function>

Contains the entire capture block

=item I<function_args>

Contains the list of arguments. In the example above, this would be C<Some string>

=item I<function_name>

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

    $RE{Apache2}{Function}

For example:

    base64("Some string")

This is quite similar to the L</function> regular expression

The capture names are:

=over 4

=item I<listfunc>

Contains the entire capture block

=item I<listfunc_args>

Contains the list of arguments. In the example above, this would be C<Some string>

=item I<listfunc_name>

The name of the function . In the example above, this would be C<base64>

=back

=head2 regex

BNF:

    "/" regpattern "/" [regflags]
    | "m" regsep regpattern regsep [regflags]

    $RE{Apache2}{Regex}

For example:

    /\w+/i
    # or
    m,\w+,i

The capture names are:

=over 4

=item I<regex>

Contains the entire capture block

=item I<regflags>

The regula expression modifiers. See L<perlre>

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

BNF: cstring | variable

    $RE{Apache2}{Substring}

For example:

    Jack
    # or
    %{REQUEST_URI}

See L</variable> and L</word> regular expression for more on those.

The capture names are:

=over 4

=item I<substring>

Contains the entire capture block

=back

=head2 variable

BNF:

    "%{" varname "}"
    | "%{" funcname ":" funcargs "}"

    $RE{Apache2}{Variable}
    # or
    $RE{Apache2}{LegacyVariable}

For example:

    %{REQUEST_URI}
    # or
    %{md5:"some string"}

See L</word> and L</cond> regular expression for more on those.

The capture names are:

=over 4

=item I<variable>

Contains the entire capture block

=item I<var_cond>

If this is a condition inside a variable, such as:

    %{:$ap_true == $ap_false}

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

    $RE{Apache2}{TrunkFunction}

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

    $RE{Apache2}{TrunkRegex}

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

=item I<variable>

Contains the entire capture block

=item I<var_cond>

If this is a condition inside a variable, such as:

    %{:$ap_true == $ap_false}

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

There are 2 expressions that can be used as legacy:

=over

=item I<comp>

See L</comp>

=item I<variable>

See L</variable>

=back

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
