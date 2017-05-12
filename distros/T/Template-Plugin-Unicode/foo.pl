use strict;
use warnings;
use 5.016;

use Template;
use utf8;
use open ':std', ':encoding(utf8)';

my $tt = Template->new( STRICT => 1, DEBUG => 1, ENCODING => 'utf8' )
  or die $Template::ERROR;

my @test_values = (
    [ '0x0041'  => 'A' ],
    [ '0x00c4'  => 'Ä' ],
    [ '0x00c4'  => ' ' ],
    [ '0x263a'  => '☺' ],
    [ '0x263a'  => ' ' ],
    [ '0x10912' => '𐤒' ],
);

my $u = sub {
    my $s = shift;
    return chr(hex($s));
};

for my $v (@test_values) {
    my $input    = $v->[0];
    my $output   = $v->[1];
    #my $template = "[% USE Unicode %][% Unicode.codepoint2char('$input') %]";
    my $template = "[% u('$input') %]";
    my $result;
    $tt->process( \$template, { u => sub{chr(hex($_[0]))} }, \$result )
      or die $tt->error();

    say $input . ' => ' . $result;
}
