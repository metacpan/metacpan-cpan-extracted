#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PodliteRun qw(run_perl);

sub program { join '', map { "$_\n" } @_ }

sub prints {
    my ( $name, $expected, @lines ) = @_;
    my $run = run_perl( program(@lines) );
    is( $run->{stdout}, $expected, $name ) or diag( $run->{stderr} );
}

# Defects of 1.00

prints( 'indented heading inside code is stripped',
    "in\n", 'use Podlite;', 'if (1) {', '    =head1 Note', '', '    print "in\n";', '}' );

prints( 'a table rule starting with = stays in the table',
    "after\n", 'use Podlite;', '=table', 'A | B', '==|==', '1 | 2', '', 'print "after\n";' );

prints( 'Perl markers inside a code example do not end the program',
    "after\nnative\n", 'use Podlite;', '=begin code', '__END__', '__DATA__', 'no Podlite;', '=end code',
    'print "after\n";', 'print scalar(<DATA>);', '__DATA__', 'native' );

prints( 'a block name starting with a non-ASCII letter',
    "after\n", 'use utf8;', 'use Podlite;', "=\x{c3}\x{89}tage x", '', 'print "after\n";' );

prints( 'a block name starting with end',
    "after\n", 'use Podlite;', '=endNote Example', '', 'print "after\n";' );

prints( 'a longer closing name does not close the block',
    "end\n", 'use Podlite;', '=begin code', '=end code-example', 'print "example ran\n";', '=end code',
    'print "end\n";' );

prints( 'a nested block with a shared name prefix',
    "after\n", 'use Podlite;', '=begin nested', '=begin nestedCase', 'inner', '=end nestedCase',
    'print "markup ran\n";', '=end nested', 'print "after\n";' );

prints( 'a line of no-break spaces ends a block',
    "ran\ndone\n", 'use utf8;', 'use Podlite;', '=head1 Title', "\x{c2}\x{a0}", 'print "ran\n";', '',
    'print "done\n";' );

prints( 'markup inside a Markdown fence does not open a block',
    "A\nB\n", 'use Podlite;', '=begin markdown', '~~~text', '=begin markdown', '~~~', '=end markdown',
    'print "A\n";', '=begin markdown', 'B', '=end markdown', 'print "B\n";' );

prints( 'markup inside a Markdown fence does not close the outer block',
    "after\n", 'use Podlite;', '=begin pod', '=begin markdown', '~~~', '=end pod', '~~~', '=end markdown',
    '=end pod', 'print "after\n";' );

{
    my $body = ( 'x' x 63 . "\n" ) x 1024;
    my $run  = run_perl( "use Podlite;\n=begin code\n${body}=end code\nprint qq(ok\\n);\n" );
    is( $run->{stdout}, "ok\n", 'a large code block does not cut the program' );
}

{
    my @assignment = ( 'sub head1 {17} sub x {2}', 'my $v', '=head1(x)', ';', 'print "sentinel=$v\n";' );
    my $bare = run_perl( program(@assignment) );
    my $run  = run_perl( program( 'use Podlite;', @assignment ) );
    is( $bare->{stdout}, "sentinel=17\n", 'bare Perl runs a continued assignment' );
    is( $run->{stdout}, $bare->{stdout}, 'a block name followed by ( is not markup' );
}

{
    my @assignment = (
        'package Foo::Bar; sub new { bless {}, shift } package main;',
        'my $obj', '=Foo::Bar->new;', 'print "o=", ref($obj), "\n";'
    );
    my $run = run_perl( program( 'use Podlite;', @assignment ) );
    is( $run->{stdout}, "o=Foo::Bar\n", 'a block name followed by :: is not markup' );
}

# Indented directives: only words the specification defines

prints( 'indented delimited custom block', "after\n",
    'use Podlite;', 'if (1) {', '    =begin MyBlock', '    text', '    =end MyBlock', '}', 'print "after\n";' );

prints( 'indented abbreviated custom block name stays Perl', "Foo\n",
    'use strict;', 'use Podlite;', 'package Foo; sub new { bless {}, shift } package main;',
    'my $obj', '    =Foo', '->new;', 'print ref($obj), "\n";' );

prints( 'indented upper-case word outside the semantic list stays Perl', "v=16\n",
    'use Podlite;', 'use constant TIMEOUT => 8;', 'my $v', '    =TIMEOUT * 2;', 'print "v=$v\n";' );

prints( 'an indented word that is not a semantic plural stays Perl', "v=1\n",
    'use Podlite;', 'my $v', '    =SUMMARYS', '    + 1;', 'print "v=$v\n";' );

prints( 'an indented semantic plural is a block', "after\n",
    'use Podlite;', 'if (1) {', '    =SUMMARIES', '    text', '', '}', 'print "after\n";' );

prints( 'underscore starts a block name', "after\n",
    'use Podlite;', '=begin _X', 'text', '=end _X', 'print "after\n";' );

prints( 'a configuration continuation at another column stays Perl', "x=7\n",
    'use Podlite;', 'my $x', '    =config head1 :numbered', '  = 7;', 'print "x=$x\n";' );

prints( 'an indented code run ends at a line without the indent', "after\n",
    'use Podlite;', '=begin para', '    We are all of us in the gutter,', '    but some are looking at the stars!',
    '=end para', 'print "after\n";' );

prints( 'a table with indented rows closes', "after\n",
    'use Podlite;', '=begin table', '    Constants           1', '    Variables           10', '=end table',
    'print "after\n";' );

# Broken markup is a compile-time error

sub fails {
    my ( $name, $message, @lines ) = @_;
    my $run = run_perl( program(@lines) );
    is( $run->{stderr}, $message, "$name: message" );
    isnt( $run->{exit}, 0, "$name: non-zero exit" );
    is( $run->{stdout}, '', "$name: nothing runs" );
}

fails( 'unclosed block before a blank line', "Podlite: unclosed =begin nested at - line 2\n",
    'use Podlite;', '=begin nested', 'body', '', 'print "alive\n";' );
fails( 'unclosed block', "Podlite: unclosed =begin nested at - line 2\n",
    'use Podlite;', '=begin nested', 'body', 'print "alive\n";' );
fails( 'stray closer', "Podlite: =end nested without =begin at - line 2\n",
    'use Podlite;', '=end nested', 'print "alive\n";' );
fails( 'mismatched closer', "Podlite: =end code at - line 4 does not close =begin nested at line 2\n",
    'use Podlite;', '=begin nested', 'body', '=end code', 'print "alive\n";' );
fails( 'two unclosed blocks',
    "Podlite: unclosed =begin nested at - line 3\nPodlite: unclosed =begin pod at - line 2\n",
    'use Podlite;', '=begin pod', '=begin nested', 'body', '', 'print "alive\n";' );
fails( 'opener with a name that starts with a connector', "Podlite: malformed =begin directive at - line 3\n",
    'use utf8;', 'use Podlite;', "=begin \x{e2}\x{80}\x{bf}x", 'body', "=end \x{e2}\x{80}\x{bf}x", 'print "alive\n";' );
fails( 'opener with a connector inside the name', "Podlite: malformed =begin directive at - line 3\n",
    'use utf8;', 'use Podlite;', "=begin a\x{e2}\x{80}\x{bf}b", 'body', "=end a\x{e2}\x{80}\x{bf}b", 'print "alive\n";' );
fails( 'opener without a name followed by space', "Podlite: malformed =begin directive at - line 2\n",
    'use Podlite;', '=begin code:lang<perl>', 'x', '=end code', 'print "alive\n";' );

# Behaviour kept from 1.00

prints( 'three block forms', "after\n",
    'use Podlite;', '=begin pod', '=head1 A', '=end pod', '=for para', 'text', '', '=head2 B', '', 'print "after\n";' );

prints( 'nested comments', "after\n",
    'use Podlite;', '=begin comment', '=begin comment', 'print "leak\n";', '=end comment', 'still',
    '=end comment', 'print "after\n";' );

prints( 'a marker right after a heading', "got=native\n",
    'use Podlite;', 'print "got=", scalar(<DATA>) // "EOF\n";', '=head1 Title', '__END__', 'native' );

prints( 'a hash key spelled __DATA__ is not a marker', "x=7\n",
    'use Podlite;', 'my %x = (', '__DATA__ => 7,', ');', '=head1 T', '', 'print "x=$x{__DATA__}\n";' );

prints( 'an indented marker', "native\n",
    'use Podlite;', 'print scalar(<DATA>);', '    __DATA__', 'native' );

prints( 'no Podlite right after an item ends the area', "after\n",
    'use Podlite;', '=item x', 'no Podlite;', 'print "after\n";' );

prints( 'a marker with a comment', "native\n",
    'use Podlite;', 'print scalar(<DATA>);', '__DATA__ # tail', 'native' );

{
    my $run = run_perl( program( 'use Podlite;', '=begin pod', '=head1 T', '=end pod', '=data ok', '',
        'die "sentinel";' ) );
    is( $run->{stderr}, "sentinel at - line 7.\n", 'line numbers are kept' );
}

# Work grows linearly with the input

for my $shape (
    [ 'long lines',  "=begin code\n" . ( 'y' x 4000 . "\n" ) x 16 . "=end code\n" ],
    [ 'many lines',  "=begin code\n" . ( "z\n" x 4000 ) . "=end code\n" ],
    [ 'near misses', "=begin code\n" . ( "=end codex\n" x 2000 ) . "=end code\n" ],
    [ 'paragraphs',  ( "=head1 T\ntext\n\n" x 1000 ) ],
    )
{
    my ( $name, $area ) = @$shape;
    my $run = run_perl( "use Podlite;\n${area}print \$Podlite::WORK, qq(\\n);\n" );
    my $n   = length($area) + length("print \$Podlite::WORK, qq(\\n);\n");
    ( my $work = $run->{stdout} ) =~ s/\n\z//;
    cmp_ok( $work, '<=', 6 * $n + 64, "work stays within budget: $name" );
}

done_testing();
