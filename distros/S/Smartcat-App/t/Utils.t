=begin comment

Smartcat::App::Utils tests

=end comment

=cut

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Test::Fatal;

use lib 'lib';

use_ok('Smartcat::App::Utils');

is( prepare_document_name(qw( ./test/java.po .po ja)), 'java_ja.po',
    "document name built corretly");

is( prepare_file_name(qw( java_ja ja .po )), 'java.po',
    "file name built corretly");
