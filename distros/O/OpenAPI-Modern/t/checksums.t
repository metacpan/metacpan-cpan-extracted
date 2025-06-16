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

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Digest::MD5 'md5_hex';
use Path::Tiny;

foreach my $line (<DATA>) {
  chomp $line;
  my ($filename, $checksum) = split / /, $line, 2;

  is(md5_hex(path($filename)->slurp_raw), $checksum, 'checksum for '.$filename.' is correct')
    or diag $filename.' is not what was shipped in the distribution!';
}

done_testing;

__DATA__
share/oas/LICENSE 7a3f5fcd4ca489b5555f5f92ec054a0a
share/oas/dialect/base.schema.json cb0121edd8ec605f34d99b3ae53d7a3d
share/oas/meta/base.schema.json 70176e6eb8dc888007ac05da90a1e07f
share/oas/schema-base.json 7c9e5a9cf7cc88adc4057c03373641c6
share/oas/schema.json 234071e79d67882e5cf81c2fcc82990b
