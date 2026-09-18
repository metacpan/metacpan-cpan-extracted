# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test2::V0 -no_pragmas => 1;
use if $ENV{AUTHOR_TESTING}, 'Test2::Warnings';
use Digest::MD5 'md5_hex';
use Mojo::File 'path';

foreach my $line (<DATA>) {
  chomp $line;
  my ($filename, $checksum) = split / /, $line, 2;

  is(md5_hex(path($filename)->slurp), $checksum, 'checksum for '.$filename.' is correct')
    or diag $filename.' is not what was shipped in the distribution!';
}

done_testing;

__DATA__
share/3.1/strict-dialect.json d13df15c1f7475a477cdff7c3dfa0bca
share/3.1/strict-schema.json bbd8a79444cfcfb51dc12bf112ebc1d2
share/3.2/strict-dialect.json 96d61636ddd9c6bf7e95e13e3ece731f
share/3.2/strict-schema.json 1aa955923954d26a96994efbdd22d686
share/oas/3.0/schema.json bd82d5fc176d386ce85d0e8d5836aa32
share/oas/3.1/dialect.json 06cea984f8807c13e2916914251e22c3
share/oas/3.1/schema-base.json 529eaf48223ccf46c0627f2b53d14815
share/oas/3.1/schema.json b1815c7f6149b1252804bc687d8211dc
share/oas/3.1/vocabulary.json ecd6e7cbcc29cdabd9c445a2752fc394
share/oas/3.2/dialect.json 1058187136a6625bdecca7bab876ae17
share/oas/3.2/schema-base.json 888078cc42327bfe69cd5a954f56be98
share/oas/3.2/schema.json 6e382b7e7d5b4ba822689ffcb239d190
share/oas/3.2/vocabulary.json 0eab1bf3ab4570c94adda602535b68f0
share/oas/LICENSE 7a3f5fcd4ca489b5555f5f92ec054a0a
