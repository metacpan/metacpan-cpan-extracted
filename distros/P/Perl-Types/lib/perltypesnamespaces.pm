## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names
package  # hide from PAUSE indexing
    perltypesnamespaces;
use strict;
use warnings;
use perltypesnamespaces_generated;
our $VERSION = 0.002_000;

use Data::Dumper;

sub array {
    my $namespaces = [];
    for my $name ( sort keys %main:: ) {
        my $glob = $main::{$name};
        if ( (not ref $glob) and  %{$glob} ) {  # check glob ref to avoid "not a HASH reference" error on DUMMY code refs
            push @{$namespaces}, $name;
        }
    }
    return $namespaces;
}

sub hash {
#    print 'in perltypesnamespaces::hash(), top of subroutine', "\n";
    my $namespaces = {};
    for my $name ( sort keys %main:: ) {
        my $glob = $main::{$name};
#        print 'in perltypesnamespaces::hash(), have ref $glob = ', ref $glob, "\n";
#        print 'in perltypesnamespaces::hash(), have $glob = ', Dumper($glob), "\n";
        if ( (not ref $glob) and  %{$glob} ) {  # check glob ref to avoid "not a HASH reference" error on DUMMY code refs
            $namespaces->{$name} = 1;
        }
    }
#    print 'in perltypesnamespaces::hash(), bottom of subroutine, about to return $namespaces = ', Dumper($namespaces), "\n";
    return $namespaces;
}

sub hash_noncore {
#    print 'in hash_noncore(), have $perltypesnamespaces_generated::CORE = ' . Dumper($perltypesnamespaces_generated::CORE) . "\n";
    my $namespaces = {};
    for my $name ( sort keys %main:: ) {
        my $glob = $main::{$name};
        if ( (not ref $glob) and  %{$glob}  # check glob ref to avoid "not a HASH reference" error on DUMMY code refs
            and ( not exists $perltypesnamespaces_generated::CORE->{$name} ) )
        {
            $namespaces->{$name} = 1;
        }
    }
    return $namespaces;
}

sub hash_noncore_nonperltypes {
#    print 'in hash_noncore(), have $perltypesnamespaces_generated::CORE = ' . Dumper($perltypesnamespaces_generated::CORE) . "\n";
    my $namespaces = {};
    for my $name ( sort keys %main:: ) {
        my $glob = $main::{$name};
        if ( (not ref $glob) and  %{$glob}  # check glob ref to avoid "not a HASH reference" error on DUMMY code refs
            and ( not exists $perltypesnamespaces_generated::CORE->{$name} )
            and ( not exists $perltypesnamespaces_generated::PERLTYPES->{$name} ) )
        {
            $namespaces->{$name} = 1;
        }
    }
    return $namespaces;
}

1;
