## Please see file perltidy.ERR
## Please see file perltidy.ERR
use strict;
use warnings;

use Test::Tester;
use Test::More;

use Test::BOM;

use Path::Tiny qw(tempfile path);

# http://www.unicode.org/faq/utf_bom.html#BOM
# http://search.cpan.org/perldoc?PPI::Token::BOM
our $boms = {
    'UTF-32, big-endian'    => "\x00\x00\xfe\xff",
    'UTF-32, little-endian' => "\xff\xfe\x00\x00",
    'UTF-16, big-endian'    => "\xfe\xff",
    'UTF-16, little-endian' => "\xff\xfe",
    'UTF-8'                 => "\xef\xbb\xbf"
};

subtest 'test for BOM in strings' => sub {

    for my $kind ( sort keys %$boms ) {
        check_test( sub { string_has_bom( $boms->{$kind} ) }, { ok => 1 } );
    }

    check_test( sub { string_has_bom('no bom') }, { ok => 0 } );
};

subtest 'test if BOM is not in strings' => sub {

    for my $kind ( sort keys %$boms ) {
        check_test( sub { string_hasnt_bom( $boms->{$kind} ) }, { ok => 0 } );
    }

    check_test( sub { string_hasnt_bom('no bom') }, { ok => 1 } );
};

subtest 'test for BOM in files' => sub {

    for my $bom ( sort values %$boms ) {
        my $f    = tempfile();
        my $file = path($f)->stringify;
        $f->append_raw($bom);
        check_test( sub { file_has_bom($file) }, { ok => 1 } );
    }

    my $f    = tempfile();
    my $file = path($f)->stringify;
    $f->append_raw('no bom');
    check_test( sub { file_has_bom($file) }, { ok => 0 } );
};

subtest 'test if BOM is not in files' => sub {

    for my $bom ( sort values %$boms ) {
        my $f    = tempfile();
        my $file = path($f)->stringify;
        $f->append_raw($bom);
        check_test( sub { file_hasnt_bom($file) }, { ok => 0 } );
    }

    my $f    = tempfile();
    my $file = path($f)->stringify;
    $f->append_raw('no bom');
    check_test( sub { file_hasnt_bom($file) }, { ok => 1 } );
};

done_testing;
