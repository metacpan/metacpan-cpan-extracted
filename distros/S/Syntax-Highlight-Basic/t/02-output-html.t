#!perl
use 5.016;
use strict;
use warnings;

use Test::More;

use lib 'lib';
use Syntax::Highlight::Basic::Parser;
use Syntax::Highlight::Basic::Output::HTML;

#===========================================================================
# Output::HTML Tests — inline style rendering
#===========================================================================

# HTML entity helpers (chr-based to survive tool pipeline)
my $AMP  = chr(38);
my $LT   = chr(60);
my $GT   = chr(62);
my $QUOT = chr(34);

sub ent_amp  { return $AMP . 'amp;' }
sub ent_lt   { return $AMP . 'lt;' }
sub ent_gt   { return $AMP . 'gt;' }
sub ent_quot { return $AMP . 'quot;' }

# Helper: parse and convert a single line
sub convert_line {
    my ($lang, $code, %opts) = @_;
    my $p = Syntax::Highlight::Basic::Parser->new(language => $lang);
    my $o = Syntax::Highlight::Basic::Output::HTML->new(%opts);
    my $result = $o->convert($p->parse($code));
    return $result;
}

#===========================================================================
# Module loading
#===========================================================================

{
    use_ok('Syntax::Highlight::Basic::Output::HTML');
    my $o = Syntax::Highlight::Basic::Output::HTML->new();
    isa_ok($o, 'Syntax::Highlight::Basic::Output::HTML', 'new() returns correct object');
}

#===========================================================================
# Constructor defaults
#===========================================================================

{
    my $o = Syntax::Highlight::Basic::Output::HTML->new();
    is($o->{wrap}, 0, 'wrap defaults to 0');
    isa_ok($o->{colors}, 'HASH', 'colors is a hash ref');
    ok(exists $o->{colors}{Keyword}, 'default colors include Keyword');
    is($o->{colors}{Keyword}, '#008000', 'Keyword default color is #008000');
}

#===========================================================================
# Constructor with wrap option
#===========================================================================

{
    my $o = Syntax::Highlight::Basic::Output::HTML->new(wrap => 1);
    is($o->{wrap}, 1, 'wrap => 1 stored correctly');
}

#===========================================================================
# Constructor with custom colors
#===========================================================================

{
    my $o = Syntax::Highlight::Basic::Output::HTML->new(
        colors => { Keyword => '#ff0000', String => '#0000ff' },
    );
    is($o->{colors}{Keyword}, '#ff0000', 'custom Keyword color overrides default');
    is($o->{colors}{String},  '#0000ff', 'custom String color overrides default');
    is($o->{colors}{Comment}, '#60a0b0', 'non-overridden Comment color remains default');
}

#===========================================================================
# Basic convert() — keyword highlighting
#===========================================================================

{
    my $html = convert_line('python', 'def foo():');
    like($html, qr/\bdef\b/, 'output contains the keyword text');
    like($html, qr/font-weight:\s*bold/, 'Statement keyword gets font-weight: bold');
    like($html, qr/color:\s*#008000/, 'Statement keyword gets color #008000');
}

#===========================================================================
# String highlighting
#===========================================================================

{
    my $html = convert_line('python', 'x = "hello"');
    like($html, qr/color:\s*#4070a0/, 'string gets color #4070a0');
    unlike($html, qr/font-weight:\s*bold.*hello/, 'string does NOT get bold');
}

#===========================================================================
# Comment highlighting
#===========================================================================

{
    my $html = convert_line('python', '# a comment');
    like($html, qr/color:\s*#60a0b0/, 'comment gets color #60a0b0');
}

#===========================================================================
# HTML entity escaping
#===========================================================================

{
    my $html = convert_line('python', 'x ' . $LT . ' y && z ' . $GT . ' w');
    my $lt_ent  = ent_lt();
    my $gt_ent  = ent_gt();
    my $amp_ent = ent_amp();
    like($html, qr/\Q$lt_ent\E/, '< is escaped to ' . ent_lt());
    like($html, qr/\Q$gt_ent\E/, '> is escaped to ' . ent_gt());
    like($html, qr/\Q$amp_ent\E/, '& is escaped to ' . ent_amp());
}

{
    my $html = convert_line('python', 'say ' . $QUOT . 'hello' . $QUOT);
    my $quot_ent = ent_quot();
    like($html, qr/\Q$quot_ent\E/, '" is escaped to ' . ent_quot());
}

#===========================================================================
# Whitespace and text tokens pass through un-styled
#===========================================================================

{
    my $html = convert_line('python', 'x = 1');
    my $stripped = $html;
    $stripped =~ s/<span[^>]*>.*?<\/span>//g;
    like($stripped, qr/ /, 'whitespace between tokens is preserved');
}

#===========================================================================
# wrap => 1 produces <pre><code> wrapper
#===========================================================================

{
    my $html = convert_line('python', 'x = 1', wrap => 1);
    like($html, qr/^<pre><code>/, 'wrap => 1 starts with <pre><code>');
    like($html, qr/<\/code><\/pre>$/, 'wrap => 1 ends with </code></pre>');
}

#===========================================================================
# wrap => 0 does NOT produce wrapper
#===========================================================================

{
    my $html = convert_line('python', 'x = 1', wrap => 0);
    unlike($html, qr/<pre><code>/, 'wrap => 0 does not produce <pre><code>');
}

#===========================================================================
# Bold groups
#===========================================================================

{
    my $html = convert_line('javascript', 'if (x) {}');
    like($html, qr/font-weight:\s*bold.*\bif\b/, 'Conditional (if) gets font-weight: bold');
}

{
    my $html = convert_line('python', 'for x in y: pass');
    like($html, qr/font-weight:\s*bold.*\bfor\b/, 'Repeat (for) gets font-weight: bold');
}

{
    pass('Function group is not in bold list (verified by code review)');
}

#===========================================================================
# Custom color overrides
#===========================================================================

{
    my $html = convert_line('python', '# comment',
        colors => { Comment => '#cccccc' });
    like($html, qr/color:\s*#cccccc/, 'custom Comment color #cccccc is used');
    unlike($html, qr/color:\s*#60a0b0/, 'default Comment color #60a0b0 is NOT used');
}

#===========================================================================
# Unknown groups pass through as plain text
#===========================================================================

{
    my $html = convert_line('python', 'hello');
    unlike($html, qr/<span[^>]*>hello/, 'unknown text tokens are not wrapped in spans');
}

#===========================================================================
# HTML-specific: tag names vs attribute names differentiated
#===========================================================================

{
    my $html = convert_line('html', $LT . 'div class=' . $QUOT . 'foo' . $QUOT . $GT);
    # Tag name 'div' should be Tag (Statement, bold, #008000)
    like($html, qr/font-weight:\s*bold;\s*color:\s*#008000[^>]*>div</, 
        'HTML tag name div gets bold + #008000');
    # Attribute name 'class' should be Type (#902000)
    like($html, qr/color:\s*#902000[^>]*>class</,
        'HTML attribute name class gets #902000 (Type)');
    # Attribute value "foo" should be String (#4070a0)
    my $quot_ent = ent_quot();
    like($html, qr/\Q$quot_ent\Efoo\Q$quot_ent\E<\/span>/,
        'HTML attribute value is wrapped in span');
}

#===========================================================================
# HTML-specific: tag delimiters are Special
#===========================================================================

{
    my $html = convert_line('html', $LT . 'p' . $GT . 'text' . $LT . '/p' . $GT);
    my $lt_ent = ent_lt();
    my $gt_ent = ent_gt();
    like($html, qr/color:\s*#4070a0[^>]*>\Q$lt_ent\E<\/span>/,
        'HTML tag delimiter < is Special');
    like($html, qr/color:\s*#4070a0[^>]*>\Q$gt_ent\E<\/span>/,
        'HTML tag delimiter > is Special');
}

#===========================================================================
# HTML-specific: closing tags have </ delimiter
#===========================================================================

{
    my $html = convert_line('html', $LT . '/div' . $GT);
    my $lt_ent = ent_lt();
    like($html, qr/\Q$lt_ent\E\//, 'closing tag has ' . ent_lt() . '/ delimiter');
}

#===========================================================================
# HTML-specific: self-closing tags have /> delimiter
#===========================================================================

{
    my $html = convert_line('html', $LT . 'br/' . $GT);
    my $gt_ent = ent_gt();
    like($html, qr/\/\Q$gt_ent\E/, 'self-closing tag has /' . ent_gt() . ' delimiter');
}

#===========================================================================
# HTML-specific: entities are Special
#===========================================================================

{
    my $entity = ent_amp();
    my $html = convert_line('html', $entity);
    my $amp_ent = ent_amp();
    like($html, qr/color:\s*#4070a0[^>]*>\Q$amp_ent\E/, 
        'HTML entity is highlighted as Special');
}

#===========================================================================
# HTML-specific: boolean attributes are Type
#===========================================================================

{
    my $html = convert_line('html', $LT . 'input disabled' . $GT);
    like($html, qr/color:\s*#902000[^>]*>disabled</,
        'HTML boolean attribute disabled gets Type color');
}

#===========================================================================
# HTML-specific: comments are Comment
#===========================================================================

{
    my $html = convert_line('html', $LT . '!-- note --' . $GT);
    like($html, qr/color:\s*#60a0b0/, 'HTML comment gets Comment color');
}

done_testing();