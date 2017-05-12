#!/usr/bin/perl

use strict;
use warnings;

use 5.010;

use Net::SSH2;
use Scalar::Quote qw(quote);

use Data::Dumper;

while (<>) {
    print;
    last if /^###+\s+CONSTANTS\s+BELOW/;
}

say <<EOH;

#
# The constant definitions are automatically extracted from the real
# Net::SSH2 module and inserted here by the gen_constants_ssh2.pl
# script.
#
# Do not touch by hand!!!
#
EOH

for my $c (@Net::SSH2::EXPORT_OK) {
    my $v = eval "Net::SSH2::$c()";
    if ($@) {
        $@ =~ /(.*\S)\s+at\s+.*\s+line\s+\d+\.?\n?$/
            or die "unable to extract error message from $@";
        my $q = quote $1;
        say "sub $c () { croak $q }"
    }
    else {
        say "sub $c () { $v }";
    }
}

say "";
say Data::Dumper->Dump([\%Net::SSH2::EXPORT_TAGS], [qw(*EXPORT_TAGS)]);
say "";

my $print;
while (<>) {
    $print = 1 if /^###+\s+CONSTANTS\s+ABOVE/;
    print if $print;
}

