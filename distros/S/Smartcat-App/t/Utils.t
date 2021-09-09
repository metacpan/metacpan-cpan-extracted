=begin comment

Smartcat::App::Utils tests

=end comment

=cut

use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;
use Test::Fatal;

use Cwd qw(abs_path);
use File::Basename;
use File::Spec::Functions qw(catfile);

use lib 'lib';

use_ok('Smartcat::App::Utils');

is( get_language_from_ts_filepath(qw( ./ ./ja/test/java.po)), 'ja',
    "language got corretly");

is( get_language_from_ts_filepath(qw( /var/serge/ts/test_smartcat_folders /var/serge/ts/test_smartcat_folders/uk/f1/f2/f3/en.json.po)), 'uk',
    "language got corretly");

is( prepare_document_name(qw( '' ./test/java.po .po ja)), 'test/java_ja.po',
    "document name built corretly");

is( prepare_document_name(qw( /var/serge/ts/test_smartcat_folders /var/serge/ts/test_smartcat_folders/uk/f1/f2/f3/en.json.po .po uk)), 'f1/f2/f3/en.json_uk.po',
    "document name built corretly");

is( prepare_file_name(qw( test/java_ja ja .po )), 'test/java.po',
    "file name built corretly");

is( get_ts_file_key(qw( var/serge/ts/test_smartcat_folders var/serge/ts/test_smartcat_folders/uk/f1/f2/en.json )), 'f1/f2/en.json (uk)',
    "ts file key built corretly");

is( get_ts_file_key(qw( var/serge/ts/test_smartcat_folders var/serge/ts/test_smartcat_folders/uk/en.json )), 'en.json (uk)',
    "ts file key built corretly");
    
is( get_ts_file_key(qw( var/serge/ts/test_smartcat_folders var/serge/ts/test_smartcat_folders/uk/en.json 1 )), 'en.json (uk)',
    "ts file key built correctly");
    
is( get_ts_file_key(qw( var/serge/ts/test_smartcat_folders var/serge/ts/test_smartcat_folders/uk/en---123.json 1 )), '123.json (uk)',
    "ts file key built correctly");
    
is( get_ts_file_key(qw( var/serge/ts/test_smartcat_folders var/serge/ts/test_smartcat_folders/uk/en---777---123.json 1 )), '123.json (uk)',
    "ts file key built correctly");

is( get_document_key(qw( en---123.json_ru ru )), 'en---123.json (ru)',
    "document key built correctly");

is( get_document_key(qw( inner_folder/en---123.json_ru ru )), 'inner_folder/en---123.json (ru)',
    "document key built correctly");

is( get_document_key(qw( en---123.json_ru ru 1 )), '123.json (ru)',
    "document key built correctly");

is( get_document_key(qw( inner_folder/en---123.json_ru ru 1 )), 'inner_folder/123.json (ru)',
    "document key built correctly");

is( get_document_key(qw( en---777---123.json_ru ru 1 )), '123.json (ru)',
    "document key built correctly");

is( get_document_key(qw( inner_folder/en---777---123.json_ru ru 1 )), 'inner_folder/123.json (ru)',
    "document key built correctly");

is ( get_file_id(qw(en.json)), undef,
    "file id built correctly");

is ( get_file_id(qw(en---123.json)), "123",
    "file id built correctly");

is ( get_file_id(qw(en---777---123.json)), "123",
    "file id built correctly");

is ( get_file_id(qw(inner_folder/en---123.json)), "123",
    "file id built correctly");

is ( get_file_id(qw(inner_folder/en---777---123.json)), "123",
    "file id built correctly");
    
my $test_data_dir =
  catfile( dirname( abs_path(__FILE__) ), 'data' );

ok( are_po_files_empty([ catfile($test_data_dir, 'empty.po') ]),
    "empty .po file is detected corretly");

ok( are_po_files_empty([ catfile($test_data_dir, 'empty-id-with-context.po') ]),
    ".po file with empty msgid is detected as empty");

ok( !are_po_files_empty([ catfile($test_data_dir, 'multiline.po') ]),
    "multiline .po file is not detected as empty");
