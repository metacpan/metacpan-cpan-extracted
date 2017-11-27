package Perl::Tokenizer;

use utf8;
use 5.018;
use strict;
use warnings;

no warnings "experimental::smartmatch";

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(perl_tokens);

our $VERSION = '0.08';

=encoding utf8

=head1 NAME

Perl::Tokenizer - A tiny Perl code tokenizer.

=head1 VERSION

Version 0.08

=cut

my $make_esc_delim = sub {
    if ($_[0] eq '\\') {
        return qr{\\(.*?)\\}s;
    }

    my $delim = quotemeta shift;
    qr{$delim([^$delim\\]*+(?>\\.|[^$delim\\]+)*+)$delim}s;
};

my $make_end_delim = sub {
    if ($_[0] eq '\\') {
        return qr{.*?\\}s;
    }

    my $delim = quotemeta shift;
    qr{[^$delim\\]*+(?>\\.|[^$delim\\]+)*+$delim}s;
};

my %bdelims;
foreach my $d ([qw~< >~], [qw~( )~], [qw~{ }~], [qw~[ ]~]) {
    my @ed = map { quotemeta } @{$d};

    $bdelims{$d->[0]} = qr{
        $ed[0]
        (?>
            [^$ed[0]$ed[1]\\]+
                |
            \\.
                |
            (??{$bdelims{$d->[0]}})
        )*
        $ed[1]
    }xs;
}

# string - single quote
my $str_sq = $make_esc_delim->(q{'});

# string - double quote
my $str_dq = $make_esc_delim->(q{"});

# backtick - backquote
my $str_bq = $make_esc_delim->(q{`});

# regex - //
my $match_re = $make_esc_delim->(q{/});

# glob/readline
my $glob = $bdelims{'<'};

# Cache regular expressions that are generated dynamically
my %cache_esc;
my %cache_end;

# Double pairs
my $dpairs = qr{
    (?=
      (?(?<=\s)
                (.)
            |
                (\W)
     )
    )
    (??{$bdelims{$+} // ($cache_esc{$+} //= $make_esc_delim->($+))})
}x;

# Double pairs -- comments
my $dcomm = qr{
    \s* (?>(?<=\s)\# (?-s:.*) \s*)*
}x;

# Quote-like balanced (q{}, m//)
my $make_single_q_balanced = sub {
    my $name = shift;
    qr{
        $name
        $dcomm
        $dpairs
    }x;
};

# Quote-like balanced (q{}, m//)
my %single_q;
foreach my $name (qw(q qq qr qw qx m)) {
    $single_q{$name} = $make_single_q_balanced->($name);
}

# First of balanced pairs
my $bbpair = qr~[<\[\{\(]~;

my $make_double_q_balanced = sub {
    my $name = shift;
    qr{
         $name
         $dcomm

        (?(?=$bbpair)                    # balanced pairs (e.g.: s{}//)
               $dpairs
                  $dcomm
               $dpairs
                   |                     # or: single delims (e.g.: s///)
               $dpairs
              (??{$cache_end{$+} //= $make_end_delim->($+)})
        )
    }x;
};

# Double quote-like balanced (s{}{}, s///)
my %double_q;
foreach my $name (qw(tr s y)) {
    $double_q{$name} = $make_double_q_balanced->($name);
}

my $number     = qr{(?=\.?[0-9])[0-9_]*(?:\.(?!\.)[0-9_]*)?(?:[Ee](?:[+-]?[0-9_]+))?};
my $hex_num    = qr{0x[_0-9A-Fa-f]*};
my $binary_num = qr{0b[_01]*};

my $var_name = qr{(?>\w+|(?>::)+|'(?=\w))++};
my $vstring  = qr{\b(?:v[0-9]+(?>\.[0-9][0-9_]*+)*+ | [0-9][0-9_]*(?>\.[0-9][0-9_]*){2,})\b}x;

# HERE-DOC beginning
my $bhdoc = qr{
    <<(?>\h*(?>$str_sq|$str_dq)|\\?+(\w+))
}x;

my $tr_flags             = qr{[rcds]*};
my $match_flags          = qr{[mnsixpogcdual]*};
my $substitution_flags   = qr{[mnsixpogcerdual]*};
my $compiled_regex_flags = qr{[mnsixpodual]*};

my @postfix_operators    = qw( ++ -- );
my @prec_operators       = qw ( ... .. -> ++ -- =~ <=> \\ ? ~~ ~. ~ : >> >= > << <= < == != ! );
my @assignment_operators = qw( && || // ** % ^. ^ &. & |. | * + - = / . << >> );

my $operators = do {
    local $" = '|';
    qr{@{[map{quotemeta} @prec_operators, @assignment_operators]}};
};

my $postfix_operators = do {
    local $" = '|';
    qr{@{[map{quotemeta} @postfix_operators]}};
};

my $assignment_operators = do {
    local $" = '|';
    qr{@{[map{($_ eq '=') ? '=(?!=)' : "\Q$_=\E"} @assignment_operators]}};
};

my @special_var_names = (qw( \\ | + / ~ ! @ $ % ^ & * ( ) } < > : ; " ` ' ? = - [ ] . ), '#', ',');
my $special_var_names = do {
    local $" = '|';
    qr{@{[map {quotemeta} @special_var_names]}};
};

my $bracket_var = qr~(?=\s*\{)(?!\s*\{\s*(?:\^?$var_name|$special_var_names|\{)\s*\})~;

#<<<
my $perl_keywords =
    qr/(?:CORE::)?(?>(a(?:(?:ccept|larm|tan2|bs|nd))|b(?:in(?:(?:mode|d))|less|reak)|c(?:aller|h(?:dir|mod
    |o(?:(?:m?p|wn))|r(?:oot)?)|lose(?:dir)?|mp|o(?:n(?:(?:tinue|nect))|s)|rypt)|d(?:bm(?:(?:close|open))|
    e(?:f(?:(?:ault|ined))|lete)|ie|ump|o)|e(?:ach|ls(?:(?:if|e))|nd(?:grent|hostent|netent|p(?:(?:roto|w)
    ent)|servent)|of|val|x(?:ec|i(?:(?:sts|t))|p)|q)|f(?:c(?:ntl)?|ileno|lock|or(?:(?:each|m(?:(?:line|at)
    )|k))?)|g(?:e(?:t(?:gr(?:(?:ent|gid|nam))|host(?:by(?:(?:addr|name))|ent)|login|net(?:by(?:(?:addr|nam
    e))|ent)|p(?:eername|grp|pid|r(?:iority|oto(?:byn(?:(?:umber|ame))|ent))|w(?:(?:ent|nam|uid)))|s(?:erv
    (?:by(?:(?:name|port))|ent)|ock(?:(?:name|opt)))|c))?|iven|lob|mtime|oto|rep|t)|hex|i(?:mport|n(?:(?:d
    ex|t))|octl|sa|f)|join|k(?:(?:eys|ill))|l(?:ast|c(?:first)?|e(?:ngth)?|i(?:(?:sten|nk))|o(?:c(?:al(?:t
    ime)?|k)|g)|stat|t)|m(?:ap|kdir|sg(?:(?:ctl|get|rcv|snd))|y)|n(?:e(?:xt)?|ot?)|o(?:ct|pen(?:dir)?|rd?|
    ur)|p(?:ack(?:age)?|ipe|o[ps]|r(?:(?:ototype|intf?))|ush)|quotemeta|r(?:and|e(?:ad(?:(?:(?:lin[ek]|pip
    e|dir)))?|cv|do|name|quire|set|turn|verse|winddir|f)|index|mdir)|s(?:ay|calar|e(?:ek(?:dir)?|lect|m(?:
    (?:ctl|get|op))|nd|t(?:grent|hostent|netent|p(?:grp|r(?:(?:iority|otoent))|went)|s(?:(?:erven|ockop)t)
    ))|h(?:ift|m(?:(?:write|read|ctl|get))|utdown)|in|leep|o(?:cket(?:pair)?|rt)|p(?:li(?:(?:ce|t))|rintf)
    |qrt|rand|t(?:(?:ate?|udy))|ub(?:str)?|y(?:mlink|s(?:(?:write|call|open|read|seek|tem))))|t(?:ell(?:di
    r)?|i(?:(?:mes?|ed?))|runcate)|u(?:c(?:first)?|mask|n(?:def|l(?:(?:ess|ink))|pack|shift|ti[el])|se|tim
    e)|v(?:(?:alues|ec))|w(?:a(?:it(?:pid)?|ntarray|rn)|h(?:(?:ile|en))|rite)|xor|BEGIN|END|INIT|CHECK))\b
    /x;
#>>>

my $perl_filetests = qr/\-[ABCMORSTWXbcdefgkloprstuwxz]/;

sub perl_tokens(&$) {
    my ($callback, $code) = @_;

    ref($callback) eq 'CODE'
      or die "usage: perl_tokens {...} \$code;";

    my $variable      = 0;
    my $flat          = 0;
    my $regex         = 1;
    my $canpod        = 1;
    my $proto         = 0;
    my $format        = 0;
    my $expect_format = 0;
    my $postfix_op    = 0;
    my @heredoc_eofs;

    given ($code) {
        {
            when (($expect_format == 1) && /\G(?=\R)/) {
                if (/.*?\R\.\h*(?=\R|\z)/cgs) {
                    $callback->('vertical_space', $-[0],     $-[0] + 1);
                    $callback->('format',         $-[0] + 1, $+[0]);
                    $expect_format = 0;
                    $canpod        = 1;
                    $regex         = 1;
                    $postfix_op    = 0;
                }
                else {
                    if (/\G(.)/cgs) {
                        $callback->('unknown_char', $-[0], $+[0]);
                        redo;
                    }
                }
                redo;
            }
            when ($#heredoc_eofs >= 0 && /\G(?=\R)/) {
                my $token = shift @heredoc_eofs;
                if (m{\G.*?\R\Q$token\E(?=\R|\z)}sgc) {
                    $callback->('vertical_space', $-[0],     $-[0] + 1);
                    $callback->('heredoc',        $-[0] + 1, $+[0]);
                }
                redo;
            }
            when (($regex == 1 || /\G(?!<<[0-9])/) && m{\G$bhdoc}gc) {
                $callback->('heredoc_beg', $-[0], $+[0]);
                push @heredoc_eofs, $+;
                $regex  = 0;
                $canpod = 0;
                redo;
            }
            when ($canpod == 1 && /\G^=[a-zA-Z]/cgm) {
                /\G.*?\R=cut\h*(?=\R|\z)/cgs || /\G.*\z/cgs;
                $callback->('pod', $-[0] - 2, $+[0]);
                redo;
            }
            when (/\G(?=\s)/) {
                when (/\G\h+/cg) {
                    $callback->('horizontal_space', $-[0], $+[0]);
                    redo;
                }
                when (/\G\v+/cg) {
                    $callback->('vertical_space', $-[0], $+[0]);
                    redo;
                }
                when (/\G\s+/cg) {
                    $callback->({other_space => [$-[0], $+[0]]});
                    redo;
                }
            }
            when ($variable > 0) {
                when ((m{\G$var_name}gco || m{\G(?<=\$)\#$var_name}gco)) {
                    $callback->('var_name', $-[0], $+[0]);
                    $regex    = 0;
                    $variable = 0;
                    $canpod   = 0;
                    $flat     = /\G(?=\s*\{)/ ? 1 : 0;
                    redo;
                }
                when (
                      (
                       m{\G(?!\$+$var_name)}o && (   m~\G(?:\s+|#?)\{\s*(?:$var_name|$special_var_names|[#{])\s*\}~goc
                                                  || m{\G(?:\^\w+|#(?!\{)|$special_var_names)}gco
                                                  || /\G#/cg)
                      )
                  ) {
                    $callback->('special_var_name', $-[0], $+[0]);
                    $regex    = 0;
                    $canpod   = 0;
                    $variable = 0;
                    $flat     = /\G(?<!\})(?=\s*\{)/ ? 1 : 0;
                    redo;
                }
                continue;
            }
            when (/\G#.*/cg) {
                $callback->('comment', $-[0], $+[0]);
                redo;
            }
            when (($regex == 1 and not($postfix_op)) or /\G(?=[\@\$])/) {
                when (/\G\$/cg) {
                    $callback->('scalar_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                when (/\G\@/cg) {
                    $callback->('array_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                when (/\G\%/cg) {
                    $callback->('hash_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                when (/\G\*/cg) {
                    $callback->('glob_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                when (/\G&/cg) {
                    $callback->('ampersand_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                continue;
            }
            when ($proto == 1 && /\G\(.*?\)/cgs) {
                $callback->('sub_proto', $-[0], $+[0]);
                $proto  = 0;
                $canpod = 0;
                $regex  = 0;
                redo;
            }
            when (/\G\(/cg) {
                $callback->('parenthesis_open', $-[0], $+[0]);
                $regex  = 1;
                $flat   = 0;
                $canpod = 0;
                redo;
            }
            when (/\G\)/cg) {
                $callback->('parenthesis_close', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when (/\G\{/cg) {
                $callback->('curly_bracket_open', $-[0], $+[0]);
                $regex = 1;
                $proto = 0;
                redo;
            }
            when (/\G\}/cg) {
                $callback->('curly_bracket_close', $-[0], $+[0]);
                $flat   = 0;
                $canpod = 1;
                redo;
            }
            when (/\G\[/cg) {
                $callback->('right_bracket_open', $-[0], $+[0]);
                $regex      = 1;
                $postfix_op = 0;
                $flat       = 0;
                $canpod     = 0;
                redo;
            }
            when (/\G\]/cg) {
                $callback->('right_bracket_close', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when ($proto == 0) {
                when ($canpod == 1 && /\Gformat\b/cg) {
                    $callback->('keyword', $-[0], $+[0]);
                    $regex  = 0;
                    $canpod = 0;
                    $format = 1;
                    redo;
                }
                when (
                      (
                       $flat == 0 || ($flat == 1
                                      && (/\G(?!\w+\h*\})/))
                      )
                        && m{\G(?<!->)$perl_keywords}gco
                  ) {
                    my $name         = $1;
                    my @pos          = ($-[0], $+[0]);
                    my $is_bare_word = /\G(?=\h*=>)/;
                    $callback->(($is_bare_word ? 'bare_word' : 'keyword'), @pos);

                    if ($name eq 'sub' and not $is_bare_word) {
                        $proto = 1;
                        $regex = 0;
                    }
                    else {
                        $regex      = 1;
                        $postfix_op = 0;
                    }
                    $canpod = 0;
                    redo;
                }
                continue;
            }
            when (/\G(?!(?>tr|[ysm]|q[rwxq]?)\h*=>)/ && /\G(?<!->)/) {

                ($flat == 1 && /\G(?=[a-z]+\h*\})/) || /\G((?<=\{)|(?<=\{\h))(?=[a-z]+\h*\})/ ? continue : ();

                when (m{\G $double_q{s} $substitution_flags }gcxo) {
                    $callback->('substitution', $-[0], $+[0]);
                    $regex  = 0;
                    $canpod = 0;
                    redo;
                }
                when (m{\G (?> $double_q{tr} | $double_q{y} ) $tr_flags }gxco) {
                    $callback->('transliteration', $-[0], $+[0]);
                    $regex  = 0;
                    $canpod = 0;
                    redo;
                }
                when ((m{\G $single_q{m} $match_flags }gcxo || ($regex == 1 && m{\G $match_re $match_flags }gcxo))) {
                    $callback->('match_regex', $-[0], $+[0]);
                    $regex  = 0;
                    $canpod = 0;
                    redo;
                }
                when (m{\G $single_q{qr} $compiled_regex_flags }gcxo) {
                    $callback->('compiled_regex', $-[0], $+[0]);
                    $regex  = 0;
                    $canpod = 0;
                    redo;
                }
                when (m{\G$single_q{q}}gco) {
                    $callback->('q_string', $-[0], $+[0]);
                    $regex  = 0;
                    $canpod = 0;
                    redo;
                }
                when (m{\G$single_q{qq}}gco) {
                    $callback->('qq_string', $-[0], $+[0]);
                    $regex  = 0;
                    $canpod = 0;
                    redo;
                }
                when (m{\G$single_q{qw}}gco) {
                    $callback->('qw_string', $-[0], $+[0]);
                    $regex  = 0;
                    $canpod = 0;
                    redo;
                }
                when (m{\G$single_q{qx}}gco) {
                    $callback->('qx_string', $-[0], $+[0]);
                    $regex  = 0;
                    $canpod = 0;
                    redo;
                }
                continue;
            }
            when (m{\G$str_dq}gco) {
                $callback->('double_quoted_string', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when (m{\G$str_sq}gco) {
                $callback->('single_quoted_string', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when (m{\G$str_bq}gco) {
                $callback->('backtick', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when (/\G;/cg) {
                $callback->('semicolon', $-[0], $+[0]);
                $canpod     = 1;
                $regex      = 1;
                $postfix_op = 0;
                $proto      = 0;
                $flat       = 0;
                redo;
            }
            when (/\G=>/cg) {
                $callback->('fat_comma', $-[0], $+[0]);
                $regex      = 1;
                $postfix_op = 0;
                $canpod     = 0;
                $flat       = 0;
                redo;
            }
            when (/\G,/cg) {
                $callback->('comma', $-[0], $+[0]);
                $regex      = 1;
                $postfix_op = 0;
                $canpod     = 0;
                $flat       = 0;
                redo;
            }
            when (m{\G$vstring}gco) {
                $callback->('v_string', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                redo;
            }
            when (m{\G$perl_filetests\b}gco) {
                my @pos = ($-[0], $+[0]);
                my $is_bare_word = /\G(?=\h*=>)/;
                $callback->(($is_bare_word ? 'bare_word' : 'file_test'), @pos);
                if ($is_bare_word) {
                    $canpod = 0;
                    $regex  = 0;
                }
                else {
                    $regex      = 1;    # ambiguous, but possible
                    $postfix_op = 0;
                    $canpod     = 0;
                }
                redo;
            }
            when (/\G(?=__)/) {
                when (m{\G__(?>DATA|END)__\b\h*+(?!=>).*\z}gcs) {
                    $callback->('data', $-[0], $+[0]);
                    redo;
                }
                when (m{\G__(?>SUB|FILE|PACKAGE|LINE)__\b(?!\h*+=>)}gc) {
                    $callback->('special_keyword', $-[0], $+[0]);
                    $canpod = 0;
                    $regex  = 0;
                    redo;
                }
                continue;
            }
            when ($regex == 1 && /\G(?<!(?:\+\+|--)\h)/ && m{\G$glob}gco) {
                $callback->('glob_readline', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                redo;
            }
            when (m{\G$assignment_operators}gco) {
                $callback->('assignment_operator', $-[0], $+[0]);
                if ($format) {
                    if (substr($_, $-[0], $+[0] - $-[0]) eq '=') {
                        $format        = 0;
                        $expect_format = 1;
                    }
                }
                $regex  = 1;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when (/\G->/cg) {
                $callback->('dereference_operator', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 1;
                redo;
            }
            when (m{\G$operators}gco || /\Gx(?=[0-9\W])/cg) {
                $callback->('operator', $-[0], $+[0]);
                if (substr($_, $-[0], ($+[0] - $-[0])) =~ /^$postfix_operators\z/) {
                    $postfix_op = 1;
                }
                else {
                    $postfix_op = 0;
                }
                $canpod = 0;
                $regex  = 1;
                $flat   = 0;
                redo;
            }
            when (m{\G$hex_num}gco) {
                $callback->('hex_number', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                redo;
            }
            when (m{\G$binary_num}gco) {
                $callback->('binary_number', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                redo;
            }
            when (m{\G$number}gco) {
                $callback->('number', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                redo;
            }
            when (m{\GSTD(?>OUT|ERR|IN)\b}gc) {
                $callback->('special_fh', $-[0], $+[0]);
                $regex      = 1;
                $postfix_op = 0;
                $canpod     = 0;
                redo;
            }
            when (m{\G$var_name}gco) {
                $callback->(($proto == 1 ? 'sub_name' : 'bare_word'), $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when (/\G\z/cg) {    # all done
                break;
            }
            default {
                if (/\G(.)/cgs) {
                    $callback->('unknown_char', $-[0], $+[0]);
                    redo;
                }
            }
        }
    }

    return pos($code);
}

1;

=head1 SYNOPSIS

    use Perl::Tokenizer;
    my $code = 'my $num = 42;';
    perl_tokens { print "@_\n" } $code;

=head1 DESCRIPTION

Perl::Tokenizer is a tiny tokenizer which splits a given Perl code into a list of tokens, using the power of regular expressions.

=head1 SUBROUTINES

=over 4

=item perl_tokens(&$)

This function takes a callback subroutine and a string. The subroutine is called for each token in real-time.

    perl_tokens {
        my ($token, $pos_beg, $pos_end) = @_;
        ...
    } $code;

The positions are absolute to the string.

=back

=head2 EXPORT

The function B<perl_tokens> is exported by default. This is the only function provided by this module.

=head1 TOKENS

The standard token names that are available are:

       format .................. Format text
       heredoc_beg ............. The beginning of a here-document ('<<"EOT"')
       heredoc ................. The content of a here-document
       pod ..................... An inline POD document, until '=cut' or end of the file
       horizontal_space ........ Horizontal whitespace (matched by /\h/)
       vertical_space .......... Vertical whitespace (matched by /\v/)
       other_space ............. Whitespace that is neither vertical nor horizontal (matched by /\s/)
       var_name ................ Alphanumeric name of a variable (excluding the sigil)
       special_var_name ........ Non-alphanumeric name of a variable, such as $/ or $^H (excluding the sigil)
       sub_name ................ Subroutine name
       sub_proto ............... Subroutine prototype
       comment ................. A #-to-newline comment (excluding the newline)
       scalar_sigil ............ The sigil of a scalar variable: '$'
       array_sigil ............. The sigil of an array variable: '@'
       hash_sigil .............. The sigil of a hash variable: '%'
       glob_sigil .............. The sigil of a glob symbol: '*'
       ampersand_sigil ......... The sigil of a subroutine call: '&'
       parenthesis_open ........ Open parenthesis: '('
       parenthesis_close ....... Closed parenthesis: ')'
       right_bracket_open ...... Open right bracket: '['
       right_bracket_close ..... Closed right bracket: ']'
       curly_bracket_open ...... Open curly bracket: '{'
       curly_bracket_close ..... Closed curly bracket: '}'
       substitution ............ Regex substitution: s/.../.../
       transliteration.......... Transliteration: tr/.../.../ or y/.../.../
       match_regex ............. Regex in matching context: m/.../
       compiled_regex .......... Quoted compiled regex: qr/.../
       q_string ................ Single quoted string: q/.../
       qq_string ............... Double quoted string: qq/.../
       qw_string ............... List of quoted words: qw/.../
       qx_string ............... System command quoted string: qx/.../
       backtick ................ Backtick system command quoted string: `...`
       single_quoted_string .... Single quoted string, as: '...'
       double_quoted_string .... Double quoted string, as: "..."
       bare_word ............... Unquoted string
       glob_readline ........... <readline> or <shell glob>
       v_string ................ Version string: "vX" or "X.X.X"
       file_test ............... File test operator (-X), such as: "-d", "-e", etc...
       data .................... The content of `__DATA__` or `__END__` sections
       keyword ................. Regular Perl keyword, such as: `if`, `else`, etc...
       special_keyword ......... Special Perl keyword, such as: `__PACKAGE__`, `__FILE__`, etc...
       comma ................... Comma: ','
       fat_comma ............... Fat comma: '=>'
       operator ................ Primitive operator, such as: '+', '||', etc...
       assignment_operator ..... '=' or any assignment operator: '+=', '||=', etc...
       dereference_operator .... Arrow dereference operator: '->'
       hex_number .............. Hexadecimal literal number: 0x...
       binary_number ........... Binary literal number: 0b...
       number .................. Decimal literal number, such as 42, 3.1e4, etc...
       special_fh .............. Special file-handle name, such as 'STDIN', 'STDOUT', etc...
       unknown_char ............ Unknown or unexpected character

=head1 EXAMPLE

For this code:

    my $num = 42;

it generates the following tokens:

      #  TOKEN                     POS
      ( keyword              => ( 0,  2) )
      ( horizontal_space     => ( 2,  3) )
      ( scalar_sigil         => ( 3,  4) )
      ( var_name             => ( 4,  7) )
      ( horizontal_space     => ( 7,  8) )
      ( assignment_operator  => ( 8,  9) )
      ( horizontal_space     => ( 9, 10) )
      ( number               => (10, 12) )
      ( semicolon            => (12, 13) )

=head1 REPOSITORY

L<https://github.com/trizen/Perl-Tokenizer>

=head1 AUTHOR

Daniel "Trizen" Șuteu, E<lt>trizenx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2017

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
