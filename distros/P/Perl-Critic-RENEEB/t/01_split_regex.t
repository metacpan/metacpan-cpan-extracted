#!perl

use strict;
use warnings;

use Perl::Critic;
use Test::More;

use Data::Dumper;
use File::Basename;
use File::Spec;

my %modules = (
    'Module::WithSplit'   => 0,
    'Module::SimpleRegex' => 1,
);

plan tests => scalar keys %modules;

my $dir = dirname __FILE__;

my $pc = Perl::Critic->new( -'single-policy' => 'Perl::Critic::Policy::RegularExpressions::RequireExtendedFormattingExceptForSplit' );

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
