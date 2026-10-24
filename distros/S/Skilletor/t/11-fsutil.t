#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin;
use Path::Tiny qw( path tempdir );
use Skilletor::JSON qw( js_parse js_stringify );
use Skilletor::FSUtil qw(
  read_text decode_utf8_lossy encode_text inner_segments hash_bytes is_executable
  atomic_write write_text path_join path_normalize path_resolve same_path
);

# t/data/fsutil-oracle.json is Node's answer (maint/oracle-fsutil.mjs).
my $oracle = js_parse( path( $FindBin::Bin, 'data', 'fsutil-oracle.json' )->slurp_utf8 );

subtest 'path.normalize, path.join, path.resolve' => sub {
  is( path_normalize( $_->{p} ), $_->{out}, 'normalize "'.$_->{p}.'"' ) for @{ $oracle->{normalize} };
  is( path_join( @{ $_->{args} } ), $_->{out}, 'join '.js_stringify( $_->{args} ) ) for @{ $oracle->{join} };
  is( path_resolve( @{ $_->{args} } ), $_->{out}, 'resolve '.js_stringify( $_->{args} ) ) for @{ $oracle->{resolve} };
};

subtest 'innerSegments' => sub {
  for my $case ( @{ $oracle->{inner} } ) {
    is( js_stringify( inner_segments( $case->{p} ) ), js_stringify( $case->{out} ), 'inner "'.$case->{p}.'"' );
  }
};

subtest 'readFileSync utf8: lossy as Node decodes' => sub {
  for my $case ( @{ $oracle->{decode} } ) {
    is( js_stringify( decode_utf8_lossy( pack 'H*', $case->{hex} ) ), js_stringify( $case->{out} ), 'bytes '.$case->{hex} );
  }
  my $dir = tempdir;
  $dir->child('f')->spew_raw("\xEF\xBB\xBF{\xC3\xA9\xFF}");
  is( read_text( $dir->child('f') ), "\x{FEFF}{\x{e9}\x{FFFD}}", 'read_text keeps the BOM, replaces the bad byte' );
};

subtest 'encode_text: a lone surrogate is U+FFFD' => sub {
  no warnings qw( surrogate utf8 );
  is( encode_text("a\x{e9}\x{D800}"), "a\xC3\xA9\xEF\xBF\xBD", 'utf-8 bytes' );
};

subtest 'hash, executable bit' => sub {
  is( hash_bytes('abc'), 'sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', 'sha256' );
  ok( is_executable(0755), 'owner x' );
  ok( !is_executable(0644), 'no owner x' );
  ok( !is_executable(0655 & ~0100), 'group x alone is not' );
};

subtest 'atomic_write' => sub {
  my $dir = tempdir;
  my $f   = $dir->child( 'deep', 'er', 'file' );
  atomic_write( "$f", "bytes\n" );
  is( $f->slurp_raw, "bytes\n", 'written, parents made' );
  my $umask = umask;
  is( ( stat $f )[2] & 07777, 0666 & ~$umask, 'mode 0666 less the umask' );
  write_text( "$f.x", "\x{e9}", 1 );
  is( path("$f.x")->slurp_raw, "\xC3\xA9", 'text as utf-8' );
  is( ( stat "$f.x" )[2] & 07777, 0777 & ~$umask, 'executable: 0777 less the umask' );
  is_deeply( [ sort map { $_->basename } $f->parent->children ], [ 'file', 'file.x' ], 'no temp file left' );
  ok( !eval { atomic_write( "$f", "\x{100}" ); 1 }, 'characters are refused' );
};

subtest 'same_path' => sub {
  my $dir = tempdir;
  $dir->child('real')->mkpath;
  symlink( $dir->child('real'), $dir->child('link') ) or plan skip_all => 'no symlinks';
  ok( same_path( $dir->child('real'), $dir->child('link') ), 'link and target' );
  ok( !same_path( $dir->child('real'), $dir->child('missing') ), 'missing differs' );
  ok( same_path( $dir->child('missing'), $dir->child( 'x', '..', 'missing' ) ), 'missing paths compare resolved' );
};

done_testing;
