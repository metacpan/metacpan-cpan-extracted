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
use Path::Tiny;

foreach my $line (<DATA>) {
  chomp $line;
  my ($filename, $checksum) = split / /, $line, 2;

  is(md5_hex(path($filename)->slurp_raw), $checksum, 'checksum for '.$filename.' is correct')
    or diag $filename.' is not what was shipped in the distribution!';
}

done_testing;

__DATA__
share/3.1/strict-dialect.json d13df15c1f7475a477cdff7c3dfa0bca
share/3.1/strict-schema.json 94554b65920faa88f89d0e65d2e099c1
share/3.2/strict-dialect.json 11c94716eb238cd21d84a4eea7c3e1ce
share/3.2/strict-schema.json 3b89643225eced6ce7d3f1a923e91624
share/oas/3.1/dialect.json 06cea984f8807c13e2916914251e22c3
share/oas/3.1/schema-base.json c7384a02a8fa98ba83488c09d76a1df1
share/oas/3.1/schema.json 724962b927e62a5a578604093e5ecc78
share/oas/3.1/vocabulary.json ecd6e7cbcc29cdabd9c445a2752fc394
share/oas/3.2/dialect.json 9535fe7b9329795d5fc0796d0f934e89
share/oas/3.2/schema-base.json 6889b580da74bc193eefd5f57d1234f0
share/oas/3.2/schema.json e236d7ccdb52e28372f4f03dd8382838
share/oas/3.2/vocabulary.json 8bc0eea7bd6d14fcc1bb66f6b3e99fdf
share/oas/LICENSE 7a3f5fcd4ca489b5555f5f92ec054a0a
