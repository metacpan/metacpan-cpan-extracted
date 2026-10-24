#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of make_tar pax_path );

use Skilletor::Tar qw( parse_tar strip_top_level is_reserved );

sub names { [ map { $_->{type}.':'.$_->{name} } @{ $_[0] } ] }

subtest 'files and dirs; mode keeps only the owner executable bit' => sub {
  my $e = parse_tar( make_tar(
    { name => 'repo-main/', type => '5' },
    { name => 'repo-main/skills/a/SKILL.md', data => "# a\n" },
    { name => 'repo-main/bin/run', data => "#!/bin/sh\n", mode => 0755 },
    { name => 'repo-main/group-x', data => 'g', mode => 0654 },
  ) );
  is_deeply( names($e), [ 'dir:repo-main', 'file:repo-main/skills/a/SKILL.md', 'file:repo-main/bin/run', 'file:repo-main/group-x' ], 'entries' );
  is( $e->[1]{data}, "# a\n", 'data' );
  ok( $e->[2]{executable}, 'owner x kept' );
  ok( !$e->[3]{executable}, 'group x alone is not executable' );
};

subtest 'GNU long names, pax paths and the ustar prefix' => sub {
  my $long = 'x/'.( 'l' x 150 ).'.md';
  my $e = parse_tar( make_tar(
    { name => '././@LongLink', type => 'L', data => $long."\0" },
    { name => 'truncated', data => 'L' },
    pax_path("p/\x{c3}\x{bc}.md"),
    { name => 'ignored', data => 'P' },
    { name => 'base.md', prefix => 'pre/fix', data => 'X' },
  ) );
  is_deeply( names($e), [ 'file:'.$long, "file:p/\x{fc}.md", 'file:pre/fix/base.md' ], 'names (pax path decoded as UTF-8)' );
};

subtest 'devices are skipped; a dir by trailing slash' => sub {
  my $e = parse_tar( make_tar( { name => 'dev', type => '3' }, { name => 'fifo', type => '6' }, { name => 'd//', type => '0' } ) );
  is_deeply( names($e), ['dir:d'], 'only the dir' );
};

subtest 'unsafe entries' => sub {
  is( error_of( sub { parse_tar( make_tar( { name => 'link', type => '2', linkname => '/etc/passwd' } ) ) } ),
    'unsafe tar entry (symlink/hardlink): link', 'symlink' );
  is( error_of( sub { parse_tar( make_tar( { name => 'hard', type => '1', linkname => 'x' } ) ) } ),
    'unsafe tar entry (symlink/hardlink): hard', 'hardlink' );
  is( error_of( sub { parse_tar( make_tar( { name => '/abs', data => 'x' } ) ) } ), 'unsafe tar entry (absolute path): /abs', 'absolute' );
  is( error_of( sub { parse_tar( make_tar( { name => 'C:x', data => 'x' } ) ) } ), 'unsafe tar entry (absolute path): C:x', 'drive' );
  is( error_of( sub { parse_tar( make_tar( { name => '\\x', data => 'x' } ) ) } ), 'unsafe tar entry (absolute path): \\x', 'backslash' );
  is( error_of( sub { parse_tar( make_tar( { name => 'a/../../x', data => 'x' } ) ) } ), 'unsafe tar entry (path traversal): a/../../x', 'dotdot' );
  is( error_of( sub { parse_tar( make_tar( pax_path(''), { name => 'x', data => 'x' } ) ) } ), 'unsafe tar entry (absolute path): <empty>', 'empty name' );
  my $err = error_of( sub { parse_tar( make_tar( { name => 'link', type => '2' } ) ) } );
  ok( $err, 'a symlink is refused even without a target' );
};

subtest 'a size that is no non-negative number is a corrupt archive' => sub {
  for my $case ( [ 'non-octal', 'zz' ], [ 'negative', '-0000001000' ], [ 'small negative', '-1' ] ) {
    my ( $what, $size ) = @$case;
    my $err;
    eval { parse_tar( make_tar( { name => 'bad', size => $size, data => '' }, { name => 'after', data => 'x' } ) ); 1 } or $err = $@;
    is( ( ref $err ? $err->message : $err ), 'corrupt tar entry (size): bad', $what.': its raw name' );
    ok( ref $err && !$err->isa('Skilletor::Error::Tar'), $what.': no unsafe-entry error (a cache serves)' );
  }
  my $e = parse_tar( make_tar( { name => 'empty', size => '', data => '' }, { name => 'next', data => 'y' } ) );
  is_deeply( names($e), [ 'file:empty', 'file:next' ], 'an empty size field is 0' );
};

subtest 'strip_top_level' => sub {
  my @e = map { { name => $_, type => 'file' } } qw( top top/a top/b/c );
  is_deeply( [ map { $_->{name} } @{ strip_top_level( \@e ) } ], [qw( a b/c )], 'one top dir stripped' );
  my @two = map { { name => $_, type => 'file' } } qw( a/x b/y );
  is_deeply( [ map { $_->{name} } @{ strip_top_level( \@two ) } ], [qw( a/x b/y )], 'two tops kept' );
  my @flat = map { { name => $_, type => 'file' } } qw( a );
  is_deeply( [ map { $_->{name} } @{ strip_top_level( \@flat ) } ], ['a'], 'nothing nested: kept' );
  my @dot = map { { name => $_, type => 'file' } } qw( . ./skills/x ./README.md );
  is_deeply( [ map { $_->{name} } @{ strip_top_level( \@dot ) } ], [qw( skills/x README.md )], '"./" stripped as a top dir' );
};

subtest 'is_reserved' => sub {
  ok( is_reserved('.skilletor-version'), 'the version file' );
  ok( is_reserved('./.skilletor-version'), 'with ./' );
  ok( is_reserved('.skilletor-version/x'), 'under it' );
  ok( !is_reserved('a/.skilletor-version'), 'deeper is fine' );
};

done_testing;
