package Perl::Minify;

use strict;
use warnings;
use v5.16;

use PPI::Document ();
use Scalar::Util  qw/weaken/;

use Exporter 'import';
our @EXPORT    = ();
our @EXPORT_OK = qw(minify minify_sub minify_error);
our %EXPORT_TAGS = (all => [qw(minify minify_sub minify_error)]);

our $VERSION = '0.4.0';

# Error reporting
our $ERROR = '';

sub minify_error { return $ERROR }

# Keys we actually read from the user-supplied options hashref.
my @KNOWN_OPTS = qw(strip_comments strip_pod strip_whitespace strip_semicolons shorten_vars wrap optimize keep_name escape_newlines);

# Keywords where a space directly before '{' is never significant
# ("sub foo {", "else {", "grep { ... } ..."). All verified valid Perl.
my %BLOCK_KEYWORD = map { $_ => 1 } qw(sub else elsif unless grep map sort);

# Punctuation operators/structures where adjacent whitespace is never significant.
my %PUNCT_OP = map { $_ => 1 } (
    '+', '-', '*', '/', '%', '**', ',', ';', ':', '.', '=', '==', '!=',
    '<=', '>=', '<', '>', '!', '~', '|', '&', '^', '<<', '>>', '?',
    ':=', '=>', '&&', '||', '//', '->', '+=', '-=', '*=', '/=', '.=',
    '<=>', '++', '--', '**=', '<<=', '>>=',
);

# Token classes whose content we consider "string/regex-like" and whose
# interior whitespace must never be used as a wrap break point.
# NOTE: PPI::Token::QuoteLike::Words (qw()) is intentionally excluded:
# qw() items are whitespace-separated and Perl treats an inserted "\n"
# as equivalent to a space, so breaking inside qw() is always safe.
my @UNSAFE_TOKEN_CLASSES = qw(
    PPI::Token::Quote
    PPI::Token::QuoteLike::Command
    PPI::Token::QuoteLike::Regexp
    PPI::Token::QuoteLike::Readline
    PPI::Token::Regexp::Match
    PPI::Token::Regexp::Substitute
    PPI::Token::Regexp::Transliterate
    PPI::Token::HereDoc
    PPI::Token::Data
    PPI::Token::Pod
);

# Token classes where symbols cannot be renamed via PPI traversal because
# they're embedded in string content. We'll handle these with post-processing.
my @STRING_EMBEDDED_CLASSES = qw(
    PPI::Token::Quote::Double
    PPI::Token::Quote::Interpolate
    PPI::Token::QuoteLike::Command
    PPI::Token::QuoteLike::Backtick
    PPI::Token::QuoteLike::Regexp
    PPI::Token::Regexp::Match
    PPI::Token::Regexp::Substitute
    PPI::Token::Regexp::Transliterate
    PPI::Token::HereDoc
);

# Token classes that disqualify a symbol from being renamed at all.
my @NO_RENAME_ANCESTOR_CLASSES = qw(
    PPI::Token::Quote::Single
    PPI::Token::Quote::Literal
    PPI::Token::QuoteLike::Words
    PPI::Token::QuoteLike::Readline
);

##############################################################################
# Public API

sub minify {
    my ($code, $opts) = @_;
    $opts = _resolve_opts($opts);

    $ERROR = '';

    my $doc = PPI::Document->new(\$code);
    unless (defined $doc) {
        $ERROR = 'Failed to parse Perl code - PPI syntax error';
        return undef;
    }

    _strip_comments($doc)   if $opts->{strip_comments};
    _strip_pod($doc)        if $opts->{strip_pod};
    _strip_whitespace($doc) if $opts->{strip_whitespace};
    _strip_semicolons($doc) if $opts->{strip_semicolons};

    _optimize_constant_folding($doc) if $opts->{optimize};

    my $varmap = _shorten_vars($doc) if $opts->{shorten_vars};

    _escape_newlines($doc) if $opts->{escape_newlines};

    my $result = $doc->serialize;

    # Post-process: replace variables in interpolated strings/regexes
    if ($varmap && %$varmap) {
        $result = _replace_vars_in_interpolations($result, $doc, $varmap);
    }

    $result = _wrap($result, $opts->{wrap}) if $opts->{wrap};

    return $result;
}

sub minify_sub {
    my ($code, $sub_name, $opts) = @_;
    $opts = _resolve_opts($opts);

    $ERROR = '';

    my $doc = PPI::Document->new(\$code);
    unless (defined $doc) {
        $ERROR = 'Failed to parse Perl code - PPI syntax error';
        return undef;
    }

    my $found = $doc->find('PPI::Statement::Sub');
    $found = [] unless ref $found eq 'ARRAY';
    my ($sub) = grep { $_->name eq $sub_name } @$found;
    unless (defined $sub) {
        $ERROR = "Subroutine '$sub_name' not found in code";
        return undef;
    }

    # Clone the sub and optionally make it anonymous (in place modification)
    my $sub_clone = $sub->clone;
    _make_sub_anonymous($sub_clone) unless $opts->{keep_name};

    # Remove the sub from its parent to make it standalone
    $sub_clone->remove if $sub_clone->parent;

    # Create a minimal document containing just this sub
    my $new_doc = PPI::Document->new;
    $new_doc->{children} = [ $sub_clone ];
    $sub_clone->{parent} = $new_doc;
    weaken($sub_clone->{parent}) if ref($sub_clone->{parent});

    _strip_comments($new_doc)   if $opts->{strip_comments};
    _strip_pod($new_doc)        if $opts->{strip_pod};
    _strip_whitespace($new_doc) if $opts->{strip_whitespace};
    _strip_semicolons($new_doc) if $opts->{strip_semicolons};

    _optimize_constant_folding($new_doc) if $opts->{optimize};

    my $varmap = _shorten_vars($new_doc) if $opts->{shorten_vars};

    _escape_newlines($new_doc) if $opts->{escape_newlines};

    my $result = $new_doc->serialize;

    # Post-process: replace variables in interpolated strings/regexes
    if ($varmap && %$varmap) {
        $result = _replace_vars_in_interpolations($result, $new_doc, $varmap);
    }

    $result = _wrap($result, $opts->{wrap}) if $opts->{wrap};

    return $result;
}

##############################################################################
# Option handling

sub _resolve_opts {
    my ($opts) = @_;
    $opts = {} unless defined $opts && ref $opts eq 'HASH';

    my %defaults = (
        strip_comments   => 1,
        strip_pod        => 1,
        strip_whitespace => 1,
        strip_semicolons => 1,
        shorten_vars     => 0,
        wrap             => 0,
        optimize         => 0,
        keep_name        => 1,
        escape_newlines  => 1,
    );

    my %out = %defaults;
    for my $k (@KNOWN_OPTS) {
        $out{$k} = $opts->{$k} if exists $opts->{$k};
    }
    return \%out;
}

##############################################################################
# Modifying a sub to make it anonymous (in place)

sub _make_sub_anonymous {
    my ($sub) = @_;

    # PPI::Statement::Sub token layout:
    #   PPI::Token::Word        'sub'
    #   PPI::Token::Whitespace  ' '
    #   PPI::Token::Word        '<name>'
    #   PPI::Token::Whitespace  ' '
    #   PPI::Structure::Block   { ... }
    #
    # We remove the name and its surrounding whitespace.

    my @children = $sub->children;
    my $saw_sub = 0;

    for my $child (@children) {
        if (!$saw_sub && $child->isa('PPI::Token::Word') && $child->content eq 'sub') {
            $saw_sub = 1;
            next;
        }

        if ($saw_sub) {
            # Remove whitespace and the name word after 'sub'
            if ($child->isa('PPI::Token::Whitespace')) {
                $child->delete;
            } elsif ($child->isa('PPI::Token::Word')) {
                # This is the sub name - delete it
                $child->delete;
                last;  # Done - the rest is the block and signature
            } else {
                # Hit the block or something else - we're done
                last;
            }
        }
    }

    # Ensure there's a single space between 'sub' and the block
    my @kids = $sub->children;
    if (@kids >= 2 && $kids[0]->isa('PPI::Token::Word') && $kids[0]->content eq 'sub') {
        # Check if there's whitespace between sub and the next element
        if (!$kids[1]->isa('PPI::Token::Whitespace')) {
            # Insert a whitespace token
            my $ws = PPI::Token::Whitespace->new(' ');
            $ws->insert_before($kids[1]);
        }
    }
}

##############################################################################
# Generic PPI helpers

sub _find {
    my ($doc, $class) = @_;
    my $found = $doc->find($class);
    return ref $found ? $found : [];
}

sub _is_unsafe_class {
    my ($tok) = @_;
    for my $cls (@UNSAFE_TOKEN_CLASSES) {
        return 1 if $tok->isa($cls);
    }
    return 0;
}

##############################################################################
# Stripping passes

sub _strip_comments {
    my ($doc) = @_;
    my $found = _find($doc, 'PPI::Token::Comment');
    $_->delete for @$found;
}

sub _strip_pod {
    my ($doc) = @_;
    my $found = _find($doc, 'PPI::Token::Pod');
    $_->delete for @$found;
}

sub _strip_whitespace {
    my ($doc) = @_;
    my $found = _find($doc, 'PPI::Token::Whitespace');
    return unless @$found;

    for my $ws (@$found) {
        my $prev = $ws->sprevious_sibling;
        my $next = $ws->snext_sibling;

        # Leading or trailing whitespace: always delete.
        unless ($prev && $next) {
            $ws->delete;
            next;
        }

        my $pc = $prev->content;
        my $nc = $next->content;

        # Rule 1: word|word -> single space (keep "use strict", "$str eq", etc.)
        if ($pc =~ /\w$/ && $nc =~ /^\w/) {
            $ws->{content} = ' ';
            next;
        }

        # Rule 2: '.' concat operator next to a Number -> single space.
        if ($prev->isa('PPI::Token::Number') &&
            $next->isa('PPI::Token::Operator') && $nc eq '.') {
            $ws->{content} = ' ';
            next;
        }
        if ($prev->isa('PPI::Token::Operator') && $pc eq '.' &&
            $next->isa('PPI::Token::Number')) {
            $ws->{content} = ' ';
            next;
        }

        # Rule 3: two consecutive symbols/magic need separation ($fh $data).
        if (_is_symbol_like($prev) && _is_symbol_like($next)) {
            $ws->{content} = ' ';
            next;
        }

        # Rule 4: letter-starting operator (x, eq, ne, lt, ...) after word-char.
        if ($nc =~ /^[a-z]/i && $next->isa('PPI::Token::Operator') && $pc =~ /\w$/) {
            $ws->{content} = ' ';
            next;
        }

        # Rule 5 (new A): punctuation-operator/structure adjacency -> delete.
        if (_is_punct_op($prev) && _is_punct_op($next)) {
            $ws->delete;
            next;
        }

        # Rule 6 (new B): trim space after opening bracket (unless next is a
        # word - protects $h{key}, $h{ bareword } shorthand).
        if (_is_open_bracket($prev)) {
            unless ($next->isa('PPI::Token::Word')) {
                $ws->delete;
                next;
            }
        }

        # Rule 7 (new B): trim space before closing bracket (always safe).
        if (_is_close_bracket($next)) {
            $ws->delete;
            next;
        }

        # Rule 8: "keyword {" -> "keyword{" (sub name, else, elsif, unless,
        # grep/map/sort with block). Space is never significant here and the
        # word cannot run into '{'.
        if ($next->isa('PPI::Structure::Block') && $nc eq '{'
            && $prev->isa('PPI::Token::Word') && $BLOCK_KEYWORD{ $pc }) {
            $ws->delete;
            next;
        }

        # Default: delete unnecessary whitespace.
        $ws->delete;
    }
}

# A semicolon is optional before a closing block delimiter when the statement
# already ends in an expression. Avoid keyword-only statements and labels:
# removing their terminator can change the grammar (or make a label invalid).
sub _strip_semicolons {
    my ($doc) = @_;
    my $blocks = _find($doc, 'PPI::Structure::Block');

    for my $block (@$blocks) {
        my @children = grep {
            !$_->isa('PPI::Token::Whitespace')
                && !$_->isa('PPI::Token::Comment')
        } $block->children;
        my $stmt = $children[-1];
        next unless $stmt && $stmt->isa('PPI::Statement');

        my @tokens = $stmt->tokens;
        my $semi = pop @tokens;
        next unless $semi && $semi->isa('PPI::Token::Structure')
                 && $semi->content eq ';';

        my $last = $tokens[-1];
        next unless $last;
        next if $last->isa('PPI::Token::Word')
             || $last->isa('PPI::Token::Operator')
             || $last->isa('PPI::Token::Comment');

        $semi->delete;
    }
}

sub _is_symbol_like {
    my ($tok) = @_;
    return $tok->isa('PPI::Token::Symbol') || $tok->isa('PPI::Token::Magic');
}

sub _is_punct_op {
    my ($tok) = @_;
    return 0 unless $tok->isa('PPI::Token::Operator') || $tok->isa('PPI::Token::Structure');
    my $c = $tok->content;
    return exists $PUNCT_OP{$c};
}

sub _is_open_bracket {
    my ($tok) = @_;
    return 0 unless $tok->isa('PPI::Token::Structure');
    my $c = $tok->content;
    return $c eq '(' || $c eq '[' || $c eq '{';
}

sub _is_close_bracket {
    my ($tok) = @_;
    return 0 unless $tok->isa('PPI::Token::Structure');
    my $c = $tok->content;
    return $c eq ')' || $c eq ']' || $c eq '}';
}

##############################################################################
# Variable shortening

sub _shorten_vars {
    my ($doc) = @_;
    my %map;

    # Pass 1a: explicit my/our/state declarations.
    # NOTE: PPI occasionally misclassifies "open(my $fh, "<", $_[0])" as a
    # PPI::Statement::Variable too. _extract_decl_names handles this by
    # stopping at the first non-LHS token, so only the real declared
    # names (e.g. $fh) get collected, never subsequent args like $_[0].
    my $var_stmts = _find($doc, 'PPI::Statement::Variable');
    for my $stmt (@$var_stmts) {
        # Only treat as a declaration if the first significant token is
        # my/our/state. Skip "local" - that's localization, not a lexical
        # declaration, and the variables involved are usually magic ($/, etc).
        my @sig = grep { !$_->isa('PPI::Token::Whitespace') } $stmt->children;
        next unless @sig && $sig[0]->isa('PPI::Token::Word')
                    && $sig[0]->content =~ /^(my|our|state)$/;
        for my $name (_extract_decl_names($stmt)) {
            $map{$name} //= _next_short_name(\%map, $name);
        }
    }

    # Pass 1b: inline my/our/state inside compound statements (for my $x ...).
    my $compounds = _find($doc, 'PPI::Statement::Compound');
    for my $stmt (@$compounds) {
        my @kids = $stmt->children;
        for (my $i = 0; $i < @kids; $i++) {
            my $c = $kids[$i];
            next unless $c->isa('PPI::Token::Word') && $c->content =~ /^(my|our|state)$/;
            # Skip whitespace/comments to the first significant token after
            # the declaration keyword, so "for my $x ..." works even when the
            # token stream still contains spacing (strip_whitespace => 0).
            my $j = $i + 1;
            while ($j < @kids
                && ($kids[$j]->isa('PPI::Token::Whitespace')
                 || $kids[$j]->isa('PPI::Token::Comment'))) {
                $j++;
            }
            my $n = $kids[$j] // next;
            next unless $n->isa('PPI::Token::Symbol');
            my $name = $n->content;
            next unless $name =~ /^[\$\@\%]/;
            $map{$name} //= _next_short_name(\%map, $name);
        }
    }

    return \%map unless %map;

    # Pass 2: rename symbol references in PPI-parseable locations
    # (skipping symbols in non-interpolating strings or other unsafe contexts).
    my $symbols = _find($doc, 'PPI::Token::Symbol');
    for my $sym (@$symbols) {
        next if $sym->isa('PPI::Token::Magic');
        next if _symbol_in_unsafe_context($sym);

        my $var = $sym->content;
        if (exists $map{$var}) {
            $sym->{content} = $map{$var};
            next;
        }

        # Cross-sigil fallback (e.g. %hash -> $hash{...}).
        my $base = $var;
        $base =~ s/^[\$\@\%]//;
        for my $sigil (qw/$ @ %/) {
            my $alt = $sigil . $base;
            if (exists $map{$alt}) {
                my $short = $map{$alt};
                $short =~ s/^[\$\@\%]//;
                $sym->{content} = substr($var, 0, 1) . $short;
                last;
            }
        }
    }

    return \%map;
}

# Post-process replacement for variables in interpolated strings/regexes.
# PPI doesn't parse the interior of these tokens, so we must do text replacement.
# We only replace within the content of interpolation-supporting tokens.
sub _replace_vars_in_interpolations {
    my ($text, $doc, $map) = @_;

    # Find all tokens that support interpolation
    my @interp_classes = qw(
        PPI::Token::Quote::Double
        PPI::Token::Quote::Interpolate
        PPI::Token::QuoteLike::Command
        PPI::Token::QuoteLike::Backtick
        PPI::Token::QuoteLike::Regexp
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::HereDoc
    );

    my @tokens;
    for my $class (@interp_classes) {
        my $found = $doc->find($class);
        push @tokens, @$found if ref $found eq 'ARRAY';
    }

    return $text unless @tokens;

    # Build a map of original content -> replacement content for each token
    my %replacements;

    for my $tok (@tokens) {
        my $orig_content = $tok->content;
        my $new_content = $orig_content;

        # Sort variables by length (longest first) to avoid partial replacements
        my @vars = sort { length($b) <=> length($a) } keys %$map;

        for my $var (@vars) {
            my $replacement = $map->{$var};
            my $sigil = substr($var, 0, 1);
            my $name = substr($var, 1);
            my $short_name = substr($replacement, 1);

            # Match the variable with word boundaries
            # Pattern: $varname followed by non-word-char or { or [ or end
            my $pattern = qr/\Q$var\E(?=\{|\[|[^\w]|\z)/;
            $new_content =~ s/$pattern/$replacement/g;

            # Handle cross-sigil: if we renamed %hash, also rename $hash{...} and @hash[...]
            if ($sigil eq '%') {
                $new_content =~ s/\$\Q$name\E(?=\{)/'$' . $short_name/ge;
                $new_content =~ s/\@\Q$name\E(?=\[)/'@' . $short_name/ge;
            } elsif ($sigil eq '@') {
                $new_content =~ s/\$\Q$name\E(?=\[)/'$' . $short_name/ge;
            }
        }

        if ($new_content ne $orig_content) {
            $replacements{$orig_content} = $new_content;
        }
    }

    # Apply replacements to the serialized text
    # We need to be careful to replace exact matches only
    for my $orig (keys %replacements) {
        my $new = $replacements{$orig};
        # Use quotemeta to escape special regex characters in the original content
        my $quoted = quotemeta($orig);
        $text =~ s/$quoted/$new/g;
    }

    return $text;
}

sub _symbol_in_unsafe_context {
    my ($sym) = @_;
    my $cur = $sym;
    while (defined $cur) {
        for my $cls (@NO_RENAME_ANCESTOR_CLASSES) {
            return 1 if $cur->isa($cls);
        }
        $cur = $cur->parent;
    }
    return 0;
}

sub _extract_decl_names {
    my ($stmt) = @_;
    my @names;
    my $found_decl_word = 0;
    for my $child ($stmt->children) {
        # Stop at the assignment operator - everything after is RHS, not a
        # declared name.
        last if $child->isa('PPI::Token::Operator') && $child->content eq '=';
        next if $child->isa('PPI::Token::Whitespace');
        next if $child->isa('PPI::Token::Comment');

        if (!$found_decl_word) {
            if ($child->isa('PPI::Token::Word')
                && $child->content =~ /^(my|our|state)$/) {
                $found_decl_word = 1;
            }
            next;
        }

        # We are in the LHS. Collect symbols and recurse into list
        # structures. A ',' separator is allowed; anything else (a
        # String, Word, or non-list Operator) means the LHS is over -
        # stop. This guards against false-positive PPI::Statement::Variable
        # nodes like "my $fh, "<", $_[0]" produced by open(my $fh, ...).
        if ($child->isa('PPI::Token::Symbol')) {
            my $var = $child->content;
            push @names, $var if $var =~ /^[\$\@\%]/;
            next;
        }
        if ($child->isa('PPI::Token::Operator') && $child->content eq ',') {
            next;
        }
        if ($child->isa('PPI::Structure::List')
         || $child->isa('PPI::Structure::Constructor')
         || $child->isa('PPI::Structure::Block')) {
            _extract_names_r($child, \@names);
            next;
        }
        last;
    }
    return @names;
}

sub _extract_names_r {
    my ($elem, $names) = @_;
    for my $child ($elem->children) {
        if ($child->isa('PPI::Token::Symbol')) {
            my $var = $child->content;
            push @$names, $var if $var =~ /^[\$\@\%]/;
        } elsif ($child->isa('PPI::Node')) {
            _extract_names_r($child, $names);
        }
    }
}

sub _next_short_name {
    my ($map, $orig) = @_;
    my $sigil = substr($orig, 0, 1);

    # Build a hash of taken names for O(1) lookup instead of O(N) linear search
    my %taken = map { defined $_ ? ($_ => 1) : () } values %$map;

    # Single letters - avoid $a, $b (used in sort blocks).
    for my $letter ('c' .. 'z', 'a', 'b') {
        my $name = $sigil . $letter;
        return $name unless $taken{$name};
    }
    # Two-letter names.
    for my $l1 ('a' .. 'z') {
        for my $l2 ('a' .. 'z') {
            my $name = $sigil . $l1 . $l2;
            return $name unless $taken{$name};
        }
    }
    # Numeric fallback.
    my $i = 0;
    while (1) {
        my $name = $sigil . 'v' . $i++;
        return $name unless $taken{$name};
    }
}

##############################################################################
# Optimization passes

sub _optimize_constant_folding {
    my ($doc) = @_;

    # Find simple binary operations with constant operands.
    # We work on SIGNIFICANT children (schildren) so spacing doesn't hide
    # Number/Operator/Number triples, and we fold in place (mutate the Number
    # token's content + remove the operator and its neighbouring whitespace)
    # rather than inserting new tokens.
    my $statements = _find($doc, 'PPI::Statement');

    for my $stmt (@$statements) {
        my $folded = 1;
        while ($folded) {
            $folded = 0;

            my @sig = $stmt->schildren;

            for (my $i = 0; $i < $#sig - 1; $i++) {
                next unless $sig[$i]->isa('PPI::Token::Number');
                next unless $sig[$i+1]->isa('PPI::Token::Operator');
                next unless $sig[$i+2]->isa('PPI::Token::Number');

                my $left = $sig[$i]->content;
                my $op = $sig[$i+1]->content;
                my $right = $sig[$i+2]->content;

                # Only handle safe arithmetic operators
                next unless $op =~ /^[+\-*]$/;  # Division excluded for safety

                # Precedence guard for chained folds: a +/- pair must not sit
                # next to a */ or ** operator, otherwise left-to-right folding
                # would evaluate out of order (e.g. 2 - 3 * 4 folding 2-3).
                my $before_t = $sig[$i]->sprevious_sibling;
                my $after_t = $sig[$i+2]->snext_sibling;
                my $before = $before_t && $before_t->isa('PPI::Token::Operator') ? $before_t->content : '';
                my $after = $after_t && $after_t->isa('PPI::Token::Operator') ? $after_t->content : '';
                my $high = qr{^[/*]$|^\*\*$};
                if ($op =~ /^[+\-]$/ && ($before =~ $high || $after =~ $high)) {
                    next;
                }
                if ($op eq '*' && $before eq '/') {
                    next;
                }

                my $result;
                if    ($op eq '+') { $result = $left + $right; }
                elsif ($op eq '-') { $result = $left - $right; }
                else               { $result = $left * $right; }

                # Fold in place: rewrite the left number with the result and
                # drop the operator and right operand. Whitespace cleanup is
                # left to the whitespace stripping pass (which runs after
                # optimize), so chained folds re-rescan cleanly.
                $sig[$i]->{content} = $result;
                $sig[$i+1]->delete;
                $sig[$i+2]->delete;

                # Successful fold - rescan the statement for more folds
                $folded = 1;
                last;
            }
        }
    }
}

##############################################################################
# Escape literal LF/TAB/CR inside string literals as \n \t \r.
#
# Double-quoted and qq strings: literal control chars in the raw body are
# replaced in place. "\<LF>" becomes "\n" (the backslash must not be doubled).
# Single-quoted and q() strings: decoded, and if the value contains a control
# char, re-emitted as a double-quoted string with "\\", '"', '$', '@' escaped.
#
# Token class is left unchanged on purpose: _replace_vars_in_interpolations
# matches by class, and must not rename variables inside the escaped text.

my %CTRL_ESCAPE = ("\n" => '\n', "\t" => '\t', "\r" => '\r');

sub _escape_newlines {
    my ($doc) = @_;

    for my $tok (@{ _find($doc, 'PPI::Token::Quote::Single') },
                 @{ _find($doc, 'PPI::Token::Quote::Literal') }) {
        _escape_single_token($tok);
    }
    for my $tok (@{ _find($doc, 'PPI::Token::Quote::Double') },
                 @{ _find($doc, 'PPI::Token::Quote::Interpolate') }) {
        _escape_double_token($tok);
    }
}

# Returns (prefix, open, body, close) where body is the raw text between the
# delimiters (as PPI's ->string reports it), or an empty list if unparseable.
sub _split_quote {
    my ($tok) = @_;
    my $content = $tok->content;
    my $body    = $tok->string;
    return () unless defined $body;

    # Layout: prefix . open . body . close, with single-char delimiters.
    my $body_pos = length($content) - 1 - length($body);
    return () if $body_pos < 1;
    return () unless substr($content, $body_pos, length $body) eq $body;

    my $head   = substr($content, 0, $body_pos);    # prefix + open delimiter
    my $open   = substr($head, -1);
    my $prefix = substr($head, 0, -1);
    my $close  = substr($content, -1);
    return ($prefix, $open, $body, $close);
}

sub _escape_single_token {
    my ($tok) = @_;
    my ($prefix, $open, $body, $close) = _split_quote($tok);
    return unless defined $body;

    # Decode: only \\ and an escaped delimiter are escapes in single quotes.
    my $val = '';
    my $len = length $body;
    for (my $i = 0; $i < $len; ) {
        my $c = substr($body, $i, 1);
        if ($c eq '\\' && $i + 1 < $len) {
            my $n = substr($body, $i + 1, 1);
            if ($n eq '\\' || $n eq $open || $n eq $close) {
                $val .= $n;
                $i += 2;
                next;
            }
        }
        $val .= $c;
        $i++;
    }

    return unless $val =~ /[\n\t\r]/;

    (my $enc = $val) =~ s/([\\"\$\@])/\\$1/g;
    $enc =~ s/([\n\t\r])/$CTRL_ESCAPE{$1}/g;
    $tok->{content} = qq{"$enc"};
}

sub _escape_double_token {
    my ($tok) = @_;
    my ($prefix, $open, $body, $close) = _split_quote($tok);
    return unless defined $body;
    return unless $body =~ /[\n\t\r]/;

    # A control char inside an interpolated expression ("@{[ ... ]}",
    # "${ ... }", "$h{...}", "$a[...]", "->{...}") is Perl code, and "\n" there
    # is a syntax error. Leave such strings alone.
    return if $body =~ /[\$\@]\{|[\$\@][\w:]+[\[\{]|->[\[\{]/;

    my $out = '';
    my $len = length $body;
    for (my $i = 0; $i < $len; ) {
        my $c = substr($body, $i, 1);
        if ($c eq '\\' && $i + 1 < $len) {
            my $n = substr($body, $i + 1, 1);
            $out .= exists $CTRL_ESCAPE{$n} ? $CTRL_ESCAPE{$n} : "$c$n";
            $i += 2;
            next;
        }
        $out .= exists $CTRL_ESCAPE{$c} ? $CTRL_ESCAPE{$c} : $c;
        $i++;
    }

    $tok->{content} = $prefix . $open . $out . $close;
}

##############################################################################
# Word wrap (string/regex aware)

sub _wrap {
    my ($text, $width) = @_;
    return $text unless $width > 0 && length($text) > $width;

    # Build per-token offset map + unsafe ranges + semicolon offsets.
    # Derive tokens from $text itself (a fresh parse) rather than the caller's
    # $doc, because $text may have been post-processed by
    # _replace_vars_in_interpolations(), which changes string lengths and
    # invalidates offsets computed against the original document.
    my $wrap_doc = PPI::Document->new(\$text);
    my $all_tokens = $wrap_doc ? $wrap_doc->find('PPI::Token') : [];
    $all_tokens = ref $all_tokens ? $all_tokens : [];
    my @unsafe_ranges;
    my @semi_offsets;
    {
        my $off = 0;
        for my $tok (@$all_tokens) {
            my $len = length($tok->content);
            if (_is_unsafe_class($tok)) {
                push @unsafe_ranges, [ $off, $off + $len ];
            }
            if ($tok->isa('PPI::Token::Structure') && $tok->content eq ';') {
                push @semi_offsets, $off + $len - 1;
            }
            $off += $len;
        }
    }
    @unsafe_ranges = sort { $a->[0] <=> $b->[0] } @unsafe_ranges;

    # Split at semicolons into statements (each includes its trailing ';').
    my @stmts;
    my $prev = 0;
    for my $pos (@semi_offsets) {
        push @stmts, substr($text, $prev, $pos - $prev + 1);
        $prev = $pos + 1;
    }
    if ($prev < length($text)) {
        my $rest = substr($text, $prev);
        push @stmts, $rest if length($rest);
    }

    # Pack statements into lines greedily.
    my @lines;
    my $line = '';
    for my $stmt (@stmts) {
        $stmt =~ s/\n+\z//;
        next if $stmt eq '';
        if ($line eq '') {
            $line = $stmt;
        } else {
            my $cand = $line . $stmt;
            if (length($cand) <= $width) {
                $line = $cand;
            } else {
                push @lines, $line;
                $line = $stmt;
            }
        }
    }
    push @lines, $line if $line ne '';

    # Split overlong lines at safe spaces.
    my @final;
    for my $l (@lines) {
        if (length($l) > $width) {
            my $split_result = _split_line_safe($l, $width, \@unsafe_ranges);
            push @final, split /\n/, $split_result;
        } else {
            push @final, $l;
        }
    }

    # Repack: if a line is short and the next line would fit when combined, merge them.
    # Also rebalance: if a line is very short, try to move content from the previous line.
    my @repacked;
    for my $i (0 .. $#final) {
        if (!@repacked) {
            push @repacked, $final[$i];
            next;
        }

        my $curr_line = $final[$i];
        my $prev_line = $repacked[-1];

        # Try to append current line to previous if both fit.
        # Add a space separator only when needed (prev ends with word-char AND
        # curr starts with word-char), e.g. inside qw() where splitting consumed
        # the separating space. In most other cases (; boundary, ) boundary),
        # no space is needed.
        my $sep = ($prev_line =~ /\w$/ && $curr_line =~ /^\w/) ? ' ' : '';
        my $cand = $prev_line . $sep . $curr_line;
        if (length($cand) <= $width) {
            $repacked[-1] = $cand;
        } elsif (length($curr_line) < $width / 3 && length($prev_line) > $width * 0.75) {
            # Current line is quite short and previous line is quite full.
            # Try to rebalance by moving content from previous to current.
            my $last_space = rindex($prev_line, ' ');
            if ($last_space > 0) {
                # Check if this space is inside a string literal
                my @prev_unsafe = _local_unsafe_ranges($prev_line);
                my $space_is_safe = !_in_any_range($last_space, \@prev_unsafe);

                if ($space_is_safe) {
                    my $move_part = substr($prev_line, $last_space + 1);
                    my $new_curr = $move_part . ' ' . $curr_line;

                    # Only rebalance if new current line fits within width
                    # and is at least as long as the current line (no worse than before)
                    if (length($new_curr) <= $width && length($new_curr) >= length($curr_line)) {
                        $repacked[-1] = substr($prev_line, 0, $last_space);
                        push @repacked, $new_curr;
                    } else {
                        push @repacked, $curr_line;
                    }
                } else {
                    push @repacked, $curr_line;
                }
            } else {
                push @repacked, $curr_line;
            }
        } else {
            # Try splitting curr_line at its first semicolon (that is not at the very
            # end). This handles the case where greedy packing merged multiple statements
            # onto one line, making it too long to merge with prev_line. Splitting at a
            # statement boundary keeps code intact and avoids breaking inside qw().
            my $semi_pos = index($curr_line, ';');
            if ($semi_pos > 0 && $semi_pos < length($curr_line) - 1) {
                my $prefix = substr($curr_line, 0, $semi_pos + 1);   # include the ;
                my $suffix = substr($curr_line, $semi_pos + 1);
                my $cand_split = $prev_line . $sep . $prefix;
                if (length($cand_split) <= $width) {
                    $repacked[-1] = $cand_split;
                    push @repacked, $suffix;
                    next;
                }
            }
            push @repacked, $curr_line;
        }
    }

    # Join lines, handling string literals that span line breaks
    my @result_lines;
    for my $i (0 .. $#repacked) {
        if ($i == 0) {
            push @result_lines, $repacked[$i];
            next;
        }

        my $prev = $result_lines[-1];
        my $curr = $repacked[$i];

        # Check if prev ends with an unclosed string that continues in curr
        my $prev_ends_in_string = _line_ends_in_unclosed_string($prev);
        my $curr_starts_continuation = _line_starts_with_string_continuation($curr);

        if ($prev_ends_in_string && $curr_starts_continuation) {
            # Need to close the string, add concat, newline, and reopen
            my $quote = $prev_ends_in_string; # '"' or "'"
            $result_lines[-1] = $prev . $quote . '.';
            push @result_lines, $quote . $curr;
        } else {
            push @result_lines, $curr;
        }
    }

    return join "\n", @result_lines;
}

# Find byte offset of the first occurrence of $line within $text starting at $start.
# Used to map a packed line back into the serialized text so we can consult
# unsafe_ranges. We track absolute positions as we build segments.
sub _split_line_safe {
    my ($line, $width, $ranges) = @_;

    # Enumerate space offsets within $line; mark each as safe/unsafe.
    my @safe_offsets;
    for (my $i = 0; $i < length($line); $i++) {
        next unless substr($line, $i, 1) eq ' ';
        # In _wrap we don't carry the absolute text offset here, but the unsafe
        # information we care about is localized: a space that sits inside a
        # string/regex literal on this very line. Re-detect that by walking the
        # line with a lightweight state machine rather than relying on the
        # serialized-text mask. (The mask is hard to align after newline joins.)
        push @safe_offsets, $i;
    }

    # Filter out safe offsets that fall inside any unsafe substring of $line.
    my @locally_unsafe = _local_unsafe_ranges($line);
    @safe_offsets = grep { !_in_any_range($_, \@locally_unsafe) } @safe_offsets;

    return $line unless @safe_offsets;

    # Greedy pack at safe spaces.
    my @out;
    my $start = 0;
    for my $si (@safe_offsets) {
        my $segment = substr($line, $start, $si - $start);
        if (!@out) {
            push @out, $segment;
            $start = $si + 1;
            next;
        }
        my $cand = $out[-1] . ' ' . $segment;
        if (length($cand) <= $width) {
            $out[-1] = $cand;
        } else {
            push @out, $segment;
        }
        $start = $si + 1;
    }

    my $tail = substr($line, $start);
    if (!@out) {
        push @out, $tail;
    } elsif (length($out[-1]) + 1 + length($tail) <= $width) {
        $out[-1] .= ' ' . $tail;
    } else {
        push @out, $tail;
    }

    # Join segments, but handle string literals that span across breaks
    my @final_out;
    for my $i (0 .. $#out) {
        if ($i == 0) {
            push @final_out, $out[$i];
            next;
        }

        my $prev = $final_out[-1];
        my $curr = $out[$i];

        # Check if prev ends with an unclosed string that continues in curr
        my $prev_ends_in_string = _line_ends_in_unclosed_string($prev);
        my $curr_starts_string = _line_starts_with_string_continuation($curr);

        if ($prev_ends_in_string && $curr_starts_string) {
            # Need to close the string, add concat, and reopen
            # Determine quote type from prev
            my $quote = $prev_ends_in_string; # '"' or "'"
            $final_out[-1] = $prev . $quote . '.';
            push @final_out, $quote . $curr;
        } else {
            push @final_out, $curr;
        }
    }

    return join "\n", @final_out;
}

# Walk $line with a quote/regex-aware state machine and return [start,end) ranges
# whose bytes fall inside a string/regex literal. Conservative: errs on marking
# MORE bytes unsafe, which means fewer breaks -> safer.
sub _local_unsafe_ranges {
    my ($line) = @_;
    my @ranges;

    # We track opens for:  " ' /  q() qq() qw() qx() m// s/// tr/// y/// and
    # escape sequences such as \e \x . The safe approach is to flag any byte
    # that is inside a pairing quote/regex construct.
    my $len = length($line);
    my $i = 0;
    while ($i < $len) {
        my $ch = substr($line, $i, 1);

        # Double- or single-quoted string.
        if ($ch eq '"' || $ch eq "'") {
            my $q   = $ch;
            my $s   = $i;
            $i++;
            while ($i < $len) {
                my $c = substr($line, $i, 1);
                if ($c eq '\\' && $i + 1 < $len) { $i += 2; next; }
                if ($c eq $q) { $i++; last; }
                $i++;
            }
            push @ranges, [ $s, $i ];
            next;
        }

        # Regex match m// or substitution s/// or transliteration tr///y///  -> flag
        # entire body up to closing delimiters. Conservative: scan to the
        # matching delimiter, allowing paired delims ( s{...}{...} ).
        if ($ch =~ m{[msy]} && $i + 1 < $len && substr($line, $i + 1, 1) =~ /[ \t]/) {
            # Skip whitespace, then look for opening delim.
            my $j = $i + 1;
            while ($j < $len && substr($line, $j, 1) =~ /[ \t]/) { $j++; }
            my $body_start = $j;
            my $delim = $j < $len ? substr($line, $j, 1) : '';
            if ($delim =~ /[{\[(<]/) {
                my $close = $delim eq '{' ? '}' :
                            $delim eq '[' ? ']' :
                            $delim eq '(' ? ')' :
                            $delim eq '<' ? '>' : $delim;
                my $depth = 1;
                $j++;
                while ($j < $len && $depth > 0) {
                    my $c = substr($line, $j, 1);
                    if    ($c eq $delim) { $depth++; }
                    elsif ($c eq $close) { $depth--; }
                    $j++;
                }
                push @ranges, [ $i, $j ];
                $i = $j;
                next;
            } elsif ($delim ne '') {
                $j++;
                while ($j < $len && substr($line, $j, 1) ne $delim) {
                    $j++ if substr($line, $j, 1) eq '\\' && $j + 1 < $len;
                    $j++;
                }
                $j++ if $j < $len;
                # For s/// and tr/// there is a second section.
                if ($ch eq 's' || $ch eq 'y' || ($ch eq 't' && substr($line,$i,2) eq 'tr')) {
                    if ($j <= $len && $j < $len) {
                        my $d2 = substr($line, $j, 1);
                        if ($d2 =~ /[{\[(<]/) {
                            my $close2 = $d2 eq '{' ? '}' :
                                         $d2 eq '[' ? ']' :
                                         $d2 eq '(' ? ')' :
                                         $d2 eq '<' ? '>' : $d2;
                            my $depth = 1;
                            $j++;
                            while ($j < $len && $depth > 0) {
                                my $c = substr($line, $j, 1);
                                if    ($c eq $d2)   { $depth++; }
                                elsif ($c eq $close2) { $depth--; }
                                $j++;
                            }
                        } else {
                            while ($j < $len && substr($line, $j, 1) ne $d2) {
                                $j++ if substr($line, $j, 1) eq '\\' && $j + 1 < $len;
                                $j++;
                            }
                            $j++ if $j < $len;
                        }
                    }
                }
                push @ranges, [ $i, $j ];
                $i = $j;
                next;
            }
        }

        # Bare regex /.../  - hard to distinguish from division reliably; only
        # treat as regex if followed by content that obviously is one. Skip
        # this heuristic rather than risk mis-flagging division. (Default: not
        # flagged - relies on _is_unsafe_class from PPI mask, which already
        # covers PPI::Token::Regexp::Match in the token-walk pass.)

        # qw( ... ) is intentionally NOT flagged as unsafe: qw() items are
        # whitespace-separated and an inserted "\n" is treated identically
        # to a space, so splitting inside qw() is always safe. Skip the
        # qw-block detection entirely so its interior spaces remain breakable.

        $i++;
    }

    return @ranges;
}

sub _in_any_range {
    my ($pos, $ranges) = @_;
    for my $r (@$ranges) {
        return 1 if $pos >= $r->[0] && $pos < $r->[1];
    }
    return 0;
}

# Check if a line ends with an unclosed string literal.
# Returns the quote character ('"' or "'") if unclosed, undef otherwise.
sub _line_ends_in_unclosed_string {
    my ($line) = @_;

    # Count unescaped quotes
    my $in_string = '';
    my $i = 0;
    while ($i < length($line)) {
        my $ch = substr($line, $i, 1);

        if (!$in_string) {
            if ($ch eq '"' || $ch eq "'") {
                $in_string = $ch;
            }
        } else {
            if ($ch eq '\\') {
                $i++; # Skip next char
            } elsif ($ch eq $in_string) {
                $in_string = '';
            }
        }
        $i++;
    }

    return $in_string || undef;
}

# Check if a line starts with content that would be inside a string if the
# previous line had an unclosed string.
sub _line_starts_with_string_continuation {
    my ($line) = @_;

    # If the line starts with characters that would be valid inside a string
    # followed by a closing quote, it's likely a continuation.
    # This is a heuristic: we check if there's a quote near the start.
    return 1 if $line =~ /^[^\\"']*["']/;
    return 0;
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::Minify - Minify Perl source with the C<minify.pl> command or from Perl code

=head1 SYNOPSIS

    # Primary use: the minify.pl command
    minify.pl script.pl > script.min.pl
    minify.pl script.pl --width 80 > script.min.pl
    minify.pl script.pl --sub color > color.min.pl

    # Programmatic use
    use Perl::Minify qw(minify minify_sub);
    my $min = minify($source_str, { wrap => 100 });

=head1 DESCRIPTION

Perl::Minify shrinks Perl source by stripping comments and POD, collapsing
non-essential whitespace, and optionally shortening lexical variable names
and wrapping lines.

Most users want the F<minify.pl> command, which is installed with this
distribution. Give it a file and it prints the minified code to STDOUT. The
module API is only needed when your own Perl program has to minify source.

=head1 COMMAND LINE USAGE

    minify.pl FILE [--width N] [--sub NAME]

Reads FILE and prints the minified code to STDOUT. The input file is never
modified, so redirect STDOUT to save the result.

    # Minify a whole file
    minify.pl script.pl > script.min.pl

    # Minify and word-wrap to 80 columns
    minify.pl script.pl --width 80 > script.min.pl

    # Emit only one named subroutine
    minify.pl script.pl --sub color > color.min.pl

=head2 Arguments

=over 4

=item C<FILE>

Path to the Perl source file (required). If the file is missing or
unreadable, a usage message is printed and the script exits with an error.

=item C<--width N>

Word-wrap the output to at most C<N> columns. Without it, the output is a
single unwrapped line.

=item C<--sub NAME>

Minify only the subroutine C<NAME>. It is printed as bare source with its
name kept (see C<minify_sub> under MODULE API). If no such sub
exists, the error is written to STDERR and the script exits 1.

=back

=head2 Behavior

C<minify.pl> always enables C<shorten_vars>, and it always uses the default
stripping behavior (comments, POD, whitespace, and semicolons are removed).
Those settings and C<optimize> are not available as command line flags. If
you need different options, use the module API below.

If the source cannot be parsed, the error is written to STDERR and the
script exits 1.

=head1 MODULE API

Use the module when your own code needs to minify Perl source. Nothing is
exported by default; import the functions you need.

=head2 minify($code, \%opts?)

Minifies a string of Perl source. Returns the minified string, or C<undef>
on PPI parse failure.

=head2 minify_sub($code, $sub_name, \%opts?)

Locates a named subroutine, and runs the minification pipeline on it
alone. Returns the sub as bare source text (no surrounding C<use>
header or file-scope code), or C<undef> on parse failure or if no sub
named C<$sub_name> is found. The sub keeps its name by default; pass
C<keep_name =E<gt> 0> to emit an anonymous C<sub { ... }> instead.
A bare sub that depends on file-scope lexicals or C<state> variables
will not compile on its own.

=head2 minify_error()

Returns the last error message set by a failed C<minify> or
C<minify_sub> call (also available as C<$Perl::Minify::ERROR>). Returns
an empty string when the most recent call succeeded.

=head1 OPTIONS

Options are passed to the module functions as a hashref. All are optional,
and unknown keys are ignored. Defaults:

     strip_comments    1   remove C<#> line comments
     strip_pod         1   remove POD blocks
     strip_whitespace  1   collapse non-significant whitespace
     strip_semicolons  1   remove safe terminators before C<}> block delimiters
     shorten_vars      0   rename lexicals to short names ($c, $d, ...)
    wrap              0   if >0, word-wrap output to <=N columns
    keep_name         1   preserve the sub name in C<minify_sub> output
    escape_newlines   1   write LF/TAB/CR in strings as C<\n \t \r> escapes
     optimize          0   EXPERIMENTAL: fold simple Number +/-/* chains
                           (e.g. C<2 + 3 + 4> becomes C<9>)

=head1 LIMITATIONS

=head2 C<shorten_vars>

Renaming is skipped for symbols that appear inside string quotes, regex
literals, C<s///e> replacement blocks, heredocs, and interpolations. Symbolic
references are not renamed. The renamer uses one global per-document map, so
two distinct C<my> declarations with the same name (in different scopes)
share a single short name.

=head2 C<wrap>

An overlong statement with no break point that is outside a string/regex
literal is emitted as a single line that may exceed the requested width.
This never breaks a string literal mid-character.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

Requires Perl v5.16 or later, and the CPAN module C<PPI> (C<cpan PPI>).

=head1 AUTHOR

Scottchiefbaker - https://github.com/scottchiefbaker/

=head1 LICENSE

Same terms as Perl itself.

=cut
