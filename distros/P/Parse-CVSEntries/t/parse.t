#!perl -w
use strict;
use Test::More tests => 8;

my $pkg = 'Parse::CVSEntries';
require_ok( $pkg );

ok( !$pkg->new("does_not_exist"),
    "parsing nothing gets you nothing" );

my $parsed = $pkg->new('t/empty_entries');
ok( $parsed, "opened empty" );
isa_ok( $parsed, $pkg );

is_deeply( [ $parsed->entries ], [], "empty yeilded no entries" );

$parsed = $pkg->new('t/module_build_entries');
ok( $parsed, "module::build entries" );
is_deeply( [ map { $_->name } $parsed->entries ],
           [ qw( Build.PL INSTALL MANIFEST.SKIP Makefile.PL
                 README TODO configs lib patches t testbed
                 .cvsignore .releaserc MANIFEST Changes ) ],
          "everything" );

is_deeply( [ map { $_->name } grep { $_->dir } $parsed->entries ],
           [ qw( configs lib patches t testbed ) ],
          "dirs" );
