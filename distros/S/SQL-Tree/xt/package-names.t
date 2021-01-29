#!/usr/bin/env perl

use Test::Most 'bail';
use File::Find;

sub expected_package_name($) {
    my $file = shift;
    $file =~ s{^lib/}{};
    $file =~ s{^t/lib/}{};
    $file =~ s{\.pm$}{};
    $file =~ s/\//::/g;
    return $file;
}

sub found_package_name($) {
    my $file = shift;

    # we assume first package name found is actual
    open my $fh, '<', $file or die "Could not open $file for reading: $!";
    my $package;
    while ( my $line = <$fh> ) {
        next unless $line =~ /^\s*package\s+((?:\w+)(::\w+)*)/;
        return $1;
    }
}

my @files;

find(
    {
        no_chdir => 1,
        wanted   => sub {
            my $file = $File::Find::name;
            return if !-f $file || $file !~ /\.pm$/ || $file =~ /\.svn/;
            push @files =>
              [ $file, found_package_name $file, expected_package_name $file];
        },
    },
    'lib'
);

find(
    {
        no_chdir => 1,
        wanted   => sub {
            my $file = $File::Find::name;
            return if !-f $file || $file !~ /\.pm$/ || $file =~ /\.svn/;
            push @files =>
              [ $file, found_package_name $file, expected_package_name $file];
        },
    },
    't/lib'
) if -d 't/lib';

plan tests => scalar @files;
for my $file (@files) {
    my ( $file, $have, $want ) = @$file;
    is $have, $want, "Package name correct for $file";
}
