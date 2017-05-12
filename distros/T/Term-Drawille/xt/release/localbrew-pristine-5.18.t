#!perl

use strict;
use warnings;

use FindBin;
use File::Copy qw(copy);
use File::Spec;
use File::Temp;
use Test::More;

sub copy_log_file {
    my ( $home ) = @_;
    my $log_file = File::Spec->catfile($home, '.cpanm', 'build.log');
    my $tempfile = File::Temp->new(
        SUFFIX => '.log',
        UNLINK => 0,
    );
    copy($log_file, $tempfile->filename);
    diag("For details, please consult $tempfile")
}

sub is_dist_root {
    my ( @path ) = @_;

    return -e File::Spec->catfile(@path, 'Makefile.PL') ||
           -e File::Spec->catfile(@path, 'Build.PL');
}

delete @ENV{qw/AUTHOR_TESTING RELEASE_TESTING PERL5LIB/};

unless($ENV{'PERLBREW_ROOT'}) {
    plan skip_all => "Environment variable 'PERLBREW_ROOT' not found";
    exit;
}

my $brew = q[pristine-5.18];

my $cpanm_path = qx(which cpanm 2>/dev/null);
unless($cpanm_path) {
    plan skip_all => "The 'cpanm' program is required to run this test";
    exit;
}
chomp $cpanm_path;

my $perlbrew_bin = File::Spec->catdir($ENV{'PERLBREW_ROOT'}, 'perls',
    $brew, 'bin');

my ( $env, $status ) = do {
    local $ENV{'SHELL'} = '/bin/bash'; # fool perlbrew
    ( scalar(qx(perlbrew env $brew)), $? )
};

unless($status == 0) {
    plan skip_all => "No such perlbrew environment '$brew'";
    exit;
}

my @lines = split /\n/, $env;

foreach my $line (@lines) {
    if($line =~ /^\s*export\s+([0-9a-zA-Z_]+)=(.*)$/) {
        my ( $k, $v ) = ( $1, $2 );
        if($v =~ /^("|')(.*)\1$/) {
            $v = $2;
            $v =~ s!\\(.)!$1!ge;
        }
        $ENV{$k} = $v;
    } elsif($line =~ /^unset\s+([0-9a-zA-Z_]+)/) {
        delete $ENV{$1};
    }
}

my $pristine_path = qx(perlbrew display-pristine-path);
chomp $pristine_path;
$ENV{'PATH'} = join(':', $ENV{'PERLBREW_PATH'}, $pristine_path);

plan tests => 1;

my $tmpdir  = File::Temp->newdir;
my $tmphome = File::Temp->newdir;

my $pid = fork;
if(!defined $pid) {
    fail "Forking failed!";
    exit 1;
} elsif($pid) {
    waitpid $pid, 0;
    ok !$?, "cpanm should successfully install your dist with no issues" or copy_log_file($tmphome->dirname);
} else {
    close STDIN;
    close STDOUT;
    close STDERR;

    my @path = File::Spec->splitdir($FindBin::Bin);

    while(@path && !is_dist_root(@path)) {
        pop @path;
    }
    unless(@path) {
        die "Unable to find dist root\n";
    }
    chdir File::Spec->catdir(@path); # exit test directory

    # override where cpanm puts its log file
    $ENV{'HOME'} = $tmphome->dirname;

    

    system 'perl', $cpanm_path, '-L', $tmpdir->dirname, '.';
    exit($? >> 8);
}
