#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 13;

use_ok('SWISH::3');

ok( my $s3 = SWISH::3->new(), "new swish3" );
is( $s3->get_file_ext('foo/bar'),     undef, "file with no ext is undef" );
is( $s3->get_file_ext('foo/bar.txt'), 'txt', "file with .txt has txt ext" );
is( $s3->get_mime('foo/bar'), undef, "file with no ext is undef mime" );
is( $s3->get_mime('foo/bar.txt'), 'text/plain', "file.txt is text/plain" );
is( $s3->get_real_mime('foo/bar.txt'),
    'text/plain', "file.txt real mime is text/plain" );
is( $s3->get_mime('foo/bar.txt.gz'),
    'application/x-gzip', "file.txt.gz is application/x-gzip" );
is( $s3->get_real_mime('foo/bar.txt.gz'),
    'text/plain', "file.txt.gz real mime is text/plain" );
is( $s3->looks_like_gz('foo/bar.txt.gz'), 1, "file.txt.gz looks like gz" );
is( $s3->looks_like_gz('foo/bar.txt'), 0, "file.txt does not look like gz" );

# alter config. right now the only way is to merge xml
my $alt_mimes = <<XML;
<swish>
 <MIME>
  <foo>application/x-foo</foo>
 </MIME>
</swish>
XML

ok( $s3->config->merge($alt_mimes), "merge new alt_mimes" );
is( $s3->get_mime('bar.foo'),
    'application/x-foo', "new .foo extension recognized" );

