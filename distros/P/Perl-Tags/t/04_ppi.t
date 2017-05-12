use strict; use warnings;
use Data::Dumper;

use Test::More;
use Test::Perl::Tags;
use FindBin qw($Bin);

SKIP: {
    eval 'use PPI';
    skip "PPI not installed $@", 1 if $@;

    use_ok("Perl::Tags::PPI") or skip "Couldn't use Perl::Tags::PPI $@", 1;

    my $ppi_tagger = Perl::Tags::PPI->new( max_level=>1 );
    ok (defined $ppi_tagger, 'created Perl::Tags' );
    isa_ok ($ppi_tagger, 'Perl::Tags::PPI' );
    isa_ok ($ppi_tagger, 'Perl::Tags' );

    my $result = 
        $ppi_tagger->process(
            files => [ "$Bin/Test.pm" ],
            refresh=> 1
        );
    ok ($result, 'processed successfully' ) or diag "RESULT $result";


    tag_ok $ppi_tagger,
        Test => "$Bin/Test.pm" => 'package Test;',
        'package line';
    tag_ok $ppi_tagger,
        '$bar' => "$Bin/Test.pm" => 'my ($foo, $bar);',
        'variable 1';
    tag_ok $ppi_tagger,
        '$foo' => "$Bin/Test.pm" => 'my ($foo, $bar);',
        'variable 2';
    tag_ok $ppi_tagger,
        wibble => "$Bin/Test.pm" => 'sub wibble {',
        'subroutine';
}

done_testing;
