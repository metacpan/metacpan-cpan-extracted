use strict; use warnings;
use Data::Dumper;

use Test::More;
use Test::Perl::Tags;
use FindBin qw($Bin);

use Perl::Tags;
use Perl::Tags::Naive;

# a naive, yet exuberant tagger
my $exuberant_tagger = Perl::Tags::Naive->new( 
    max_level=>1,
    exts     =>1,
);
ok (defined $exuberant_tagger, 'created an exuberant tagger' );
isa_ok ($exuberant_tagger, 'Perl::Tags::Naive' );
isa_ok ($exuberant_tagger, 'Perl::Tags' );

my $result = 
    $exuberant_tagger->process(
        files => [ "$Bin/Test.pm" ],
        refresh=> 1
    );
ok ($result, 'processed successfully' ) or diag "RESULT $result";

tag_ok $exuberant_tagger, 
    Test => "$Bin/Test.pm" => 'package Test;' => 'p' => 'line:1' => 'class:Test',
   'package line';
tag_ok $exuberant_tagger, 
    bar => "$Bin/Test.pm" => 'my ($foo, $bar);' => 'v' => 'line:6' => 'file:' => 'class:Test',
   'variable 1';
tag_ok $exuberant_tagger, 
    foo => "$Bin/Test.pm" => 'my ($foo, $bar);' => 'v' => 'line:6' => 'file:' => 'class:Test',
   'variable 2';
tag_ok $exuberant_tagger, 
    wibble => "$Bin/Test.pm" => 'sub wibble {' => 's' => 'line:16' => 'class:Test',
   'subroutine' or diag $exuberant_tagger;

done_testing;
