use Test::More;
use strict;
use warnings;
use File::Spec::Functions;
use SVN::Dump;

plan tests => 10;

# non-existing dumpfile
eval { my $dump = SVN::Dump->new( { file => 'krunch' } ); };
like( $@, qr/^Can't open krunch: /, "new() fails with non-existing file" );

# a SVN::Dump with a reader
my $dump
    = SVN::Dump->new( { file => catfile(qw( t dump full test123-r0.svn)) } );

is( $dump->version(), '', 'No dump format version yet' );
$dump->next_record();
is( $dump->version(), '2', 'Read dump format version' );

is( $dump->uuid(), '', 'No UUID yet' );
$dump->next_record();
is( $dump->uuid(), '2785358f-ed1c-0410-8d81-93a2a39f1216', 'Read UUID' );

my $as_string = join "\012", 'SVN-fs-dump-format-version: 2',
    "\012UUID: 2785358f-ed1c-0410-8d81-93a2a39f1216", "\012";

is( $dump->as_string(), $as_string, 'as_string()' );

# a SVN::Dump without a reader
$dump = SVN::Dump->new( { version => 3 } );
is( $dump->version(), '3', 'version set by new()' );

$dump = SVN::Dump->new( { uuid => 'bc4ef365-ce1c-0410-99c4-bdd0034106c0' } );
is( $dump->uuid(),
    'bc4ef365-ce1c-0410-99c4-bdd0034106c0',
    'uuid set by new()'
);

$dump = SVN::Dump->new(
    {   version => 2,
        uuid    => '77f6eb63-2709-0410-a607-da1692a51919'
    }
);
is( $dump->version(), '2', 'version set by new()' );
is( $dump->uuid(),
    '77f6eb63-2709-0410-a607-da1692a51919',
    'uuid set by new()'
);

