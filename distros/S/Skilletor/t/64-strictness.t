#!/usr/bin/env perl
# k145: a source's `vars` must be an object, a lock entry's `via` an array of strings, and a tarball
# cut short is an error – as in the reference.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of make_tar write_json );

use Path::Tiny qw( path tempdir );
use Skilletor::Catalog;
use Skilletor::Lock qw( read_lock );
use Skilletor::Tar qw( parse_tar );

subtest 'vars of a source must be an object' => sub {
  my $dir = tempdir;
  path( $dir, 'skills/a' )->mkpath;
  path( $dir, 'skills/a/SKILL.md' )->spew_raw("---\nname: a\ndescription: A\n---\nbody\n");
  for my $vars ( '[1]', '"x"', '3', 'true', 'null' ) {
    path( $dir, 'skilletor.json' )->spew_raw(qq({"description":"d","vars":$vars}));
    like( error_of( sub { Skilletor::Catalog->scan("$dir") } ), qr/"vars" must be an object/, "vars $vars" );
  }
  path( $dir, 'skilletor.json' )->spew_raw('{"vars":{"k":1}}');
  is_deeply( Skilletor::Catalog->scan("$dir")->{meta}{vars}, { k => 1 }, 'an object is read' );
};

subtest 'via of a lock entry must be an array of strings' => sub {
  my $dir  = tempdir;
  my $file = "$dir/skilletor.lock.json";
  my $put  = sub { path($file)->spew_raw( '{"skills/x":{"source":"s","version":"v","files":{},"via":'.$_[0].'}}' ) };
  $put->('["bundle:perl@shared"]');
  is_deeply( read_lock($file)->{'skills/x'}{via}, ['bundle:perl@shared'], 'an array is read' );
  for my $bad ( '"bundle:perl@shared-extra"', '"bundle:perl@shared"', '3', '[1]', 'null', '{"a":1}' ) {
    $put->($bad);
    like( error_of( sub { read_lock($file) } ), qr/skills\/x: "via" must be an array of strings/, "via $bad" );
  }
};

subtest 'a tarball cut short is a corrupt archive' => sub {
  my $full = make_tar( { name => 'p/a', data => 'a' }, { name => 'p/b', data => 'b' x 700 } );
  is( scalar @{ parse_tar($full) }, 2, 'the whole archive is read' );
  for my $case ( [ 'inside data', 512 + 100 ], [ 'after a header', 3 * 512 ], [ 'inside a header', 1024 + 100 ],
    [ 'end marker gone', 512 + 512 + 512 + 1024 ], [ 'partial block after the last entry', 3 * 512 + 1024 + 100 ] ) {
    my ( $what, $at ) = @$case;
    like( error_of( sub { parse_tar( substr $full, 0, $at ) } ), qr/^corrupt tar/, $what );
  }
};

done_testing;
