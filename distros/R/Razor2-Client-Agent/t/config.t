#!perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use Razor2::Client::Config;

# Config.pm expects a log() method provided via multiple inheritance
# in the full Agent stack. Provide a no-op stub for testing.
no warnings 'once';
*Razor2::Client::Config::log = sub { };

# === find_home tests ===

subtest 'find_home uses razorhome attribute when set' => sub {
    my $config = Razor2::Client::Config->new;
    $config->{razorhome} = '/custom/razor';
    $config->find_home();
    is( $config->{razorhome_computed}, '/custom/razor',
        'razorhome_computed set from razorhome attribute' );
};

subtest 'find_home uses opt->{razorhome} when set' => sub {
    my $config = Razor2::Client::Config->new;
    $config->{opt} = { razorhome => '/opt/razor/home' };
    $config->find_home();
    is( $config->{razorhome_computed}, '/opt/razor/home',
        'razorhome_computed set from opt->{razorhome}' );
};

subtest 'find_home prefers razorhome over opt->{razorhome}' => sub {
    my $config = Razor2::Client::Config->new;
    $config->{razorhome} = '/direct';
    $config->{opt} = { razorhome => '/from-opt' };
    $config->find_home();
    is( $config->{razorhome_computed}, '/direct',
        'razorhome attribute takes priority' );
};

subtest 'find_home falls back to HOME env' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    local $ENV{HOME} = $tmpdir;
    my $config = Razor2::Client::Config->new;
    $config->find_home();
    my $expected = File::Spec->catdir( $tmpdir, '.razor' );
    is( $config->{razorhome_computed}, $expected,
        'razorhome_computed derived from HOME env' );
};

# === my_readlink tests ===

subtest 'my_readlink returns regular file unchanged' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $file   = "$tmpdir/regular.txt";
    open my $fh, '>', $file or die "Cannot create $file: $!";
    close $fh;

    my $config = Razor2::Client::Config->new;
    my $result = $config->my_readlink($file);
    is( $result, $file, 'regular file returned as-is' );
};

subtest 'my_readlink follows valid symlink' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $target = "$tmpdir/target.txt";
    my $link   = "$tmpdir/link.txt";
    open my $fh, '>', $target or die "Cannot create $target: $!";
    close $fh;
    symlink( $target, $link ) or plan skip_all => 'symlinks not supported';

    my $config = Razor2::Client::Config->new;
    my $result = $config->my_readlink($link);
    ( my $norm_result = defined $result ? $result : '' ) =~ s{\\}{/}g;
    ( my $norm_target = $target )        =~ s{\\}{/}g;
    is( $norm_result, $norm_target, 'symlink resolved to target' );
};

subtest 'my_readlink handles dangling symlink without crashing' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $link   = "$tmpdir/broken";
    symlink( "$tmpdir/nonexistent", $link ) or plan skip_all => 'symlinks not supported';

    my $config = Razor2::Client::Config->new;
    # readlink succeeds on dangling symlinks (returns target path),
    # but the target doesn't exist. The function should not crash.
    my $result = $config->my_readlink($link);
    ( my $norm_result   = defined $result ? $result : '' )        =~ s{\\}{/}g;
    ( my $norm_expected = "$tmpdir/nonexistent" ) =~ s{\\}{/}g;
    is( $norm_result, $norm_expected,
        'dangling symlink resolved to target path without crashing' );
};

subtest 'my_readlink follows relative symlink' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $target = "$tmpdir/real.txt";
    my $link   = "$tmpdir/relative_link.txt";
    open my $fh, '>', $target or die "Cannot create $target: $!";
    close $fh;
    symlink( 'real.txt', $link ) or plan skip_all => 'symlinks not supported';

    my $config = Razor2::Client::Config->new;
    my $result = $config->my_readlink($link);
    is( $result, $target, 'relative symlink resolved with directory prefix' );
};

done_testing;
