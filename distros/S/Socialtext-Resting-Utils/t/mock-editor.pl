#!/usr/bin/perl

# Make everything ALLCAPS

my $name = shift;
open(my $fh, $name) or die "Can't open $name: $!";
local $/;
my $content = <$fh>;
close $fh;

$content =~ s/([a-z])/uc($1)/eg;

open(my $wfh, ">$name") or die "Can't open $name: $!";
print $wfh $content;
close $wfh or die "Can't write $name: $!";
