use strict;
use warnings;

use open ':std', ':encoding(utf8)';
use Test::More;
use Template;
use utf8;

my $tt = Template->new( STRICT => 1, DEBUG => 1, ENCODING => 'utf8' )
  or die $Template::ERROR;

ok( defined($tt) );

my @test_values = (
    [ '0x0041'  => 'A' ],
    [ '0x00c4'  => 'Ä' ],
    [ '0x263a'  => '☺' ],
    [ '0x10912' => '𐤒' ],
);

for my $v (@test_values) {
    my $input    = $v->[0];
    my $output   = $v->[1];
    my $template = "[% USE Unicode %][% Unicode.codepoint2char('$input') %]";
    my $result;
    $tt->process( \$template, {}, \$result )
      or die $tt->error();

    is( $result, $output );
}

done_testing;
