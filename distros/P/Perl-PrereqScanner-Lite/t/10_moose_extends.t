#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec::Functions qw/catfile/;
use Perl::PrereqScanner::Lite;

use t::Util;
use Test::More;
use Test::Deep;

subtest 'omitted scanner name' => sub {
    subtest 'add extra scanner by add_extra_scanner method' => sub {
        my $scanner = Perl::PrereqScanner::Lite->new;
        $scanner->add_extra_scanner('Moose');

        my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'moose.pl'));
        cmp_deeply(get_reqs_hash($got), {
            Carp           => 0,
            Cwd            => 0,
            Env            => 0,
            Fnctrl         => 0,
            "Getopt::Long" => 0,
            "Getopt::Std"  => 0,
            Moose          => 0,
            POSIX          => 0,
            strict         => 0,
            warnings       => 0,
            perlIO         => 0,
            Opcode         => 0,
        });
    };

    subtest 'add extra scanner by constructor' => sub {
        my $scanner = Perl::PrereqScanner::Lite->new({
            extra_scanners => [qw/Moose/],
        });

        my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'moose.pl'));
        cmp_deeply(get_reqs_hash($got), {
            Carp           => 0,
            Cwd            => 0,
            Env            => 0,
            Fnctrl         => 0,
            "Getopt::Long" => 0,
            "Getopt::Std"  => 0,
            Moose          => 0,
            POSIX          => 0,
            strict         => 0,
            warnings       => 0,
            perlIO         => 0,
            Opcode         => 0,
        });
    };
};

subtest 'fully scanner name' => sub {
    subtest 'add extra scanner by add_extra_scanner method' => sub {
        my $scanner = Perl::PrereqScanner::Lite->new;
        $scanner->add_extra_scanner('+Perl::PrereqScanner::Lite::Scanner::Moose');

        my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'moose.pl'));
        cmp_deeply(get_reqs_hash($got), {
            Carp           => 0,
            Cwd            => 0,
            Env            => 0,
            Fnctrl         => 0,
            "Getopt::Long" => 0,
            "Getopt::Std"  => 0,
            Moose          => 0,
            POSIX          => 0,
            strict         => 0,
            warnings       => 0,
            perlIO         => 0,
            Opcode         => 0,
        });
    };

    subtest 'add extra scanner by constructor' => sub {
        my $scanner = Perl::PrereqScanner::Lite->new({
            extra_scanners => [qw/+Perl::PrereqScanner::Lite::Scanner::Moose/],
        });

        my $got = $scanner->scan_file(catfile($FindBin::Bin, 'resources', 'moose.pl'));
        cmp_deeply(get_reqs_hash($got), {
            Carp           => 0,
            Cwd            => 0,
            Env            => 0,
            Fnctrl         => 0,
            "Getopt::Long" => 0,
            "Getopt::Std"  => 0,
            Moose          => 0,
            POSIX          => 0,
            strict         => 0,
            warnings       => 0,
            perlIO         => 0,
            Opcode         => 0,
        });
    };
};

done_testing;

