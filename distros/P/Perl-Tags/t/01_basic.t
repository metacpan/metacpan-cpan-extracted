use strict; use warnings;
use Data::Dumper;

use Test::More;
use Test::Perl::Tags;
use FindBin qw($Bin);

use Perl::Tags;
use Perl::Tags::Naive;

my $naive_tagger = Perl::Tags::Naive->new( max_level=>1 );
ok (defined $naive_tagger, 'created Perl::Tags' );
isa_ok ($naive_tagger, 'Perl::Tags::Naive' );
isa_ok ($naive_tagger, 'Perl::Tags' );

my $result = 
    $naive_tagger->process(
        files => [ "$Bin/Test.pm" ],
        refresh=> 1
    );
ok ($result, 'processed successfully' ) or diag "RESULT $result";

tag_ok $naive_tagger, 
    Test => "$Bin/Test.pm" => 'package Test;',
    'package line';
tag_ok $naive_tagger, 
    bar =>  "$Bin/Test.pm" => 'my ($foo, $bar);', 
    'variable 1';
tag_ok $naive_tagger, 
    foo => "$Bin/Test.pm" => 'my ($foo, $bar);', 
    'variable 2';
tag_ok $naive_tagger, 
    wibble => "$Bin/Test.pm" => 'sub wibble {', 
    'subroutine';

ok $naive_tagger !~ /sub example/, 'Code in POD is skipped';

done_testing;
