package t::Util;
use strict;
use warnings;
use utf8;
use CPAN::Meta::Requirements;
use Test::Deep;

use parent qw/Exporter/;

our @EXPORT = qw/slurp get_reqs_hash prereqs_ok/;

sub slurp {
    my ($file_path) = @_;

    open my $fh, '<', $file_path;
    do { local $/; <$fh>; };
}

sub get_reqs_hash {
    my ($req) = @_;

    CPAN::Meta::Requirements->new->add_requirements($req)->as_string_hash;
}

sub prereqs_ok {
    my ($got) = @_;
    cmp_deeply(get_reqs_hash($got), {
        'strict'       => 0,
        'warnings'     => 0,
        'parent'       => 0,
        'base'         => 0,
        'lib'          => 0,
        'constant'     => 0,
        'aliased'      => 0,
        'perl'         => 'v5.8.1',
        'Time::Local'  => 0,
        'Exporter'     => 0,
        'File::Temp'   => '0.1_2',
        'Fcntl'        => 0,
        'FileHandle'   => 0,
        'Env'          => 0,
        'English'      => 0,
        'Carp'         => 0,
        'Cwd'          => 0,
        'Getopt::Long' => 0,
        'Getopt::Std'  => 0,
        'TieHash'      => 0,
        'Text::Tabs'   => 0,
        'PerlIO'       => 0,
        'Opcode'       => 0,
        'Pod::Checker' => 0,
        'Pod::Find'    => 0,
        'JSON'         => 2,
        'Test::More'   => 0,
        'Perl::PrereqScanner'       => 0,
        'Perl::PrereqScanner::Lite' => 0,
        'Locale::MakeText'          => 0,
        'Locale::MakeText::Lexicon' => 0,
        'Moose' => 0,
        'Any::Moose' => 0,
        'if' => 0,
    });
}

1;

