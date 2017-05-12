use strict; use warnings;
use Data::Dumper;

use Test::More;
use Test::Exception;
use FindBin qw($Bin);

use File::Temp qw( tempdir );
use File::Copy;

use Perl::Tags;
use Perl::Tags::Naive;

my $naive_tagger = Perl::Tags::Naive->new( max_level=>1 );
ok (defined $naive_tagger, 'created Perl::Tags' );
isa_ok ($naive_tagger, 'Perl::Tags::Naive' );
isa_ok ($naive_tagger, 'Perl::Tags' );

my $tempdir = tempdir( 'perltagsXXXX', CLEANUP => 1 );

my $temp = "$tempdir/Test.pm";
copy( "$Bin/Test.pm", $temp ) or die "Couldn't copy $temp to $tempdir: $!";

subtest 'output' => sub {
    my $result = 
        $naive_tagger->process(
            files => [ $temp ],
            refresh=> 1
        );
    ok ($result, 'processed successfully' ) or diag "RESULT $result";

    throws_ok {
        $naive_tagger->output();
    } qr/No file to write to/, 'output with no outfile raises error';

    my $tagsfile = "$tempdir/tags";

    $naive_tagger->process(
        files => [ $temp ],
        refresh=> 1
    );

    lives_ok {
        $naive_tagger->output( outfile => $tagsfile );
    } 'output with outfile is OK';

    my $mtime = (stat($tagsfile))[10];

    sleep 1;

    lives_ok {
        $naive_tagger->output( outfile => $tagsfile );
    } 'output with outfile but no changes is OK';

    is $mtime, (stat($tagsfile))[10], 'Access time unchanged';

    $naive_tagger->process(
        files => [ $temp ],
        refresh=> 1
    );

    lives_ok {
        $naive_tagger->output( outfile => $tagsfile );
    } 'output with outfile and refresh is OK';

    isnt $mtime, (stat($tagsfile))[10], 'Access time now changed';

    unlink $tagsfile;
    lives_ok {
        $naive_tagger->output( outfile => $tagsfile );
    } 'output with deleted outfile and not dirty';
};

done_testing;
