package Perl::Tokenizer;

use 5.018;
use strict;
use warnings;

no warnings "experimental::smartmatch";

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(perl_tokens);

our $VERSION = '0.05';

=encoding utf8

=head1 NAME

Perl::Tokenizer - A tiny Perl code tokenizer.

=head1 VERSION

Version 0.05

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

my $number     = qr{(?=[0-9]|\.[0-9])[0-9_]*(?:\.(?!\.)[0-9_]*)?(?:[Ee](?:[+-]?[0-9_]+))?};
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

my @postfix_operators  = qw( ++ -- );
my @prec_operators     = qw ( ... .. -> ++ -- =~ <=> \\ ? ~~ ~. ~ : );
my @asigment_operators = qw( && || // ** ! % ^. ^ &. & |. | * + - = / . << >> < > );

my $operators = do {
    local $" = '|';
    qr{@{[map{quotemeta} @prec_operators, @asigment_operators]}};
};

my $postfix_operators = do {
    local $" = '|';
    qr{@{[map{quotemeta} @postfix_operators]}};
};

my $asigment_operators = do {
    local $" = '|';
    qr{@{[map{"\Q$_=\E"} @asigment_operators]}};
};

my @special_var_names = (qw( \\ | + / ~ ! @ $ % ^ & * ( ) } < > : ; " ` ' ? = - [ ] . ), '#', ',');
my $special_var_names = do {
    local $" = '|';
    qr{@{[map {quotemeta} @special_var_names]}};
};

my $bracket_var = qr~(?=\s*\{)(?!\s*\{\s*(?:\^?$var_name|$special_var_names|\{)\s*\})~;

my $perl_keywords = qr{(?:CORE::)?(?>(a(?:bs|ccept|larm|nd|tan2)|b(?:in(?:mode|d)|les
s|reak)|c(?:aller|h(?:dir|mod|o(?:mp|wn|p)|r(?:oot)?)|lose(?:dir)?|mp|o(?:
n(?:nect|tinue)|s)|rypt)|d(?:bm(?:close|open)|e(?:f(?:ault|ined)|lete)|ie|
ump|o)|e(?:ach|ls(?:if|e)|nd(?:grent|hostent|netent|p(?:rotoent|went)|serv
ent)|of|val|x(?:ec|i(?:sts|t)|p)|q)|f(?:c(?:ntl)?|ileno|lock|or(?:(?:each|
m(?:at|line)|k))?)|g(?:e(?:t(?:gr(?:ent|gid|nam)|host(?:by(?:addr|name)|en
t)|login|net(?:by(?:addr|name)|ent)|p(?:eername|grp|pid|r(?:iority|oto(?:b
yn(?:ame|umber)|ent))|w(?:ent|nam|uid))|s(?:erv(?:by(?:name|port)|ent)|ock
(?:name|opt))|c))?|iven|lob|mtime|oto|rep|t)|hex|i(?:mport|n(?:dex|t)|octl
|sa|f)|join|k(?:eys|ill)|l(?:ast|c(?:first)?|e(?:ngth)?|i(?:nk|sten)|o(?:c
(?:al(?:time)?|k)|g)|stat|t)|m(?:ap|kdir|sg(?:ctl|get|rcv|snd)|y)|n(?:e(?:
xt)?|ot?)|o(?:ct|pen(?:dir)?|rd?|ur)|p(?:ack(?:age)?|ipe|o[ps]|r(?:intf?|o
totype)|ush)|quotemeta|r(?:and|e(?:ad(?:(?:dir|lin[ek]|pipe))?|cv|do|name|
quire|set|turn|verse|winddir|f)|index|mdir)|s(?:ay|calar|e(?:ek(?:dir)?|le
ct|m(?:ctl|get|op)|nd|t(?:grent|hostent|netent|p(?:grp|r(?:iority|otoent)|
went)|s(?:ervent|ockopt)))|h(?:ift|m(?:ctl|get|read|write)|utdown)|in|leep
|o(?:cket(?:pair)?|rt)|p(?:li(?:ce|t)|rintf)|qrt|rand|t(?:ate?|udy)|ub(?:s
tr)?|y(?:mlink|s(?:call|open|read|seek|tem|write)))|t(?:ell(?:dir)?|i(?:ed
?|mes?)|runcate)|u(?:c(?:first)?|mask|n(?:def|l(?:ess|ink)|pack|shift|ti[e
l])|se|time)|v(?:alues|ec)|w(?:a(?:it(?:pid)?|ntarray|rn)|h(?:en|ile)|rite
)|xor|BEGIN|END|INIT|CHECK)) \b }x;

my $perl_filetests = qr{\-[ABCMORSTWXbcdefgkloprstuwxz]};

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
            when ($expect_format == 1 && m{\G(?=\n)}) {
                if (m{.*?\n\.\h*(?=\n|\z)}gsc) {
                    $callback->('vertical_space', $-[0],     $-[0] + 1);
                    $callback->('format',         $-[0] + 1, $+[0]);
                    $expect_format = 0;
                    $canpod        = 1;
                    $regex         = 1;
                    $postfix_op    = 0;
                }
                else {
                    m{\G.}gcs ? redo : exit -1;
                }
                redo;
            }
            when ($#heredoc_eofs >= 0 && m{\G(?=\n)}) {
                my $token = shift @heredoc_eofs;
                if (m{\G.*?\n\Q$token\E(?=\n|\z)}sgc) {
                    $callback->('vertical_space', $-[0],     $-[0] + 1);
                    $callback->('heredoc',        $-[0] + 1, $+[0]);
                }
                redo;
            }
            when (($regex == 1 || m{\G(?!<<[0-9])}) && m{\G$bhdoc}gc) {
                $callback->('heredoc_beg', $-[0], $+[0]);
                push @heredoc_eofs, $+;
                $regex  = 0;
                $canpod = 0;
                redo;
            }
            when ($canpod == 1 && m{\G^=[a-zA-Z]}mgc) {
                m{\G.*?\n=cut\h*(?=\n|z)}sgc || m{\G.*\z}gcs;
                $callback->('pod', $-[0] - 2, $+[0]);
                redo;
            }
            when (m{\G(?=\s)}) {
                when (m{\G\h+}gc) {
                    $callback->('horizontal_space', $-[0], $+[0]);
                    redo;
                }
                when (m{\G\v+}gc) {
                    $callback->('vertical_space', $-[0], $+[0]);
                    redo;
                }
                when (m{\G\s+}gc) {
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
                    $flat     = m~\G(?=\s*\{)~ ? 1 : 0;
                    redo;
                }
                when (
                      (
                       m{\G(?!\$+$var_name)}o && (   m~\G(?:\s+|#?)\{\s*(?:$var_name|$special_var_names|[#{])\s*\}~goc
                                                  || m{\G(?:\^\w+|#(?!\{)|$special_var_names)}gco
                                                  || m~\G#~gc)
                      )
                  ) {
                    $callback->('special_var_name', $-[0], $+[0]);
                    $regex    = 0;
                    $canpod   = 0;
                    $variable = 0;
                    $flat     = m~\G(?<!\})(?=\s*\{)~ ? 1 : 0;
                    redo;
                }
                continue;
            }
            when (m{\G#.*}gc) {
                $callback->('comment', $-[0], $+[0]);
                redo;
            }
            when (($regex == 1 and not($postfix_op)) or m{\G(?=[\@\$])}) {
                when (m{\G\$}gc) {
                    $callback->('scalar_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                when (m{\G\@}gc) {
                    $callback->('array_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                when (m{\G\%}gc) {
                    $callback->('hash_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                when (m{\G\*}gc) {
                    $callback->('glob_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                when (m{\G&}gc) {
                    $callback->('ampersand_sigil', $-[0], $+[0]);
                    /\G$bracket_var/o || ++$variable;
                    $regex  = 0;
                    $canpod = 0;
                    $flat   = 1;
                    redo;
                }
                continue;
            }
            when ($proto == 1 && m{\G\(.*?\)}gcs) {
                $callback->('sub_proto', $-[0], $+[0]);
                $proto  = 0;
                $canpod = 0;
                $regex  = 0;
                redo;
            }
            when (m{\G\(}gc) {
                $callback->('parenthesis_open', $-[0], $+[0]);
                $regex  = 1;
                $flat   = 0;
                $canpod = 0;
                redo;
            }
            when (m{\G\)}gc) {
                $callback->('parenthesis_close', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when (m~\G\{~gc) {
                $callback->('curly_bracket_open', $-[0], $+[0]);
                $regex = 1;
                $proto = 0;
                redo;
            }
            when (m~\G\}~gc) {
                $callback->('curly_bracket_close', $-[0], $+[0]);
                $flat = 0;
                redo;
            }
            when (m~\G\[~gc) {
                $callback->('right_bracket_open', $-[0], $+[0]);
                $regex      = 1;
                $postfix_op = 0;
                $flat       = 0;
                $canpod     = 0;
                redo;
            }
            when (m~\G\]~gc) {
                $callback->('right_bracket_close', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when ($proto == 0) {
                when ($canpod == 1 && m{\Gformat\b}gc) {
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
            when (m{\G;}goc) {
                $callback->('semicolon', $-[0], $+[0]);
                $canpod     = 1;
                $regex      = 1;
                $postfix_op = 0;
                $proto      = 0;
                $flat       = 0;
                redo;
            }
            when (m{\G=>}gc) {
                $callback->('fat_comma', $-[0], $+[0]);
                $regex      = 1;
                $postfix_op = 0;
                $canpod     = 0;
                $flat       = 0;
                redo;
            }
            when (m{\G,}gc) {
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
            when (m{\G(?=__)}) {
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
            when ($regex == 1 && /\G(?<!(?:--|\+\+)\h)/ && m{\G$glob}gco) {
                $callback->('glob_readline', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                redo;
            }
            when (m{\G$asigment_operators}gco) {
                $callback->('assignment_operator', $-[0], $+[0]);
                $regex  = 1;
                $canpod = 0;
                $flat   = 0;
                redo;
            }
            when (m{\G->}gc) {
                $callback->('dereference_operator', $-[0], $+[0]);
                $regex  = 0;
                $canpod = 0;
                $flat   = 1;
                redo;
            }
            when (m{\G$operators}gco || m{\Gx(?=[0-9\W])}gc) {
                $callback->('operator', $-[0], $+[0]);
                if ($format) {
                    if (substr($_, $-[0], ($+[0] - $-[0])) eq '=') {
                        $format        = 0;
                        $expect_format = 1;
                    }
                }
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
            when (m{\G\z}gc) {    # all done
                break;
            }
            default {
                if (/\G(.)/sgc) {
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

    use Perl::Tokenizer qw(perl_tokens);
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

Nothing is exported by default.
Only the function B<perl_tokens()> is exportable.

=head1 TOKENS

=over 4

=item format

Format text.

=item heredoc_beg

The beginning of a here-document.

=item heredoc

The content of a here-document.

=item pod

POD content.

=item horizontal_space

Horizontal whitespace.

=item vertical_space

Vertical whitespace.

=item other_space

Other whitespace.

=item var_name

Variable name.

=item special_var_name

Special variable name.

=item sub_name

Subroutine name.

=item sub_proto

Prototype of a subroutine.

=item comment

Comment.

=item scalar_sigil

Scalar sigil. (C<$>)

=item array_sigil

Array sigil. (C<@>)

=item hash_sigil

Hash sigil. (C<%>)

=item glob_sigil

Glob sigil. (C<*>)

=item ampersand_sigil

Ampersand sigil. (C<&>)

=item parenthesis_open

Open parenthesis. (C<(>)

=item parenthesis_close

Closed parenthesis. (C<)>)

=item curly_bracket_open

Open curly backet. (C<{>)

=item curly_bracket_close

Closed curly bracket. (C<}>)

=item right_bracket_open

Open right bracket. (C<[>)

=item right_bracket_close

Closed right bracket. (C<]>)

=item keyword

Perl keyword.

=item substitution

Regex substitution. (C<s///>)

=item transliteration

Transliteration. (C<tr///>)

=item match_regex

Match regex. (C<m//>)

=item compiled_regex

Compiled regex. (C<qr//>)

=item q_string

Single quoted string. (C<q//>)

=item qq_string

Double quoted string. (C<qq//>)

=item qw_string

Word quoted string. (C<qw//>)

=item qx_string

Backtick quoted string. (C<qx//>)

=item double_quoted_string

Double quoted string. (C<"">)

=item single_quoted_string

Single quoted string. (C<''>)

=item backtick

Backtick quoted string. (C<``>)

=item bare_word

Unquoted string.

=item semicolon

End of statement. (C<;>)

=item comma

Comma. (C<,>)

=item fat_comma

Fat comma. (C<=E<gt>>)

=item v_string

Version string. (C<vX> or C<X.X.X>)

=item file_test

File test operator. (C<-X>)

=item data

DATA/END content.

=item special_keyword

Special keyword, such as C<__PACKAGE__>, C<__FILE__>, etc.

=item glob_readline

Glob/readline angle brackets. (C<E<lt>...E<gt>>)

=item operator

Primitive operator, such as C<+>, C<||>, etc.

=item assignment_operator

Assignment operator, such as C<+=>, C<||=>, etc.

=item dereference_operator

The arrow dereference operator. (C<-E<gt>>)

=item hex_number

Hex number. (C<0x...>)

=item binary_number

Binary number. (C<0b...>)

=item number

Decimal number, such as C<42>, C<3.14>, etc.

=item special_fh

Special file-handle, such as C<STDIN>, C<STDOUT>, etc.

=item unknown_char

An unknown unexpected character.

=back

=head1 EXAMPLE

For this code:

    my $num = 42;

it generates the following tokens:

      #  TOKEN                    POS
      ( keyword              => (0, 2) )
      ( horizontal_space     => (2, 3) )
      ( scalar_sigil         => (3, 4) )
      ( var_name             => (4, 7) )
      ( horizontal_space     => (7, 8) )
      ( operator             => (8, 9) )
      ( horizontal_space     => (9, 10) )
      ( number               => (10, 12) )
      ( semicolon            => (12, 13) )

=head1 REPOSITORY

L<https://github.com/trizen/Perl-Tokenizer>

=head1 AUTHOR

Daniel "Trizen" Șuteu, E<lt>trizenx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2016

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
