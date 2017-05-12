use strict; use warnings;
use Data::Dumper;

use Test::More;
use Test::Perl::Tags;
use FindBin qw($Bin);

use Perl::Tags;
use Perl::Tags::Naive;
use Perl::Tags::Hybrid;

{
    package DummyTagger;
    use parent 'Perl::Tags';

    sub get_tags_for_file {
        # always return one tag, without parsing anything.
        my ($self, $file) = @_;
        return Perl::Tags::Tag::Label->new(
            name    => 'DUMMY',,
            file    => $file,
            line    => 'DUMMY',
            linenum => 100,
        );
    }
}

my $hybrid_tagger = Perl::Tags::Hybrid->new( 
    max_level=>1,
    taggers => [
        Perl::Tags::Naive->new( max_level => 1),
        DummyTagger->new(),
    ]
);

ok (defined $hybrid_tagger, 'created Perl::Tags' );
isa_ok ($hybrid_tagger, 'Perl::Tags::Hybrid' );
isa_ok ($hybrid_tagger, 'Perl::Tags' );

my $result = 
    $hybrid_tagger->process(
        files => [ "$Bin/Test.pm" ],
        ,refresh=> 1
    );
ok ($result, 'processed successfully' ) or diag "RESULT $result";

tag_ok $hybrid_tagger, 
    Test => "$Bin/Test.pm" => 'package Test;',
    'package line';
tag_ok $hybrid_tagger, 
    bar =>  "$Bin/Test.pm" => 'my ($foo, $bar);', 
    'variable 1';
tag_ok $hybrid_tagger, 
    foo => "$Bin/Test.pm" => 'my ($foo, $bar);', 
    'variable 2';
tag_ok $hybrid_tagger, 
    wibble => "$Bin/Test.pm" => 'sub wibble {', 
    'subroutine';
tag_ok $hybrid_tagger, 
    DUMMY => "$Bin/Test.pm" => 'DUMMY', 
    'Hybrid Dummy Tagger';

done_testing;
