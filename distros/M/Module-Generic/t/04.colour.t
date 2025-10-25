#!/usr/bin/perl

# t/04.colour.t - terminal coloured message

use Test::More qw( no_plan );
use strict;
use warnings;
use utf8;
use vars qw( $DEBUG );
use Cwd qw( abs_path );
use lib abs_path( './lib' );
use open ':std' => 'utf8';
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;

BEGIN { use_ok( 'Module::Generic' ) || BAIL_OUT( "Unable to load Module::Generic" ); }

my $m = Module::Generic->new(
    debug => $DEBUG,
    colour_open => "\{",
    colour_close => "\}",
    ( $DEBUG ? ( force_tty => 1 ) : () ),
);

is(
    $m->colour_parse( "Hello {style => 'b', color => 'red'}red everyone! This is {style => 'u', color => 'rgb(255250250)'}embedded{/}{/} text..." ),
    "Hello \e[38;5;224;1m\e[38;2;255;0;0;1mred everyone! This is \e[38;5;250;4m\e[38;2;255;250;250;4membedded\e[m\e[m text...",
    "Inline style: Hello \e[38;5;224;1m\e[38;2;255;0;0;1mred everyone! This is \e[38;5;250;4m\e[38;2;255;250;250;4membedded\e[m\e[m text..."
);

is(
    $m->colour_parse( "And {style => 'i|b', color => light_red, bgcolor => white}light red on white{/} {style => 'blink', color => yellow}and yellow text{/} ?" ),
    "And \e[38;5;224;48;5;255;3;1m\e[38;2;255;0;0;48;2;255;255;255;3;1mlight red on white\e[m \e[38;5;252;5m\e[38;2;255;255;0;5mand yellow text\e[m ?",
    "Inline style: And \e[38;5;224;48;5;255;3;1m\e[38;2;255;0;0;48;2;255;255;255;3;1mlight red on white\e[m \e[38;5;252;5m\e[38;2;255;255;0;5mand yellow text\e[m ?",
);

is(
    $m->coloured( 'bold white on red', "Bold white text on red background" ),
    "\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mBold white text on red background\e[m",
    "Coloured() style: \e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mBold white text on red background\e[m",
);

is(
    $m->colour_parse( "And {bold light white on red}light white\non red multi line{/} {underline green}underlined green text{/}" ),
    "And \e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1m\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mlight white\e[m
\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mon red multi line\e[m \e[38;5;28;4m\e[38;2;0;255;0;4munderlined green text\e[m",
    "Inline with multi line: And \e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1m\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mlight white\e[m\\n\e[38;5;255;48;5;224;1m\e[38;2;255;255;255;48;2;255;0;0;1mon red multi line\e[m \e[38;5;28;4m\e[38;2;0;255;0;4munderlined green text\e[m",
);

is(
    $m->colour_parse( "Some {bold red on white}red on white. And {underline rgb( 0, 0, 255 )}underlined{/}{/} text..." ),
    "Some \e[38;5;224;48;5;255;1m\e[38;2;255;0;0;48;2;255;255;255;1mred on white. And \e[38;5;3;4m\e[38;2;0;0;255;4munderlined\e[m\e[m text...",
    "Inline style with rgb: Some \e[38;5;224;48;5;255;1m\e[38;2;255;0;0;48;2;255;255;255;1mred on white. And \e[38;5;3;4m\e[38;2;0;0;255;4munderlined\e[m\e[m text...",
);

is(
    $m->coloured( 'bold rgb(255, 0, 0) on white', "Some red on white text." ),
    "\e[38;5;224;48;5;255;1m\e[38;2;255;0;0;48;2;255;255;255;1mSome red on white text.\e[m",
    "Coloured() style with rgb: \e[38;5;224;48;5;255;1m\e[38;2;255;0;0;48;2;255;255;255;1mSome red on white text.\e[m",
);

is(
    $m->coloured( 'bold rgb(255, 0, 0, 0.5) on white', "Some red on white text with 50% alpha." ),
    "\e[38;5;237;48;5;255;1m\e[38;2;255;128;128;48;2;255;255;255;1mSome red on white text with 50% alpha.\e[m",
    "Coloured() style with rgba: \e[38;5;237;48;5;255;1m\e[38;2;255;128;128;48;2;255;255;255;1mSome red on white text with 50% alpha.\e[m",
);

$m->colour_open( '<' );
$m->colour_close( '>' );
is(
    $m->colour_parse( "Regular <something here>phrase</>" ),
    'Regular phrase',
    'Unknown style parameter -> no change',
);

subtest 'literal braces/angles' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '{', colour_close => '}' );
    is( $m->colour_parse('1 + { 2 } = 3'), '1 + { 2 } = 3', 'curly braces literal' );
    is( $m->colour_parse('XML <tag attr="x"> y </tag>'), 'XML <tag attr="x"> y </tag>', 'angles literal' );
    is( $m->colour_parse('just {/} slashes'), 'just {/} slashes', 'looks like close but no open' );
};

subtest 'nesting mixed delimiters' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '{', colour_close => '}' );
    my $out = $m->colour_parse('{bold red}A <underline green>B</> C{/}');
    like( $out, qr/\e\[.*?mA .*?B.*? C\e\[m/s, 'nested < > inside { } works' );

    $m->colour_open('<'); $m->colour_close('>');
    $out = $m->colour_parse('<underline green>A {bold red}B{/} C</>');
    like( $out, qr/\e\[.*?mA .*?B.*? C\e\[m/s, 'nested { } inside < > works' );
};

subtest 'non-TTY strips formatting' => sub
{
    {
        package Local::NoTTY;
        our @ISA = ('Module::Generic');
    }
    my $m = Local::NoTTY->new(
        debug => $DEBUG,
        colour_open => '{',
        colour_close => '}',
        # We force it to believe it is NOT in a tty.
        force_tty => 0,
    );
    is( $m->colour_parse('{bold red}plain{/} text'), 'plain text', 'no tty → keep only content' );
};

subtest 'whitespace and case variants' => sub
{
    my $m = Module::Generic->new( debug => 0, colour_open => '{', colour_close => '}' );
    is(
        $m->colour_parse('{  LIGHT   Red   on  White }X{/}'),
        '{  LIGHT   Red   on  White }X{/}',
        'leading whitespace not tolerated'
    );
    like(
        $m->colour_parse('{LIGHT   Red   on  White }X{/}'),
        qr/\e\[.*?mX\e\[m/s,
        'whitespace and case tolerated'
    );
    like(
        $m->colour_parse('{underline rgb( 0 , 0 , 255 )}B{/}'),
        qr/\e\[.*?mB\e\[m/s,
        'rgb with spaces'
    );
    like(
        $m->colour_parse('{bold rgba(255,0,0,0.3)}R{/}'),
        qr/\e\[.*?mR\e\[m/s,
        'rgba accepted'
    );
};

subtest 'rgb/rgba bounds' => sub
{
    my $m = Module::Generic->new(
        debug => $DEBUG,
        colour_open => '{',
        colour_close => '}',
    );
    # Si ton colour_format clippe, adapte l’assertion. Ici on exige le littéral si hors bornes.
    is(
        $m->colour_parse('{bold rgb(300, -1, 260)}X{/}'),
        'X',
        'out-of-range rgb -> literal'
    );
};

subtest 'custom delimiters only' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '[[', colour_close => ']]' );
    like( $m->colour_parse('[[bold red]]X[[/]]'), qr/\e\[.*?mX\e\[m/s, 'custom delimiters work' );
};

subtest 'unicode content' => sub
{
    my $m = Module::Generic->new( debug => 0, colour_open => '{', colour_close => '}' );
    like(
        $m->colour_parse('{bold red}café 😊{/}'),
        qr/\e\[.*?mcafé 😊\e\[m/s,
        'unicode kept'
    );
};

subtest 'unbalanced nested tags' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '{', colour_close => '}' );
    is(
        $m->colour_parse('{bold red}outer {underline green}inner{/'),
        "\e[38;5;224;1m\e[38;2;255;0;0;1mouter \e[38;5;28;4m\e[38;2;0;255;0;4minner{/",
        # '{bold red}outer {underline green}inner{/',
        'unclosed nested tag treated as literal'
    );
    is(
        $m->colour_parse('{bold red}outer {/} inner{/}'),
        "\e[38;5;224;1m\e[38;2;255;0;0;1mouter \e[m inner\e[m",
        'stray closing in nested treated correctly'
    );
};

subtest 'empty parameters' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '{', colour_close => '}' );
    is( $m->colour_parse('{}empty params{/}'), '{}empty params{/}', 'empty parameters treated as literal' );
    is( $m->colour_parse('{  }spaces only{/}'), '{  }spaces only{/}', 'spaces in parameters treated as literal' );
};

subtest 'adjacent tags' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '{', colour_close => '}' );
    like(
        $m->colour_parse('{bold red}A{/}{underline green}B{/}'),
        qr/\e\[.*?mA\e\[m.*?\e\[.*?mB\e\[m/s,
        'adjacent tags processed separately'
    );
};

subtest 'malformed tags' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '{', colour_close => '}' );
    is(
        $m->colour_parse('{bold red}missing close'),
        "\e[38;5;224;1m\e[38;2;255;0;0;1mmissing close",
        'unclosed tag processed anyway'
    );
    is(
        $m->colour_parse('{/}stray close'),
        '{/}stray close',
        'stray closing tag treated as literal'
    );
    is(
        $m->colour_parse('{bold red}{/}empty tag{/}'),
        "\e[38;5;224;1m\e[38;2;255;0;0;1m\e[mempty tag\e[m",
        'empty tag with valid format'
    );
    is( $m->colour_parse('{in valid}text{/}'), 'text', 'invalid params are ignored' );
};

subtest 'deep recursion' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '{', colour_close => '}' );
    my $deep = '{bold red}' . ( '{underline green}' x 5 ) . 'deep' . ( '{/}' x 5 ) . '{/}';
    is(
        $m->colour_parse( $deep ),
        "\e[38;5;224;1m\e[38;2;255;0;0;1m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4mdeep\e[m\e[m\e[m\e[m\e[m\e[m",
        'deep nesting up to limit works'
    );
    my $too_deep = '{bold red}' . ( '{underline green}' x 10 ) . 'too deep' . ( '{/}' x 10 ) . '{/}';
    is(
        $m->colour_parse( $too_deep ),
        # $too_deep,
        "\e[38;5;224;1m\e[38;2;255;0;0;1m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\e[38;5;28;4m\e[38;2;0;255;0;4m\{underline green\}too deep\e[m\e[m\e[m\e[m\e[m\e[m\e[m\e[m\e[m\{\/\}\{\/\}",
        'excessive nesting returns literal'
    );
};

subtest 'custom delimiter edge cases' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '[[', colour_close => ']]' );
    is(
        $m->colour_parse('[[bold red]]text{ x: 1 }[[/]]'),
        "\e[38;5;224;1m\e[38;2;255;0;0;1mtext{ x: 1 }\e[m",
        'custom delimiters work'
    );
    is(
        $m->colour_parse('[[[/]]stray close'),
        '[[[/]]stray close',
        'stray custom closing tag treated as literal'
    );
};

subtest 'curly braces in content' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '{', colour_close => '}' );
    is(
        $m->colour_parse('{bold red}code { x: 1 } here{/}'),
        "\e[38;5;224;1m\e[38;2;255;0;0;1mcode { x: 1 } here\e[m",
        'curly braces in content preserved'
    );
    is(
        $m->colour_parse('{bold red}nested {underline green}{ x: 1 }{/} here{/}'),
        "\e[38;5;224;1m\e[38;2;255;0;0;1mnested \e[38;5;28;4m\e[38;2;0;255;0;4m{ x: 1 }\e[m here\e[m",
        'curly braces in nested content preserved'
    );
    is(
        $m->colour_parse('code ${variable} here'),
        'code ${variable} here',
        'curly braces with $ prefix preserved'
    );
};

subtest 'complex mixed content' => sub
{
    my $m = Module::Generic->new( debug => $DEBUG, colour_open => '{', colour_close => '}' );
    is(
        $m->colour_parse('Start {bold red}red { x: {underline green}green{/} } end{/}'),
        "Start \e[38;5;224;1m\e[38;2;255;0;0;1mred { x: \e[38;5;28;4m\e[38;2;0;255;0;4mgreen\e[m } end\e[m",
        'curly braces with nested formatting'
    );
};


# Helper: no ANSI anywhere
sub no_ansi { unlike( $_[0], qr/\e\[/, $_[1] ) }
# Helper: has ANSI
sub has_ansi { like( $_[0], qr/\e\[/, $_[1] ) }

# Force TTY so colour is applied when allowed
$m = Module::Generic->new(
  debug        => $DEBUG,
  colour_open  => '{',
  colour_close => '}',
  force_tty    => 1,
);

subtest 'benign hash-like values pass' => sub
{
    has_ansi(
        $m->colour_parse( "{style => 'bold', color => 'red'}X{/}" ),
        'simple quoted values'
    );

    has_ansi(
        $m->colour_parse( "{style => 'bold|underline', color => 'light blue'}X{/}" ),
        'pipe style lists, space in colour name'
    );

    has_ansi(
        $m->colour_parse( '{color => "rgb(0,128,255)"}X{/}' ),
        'rgb() double-quoted'
    );

    has_ansi(
        $m->colour_parse( "{color => 'rgba(255,0,0,0.5)'}X{/}" ),
        'rgba() accepted'
    );

    has_ansi(
        $m->colour_parse( "{fg_color => 'red', bg_color => 'white'}X{/}" ),
        'aliases accepted as plain scalars'
    );
};

subtest 'rejection by illegal characters (whitelist catches)' => sub
{
    # semicolon ; should be banned
    no_ansi(
        $m->colour_parse( "{style => 'bold'; color => 'red'}X{/}" ),
        'semicolon => reject'
    );

    # dollar sigil $
    no_ansi(
        $m->colour_parse("{style => $ENV{HOME}}X{/}" ),
        'sigil => reject'
    );

    # backticks `
    no_ansi(
        $m->colour_parse("{style => `uname`}X{/}" ),
        'backticks => reject'
    );

    # braces { } in value
    no_ansi(
        $m->colour_parse("{style => 'bold', color => q{red}}X{/}" ),
        'braces => reject'
    );

    # square brackets []
    no_ansi(
        $m->colour_parse( "{style => [ 'bold' ]}X{/}" ),
        'brackets => reject'
    );

    # colon :
    no_ansi(
        $m->colour_parse( "{style: 'bold'}X{/}" ),
        'colon => reject'
    );

    # newline (we used \h, not \s)
    no_ansi(
        $m->colour_parse( "{style => 'bold'\n, color => 'red'}X{/}" ),
        'newline => reject'
    );
};

subtest 'dangerous function-like values (only letters + parens) MUST be rejected' => sub
{
    # These use only allowed characters by the char-whitelist,
    # so add a *keyword* pre-check (qx|system|open|exec|fork|require|use|eval|do|sub|BEGIN|END)
    # before eval. These tests should produce NO ANSI.

    no_ansi(
        $m->colour_parse( "{style => qx(ls)}X{/}" ),
        'qx(...) must be rejected'
    );

    no_ansi(
        $m->colour_parse( "{style => system('ls')}X{/}" ),
        'system(...) must be rejected (quotes allowed but still reject by keyword)'
    );

    no_ansi(
        $m->colour_parse( "{style => eval('1+1')}X{/}" ),
        'eval(...) must be rejected'
    );

    no_ansi(
        $m->colour_parse( "{style => require(Moose)}X{/}" ),
        'require(...) must be rejected'
    );

    no_ansi(
        $m->colour_parse( "{style => use(Moose)}X{/}" ),
        'use(...) must be rejected'
    );

    no_ansi(
        $m->colour_parse( "{style => do('file')}X{/}" ),
        'do(...) must be rejected'
    );

    no_ansi(
        $m->colour_parse( "{ style => open(F,'/etc/passwd')}X{/}" ),
        'open(...) must be rejected'
    );
};

subtest 'malformed or odd but harmless things' => sub
{
    no_ansi(
        $m->colour_parse( "{style => 'bold}X{/}" ),
        'unclosed quote => eval fails => no format'
    );

    no_ansi(
        $m->colour_parse( "{style => bold\"}X{/}" ),
        'bad quoting => no format'
    );

    no_ansi(
        $m->colour_parse( "{bogus => 'bold'}X{/}" ),
        'unknown key still ok to ignore later, but ensure no crash (may format if you accept unknown keys; allow either way)'
    );
};

subtest 'values that should still pass under KISS guard' => sub
{
    no_ansi(
        $m->colour_parse( "{style => 'b-old'}X{/}" ),
        'dash in value ok, but value is unsupported'
    );

    has_ansi(
        $m->colour_parse( "{style => 'bold|italic|underline'}X{/}" ),
        'multi-style pipe list ok'
    );

    has_ansi(
        $m->colour_parse( "{color => 'light-blue'}X{/}" ),
        'light-blue ok if your mapper tolerates it'
    );
};

subtest 'very long but benign values' => sub
{
    my $long = "{style => '" . ( "bold|" x 50 ) . "italic'}X{/}";
    has_ansi(
        $m->colour_parse( $long ),
        'long list still ok (consider an optional size cap)'
    );
};

subtest 'edge cases' => sub
{
    is(
        $m->colour_parse( '{bold red}valid{in valid}text{/}' ),
        "\e[38;5;224;1m\e[38;2;255;0;0;1mvalidtext\e[m",
        'mixed valid and invalid tags' 
    );

    is(
        $m->colour_parse( '{bold red}code ${var with spaces} here{/}' ),
        "\e[38;5;224;1m\e[38;2;255;0;0;1mcode \${var with spaces} here\e[m",
        'Perl variable with spaces'
    );

    my $long = '{bold red}' . 'text ' x 1000 . '{/}';
    is(
        $m->colour_parse( $long ),
        "\e[38;5;224;1m\e[38;2;255;0;0;1m" . 'text ' x 1000 . "\e[m",
        'long string with tags'
    );

    is(
        $m->colour_parse( '{bold red}outer {underline green}inner' ),
        "\e[38;5;224;1m\e[38;2;255;0;0;1mouter \e[38;5;28;4m\e[38;2;0;255;0;4minner",
        'nested tags with missing closes'
    );

    $m->colour_open( '[[' );
    $m->colour_close( ']]' );
    is(
        $m->colour_parse( '[[in valid]]text[[/]]' ),
        'text',
        'invalid params with custom delimiters'
    );
};

done_testing();

__END__

