use strictures;

package basic_test;

use Test::InDistDir;
use Test::More;
use Capture::Tiny 'capture';
use File::Slurp 'write_file';
use File::chdir;

use Perl::Tidy::Komodo;

run();
done_testing;
exit;

sub run {
    delete $ENV{PERLTIDY};
    $CWD = "corpus/lib/dir with space";

    my @tidy_call = ( "$^X", qw( -I../../../lib ../../../bin/perltidy_ko -st test.pl ), );

    my $rc = "../../.perltidyrc";
    eval { unlink $rc };

    {
        my ( $out, $err ) = capture { system @tidy_call };
        is $out, "1, 2, 3, 4, 5;\n";
    }
    write_file $rc, "-l=4";

    {
        my ( $out, $err ) = capture { system @tidy_call };
        is $out, "1,\n  2,\n  3,\n  4,\n  5;\n";
    }

    return;
}
