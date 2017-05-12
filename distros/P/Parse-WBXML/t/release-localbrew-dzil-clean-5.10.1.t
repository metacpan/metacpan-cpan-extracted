#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Temp;
use Test::More;

delete @ENV{qw/AUTHOR_TESTING RELEASE_TESTING/};

unless($ENV{'PERLBREW_ROOT'}) {
    plan skip_all => "Environment variable 'PERLBREW_ROOT' not found";
    exit;
}

my $brew = q[dzil-clean-5.10.1];

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

$ENV{'PATH'} = join(':', @ENV{qw/PERLBREW_PATH PATH_WITHOUT_PERLBREW/});

plan tests => 1;

my $tmpdir = File::Temp->newdir;

my $pid = fork;
if(!defined $pid) {
	fail "Forking failed!";
	exit 1;
} elsif($pid) {
    waitpid $pid, 0;
    ok !$?, "cpanm should successfully install your dist with no issues";
} else {
    close STDOUT;
    close STDERR;

    chdir File::Spec->catdir($FindBin::Bin,
        File::Spec->updir); # exit test directory

    exec 'perl', $cpanm_path, '-L', $tmpdir->dirname, '.';
}
