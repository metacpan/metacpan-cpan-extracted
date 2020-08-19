=begin comment

Smartcat::App::Utils tests

=end comment

=cut

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
use Test::Fatal;

use Cwd qw(abs_path);
use File::Basename;
use File::Spec::Functions qw(catfile);

use lib 'lib';

use_ok('Smartcat::App::Utils');

is( prepare_document_name(qw( ./test/java.po .po ja)), 'java_ja.po',
    "document name built corretly");

is( prepare_file_name(qw( java_ja ja .po )), 'java.po',
    "file name built corretly");

my $test_data_dir =
  catfile( dirname( abs_path(__FILE__) ), 'data' );

ok( are_po_files_empty([ catfile($test_data_dir, 'empty.po') ]),
    "empty .po file is detected corretly");

ok( are_po_files_empty([ catfile($test_data_dir, 'empty-id-with-context.po') ]),
    ".po file with empty msgid is detected as empty");

ok( !are_po_files_empty([ catfile($test_data_dir, 'multiline.po') ]),
    "multiline .po file is not detected as empty");
