#!perl

use strict;
use warnings;

use Perl::Critic;
use Test::More;

use Data::Dumper;
use File::Basename;
use File::Spec;

my %modules = (
    'Module::Empty'    => 0,
    'Module::CoreFunc' => 11,
);

my $dir = dirname __FILE__;

plan skip_all =>'This test is not run on Windows machines' if $^O eq 'MSWin32';

my $pc = Perl::Critic->new( -'single-policy' => 'OTRS::ProhibitSomeCoreFunctions' );

for my $module ( keys %modules ) {
    my @parts = split /::/, $module;
    $parts[-1] .= '.pm';

    my $path = File::Spec->catfile(
        $dir,
        @parts,
    );

    my @violations = $pc->critique( $path );

    is scalar @violations, $modules{$module}, "Check $module";
}

done_testing();
