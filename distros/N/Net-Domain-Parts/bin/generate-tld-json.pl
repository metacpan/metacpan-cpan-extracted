#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use File::Edit::Portable;
use JSON;

# This script updates the lib/Net/Domain/Parts.pm file with updated TLD data

# To use it, download the file found at:
# https://publicsuffix.org/list/public_suffix_list.dat as plain text into the
# data/tld.txt file, then delete everything below the __DATA__ line in the
# forementioned library file, then run the script

my $tld_txt_file = 'data/tld.txt';
my $tld_json_file = 'data/tld.json';

open my $fh, '<', $tld_txt_file or die "Can't open $tld_txt_file for reading: $!";

my %data;

while (my $line = <$fh>) {
    last if $line =~ /END ICANN DOMAINS/;
    chomp $line;

    next unless $line =~ /[a-z0-9]/i;
    $line =~ s|^\*\.||;
    $line =~ s|^\!||;

    if (! $data{version} && $line =~ /VERSION:\s+(\d{4}-\d{2}.*UTC)$/) {
        $data{version} = $1;
    }

    if ($line =~ /^$/ || $line =~ m{^[\s|\/]}) {
        next;
    }

    if ($line =~ /\..+\./) {
        $data{third_level_domain}->{$line} = 1;
    }
    elsif ($line =~ /\./) {
        $data{second_level_domain}->{$line} = 1;
    }
    else {
        $data{top_level_domain}->{$line} = 1;
    }
}

close $fh;

open my $wfh, '>', $tld_json_file or die "Can't open $tld_json_file for writing: $!";
my $json = JSON->new->pretty->encode(\%data);
print $wfh $json;
print "\nWrote out $tld_json_file\n";
close $wfh;

my @content;

{
    open my $fh, '<', $tld_json_file or die "Can't open $tld_json_file for reading: $!";
    @content = <$fh>;
}

my $rw = File::Edit::Portable->new;

$rw->splice(
    file   => 'lib/Net/Domain/Parts.pm',
    find   => '__DATA__',
    insert => \@content
);

