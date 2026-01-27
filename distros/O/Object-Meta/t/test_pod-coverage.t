#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2026-01-27
# @package Test for the POD Coverage
# @subpackage t/test_pod-coverage.t

# This Module checks the POD Coverage for all modules in the project
#
#---------------------------------
# Requirements:
# - The Perl Module "Pod::Coverage" must be installed
#

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Find;

use Test::More;
use Test::Pod;
use Pod::Coverage;


BEGIN {
    use lib "lib";
    use lib "../lib";
}    #BEGIN

my $smodule = "";
my $spath   = abs_path($0);

( $smodule = $spath ) =~ s/.*\/([^\/]+)$/$1/;
$spath =~ s/^(.*\/)$smodule$/$1/;

my @modules_found = ();
my $module_name   = undef;

sub module_files {
    if ( -f $_ && $File::Find::name =~ qr/(.+).pm$/i ) {
        $module_name = $1;
        $module_name =~ s#^lib/##;
        $module_name =~ s#/#::#g;

        push @modules_found, ($module_name);
    }
}

# Find all Perl Modules
find( { wanted => \&module_files, follow => 0 }, 'lib' );

print "# Found Modules:\n", join( "\n", @modules_found ), "\n";

# The known modules in the project
my %modules_expected = (
    'Object::Meta' => {
        package           => 'Object::Meta',
        file => 'lib/Object/Meta.pm',
        expected_coverage => 1
    },
    'Object::Meta::List' => {
        package            => 'Object::Meta::List',
        file => 'lib/Object/Meta/List.pm',
        expected_coverage  => 0.333333333333333,
        expected_uncovered => {
            setIndexField         => 0,
            createIndex           => 0,
            buildIndex            => 0,
            buildIndexAll         => 0,
            Clear                 => 0,
            clearList             => 0,
            clearLists            => 0,
            getMetaObject         => 0,
            getIdxValueArray      => 0,
            getIdxMetaObjectCount => 0,
        }
    },
    'Object::Meta::Named' => {
        package           => 'Object::Meta::Named',
        file => 'lib/Object/Meta/Named.pm',
        expected_coverage => 1
    },
    'Object::Meta::Named::List' => {
        package           => 'Object::Meta::Named::List',
        file => 'lib/Object/Meta/Named/List.pm',
        expected_coverage => 1
    },
);

subtest 'Module POD Coverage' => sub {
    for $module_name (@modules_found) {

        subtest "Module '$module_name'" => sub {
            pod_file_ok( $modules_expected{$module_name}{file}, "Module '$module_name': POD is valid" );

            isnt( $modules_expected{$module_name}, undef, "Module '$module_name': Coverage as expected" );

            # Check the POD Coverage
            my $coverage = Pod::Coverage->new( %{ $modules_expected{$module_name} } );

            is(
                $coverage->coverage(),
                $modules_expected{$module_name}{expected_coverage},
                "Module '$module_name': Coverage '$modules_expected{$module_name}{expected_coverage}' as expected"
            );

            my @methods_uncovered = $coverage->uncovered();

            for my $method (@methods_uncovered) {
                isnt( $modules_expected{$module_name}{expected_uncovered}{$method},
                    undef, "Method '$module_name :: $method ()' is uncovered as expected" );
            }
        };

    }
};

done_testing();
