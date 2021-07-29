#!/usr/bin/env perl

use 5.006;
use warnings;
use autodie;

use English qw( -no_match_vars );
use File::Spec;
use Rex::Hook::File::Impostor;
use Test2::V0;

our $VERSION = '9999';

plan tests => 1;

my $impostor_directory = Rex::Hook::File::Impostor::get_impostor_directory();

my %expected_impostor_file_on = (
    not_windows =>
      { '/tmp/123' => File::Spec->join( $impostor_directory, 'tmp', '123' ), },
    windows => { ## no critic ( RequireInterpolationOfMetachars )
        'C:\temp\456' => File::Spec->join( $impostor_directory, 'C', 'temp', '456' ),
    },
);

my $os = $OSNAME eq 'MSWin32' ? 'windows' : 'not_windows';

for my $managed_file ( keys %{ $expected_impostor_file_on{$os} } ) {
    my $impostor_file = Rex::Hook::File::Impostor::get_impostor_for($managed_file);
    my $expected_impostor_file = $expected_impostor_file_on{$os}->{$managed_file};

    is( $impostor_file, $expected_impostor_file );
}
