#!/usr/bin/perl
use warnings;
use strict;

use FindBin;
use Test::More;
use Syntax::Construct ();


unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my %constructs;

my $libfile = $INC{'Syntax/Construct.pm'};
open my $IN, '<', $libfile or die $!;
my $version;
while (my $line = <$IN>) {
    if (my ($v) = $line =~ /^=head2 ([.0-9]+|old)/) {
        $version = $v;

    } elsif (my ($constrs) = $line =~ /^=head3 (.*)$/) {
        for my $constr (split ' ', $constrs) {
            $constructs{$constr}{pod}++;
            $constructs{$constr}{version}{$version}++;
        }

    } elsif ($line =~ / (?:'(5\.[0-9]{3})'|(old)) => \[qw\[$/) {
        my $v = $1 || $2;
        until ((my $l = <$IN>) =~ /\]\],$/) {
            for my $constr ($l =~ /(\S+)/g) {
                $constructs{$constr}{code}++;
                $constructs{$constr}{version}{$v}++;
            }
        }
    } elsif (my ($removed_construct, $rm_version)
             = $line =~ / '([^']*)' +=> '(5\.[0-9]{3})',$/
    ) {
        $constructs{$removed_construct}{removed}{$rm_version}++;
    }
}

open my $TEST, '<', "$FindBin::Bin/02-constructs.t" or die $!;
undef $version;
while (<$TEST>) {
    if (/^ +(?:'([.0-9]+)'|(old)) => \[$/) {
        $version = $1 || $2;
    }
    if (my ($constr) = /^ +\[ '(.+)',/) {
        $constructs{$constr}{test}++;
        $constructs{$constr}{version}{$version}++;
    }
}

my $count_old = 0;
for my $constr (keys %constructs) {
    is($constructs{$constr}{$_}, 1, "$_ for $constr") for qw( pod code test );

    my @versions = keys %{ $constructs{$constr}{version} };
    is(@versions, 1, "versions $constr");
    is($constructs{$constr}{version}{ $versions[0] }, 3, "version $constr");

    if ('old' eq $versions[0]) {
        ++$count_old;
        is(keys %{ $constructs{$constr}{removed} }, 1, "$constr removed once");
    }

}

done_testing($count_old + 5 * keys %constructs);
