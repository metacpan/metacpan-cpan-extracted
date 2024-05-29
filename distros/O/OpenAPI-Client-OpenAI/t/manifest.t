#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Cwd qw( abs_path );

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

my @paths = map { abs_path($_) } qw( .gitignore .git openai-openapi );
ok_manifest( { exclude => \@paths } );
