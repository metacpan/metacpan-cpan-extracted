#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;
use Cwd qw(getcwd);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Temp qw(tempdir);

subtest 'Makefile.PL runs nested test directories' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/lib/Net");
    make_path("$tmp/t/nip");

    copy('Makefile.PL', "$tmp/Makefile.PL") or die "copy Makefile.PL: $!";
    copy('lib/Net/Nostr.pm', "$tmp/lib/Net/Nostr.pm") or die "copy Net::Nostr: $!";

    for my $path ("$tmp/t/top.t", "$tmp/t/nip/nested.t") {
        open my $tfh, '>', $path or die "open $path: $!";
        print {$tfh} "use strictures 2;\nuse Test2::V0 -no_srand => 1;\nok 1;\ndone_testing;\n";
        close $tfh;
    }

    my $cwd = getcwd();
    chdir $tmp or die "chdir $tmp: $!";
    my $output = `$^X Makefile.PL 2>&1`;
    my $exit = $? >> 8;
    chdir $cwd or die "chdir $cwd: $!";

    is($exit, 0, 'Makefile.PL exits cleanly') or diag $output;

    open my $fh, '<', "$tmp/Makefile" or die "open generated Makefile: $!";
    my $makefile = do { local $/; <$fh> };
    close $fh;

    my ($test_files) = $makefile =~ /^TEST_FILES\s*=\s*(.+)$/m;
    ok(defined $test_files, 'TEST_FILES is defined');
    like(
        $test_files,
        qr/(?:^|\s)(?:t\/\*\.t|t\/top\.t)(?:\s|$)/,
        'top-level test included'
    );
    like(
        $test_files,
        qr/(?:^|\s)(?:t\/\*\/\*\.t|t\/nip\/nested\.t)(?:\s|$)/,
        'nested test included'
    );
};

done_testing;
