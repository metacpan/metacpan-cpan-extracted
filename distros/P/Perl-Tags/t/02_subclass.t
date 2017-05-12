use strict; use warnings;
use Data::Dumper;

use Test::More;
use Test::Perl::Tags;
use FindBin qw($Bin);

use lib ($Bin);
use TodoTagger; # test class

my $todo_tagger = TodoTagger->new( max_level=>1 );
ok (defined $todo_tagger, 'created Perl::Tags' );
isa_ok ($todo_tagger, 'TodoTagger' );
isa_ok ($todo_tagger, 'Perl::Tags::Naive' );
isa_ok ($todo_tagger, 'Perl::Tags' );

my $result = 
    $todo_tagger->process(
        files => [ "$Bin/Test.pm" ],
        refresh=> 1
    );
ok ($result, 'processed successfully' ) or diag "RESULT $result";


tag_ok $todo_tagger, 
    Test => "$Bin/Test.pm" => 'package Test;',
    'package line';
tag_ok $todo_tagger, 
    bar =>  "$Bin/Test.pm" => 'my ($foo, $bar);', 
    'variable 1';
tag_ok $todo_tagger, 
    foo => "$Bin/Test.pm" => 'my ($foo, $bar);', 
    'variable 2';
tag_ok $todo_tagger, 
    wibble => "$Bin/Test.pm" => 'sub wibble {', 
    'subroutine';
tag_ok $todo_tagger, 
    TODO => "$Bin/Test.pm" => '# TODO: test this line',
    "subclass\'s TODO tag";

done_testing;
