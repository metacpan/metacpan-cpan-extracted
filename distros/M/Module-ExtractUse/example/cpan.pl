#!/usr/bin/perl -w
use strict;
use CPANPLUS::Backend;
use File::Find;
use Module::ExtractUse;

my $cp=new CPANPLUS::Backend;

my $filter=shift @ARGV || '^Class::DBI$';
my $hide_own=1;

my $mod_search=$cp->search(type=>'module',
			   list => [$filter]);

my %seen;

foreach my $module (values %{$mod_search}) {
    my $package=$module->package;
    next unless $package;
    next if $seen{$package}++;

    print "*** CHECKING DISTRIBUTION $package\n";

    $module->fetch || next;
    my $extracted_to=$module->extract;
    find(\&find_pms,$extracted_to);
}


sub find_pms {
    return unless /\.pm$/;
    return if $File::Find::dir=~m|/t/|;
    my $p=Module::ExtractUse->new;

    my @used=$p->extract_use($_)->array;
    print "\n$File::Find::dir $_\n * ";
    print join("\n * ",@used),"\n";;
}








