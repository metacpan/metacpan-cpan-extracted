use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use lib 'lib';
use lib 't/lib';

use Qmail::Deliverable ':all';
$Qmail::Deliverable::qmail_dir = 't/fixtures';
Qmail::Deliverable::reread_config();

subtest '1-argument form' => sub {
    is dot_qmail('alice@sub.example.com'),
        't/fixtures/domains/realhome/.qmail',
        'address routed via locals + exact assign returns bare .qmail';

    is dot_qmail('user@nowhere.test'), undef, 'non-local domain returns undef';

    is dot_qmail('luser-list@example.com'),
        't/fixtures/domains/example.com/.qmail-luser-list',
        'address routed via virtualdomain + wildcard finds .qmail-luser-list';

    is dot_qmail('luser-nobox@example.com'),
        't/fixtures/domains/example.com/.qmail-default',
        'falls back to .qmail-default when no specific .qmail-EXT exists';
};

subtest '6-argument form, empty dash + ext' => sub {
    is dot_qmail( 'alice', 1001, 1001, 't/fixtures/domains/realhome', '', '' ),
        't/fixtures/domains/realhome/.qmail',
        'bare .qmail returned when both dash and ext are empty';

    my $empty = tempdir( CLEANUP => 1 );
    is dot_qmail( 'x', 1, 1, $empty, '', '' ), '',
        'empty string (defaultdelivery) when no bare .qmail exists';
};

subtest '6-argument form with extension' => sub {
    is dot_qmail( 'vpopmail', 89, 89, 't/fixtures/domains/example.com', '-', 'luser-list' ),
        't/fixtures/domains/example.com/.qmail-luser-list',
        'exact .qmail-luser-list wins';

    is dot_qmail( 'vpopmail', 89, 89, 't/fixtures/domains/example.com', '-', 'luser-empty' ),
        't/fixtures/domains/example.com/.qmail-luser-empty',
        'empty file matches by name';

    is dot_qmail( 'vpopmail', 89, 89, 't/fixtures/domains/example.com', '-', 'luser-nosuch' ),
        't/fixtures/domains/example.com/.qmail-default',
        'falls back through .qmail-luser-default to .qmail-default';
};

subtest 'user-default fallback' => sub {
    my $home = tempdir( CLEANUP => 1 );
    open my $fh, '>', "$home/.qmail-foo-default" or die $!;
    print {$fh} "&user-default-handler\n";
    close $fh;

    is dot_qmail( 'user', 1, 1, $home, '-', 'foo-bar' ),
        "$home/.qmail-foo-default",
        '.qmail-foo-default catches foo-bar when no .qmail-foo-bar exists';
};

subtest 'returns undef when nothing matches' => sub {
    my $home = tempdir( CLEANUP => 1 );
    is dot_qmail( 'user', 1, 1, $home, '-', 'something' ),
        undef,
        'no .qmail-* and no .qmail-default => undef';
};

done_testing();
