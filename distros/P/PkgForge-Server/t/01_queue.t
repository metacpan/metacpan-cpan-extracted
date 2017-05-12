#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 16;
use File::Temp ();

use PkgForge::Queue;

my $queue_dir = File::Temp::tempdir('pkgforge-tests-XXXX',
                                    CLEANUP => 1,
                                    TMPDIR  => 1 )
    or die "Could not open tempdir: $!";

my %created;
for (1..100) {
    my $dir = File::Temp::tempdir( 'XXXXXXXX',
                                   CLEANUP => 1,
                                   DIR => $queue_dir )
        or die "Could not open tempdir: $!";

    $created{$dir} = 1;
}

my $queue = PkgForge::Queue->new($queue_dir);

isa_ok( $queue, 'PkgForge::Queue' );

can_ok( $queue, qw(directory allow_symlinks) );

is( $queue->directory, $queue_dir, 'Directory accessor' );

is( $queue->allow_symlinks, 0, 'Allow symlinks accessor' );

can_ok( $queue, qw(entries clear_entries add_entries count_entries) );
can_ok( $queue, qw(cruft clear_cruft add_cruft count_cruft erase_cruft) );

can_ok( $queue, qw(rescan) );

is( $queue->count_entries, 100, 'entries count' );

is( $queue->count_cruft, 0, 'cruft count' );

my @cruft = $queue->cruft;

is_deeply( \@cruft, [], 'correct cruft' );

my %found;
for my $qentry ($queue->entries) {
    my $path = $qentry->path;
    $found{$path} = 1;
}

is_deeply( \%found, \%created, 'correct entries' );

my %created_cruft;
for (1..10) {
    my $fh = File::Temp->new( TEMPLATE => 'XXXX',
                              DIR      => $queue_dir,
                              UNLINK   => 0 )
        or die "Could not open tempfile: $!";

    my $fname = $fh->filename;
    $fh->print('test') or die "Could not print to tempfile: $!";
    $fh->close or die "Could not close tempfile: $!";
    $created_cruft{$fname} = 1;
}

$queue->rescan;

is( $queue->count_entries, 100, 'entries count after rescan' );

is( $queue->count_cruft, 10, 'cruft count after rescan' );

%found = ();
for my $qentry ($queue->entries) {
    my $path = $qentry->path;
    $found{$path} = 1;
}

is_deeply( \%found, \%created, 'correct entries after rescan' );

my %found_cruft = ();
for my $path ($queue->cruft) {
    $found_cruft{$path} = 1;
}

is_deeply( \%found_cruft, \%created_cruft, 'correct cruft after rescan' );

$queue->erase_cruft;

$queue->rescan;

is( $queue->count_cruft, 0, 'cruft count after erase' );
