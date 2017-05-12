#!/usr/bin/env perl

use 5.008001;
use utf8;
use strict;
use warnings;

use version; our $VERSION = qv('v0.0.3');


use Readonly;

use PPIx::Grep;
use Test::Deep qw< cmp_deeply >;


use Test::More tests => 7 * 2;


## no critic (Subroutines::ProtectPrivateSubs)

my @argv;
my %expected_options;


{
    @argv = qw< --help >;
    %expected_options = (
        help    => 1,
    );

    _test_call( \@argv, \%expected_options, [] );

    @argv = qw< -? >;
    _test_call( \@argv, \%expected_options, [] );
} # end block


{
    @argv = qw< --version >;
    %expected_options = (
        version => 1,
    );

    _test_call( \@argv, \%expected_options, [] );

    @argv = qw< -V >;
    _test_call( \@argv, \%expected_options, [] );
} # end block


{
    my $format = '%f:%l:%c:%s\n';   ## no critic (RequireInterpolationOfMetachars)
    @argv = ( qw< --format >, $format );
    %expected_options = (
        format  => $format,
    );

    _test_call( \@argv, \%expected_options, [] );

    @argv = ( "--format=$format" );
    _test_call( \@argv, \%expected_options, [] );

    my $pattern = 'PPI::Statement::Include';
    my $file = 'lib/Foo/Bar.pm';
    @argv = ( "--format=$format", $pattern, $file );
    _test_call( \@argv, \%expected_options, [ $pattern, $file ] );
} # end block


sub _test_call {
    my ($argv, $expected_options, $expected_argv) = @_;

    my @argv_copy = @{$argv};

    my %actual_options = PPIx::Grep::_initialize_from_command_line(\@argv_copy);
    my $message_suffix = join q< >, @{$argv};

    cmp_deeply(
        \%actual_options,
        $expected_options,
        "Got expected options for: $message_suffix",
    );

    cmp_deeply(
        \@argv_copy,
        $expected_argv,
        "Got expected leftovers in \@argv for: $message_suffix",
    );

    return;
} # end _test_call()

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
