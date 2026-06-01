package Perl500503Syntax::OrDie;

######################################################################
#
# Perl500503Syntax::OrDie - Validate Perl 5.005_03 source compatibility
#
# https://metacpan.org/dist/Perl500503Syntax-OrDie
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com>
#
######################################################################

use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use vars qw($VERSION @BLACKLIST @REGEX_BLACKLIST @RAW_BLACKLIST $_OPEN_GUARDED $_MKDIR_GUARDED);

$VERSION = '0.03';

# ======================================================================
# BLACKLIST
# Each entry: [ qr/pattern/, 'human-readable description' ]
# Matched against source after masking comments and string literals.
# ======================================================================
@BLACKLIST = (

    # ------------------------------------------------------------------
    # Perl 5.6 features
    # ------------------------------------------------------------------

    # our VARIABLE
    [ qr/\bour\s*[\$\@\%\*]/,
      "'our' declaration (introduced in Perl 5.6; use 'use vars' instead)" ],

    # 3-argument open() is detected in a dedicated paren-aware stage
    # (see "Stage 1c" in _check_source); a flat comma-counting regex
    # cannot tell a top-level argument comma from one nested inside an
    # expression such as  open(FH, '>' . File::Spec->catfile($d, $f)).

    # use utf8
    [ qr/\buse\s+utf8\b/,
      "'use utf8' (introduced in Perl 5.6)" ],

    # use VERSION >= 5.6  (numeric forms: 5.6, 5.06, 5.006, 5.010, 5.100 ...)
    # Pattern: 5. followed by (0*[6-9]) OR (0[1-9]\d+) OR ([1-9]\d+)
    # This catches 5.6, 5.06, 5.006, 5.010, 5.012, 5.100 etc.
    # but not 5.5, 5.005, 5.004
    [ qr/\buse\s+5\s*\.\s*(?:0*[6-9]|0[1-9]\d+|[1-9]\d+)\b/,
      "use VERSION >= 5.6 (target is Perl 5.005_03)" ],

    # use v5.6, use v5.10, ...
    [ qr/\buse\s+v5\s*\.\s*[6-9]/,
      "use vVERSION >= v5.6 (target is Perl 5.005_03)" ],
    [ qr/\buse\s+v5\s*\.1/,
      "use vVERSION >= v5.10 (target is Perl 5.005_03)" ],

    # \x{HHHH} Unicode escape
    [ qr/\\x\{[0-9A-Fa-f]+\}/,
      "\\x{} Unicode escape (introduced in Perl 5.6)" ],

    # \N{name} named character
    [ qr/\\N\{[^}]+\}/,
      "\\N{} named character escape (introduced in Perl 5.6)" ],

    # @+ / @- match-position arrays: $+[N]  $-[N]  @+  @-
    [ qr/(?:\$[+\-]\[|\@[+\-](?!\w))/,
      'match-position arrays @+/@- or $+[N]/$-[N] (introduced in Perl 5.6)' ],

    # CHECK { } / INIT { } named phase blocks
    [ qr/\b(?:CHECK|INIT)\s*\{/,
      "CHECK/INIT phase blocks (introduced in Perl 5.6)" ],

    # v-strings: v1.2.3 or v5.6.0
    [ qr/(?<!\w)v\d+\.\d+/,
      "v-string notation (introduced in Perl 5.6; use a plain number instead)" ],

    # $^V  (version object; use $] instead)
    [ qr/\$\^V\b/,
      '$^V version object (introduced in Perl 5.6; use $] instead)' ],

    # :lvalue subroutine attribute
    [ qr/\bsub\s+\w[\w:]*\s*(?:\([^)]*\)\s*)?:[^{]*\blvalue\b/,
      "':lvalue' subroutine attribute (introduced in Perl 5.6)" ],

    # typeglob component slice  *FH{IO}  *foo{SCALAR}  *foo{CODE}  etc.
    # Perl 5.005_03 does not support typeglob-element access via *name{SLOT}.
    # Guard: require leading sigil or word boundary to avoid false positives.
    [ qr/\*\w[\w:]*\s*\{\s*(?:IO|SCALAR|ARRAY|HASH|CODE|GLOB|FORMAT|NAME|PACKAGE)\s*\}/,
      "typeglob component access *name{SLOT} (introduced in Perl 5.6)" ],

    # ------------------------------------------------------------------
    # Perl 5.8 features
    # ------------------------------------------------------------------

    # use encoding
    [ qr/\buse\s+encoding\b/,
      "'use encoding' (introduced in Perl 5.8)" ],

    # use constant with a hashref (hash of constants)  -- Perl 5.8
    # Single-value form  use constant NAME => VALUE  is 5.004+, always OK.
    # Hash-ref form  use constant { A => 1, B => 2 }  was added in Perl 5.8.
    [ qr/\buse\s+constant\s*\{/,
      "'use constant { HASH }' multi-constant form (introduced in Perl 5.8; use separate 'use constant' statements)" ],

    # ------------------------------------------------------------------
    # Perl 5.10 features
    # ------------------------------------------------------------------

    # defined-or-assignment operator
    [ do { my $p = '/' . '/='; qr/$p/ },
      "defined-or assignment '" . '/' . "/=' (introduced in Perl 5.10)" ],

    # say HANDLE or say LIST
    # Exclude ->say(...) method calls and say => hash-key usage
    [ do { my $kw = 'sa' . 'y'; qr/(?<!->)\b$kw\b(?!\s*=>)/ },
      "'say' (introduced in Perl 5.10)" ],

    # sta-te $var
    [ do { my $kw = 'sta' . 'te'; qr/\b$kw\s+[\$\@\%]/ },
      "'sta" . "te' variable (introduced in Perl 5.10)" ],

    # given(...)
    [ qr/\bgiven\s*\(/,
      "'given' (introduced in Perl 5.10)" ],

    # when(...)
    [ qr/\bwhen\s*\(/,
      "'when' (introduced in Perl 5.10)" ],

    # smart-match ~~
    [ qr/~~/,
      "smart-match operator '~~' (introduced in Perl 5.10)" ],

    # use feature
    # The empty-import form  use feature ()  imports nothing and, when paired
    # with a  BEGIN { $INC{'feature.pm'} = '' if $] < 5.010 }  stub, loads
    # nothing on Perl 5.005_03.  It is a no-op on every Perl version and is the
    # standard cross-version guard idiom (parallel to the tolerated
    # use warnings stub), so it is NOT a violation.  A non-empty import list
    # such as  use feature 'say'  or  use feature qw(...)  still is.
    [ qr/\buse\s+feature\b(?!\s*\(\s*\))/,
      "'use feature' (introduced in Perl 5.10)" ],

    # defined-or operator (two slashes, not part of s///, m//, =~, !~)
    # and not the defined-or-assign variant
    [ qr/(?<![=~!])\s\/\/(?!=)/,
      "defined-or operator (introduced in Perl 5.10)" ],

    # UNITCHECK phase block
    [ qr/\bUNITCHECK\s*\{/,
      "UNITCHECK phase block (introduced in Perl 5.10)" ],

    # ${^MATCH} ${^PREMATCH} ${^POSTMATCH} (used with /p flag -- 5.10)
    [ qr/\$\{\^(?:MATCH|PREMATCH|POSTMATCH)\}/,
      "\${^MATCH}/\${^PREMATCH}/\${^POSTMATCH} (introduced in Perl 5.10; require /p flag)" ],

    # ------------------------------------------------------------------
    # Perl 5.12 features
    # ------------------------------------------------------------------

    # package NAME VERSION
    [ qr/\bpackage\s+\w[\w:]*\s+v?\d/,
      "'package NAME VERSION' (introduced in Perl 5.12)" ],

    # yada-yada operator ...  (not to be confused with .. range)
    [ do { my $p = '\\.' x 3; qr/(?<!\\.)$p(?!\\.)/ },
      "yada-yada operator '...' (introduced in Perl 5.12)" ],

    # ------------------------------------------------------------------
    # Perl 5.14 features
    # ------------------------------------------------------------------

    # /r (non-destructive) flag on s/// or tr///
    # _mask_source emits __SR__ or __TRR__ marker when r flag is present.
    [ qr/__SR__|__TRR__/,
      "s///r or tr///r non-destructive flag (introduced in Perl 5.14)" ],

    # ------------------------------------------------------------------
    # Perl 5.16 features
    # ------------------------------------------------------------------

    # __SUB__ token (reference to the current subroutine)
    [ qr/__SUB__/,
      "__SUB__ (introduced in Perl 5.16; use explicit sub name or \$_[0] recursion)" ],

    # ------------------------------------------------------------------
    # Perl 5.18 features
    # ------------------------------------------------------------------

    # my sub NAME / state sub NAME -- lexical subroutines (Perl 5.18)
    [ do { my $kw = 'su' . 'b'; qr/\b(?:my|state)\s+$kw\s+\w/ },
      "'my sub'/'state sub' lexical subroutine (introduced in Perl 5.18)" ],

    # ------------------------------------------------------------------
    # Perl 5.20 features
    # ------------------------------------------------------------------

    # subroutine signatures: sub foo ($x, $y) {  (Perl 5.20)
    [ qr/\bsub\s+\w+\s*\([^\)]*(?<!\\)[\$\@\%][a-zA-Z_][^\)]*\)\s*\{/,
      "subroutine signature (introduced in Perl 5.20)" ],

    # postfix dereference  $ref->@*  $ref->%*  $ref->&*
    [ qr/->\s*[\@\%\&\$]\s*\*/,
      "postfix dereference (introduced in Perl 5.20)" ],

    # %hash{LIST} and %array[LIST]  key/value (index/value) slices  (Perl 5.20)
    # Exclude plain %hash alone (no subscript) and %hash = (...) assignment.
    # Require preceding context that cannot be an assignment target start.
    [ qr/(?:[\(=,;!&|?:]|\breturn\b)\s*\%\w[\w:]*\s*[\{\[]/,
      "key/value hash/array slice %hash{} or %array[] (introduced in Perl 5.20)" ],

    # ------------------------------------------------------------------
    # Perl 5.22 features
    # ------------------------------------------------------------------

    # &. |. ^. ~.  string bitwise operators  (use feature 'bitwise')
    [ qr/(?:[&|^]\.=?|~\.)/,
      "string bitwise operator '&.' '|.' '^.' '~.' (introduced in Perl 5.22)" ],

    # \$scalar in foreach -- reference aliasing  (use feature 'refaliasing')
    [ qr/\bforeach\s+\\(?:my\s+)?[\$\@\%\*]/,
      "reference aliasing in foreach (introduced in Perl 5.22; use index-based loop instead)" ],

    # <<>> double-diamond operator
    [ qr/<</,
      "<<>> double-diamond operator (introduced in Perl 5.22)" ],

    # /n flag (non-capturing groups make all captures non-capturing)
    [ qr{(?:=~|!~|(?<!\w)[msqy])\s*X+[gimsxodualp]*n[gimsxodualp]*\s*[;,)\s\{]},
      "/n non-capturing regex flag (introduced in Perl 5.22)" ],

    # ------------------------------------------------------------------
    # Perl 5.26 features
    # ------------------------------------------------------------------

    # <<~ indented heredoc
    [ qr/<<~/,
      "<<~ indented heredoc (introduced in Perl 5.26)" ],

    # ------------------------------------------------------------------
    # Perl 5.32 features
    # ------------------------------------------------------------------

    # isa infix operator:  $obj isa ClassName
    # Exclude ->isa() method calls (> before) and UNIVERSAL::isa() (:: before)
    # Exclude isa( call form (followed by open paren = sub call, not infix)
    [ qr/(?<![>:])(?<![>])\bisa\b(?!::)(?!\s*\()/,
      "'isa' infix operator (introduced in Perl 5.32; use UNIVERSAL::isa() instead)" ],

    # ------------------------------------------------------------------
    # Perl 5.34+ features
    # ------------------------------------------------------------------

    # try { } catch ($e) { }
    [ qr/\btry\s*\{/,
      "'try' block (introduced in Perl 5.34)" ],

    # ------------------------------------------------------------------
    # Perl 5.36 features
    # ------------------------------------------------------------------

    # use builtin
    [ qr/\buse\s+builtin\b/,
      "'use builtin' (introduced in Perl 5.36)" ],

    # for my ($a, $b) (@list)  -- iterable-value variables in for loop
    [ qr/\bfor\s+my\s*\(/,
      "'for my (\$a,\$b)' paired iteration (introduced in Perl 5.36)" ],

    # ------------------------------------------------------------------
    # Perl 5.38+ features
    # ------------------------------------------------------------------

    # class Foo { }
    [ qr/\bclass\s+\w/,
      "'class' keyword (introduced in Perl 5.38)" ],

    # ------------------------------------------------------------------
    # Perl 5.40 features
    # ------------------------------------------------------------------

    # ^^ high-precedence logical XOR operator  ($x ^^ $y)
    [ qr/\^\^[^>]/,
      "'^^ / ^^=' high-precedence logical XOR (introduced in Perl 5.40)" ],

    # __CLASS__ keyword
    [ qr/__CLASS__/,
      "'__CLASS__' keyword (introduced in Perl 5.40; use __PACKAGE__ or \$class instead)" ],

    # ------------------------------------------------------------------
    # Perl 5.42 features
    # ------------------------------------------------------------------

    # any { } LIST  and  all { } LIST  -- experimental keyword operators
    # Exclude files that have "use List::Util" with any/all in the import list,
    # since those are sub calls, not keywords. Detection deferred to
    # _check_source() which performs the import pre-scan.
    # (Pattern is applied conditionally; see _check_source().)

    # my method NAME -- lexical method declaration inside class block
    [ do { my $kw = 'meth' . 'od'; qr/\bmy\s+$kw\b/ },
      "'my method' lexical method declaration (introduced in Perl 5.42)" ],

    # ->& invocation of lexical method (Perl 5.42)
    [ qr/->&\s*\w/,
      "'->&name' lexical method call operator (introduced in Perl 5.42)" ],

);

# ======================================================================
# BLACKLIST_CONDITIONAL
# Entries that are only applied when certain file-level conditions hold.
# Each entry: [ $condition_key, qr/pattern/, 'description' ]
# $condition_key is checked against %cond hash in _check_source().
# ======================================================================
# (Currently used for any/all keyword detection.)

# ======================================================================
# REGEX_BLACKLIST
# Patterns checked against the CONTENT of regex literals only.
# Each entry: [ qr/pattern/, 'human-readable description' ]
# ======================================================================
@REGEX_BLACKLIST = (

    # \x{HHHH} Unicode escape in regex -- Perl 5.6
    [ qr/\\x\{[0-9A-Fa-f]+\}/,
      "\\x{} Unicode escape (introduced in Perl 5.6)" ],

    # \N{name} named character in regex -- Perl 5.6
    [ qr/\\N\{[^}]+\}/,
      "\\N{} named character escape (introduced in Perl 5.6)" ],

    # \p{} \P{} Unicode property escapes -- Perl 5.6
    [ qr/\\[pP]\{/,
      "\\p{}\\P{} Unicode property in regex (introduced in Perl 5.6)" ],

    # \K (keep) -- Perl 5.10
    [ qr/\\K/,
      "\\K (keep) in regex (introduced in Perl 5.10)" ],

    # Named capture (?<name>...) or \k<name> backreference -- Perl 5.10
    [ qr/(?:\(\?<[A-Za-z_]|\\k<)/,
      "named capture (?<name>...) or \\k<name> (introduced in Perl 5.10)" ],

    # Branch reset group (?|...) -- Perl 5.10
    [ qr/\(\?[|]/,
      "branch reset (?|...) in regex (introduced in Perl 5.10)" ],

    # Backtrack control verbs (*FAIL) (*ACCEPT) (*PRUNE) (*SKIP) etc -- Perl 5.10
    [ qr/\(\*[A-Z]/,
      "backtrack control verb (*VERB) in regex (introduced in Perl 5.10)" ],

    # \h \H \v \V \R -- horizontal/vertical whitespace -- Perl 5.10
    [ qr/\\[hHvVR](?!\w)/,
      "\\h/\\H/\\v/\\V/\\R regex escape (introduced in Perl 5.10)" ],

    # Variable-length lookbehind -- experimental Perl 5.30, stable Perl 5.38
    [ qr/\(\?<[=!][^)]*(?:\{|\*|\+)[^)]*\)/,
      "variable-length lookbehind in regex (experimental from Perl 5.30, stable in Perl 5.38; use fixed-length)" ],

    # Possessive quantifiers in regex: a++  a*+  a?+  a{n,m}+ -- Perl 5.10
    [ qr/(?:[A-Za-z0-9_)\].])(?:[+*?]|\{\d+(?:,\d*)?\})\+/,
      "possessive quantifier (++/*+/?+/{n,m}+) in regex (introduced in Perl 5.10)" ],

    # Recursive patterns (?PARNO) (?&name) (?R) -- Perl 5.10
    [ qr/\(\?(?:[0-9]+|[+-][0-9]+|R|&\w+)\)/,
      "recursive pattern (?PARNO) / (?&name) / (?R) (introduced in Perl 5.10)" ],

    # \g{N} relative or absolute backreference -- Perl 5.10
    [ qr/\\g\{/,
      "\\g{N} relative/absolute backreference (introduced in Perl 5.10)" ],

);

# ======================================================================
# RAW_BLACKLIST
# Abolished: string and regex contents must be freely writable in
# Perl 5.005_03 code.  Checking runtime string values (PerlIO layer
# names, sprintf format flags, etc.) is not the role of a static
# syntax checker.
#
# Former entries and why they were removed:
#   PerlIO layer (:utf8 etc) in open()/binmode()
#     -> open() with a PerlIO layer requires 3-argument form, already
#        caught by the 3-argument open() entry in @BLACKLIST.
#        binmode() layer string is a runtime value, not syntax.
#   sprintf/printf "%v" format flag
#     -> The format string is a runtime value, not a syntax construct.
#        A string literal containing "%v" is valid Perl 5.005_03 syntax.
# ======================================================================
@RAW_BLACKLIST = ();

# ======================================================================
# import() -- called when the caller writes:  use Perl500503Syntax::OrDie;
# ======================================================================
sub import {
    my $class = shift;

    my ($pkg, $file, $line) = caller(0);

    if (defined $file && $file ne '' && $file ne '-e' && $file ne '-') {
        if (-f $file) {
            my @violations = _check_file($file);
            if (@violations) {
                die join('', @violations);
            }
        }
    }

    _install_runtime_guards();
    return;
}

# ======================================================================
# _check_file($path)
# Returns a list of violation strings (empty list = no violations).
# ======================================================================
sub _check_file {
    my ($file) = @_;

    local *_ORDIE_FH;
    eval 'CORE::' . 'open(_ORDIE_FH, $file) or die $!';
    if ($@) {
        warn "Perl500503Syntax::OrDie: cannot open '$file': $!\n";
        return ();
    }
    my $source = do { local $/; <_ORDIE_FH> };
    close _ORDIE_FH;

    return _check_source($source, $file);
}

# ======================================================================
# _check_source($source, $filename)
# Returns a list of violation strings (empty list = no violations).
# ======================================================================
sub _check_source {
    my ($source, $file) = @_;
    $file = '(unknown)' unless defined $file && $file ne '';

    my @violations;

    my ($masked, $regex_bodies_ref) = _mask_source($source);
    my @lines    = split(/\n/, $masked, -1);
    my @rawlines = split(/\n/, $source,  -1);

    # ------------------------------------------------------------------
    # Pre-scan: detect  use List::Util qw(... any ... all ...)
    # If found, the any/all BLOCK keyword check is suppressed because
    # those names are imported subs, not the new keyword form.
    # ------------------------------------------------------------------
    my $listutil_any_imported = 0;
    my $listutil_all_imported = 0;
    {
        my $cm = _mask_comments($source);
        if ($cm =~ /\buse\s+List::Util\b([^;]+);/s) {
            my $args = $1;
            $listutil_any_imported = 1 if $args =~ /\bany\b/;
            $listutil_all_imported = 1 if $args =~ /\ball\b/;
        }
    }

    # Stage 1: BLACKLIST -- scan masked source (comments + strings masked)
    for my $entry (@BLACKLIST) {
        my ($pattern, $desc) = @{$entry};
        my $lineno = 0;
        for my $mline (@lines) {
            $lineno++;
            if ($mline =~ $pattern) {
                push @violations,
                    "Perl500503Syntax::OrDie: VIOLATION at $file line $lineno:\n"
                  . "  $desc\n";
            }
        }
    }

    # Stage 1b: any/all BLOCK keyword -- conditional on import pre-scan.
    # The List::Util keyword form is an expression  any { ... } LIST .
    # A subroutine *definition*  sub any { ... }  (or a method call such
    # as  $obj->all { ... } ) must NOT be flagged.  We therefore inspect
    # the text immediately preceding each  any{ / all{  match and skip it
    # when it is preceded by  sub  or by an arrow operator.
    {
        my $check_any = $listutil_any_imported ? 0 : 1;
        my $check_all = $listutil_all_imported ? 0 : 1;
        my $desc_any = "'any BLOCK LIST' keyword operator (introduced in Perl 5.42; use List::Util instead)";
        my $desc_all = "'all BLOCK LIST' keyword operator (introduced in Perl 5.42; use List::Util instead)";
        my $lineno = 0;
        for my $mline (@lines) {
            $lineno++;
            while ($mline =~ /\b(any|all)(\s*)\{/g) {
                my $word     = $1;
                my $matchlen = length($1) + length($2) + 1;
                my $start    = pos($mline) - $matchlen;
                my $pre      = substr($mline, 0, $start);
                next if $pre =~ /\bsub\s+$/;   # sub any { ... } definition
                next if $pre =~ /->\s*$/;      # $obj->any { ... } method
                if ($word eq 'any' && $check_any) {
                    push @violations,
                        "Perl500503Syntax::OrDie: VIOLATION at $file line $lineno:\n"
                      . "  $desc_any\n";
                }
                elsif ($word eq 'all' && $check_all) {
                    push @violations,
                        "Perl500503Syntax::OrDie: VIOLATION at $file line $lineno:\n"
                      . "  $desc_all\n";
                }
            }
        }
    }

    # Stage 1c: 3-argument open() -- paren-aware top-level comma count.
    # open(FH, MODE, EXPR) has two commas at the top level of the call;
    # open(FH, EXPR) has one.  Commas nested inside parentheses -- e.g. a
    # function call used as the second argument, as in
    #   open(FH, '>' . File::Spec->catfile($dir, $file))
    # -- sit at depth >= 2 and are not counted, so the 2-argument form is
    # no longer mistaken for the 3-argument form.
    {
        my $kw      = 'op' . 'en';
        my $open_re = qr/\b$kw\s*\(/;
        my $lineno  = 0;
        for my $mline (@lines) {
            $lineno++;
            while ($mline =~ /$open_re/g) {
                my $i      = pos($mline);   # index just after the '('
                my $len    = length($mline);
                my $depth  = 1;
                my $commas = 0;
                while ($i < $len && $depth > 0) {
                    my $c = substr($mline, $i, 1);
                    if ($c eq '(') {
                        $depth++;
                    }
                    elsif ($c eq ')') {
                        $depth--;
                    }
                    elsif ($c eq ',' && $depth == 1) {
                        $commas++;
                    }
                    $i++;
                }
                if ($commas >= 2) {
                    push @violations,
                        "Perl500503Syntax::OrDie: VIOLATION at $file line $lineno:\n"
                      . "  3-argument $kw() (introduced in Perl 5.6; use 2-argument form)\n";
                }
            }
        }
    }

    # Possessive quantifiers in code: a++  a*+  a?+  a{n,m}+
    {
        my $lineno2 = 0;
        for my $mline (@lines) {
            $lineno2++;
            while ($mline =~ /(?<=[a-zA-Z0-9_.)\]])((?:[+*?]|\{\d+(?:,\d*)?\})\+)/g) {
                my $quant  = $1;
                # In masked code a "++" is always the postfix-increment
                # operator (e.g. $pkg::var++, $a[0]++); a genuine possessive
                # quantifier can only occur inside a regex, which is masked,
                # and is caught by REGEX_BLACKLIST instead.
                next if $quant eq '++';
                my $qpos   = pos($mline) - length($quant) - 1;
                my $before = substr($mline, 0, $qpos + 1);
                next if $before =~ /\$\w+$/;
                next if $before =~ /\@\w+$/;
                push @violations,
                    "Perl500503Syntax::OrDie: VIOLATION at $file line $lineno2:\n"
                  . "  possessive quantifier (++/*+/?+/{n,m}+) (introduced in Perl 5.10)\n";
            }
        }
    }

    # Stage 2: RAW_BLACKLIST -- comment-stripped raw source
    my $comment_masked = _mask_comments($source);
    my @cmlines = split(/\n/, $comment_masked, -1);
    for my $entry (@RAW_BLACKLIST) {
        my ($pattern, $desc) = @{$entry};
        my $lineno = 0;
        for my $cmline (@cmlines) {
            $lineno++;
            if ($cmline =~ $pattern) {
                push @violations,
                    "Perl500503Syntax::OrDie: VIOLATION at $file line $lineno:\n"
                  . "  $desc\n";
            }
        }
    }

    # Stage 3: REGEX_BLACKLIST -- content of regex literals only
    # Each element of @$regex_bodies_ref is [$body_text, $line_number].
    # Escaped backslashes are first neutralised so that, for example, the
    # two-character literal sequence "\\h" (an escaped backslash followed
    # by the letter h, valid in every Perl) is not mistaken for the \h
    # horizontal-whitespace escape introduced in Perl 5.10.  Backslash
    # pairs are consumed left to right, leaving a genuine escape introducer
    # intact (so "\\\h" still exposes a real \h).
    my @scan_bodies;
    for my $rbody (@{$regex_bodies_ref}) {
        my ($body_text, $body_line) = @{$rbody};
        (my $scan = $body_text) =~ s/\\\\/\0\0/g;
        push @scan_bodies, [$scan, $body_line];
    }
    for my $entry (@REGEX_BLACKLIST) {
        my ($pattern, $desc) = @{$entry};
        for my $rbody (@scan_bodies) {
            my ($body_text, $body_line) = @{$rbody};
            if ($body_text =~ $pattern) {
                push @violations,
                    "Perl500503Syntax::OrDie: VIOLATION at $file line $body_line:\n"
                  . "  $desc\n";
            }
        }
    }

    return @violations;
}

# ======================================================================
# _mask_comments($source)
# ======================================================================
sub _mask_comments {
    my ($src) = @_;
    my $out = '';
    my $pos = 0;
    my $len = length($src);
    while ($pos < $len) {
        my $ch = substr($src, $pos, 1);
        if ($ch eq '#') {
            my $end = index($src, "\n", $pos);
            $end = $len if $end == -1;
            $out .= '#' . ('X' x ($end - $pos - 1));
            $pos = $end;
            next;
        }
        if ($ch eq '"') {
            my ($rep, $len2) = _mask_dquote($src, $pos);
            $out .= substr($src, $pos, $len2);
            $pos += $len2;
            next;
        }
        if ($ch eq "'") {
            my ($rep, $len2) = _mask_squote($src, $pos);
            $out .= substr($src, $pos, $len2);
            $pos += $len2;
            next;
        }
        $out .= $ch;
        $pos++;
    }
    return $out;
}

# ======================================================================
# _mask_source($source)
#
# Returns ($masked_source, \@regex_bodies).
# Each element of @regex_bodies is [$body_text, $start_line_number].
# ======================================================================
sub _mask_source {
    my ($src) = @_;
    my $out          = '';
    my $pos          = 0;
    my $len          = length($src);
    my @regex_bodies;
    my $in_pod       = 0;
    my @pending_heredocs;

    while ($pos < $len) {
        my $ch = substr($src, $pos, 1);

        # -- flush pending heredoc bodies at the end of their line ------
        # Heredoc bodies follow, in order, the line on which their <<
        # operators appear.  When that line's newline is reached, consume
        # every queued body so that two or more heredocs sharing one line
        # (e.g.  $_ = <<'A'; $x eq <<'B';) are all masked correctly.
        if ($ch eq "\n" && @pending_heredocs) {
            $out .= "\n";
            $pos++;
            while (@pending_heredocs) {
                my $sentinel = shift @pending_heredocs;
                my $remain   = substr($src, $pos);
                my $bodylen;
                if ($remain =~ /^\Q$sentinel\E[\t ]*\r?\n/m) {
                    $bodylen = length($`) + length($&);
                }
                elsif ($remain =~ /^\Q$sentinel\E[\t ]*\r?\z/m) {
                    $bodylen = length($`) + length($&);
                }
                else {
                    $bodylen = length($remain);
                }
                my $raw = substr($src, $pos, $bodylen);
                (my $masked_body = $raw) =~ s/[^\n]/X/g;
                $out .= $masked_body;
                $pos += $bodylen;
            }
            next;
        }

        # -- __END__ / __DATA__ : mask everything after this line ------
        if ($ch eq '_' && ($pos == 0 || substr($src, $pos - 1, 1) eq "\n")) {
            if (substr($src, $pos, 7) eq '__END__' || substr($src, $pos, 8) eq '__DATA__') {
                my $rest = substr($src, $pos);
                $rest =~ s/[^\n]/X/g;
                $out .= $rest;
                last;
            }
        }

        # -- POD block -------------------------------------------------
        if (!$in_pod && $ch eq '=' && ($pos == 0 || substr($src, $pos - 1, 1) eq "\n")) {
            my $nxt = substr($src, $pos, 12);
            if ($nxt =~ /^=(head|over|item|back|pod|begin|end|for|encoding)\b/) {
                $in_pod = 1;
            }
        }
        if ($in_pod) {
            if ($ch eq '=' && ($pos == 0 || substr($src, $pos - 1, 1) eq "\n")) {
                if (substr($src, $pos, 4) eq '=cut') {
                    my $end2 = index($src, "\n", $pos);
                    $end2 = $len if $end2 == -1;
                    $out .= 'X' x ($end2 - $pos);
                    $pos = $end2;
                    $in_pod = 0;
                    next;
                }
            }
            $out .= ($ch eq "\n") ? "\n" : 'X';
            $pos++;
            next;
        }

        # -- single-line comment  # ... --------------------------------
        if ($ch eq '#') {
            my $end = index($src, "\n", $pos);
            $end = $len if $end == -1;
            $out .= '#' . ('X' x ($end - $pos - 1));
            $pos = $end;
            next;
        }

        # -- double-quoted string  "..." --------------------------------
        if ($ch eq '"') {
            my ($rep, $len2) = _mask_dquote($src, $pos);
            $out .= $rep;
            $pos += $len2;
            next;
        }

        # -- single-quoted string  '...' --------------------------------
        if ($ch eq "'") {
            # Old-style package separator:  &jcode'tr  is  &jcode::tr .
            # When a sigil-led identifier ($pkg'var, &pkg'sub, *pkg'glob,
            # ...) abuts the apostrophe and a word character follows, the
            # apostrophe separates package components and is NOT a string
            # delimiter.  Emit it verbatim so the following name is not read
            # as the start of a new string.
            my $nextc = ($pos + 1 < $len) ? substr($src, $pos + 1, 1) : '';
            if ($out =~ /[\$\@\%\&\*]\w*\z/ && $nextc =~ /[A-Za-z_]/) {
                # Emit the apostrophe together with the whole following
                # identifier, so that a quote-like name such as the tr in
                # &jcode'tr is not subsequently read as the tr/// operator
                # (the operator detector keys off the preceding character).
                my $rest = substr($src, $pos);
                $rest =~ /\A('(\w+))/;
                $out .= $1;
                $pos += length($1);
                next;
            }
            my ($rep, $len2) = _mask_squote($src, $pos);
            $out .= $rep;
            $pos += $len2;
            next;
        }

        # -- backtick string  `...` -------------------------------------
        if ($ch eq '`') {
            my ($rep, $len2) = _mask_delimited($src, $pos, '`', '`');
            $out .= $rep;
            $pos += $len2;
            next;
        }

        # -- q{} qq{} qw{} qx{} (but NOT qr) ---------------------------
        if ($ch eq 'q' && $pos + 1 < $len) {
            my $nxt = substr($src, $pos + 1, 1);
            if ($nxt =~ /^[qwx]$/ && $pos + 2 < $len) {
                my $d = substr($src, $pos + 2, 1);
                if ($d =~ /\S/) {
                    my $cl = _matching_delim($d);
                    my ($rep, $len2) = _mask_delimited($src, $pos + 2, $d, $cl);
                    $out .= substr($src, $pos, 2) . $rep;
                    $pos += 2 + $len2;
                    next;
                }
            }
            elsif ($nxt =~ /^[\{\(\[\/\|!<]$/) {
                my $cl = _matching_delim($nxt);
                my ($rep, $len2) = _mask_delimited($src, $pos + 1, $nxt, $cl);
                $out .= 'q' . $rep;
                $pos += 1 + $len2;
                next;
            }
        }

        # -- heredoc start  <<WORD  <<"WORD"  <<'WORD' ------------------
        # Only the operator token (<< plus the sentinel) is masked here;
        # the body is consumed when the current line's newline is reached
        # (see the flush handler at the top of the loop).  This lets two or
        # more heredocs that share a single line all be masked in order.
        if ($ch eq '<' && $pos + 1 < $len && substr($src, $pos + 1, 1) eq '<') {
            my $rest = substr($src, $pos);
            if ($rest =~ /\A(<<\s*([\"']?)(\w+)\2)/) {
                my $token    = $1;
                my $sentinel = $3;
                push @pending_heredocs, $sentinel;
                $out .= 'X' x length($token);
                $pos += length($token);
                next;
            }
        }

        # -- Regex/subst/transliteration operators ----------------------
        # A quote-like operator (q/qq/qw/qx/qr/m/s/tr/y) is not recognised
        # when the immediately preceding character is a typeglob sigil '*',
        # a subroutine sigil '&', or a package-separator colon ':'; there
        # the following word is a symbol name, not an operator -- e.g. the
        # typeglob *s in  local(*s, $n) = @_;  or the function name tr in a
        # package-qualified call such as  mb::tr($_, 'A', '1').
        if ($out !~ /[\w\$\@\%*&:]\z/) {
            my $rest = substr($src, $pos);
            if ($rest =~ /\A(qr|m(?!y(?:\b|\s*=>))|s(?!ub(?:\b|\s*\{))|tr|y)\s*([^\w\s#])/s) {
                my $op    = $1;
                my $delim = $2;
                my $close = _matching_delim($delim);
                my $ws = '';
                if (substr($rest, length($op)) =~ /\A(\s*)([^\w\s#])/s) {
                    $ws    = $1;
                    $delim = $2;
                    $close = _matching_delim($delim);
                }
                my $op_len = length($op) + length($ws) + 1;

                # Compute line number of the start of this regex
                my $cur_line = 1 + _count_newlines($src, 0, $pos);

                $pos += $op_len;

                my ($body1, $blen1) = _mask_delimited_raw($src, $pos, $delim, $close);
                $pos += $blen1;
                my $pat1 = substr($body1, 0, length($body1) - 1);
                push @regex_bodies, [$pat1, $cur_line]
                    unless $op eq 'tr' || $op eq 'y';

                my $repl_len = 0;
                if ($op eq 's' || $op eq 'tr' || $op eq 'y') {
                    my $delim2 = $delim;
                    my $close2 = $close;
                    if ($delim ne $close) {
                        my $gap = substr($src, $pos);
                        if ($gap =~ /\A(\s*)([^\w\s])/s) {
                            $pos += length($1) + 1;
                            $repl_len += length($1) + 1;
                            $delim2 = $2;
                            $close2 = _matching_delim($delim2);
                        }
                    }
                    my ($body2, $blen2) = _mask_delimited_raw($src, $pos, $delim2, $close2);
                    $pos += $blen2;
                    $repl_len += $blen2;
                }

                my $flags = '';
                if (substr($src, $pos) =~ /\A([msixpgeodualncrs]*)/s) {
                    $flags = $1;
                    $pos += length($flags);
                }

                my $marker = '';
                if ($flags =~ /r/) {
                    if    ($op eq 's')                    { $marker = '__SR__'; }
                    elsif ($op eq 'tr' || $op eq 'y')    { $marker = '__TRR__'; }
                }

                my $raw_body = substr($src,
                    $pos - length($flags) - $repl_len - $blen1,
                    $blen1 + $repl_len);
                (my $mbody = $ws . $raw_body) =~ s/[^\n]/X/g;
                $out .= $op . $mbody . $flags . $marker;
                next;
            }
        }

        # -- bare /regex/ -- only in regex context ----------------------
        # The keyword alternation also lists the regex-first-argument list
        # operators split/grep/map: a '/' immediately following one of these
        # barewords can only begin a pattern (e.g. split //, $str), never a
        # division, so it is treated as a regex.  This keeps the empty
        # pattern // in  split //, ...  from being misread as the Perl 5.10
        # defined-or operator.
        if ($ch eq '/' &&
            $out =~ /(?:=~|!~|[=(,\{\[!&|;]|\b(?:if|while|unless|until|not|and|or|return|split|grep|map))\s*\z/s)
        {
            my $cur_line = 1 + _count_newlines($src, 0, $pos);
            $pos++;
            my ($body, $blen) = _mask_delimited_raw($src, $pos, '/', '/');
            $pos += $blen;
            my $pat = substr($body, 0, length($body) - 1);
            push @regex_bodies, [$pat, $cur_line];
            my $flags = '';
            if (substr($src, $pos) =~ /\A([msixpgeodualn]*)/s) {
                $flags = $1;
                $pos += length($flags);
            }
            (my $mtext = '/' . $body) =~ s/[^\n]/X/g;
            $out .= $mtext . $flags;
            next;
        }

        $out .= $ch;
        $pos++;
    }

    return ($out, \@regex_bodies);
}

# ======================================================================
# _count_newlines($str, $from, $to)
# Count newline characters in $str between positions $from and $to-1.
# Used to compute line numbers from byte offsets.
# ======================================================================
sub _count_newlines {
    my ($str, $from, $to) = @_;
    my $count = 0;
    my $p = $from;
    while ($p < $to) {
        $count++ if substr($str, $p, 1) eq "\n";
        $p++;
    }
    return $count;
}

# _mask_delimited_raw($src, $start, $open, $close)
sub _mask_delimited_raw {
    my ($src, $start, $open, $close) = @_;
    my $pos    = $start;
    my $slen   = length($src);
    my $depth  = 1;
    my $paired = ($open ne $close);
    my $out    = '';

    while ($pos < $slen) {
        my $c = substr($src, $pos, 1);
        $out .= $c;
        $pos++;
        if ($c eq '\\' && $pos < $slen) {
            $out .= substr($src, $pos, 1);
            $pos++;
            next;
        }
        if ($paired) {
            $depth++ if $c eq $open;
            $depth-- if $c eq $close;
            last if $depth == 0;
        }
        else {
            last if $c eq $close;
        }
    }
    return ($out, $pos - $start);
}

# ----------------------------------------------------------------------
sub _mask_dquote {
    my ($src, $start) = @_;
    my $pos = $start + 1;
    my $len = length($src);
    my $out = '"';
    while ($pos < $len) {
        my $ch = substr($src, $pos, 1);
        if ($ch eq '\\') {
            my $nx = ($pos + 1 < $len) ? substr($src, $pos + 1, 1) : '';
            $out .= ($nx eq "\n") ? "\\\n" : 'XX';
            $pos += 2;
        }
        elsif ($ch eq '"') {
            $out .= '"'; $pos++; last;
        }
        elsif ($ch eq "\n") {
            $out .= "\n"; $pos++;
        }
        else {
            $out .= 'X'; $pos++;
        }
    }
    return ($out, $pos - $start);
}

sub _mask_squote {
    my ($src, $start) = @_;
    my $pos = $start + 1;
    my $len = length($src);
    my $out = "'";
    while ($pos < $len) {
        my $ch = substr($src, $pos, 1);
        if ($ch eq '\\') {
            my $nx = ($pos + 1 < $len) ? substr($src, $pos + 1, 1) : '';
            $out .= ($nx eq "'" || $nx eq '\\') ? 'XX' : ('\\' . $nx);
            $pos += 2;
        }
        elsif ($ch eq "'") {
            $out .= "'"; $pos++; last;
        }
        elsif ($ch eq "\n") {
            $out .= "\n"; $pos++;
        }
        else {
            $out .= 'X'; $pos++;
        }
    }
    return ($out, $pos - $start);
}

sub _mask_delimited {
    my ($src, $start, $open, $close) = @_;
    my $pos   = $start + 1;
    my $len   = length($src);
    my $depth = 1;
    my $out   = $open;
    while ($pos < $len && $depth > 0) {
        my $ch = substr($src, $pos, 1);
        if ($ch eq '\\') {
            $out .= 'XX'; $pos += 2;
        }
        elsif ($open ne $close && $ch eq $open) {
            $depth++; $out .= $open; $pos++;
        }
        elsif ($ch eq $close) {
            $depth--; $out .= $close; $pos++;
        }
        elsif ($ch eq "\n") {
            $out .= "\n"; $pos++;
        }
        else {
            $out .= 'X'; $pos++;
        }
    }
    return ($out, $pos - $start);
}

sub _matching_delim {
    my ($o) = @_;
    return '{' eq $o ? '}' : '(' eq $o ? ')' :
           '[' eq $o ? ']' : '<' eq $o ? '>' : $o;
}

# ======================================================================
# _install_runtime_guards()
# ======================================================================
sub _install_runtime_guards {
    unless ($_OPEN_GUARDED) {
        $_OPEN_GUARDED = 1;
        no strict 'refs';
        *{'CORE::GLOBAL::open'} = \&_guarded_open;
    }
    unless ($_MKDIR_GUARDED) {
        $_MKDIR_GUARDED = 1;
        no strict 'refs';
        *{'CORE::GLOBAL::mkdir'} = \&_guarded_mkdir;
    }
    return;
}

sub _guarded_open {
    if (@_ >= 3) {
        my ($p, $f, $l) = caller(0);
        die "Perl500503Syntax::OrDie: RUNTIME VIOLATION at $f line $l:\n"
          . "  3-argument open() is not supported in Perl 5.005_03\n";
    }
    if (@_ >= 2 && ref $_[1]) {
        my ($p, $f, $l) = caller(0);
        die "Perl500503Syntax::OrDie: RUNTIME VIOLATION at $f line $l:\n"
          . "  open() with a reference as mode is not supported"
          . " in Perl 5.005_03\n";
    }
    no strict 'refs';
    if (@_ == 1) {
        my $ofn = 'CORE::' . 'open';
        return &{$ofn}($_[0]);
    }
    return CORE::open($_[0], $_[1]);
}

sub _guarded_mkdir {
    if (@_ < 2) {
        my ($p, $f, $l) = caller(0);
        die "Perl500503Syntax::OrDie: RUNTIME VIOLATION at $f line $l:\n"
          . "  mkdir() requires an explicit mode argument in Perl 5.005_03\n";
    }
    return CORE::mkdir($_[0], $_[1]);
}

# ======================================================================
# Public API
# ======================================================================
sub check_file {
    my $first = shift;
    my $path = ($first eq 'Perl500503Syntax::OrDie' || ref $first) ? shift : $first;
    my @v = _check_file($path);
    if (@v) {
        die join('', @v);
    }
    return;
}

sub check_source {
    my $first = shift;
    my ($src, $label);
    if ($first eq 'Perl500503Syntax::OrDie' || ref $first) {
        ($src, $label) = @_;
    }
    else {
        ($src, $label) = ($first, shift);
    }
    my @violations = _check_source($src, $label);
    return @violations;
}

# ======================================================================
# Command-line interface
# ======================================================================
sub _run_as_command {
    if (!@ARGV || ($ARGV[0] eq '--help') || ($ARGV[0] eq '-h')) {
        print "Usage: perl Perl500503Syntax/OrDie.pm <file> [<file> ...]\n";
        print "       perl Perl500503Syntax/OrDie.pm -\n";
        print "\n";
        print "  Check each <file> for constructs not available in Perl 5.005_03.\n";
        print "  Use '-' to read from standard input.\n";
        print "  Violations are reported with file name and line number.\n";
        print "\n";
        print "Example:\n";
        print "  perl lib/Perl500503Syntax/OrDie.pm myscript.pl\n";
        exit 0;
    }

    my $ok      = 0;
    my $fail    = 0;
    my $sep     = '-' x 60;
    for my $path (@ARGV) {
        print "$sep\n";
        my @violations;
        if ($path eq '-') {
            print "Checking: (standard input)\n";
            my $source = do { local $/; <STDIN> };
            @violations = _check_source($source, '(stdin)');
        }
        elsif (!-f $path) {
            print "ERROR: file not found: $path\n";
            $fail++;
            next;
        }
        else {
            print "Checking: $path\n";
            @violations = _check_file($path);
        }
        if (@violations) {
            print join('', @violations);
            $fail++;
        }
        else {
            print "  -> No violations found.\n";
            $ok++;
        }
    }
    print "$sep\n";
    my $total = $ok + $fail;
    print "Results: $ok/$total passed";
    if ($fail) {
        print ", $fail failed";
    }
    print "\n";
    exit($fail ? 1 : 0);
}


_run_as_command() if $0 eq __FILE__;

1;

__END__

=head1 NAME

Perl500503Syntax::OrDie - Validate that source code is compatible with Perl 5.005_03

=head1 VERSION

0.03

=head1 SYNOPSIS

    # Place at the top of any script you wish to guard:
    use Perl500503Syntax::OrDie;

    # The remainder of the script is validated automatically.
    use strict;
    use vars qw($x);
    $x = 42;
    open(FH, ">output.txt") or die $!;   # OK: 2-argument bareword form
    print FH "$x\n";
    close FH;
    mkdir("newdir", 0755);               # OK: explicit mode

    # Programmatic API (no auto-check, no runtime guards):
    use Perl500503Syntax::OrDie ();
    my @v = Perl500503Syntax::OrDie::check_source($source_text, 'label.pl');
    if (@v) { warn $_ for @v }
    Perl500503Syntax::OrDie::check_file('/path/to/script.pl');  # dies on violation

    # Command-line (stdin supported):
    #   perl lib/Perl500503Syntax/OrDie.pm myscript.pl
    #   perl lib/Perl500503Syntax/OrDie.pm script1.pl script2.pl ...
    #   perl lib/Perl500503Syntax/OrDie.pm -

=head1 DESCRIPTION

C<Perl500503Syntax::OrDie> helps authors who target Perl 5.005_03
compatibility detect incompatible constructs before deploying code to
legacy systems.

When loaded with C<use Perl500503Syntax::OrDie;>, the module:

=over 4

=item 1.

Uses C<caller()> to locate the calling source file.

=item 2.

Reads that file and runs a two-stage scan.  Stage 1: the source is
masked (comments, string literals, and regex literals replaced with
C<X> while preserving newlines) and scanned against C<@BLACKLIST>.
Stage 2: the content of each regex literal (C<m//>, C<s///>, C<qr//>,
C<//>) is scanned against C<@REGEX_BLACKLIST>.

=item 3.

Dies with file name and line number on any violation.

=item 4.

Installs C<CORE::GLOBAL::> overrides that enforce correct runtime
behaviour for C<open()> and C<mkdir()>.

=back

String and regex I<contents> are intentionally not inspected: a string
literal may freely contain any text (such as C<"say"> or C<"%v">)
without triggering a violation, because those are runtime values, not
syntax constructs.

No source-filter infrastructure (C<Filter::Util::Call>, etc.) is
required or used.  The module works on every Perl from 5.005_03
through the current release.

=head1 PROGRAMMATIC API

=over 4

=item C<check_source($source, $label)>

Scans C<$source> (a string) and returns a list of violation strings.
Returns an empty list when no violations are found.
Does B<not> C<die> automatically; the caller decides what to do with
the list.  String and regex contents are not inspected; only
source-level syntax constructs are flagged.

    my @v = Perl500503Syntax::OrDie::check_source($src, 'foo.pl');
    if (@v) { warn $_ for @v }

=item C<check_file($path)>

Reads C<$path> and calls C<check_source>.  Dies with the violation
list if any violations are found; returns normally otherwise.

=back

=head1 CHECKED CONSTRUCTS

=head2 Static checks (compile time, via source scan)

=over 4

=item * C<our> declaration -- Perl 5.6

=item * 3-argument C<open()> -- Perl 5.6

=item * C<use utf8> -- Perl 5.6

=item * C<use VERSION> where VERSION E<gt>= 5.6

=item * C<use vVERSION> where VERSION E<gt>= v5.6

=item * C<\x{HHHH}> Unicode escape -- Perl 5.6

=item * C<\N{name}> named character escape -- Perl 5.6

=item * Match-position arrays C<@+>/C<@-> and C<$+[N]>/C<$-[N]> -- Perl 5.6

=item * C<CHECK>/C<INIT> phase blocks -- Perl 5.6

=item * v-string notation (C<v1.2.3>) -- Perl 5.6

=item * C<$^V> version object -- Perl 5.6

=item * C<:lvalue> subroutine attribute -- Perl 5.6

=item * Typeglob component access C<*name{SLOT}> -- Perl 5.6

=item * C<use encoding> -- Perl 5.8

=item * C<use constant { HASH }> multi-constant form -- Perl 5.8

=item * defined-or assignment operator C<//=> -- Perl 5.10

=item * C<say> -- Perl 5.10 (C<-E<gt>say()> method calls and C<say =E<gt>> hash keys excluded)

=item * C<state variable> -- Perl 5.10

=item * C<given>/C<when> -- Perl 5.10

=item * Smart-match C<~~> -- Perl 5.10

=item * C<use feature> -- Perl 5.10
(the empty-import form C<use feature ()> is a no-op on every Perl version
and is treated as compatible)

=item * Defined-or operator C<//> (standalone) -- Perl 5.10

=item * C<UNITCHECK> phase block -- Perl 5.10

=item * C<${^MATCH}>/C<${^PREMATCH}>/C<${^POSTMATCH}> -- Perl 5.10

=item * C<package NAME VERSION> -- Perl 5.12

=item * Yada-yada C<...> -- Perl 5.12

=item * C<s///r> or C<tr///r> non-destructive flag -- Perl 5.14

=item * C<__SUB__> token -- Perl 5.16

=item * C<my sub>/C<state sub> lexical subroutine -- Perl 5.18

=item * Subroutine signatures -- Perl 5.20

=item * Postfix dereference C<$ref-E<gt>@*> -- Perl 5.20

=item * C<%hash{LIST}>/C<%array[LIST]> key/value slices -- Perl 5.20

=item * C<&.> C<|.> C<^.> C<~.> string bitwise operators -- Perl 5.22

=item * Reference aliasing in C<foreach> -- Perl 5.22

=item * C<E<lt>E<lt>E<gt>E<gt>> double-diamond operator -- Perl 5.22

=item * C</n> non-capturing regex flag -- Perl 5.22

=item * C<E<lt>E<lt>~> indented heredoc -- Perl 5.26

=item * C<isa> infix operator -- Perl 5.32 (C<-E<gt>isa()> method calls and C<isa()> function calls excluded)

=item * C<try> block -- Perl 5.34

=item * C<use builtin> -- Perl 5.36

=item * C<for my ($a,$b)> paired iteration -- Perl 5.36

=item * C<class> keyword -- Perl 5.38

=item * C<^^>/C<^^=> high-precedence logical XOR -- Perl 5.40

=item * C<__CLASS__> keyword -- Perl 5.40

=item * C<any BLOCK LIST>/C<all BLOCK LIST> keyword operators -- Perl 5.42
(suppressed when C<List::Util> imports C<any>/C<all>)

=item * C<my method> lexical method declaration -- Perl 5.42

=item * C<-E<gt>&name> lexical method call -- Perl 5.42

=item * Possessive quantifiers C<a++>/C<a*+>/C<a?+> in code -- Perl 5.10

=item * C<\p{}>C<\P{}> Unicode property escapes in regex -- Perl 5.6

=item * C<\K> (keep) in regex -- Perl 5.10

=item * Named capture C<(?E<lt>nameE<gt>...)> and C<\kE<lt>nameE<gt>> -- Perl 5.10

=item * Branch reset C<(?|...)> in regex -- Perl 5.10

=item * Backtrack control verbs C<(*VERB)> in regex -- Perl 5.10

=item * C<\h>/C<\H>/C<\v>/C<\V>/C<\R> regex escapes -- Perl 5.10

=item * Variable-length lookbehind in regex -- Perl 5.30/5.38

=item * Possessive quantifiers in regex -- Perl 5.10

=item * Recursive patterns C<(?PARNO)>/C<(?&name)>/C<(?R)> -- Perl 5.10

=item * C<\g{N}> relative/absolute backreference -- Perl 5.10

=back

=head2 RAW checks

None.  String and regex contents are intentionally not inspected:
string literals containing any text (including PerlIO layer names or
sprintf format flags) are valid Perl 5.005_03 syntax.  Only source-level
syntax constructs are checked.

=head2 Runtime checks (via CORE::GLOBAL:: overrides)

=over 4

=item * C<open()> with 3 or more arguments -- Perl 5.6

=item * C<open()> with a reference as the mode argument

=item * C<mkdir()> without an explicit mode argument -- Perl 5.6

=back

=head1 DIAGNOSTICS

=over 4

=item Perl500503Syntax::OrDie: VIOLATION at E<lt>fileE<gt> line E<lt>NE<gt>: E<lt>descriptionE<gt>

A construct not available in Perl 5.005_03 was detected in the
source file.

=item Perl500503Syntax::OrDie: RUNTIME VIOLATION at E<lt>fileE<gt> line E<lt>NE<gt>: E<lt>descriptionE<gt>

A built-in function was called at runtime in a manner not supported
by Perl 5.005_03.

=item Perl500503Syntax::OrDie: cannot open 'E<lt>fileE<gt>': E<lt>reasonE<gt>

The calling source file could not be opened for reading.

=back

=head1 COMPATIBILITY

This module itself is written to run on every Perl from 5.005_03
through the current release:

=over 4

=item * C<use vars> instead of C<our>

=item * C<$^W> semantics; no C<use warnings> without guard

=item * 2-argument C<open(BAREWORD, $path)> with bareword filehandles

=item * No syntax or function introduced after 5.005_03

=back

=head1 LIMITATIONS

=over 4

=item *

The source masker handles the most common quoting forms but is not a
full Perl lexer.  Unusual constructs may occasionally yield false
positives or negatives.

=item *

Dynamically generated code (e.g. C<eval "our \$x = 1">) is not
checked statically.

=item *

C<CORE::GLOBAL::> overrides affect the entire interpreter process.
Do not use this module in production deployments.

=item *

Regex violations are reported with the line number of the opening
delimiter of the regex, not the line within the regex body.

=back

=head1 SEE ALSO

L<perlpolicy>, L<perlhist>

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

