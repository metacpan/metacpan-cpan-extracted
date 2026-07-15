#!perl
use 5.016;
use strict;
use warnings;

use Test::More;

use lib 'lib';
use Syntax::Highlight::Basic::Parser;
use Syntax::Highlight::Basic::Output::Ansi;

#===========================================================================
# Output::Ansi Tests — ANSI 256-color terminal rendering
#===========================================================================

# ANSI escape helpers (chr-based to survive tool pipeline)
my $ESC = chr(27);

# Helper: parse and convert a single line
sub convert_line {
    my ($lang, $code, %opts) = @_;
    my $p = Syntax::Highlight::Basic::Parser->new(language => $lang);
    my $o = Syntax::Highlight::Basic::Output::Ansi->new(%opts);
    my $result = $o->convert($p->parse($code));
    return $result;
}

#===========================================================================
# Module loading
#===========================================================================

{
    use_ok('Syntax::Highlight::Basic::Output::Ansi');
    my $o = Syntax::Highlight::Basic::Output::Ansi->new();
    isa_ok($o, 'Syntax::Highlight::Basic::Output::Ansi', 'new() returns correct object');
}

#===========================================================================
# Constructor defaults
#===========================================================================

{
    my $o = Syntax::Highlight::Basic::Output::Ansi->new();
    isa_ok($o->{colors}, 'HASH', 'colors is a hash ref');
    ok(exists $o->{colors}{Keyword}, 'default colors include Keyword');
    is($o->{colors}{Keyword}{color}, 28, 'Keyword default color index is 28');
    is($o->{colors}{Keyword}{bold},  1,  'Keyword default bold is 1');
    is($o->{colors}{Identifier}{color}, 33, 'Identifier default color index is 33 (light blue)');
}

#===========================================================================
# Constructor with custom colors
#===========================================================================

{
    my $o = Syntax::Highlight::Basic::Output::Ansi->new(
        colors => {
            Keyword => { color => 196, bold => 0 },
            String  => { color => 33,  bold => 0 },
        },
    );
    is($o->{colors}{Keyword}{color}, 196, 'custom Keyword color overrides default');
    is($o->{colors}{String}{color},   33, 'custom String color overrides default');
    is($o->{colors}{Comment}{color},  73, 'non-overridden Comment color remains default');
}

#===========================================================================
# Basic convert() — keyword gets ANSI codes
#===========================================================================

{
    my $str = convert_line('python', 'def foo():');
    like($str, qr/\Q${ESC}[1;38;5;28m\Edef\Q${ESC}[0m\E/,
        'Statement keyword gets bold+color ANSI codes');
}

#===========================================================================
# String gets color but not bold
#===========================================================================

{
    my $str = convert_line('python', 'x = "hello"');
    like($str, qr/\Q${ESC}[38;5;67m\E/, 'string gets color ANSI code');
    unlike($str, qr/\Q${ESC}[1;38;5;67m\E/, 'string does NOT get bold ANSI code');
}

#===========================================================================
# Comment highlighting
#===========================================================================

{
    my $str = convert_line('python', '# a comment');
    like($str, qr/\Q${ESC}[38;5;73m\E/, 'comment gets ANSI color 73 (teal)');
}

#===========================================================================
# Whitespace and text tokens pass through un-styled
#===========================================================================

{
    my $str = convert_line('python', 'x = 1');
    # Whitespace between tokens should be present without escape codes around it
    like($str, qr/ /, 'whitespace between tokens is preserved');
}

#===========================================================================
# No HTML escaping needed for terminal output
#===========================================================================

{
    my $str = convert_line('python', 'x ' . chr(60) . ' y');
    like($str, qr/</, '< is passed through literally (no HTML escaping)');
    my $lt_ent = chr(38) . 'lt;';
    unlike($str, qr/\Q$lt_ent\E/, 'no HTML entities in ANSI output');
}

#===========================================================================
# Bold groups
#===========================================================================

{
    my $str = convert_line('javascript', 'if (x) {}');
    like($str, qr/\Q${ESC}[1;38;5;28m\Eif\Q${ESC}[0m\E/,
        'Conditional (if) gets bold ANSI code');
}

{
    my $str = convert_line('python', 'for x in y: pass');
    like($str, qr/\Q${ESC}[1;38;5;28m\Efor\Q${ESC}[0m\E/,
        'Repeat (for) gets bold ANSI code');
}

#===========================================================================
# Custom color overrides
#===========================================================================

{
    my $str = convert_line('python', '# comment',
        colors => { Comment => { color => 245, bold => 0 } });
    like($str, qr/\Q${ESC}[38;5;245m\E/, 'custom Comment color 245 is used');
    unlike($str, qr/\Q${ESC}[38;5;73m\E/, 'default Comment color 73 is NOT used');
}

#===========================================================================
# Unknown groups pass through as plain text
#===========================================================================

{
    my $str = convert_line('python', 'hello');
    unlike($str, qr/\Q${ESC}[38;5/, 'unknown text tokens have no ANSI codes');
}

#===========================================================================
# Multi-line output
#===========================================================================

{
    my $str = convert_line('python', "x = 1\ny = 2");
    like($str, qr/\n/, 'multi-line output contains newline separator');
}

#===========================================================================
# Reset code after each token
#===========================================================================

{
    my $str = convert_line('python', 'def foo():');
    # Count ESC[0m occurrences — should have one per styled token
    my @resets = ($str =~ /\Q${ESC}[0m\E/g);
    cmp_ok(scalar @resets, '>=', 1, 'output contains reset codes');
}

#===========================================================================
# HTML-specific: tag names vs attribute names differentiated
#===========================================================================

{
    my $LT   = chr(60);
    my $GT   = chr(62);
    my $QUOT = chr(34);
    my $str = convert_line('html', $LT . 'div class=' . $QUOT . 'foo' . $QUOT . $GT);
    # Tag name 'div' should be bold (Tag -> Statement -> bold)
    like($str, qr/\Q${ESC}[1;38;5;28m\Ediv\Q${ESC}[0m\E/,
        'HTML tag name div gets bold ANSI');
    # Attribute name 'class' should be Type (88, not bold)
    like($str, qr/\Q${ESC}[38;5;88m\Eclass\Q${ESC}[0m\E/,
        'HTML attribute name class gets ANSI color 88 (Type)');
}

#===========================================================================
# HTML-specific: entities are Special
#===========================================================================

{
    my $entity = chr(38) . 'amp;';
    my $str = convert_line('html', $entity);
    like($str, qr/\Q${ESC}[38;5;67m\E/, 'HTML entity gets Special ANSI color');
}

done_testing();