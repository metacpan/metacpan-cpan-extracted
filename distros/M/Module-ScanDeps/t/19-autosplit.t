#!/usr/bin/perl

use strict;
use warnings;
use File::Temp;
use File::Spec;
use IPC::Run3;

use Test::More;
use lib 't/data/autosplit';

BEGIN { use_ok( 'Module::ScanDeps' ); }

sub create_script
{
    my ($text) = @_;
    my ($fh, $filename) = File::Temp::tempfile( UNLINK => 1, SUFFIX => '.pl' );
    print $fh $text;
    close $fh;
    return $filename;
}

sub test_autosplit
{
    my ($tag, $scan, $expected, $text) = @_;

    diag($tag);
    my $filename = create_script($text);
    my $rv = $scan->($filename);

    foreach my $mod (@$expected)
    {
        ok($rv->{$mod}, "$mod detected");
    }
    my @bogus = grep { File::Spec->file_name_is_absolute($_) or m|^\.[/\\]| } keys %$rv;
    is("@bogus", "", "no bogus keys in \$rv");
}

test_autosplit(
    'use autosplitted module - static scan',
    sub { scan_deps(files => [$_[0]], recurse => 1) },
    [qw(AutoLoader.pm Foo.pm auto/Foo/autosplit.ix auto/Foo/barnie.al auto/Foo/fred.al)],
    'use Foo');

test_autosplit(
    'use autosplitted module - runtime scan, absolute search path',
    sub { scan_deps_runtime(files => [$_[0]], recurse => 1, execute => [qw(fee fo fum)]) },
    [qw(AutoLoader.pm Foo.pm auto/Foo/autosplit.ix auto/Foo/barnie.al)],
    << '...');
        use Cwd;
        use lib getcwd().'/t/data/autosplit';
        my $Foo = "Foo";
        eval "use $Foo";
        Foo::blab(@ARGV);
        Foo::barnie();
...
test_autosplit(
    'use autosplitted module - runtime scan, relative search path',
    sub { scan_deps_runtime(files => [$_[0]], recurse => 1, execute => 1) },
    [qw(AutoLoader.pm Foo.pm auto/Foo/autosplit.ix auto/Foo/barnie.al)],
    << '...');
        use lib 't/data/autosplit';
        my $Foo = "Foo";
        eval "use $Foo";
        Foo::blab(@ARGV);
        Foo::barnie();
...


my $scanner = create_script(<< '...');
    use Module::ScanDeps;
    my ($file, @args) = @ARGV; 
    scan_deps_runtime(files => [$file], recurse => 1, execute => \@args);
...
my $file = create_script(<< '...');
        use lib 't/data/autosplit';
        my $Foo = "Foo";
        eval "use $Foo";
        Foo::blab(@ARGV);
        Foo::barnie();
...
my @args = qw(fee fo fum);

# run $file with @args once and capture its output
my $exp;
run3([$^X, $scanner, $file, @args], \undef, \$exp);
is($?, 0, "script ran successfully");
my $rx = join(".*", map { quotemeta($_) } @args, "barnie!");
like($exp, qr/$rx/s, "script output");

# run $scanner on $file with @args
my ($out, $err);
run3([$^X, "-Mblib", $scanner, $file, @args], \undef, \$out, \$err);
is($?, 0, "scanner ran successfully");
is($out, $exp, "scanner output");

done_testing();

