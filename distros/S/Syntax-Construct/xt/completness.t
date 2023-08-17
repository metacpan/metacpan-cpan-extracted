#!/usr/bin/perl
use warnings;
use strict;
use FindBin;

my $plan;
BEGIN {
    my %count = (constructs => 97,
                 removed    => 7,
                 aliases    => 77,
                 old        => 4);
    $plan = 5 * $count{constructs} + 3 * $count{removed}
          + 6 * $count{aliases} + $count{old} + 1;
}

use FindBin;
use Test::More tests => $plan;
use Syntax::Construct ();

my %constructs;

my $libfile = $INC{'Syntax/Construct.pm'};
open my $IN, '<', $libfile or die $!;
my ($version, $in_alias, $pod_construct, %aliases);
my $count_old = 0;
while (my $line = <$IN>) {
    if (my ($v) = $line =~ /^=head2 ([.0-9]+|old)/) {
        $version = $v;

    } elsif (my ($constrs) = $line =~ /^=head3 (.*)$/) {
        for my $constr (split ' ', $constrs) {
            $constructs{$constr}{pod}++;
            $constructs{$constr}{version}{$version}++;
            $pod_construct = $constr;
            ++$count_old if $version eq 'old';
        }

    } elsif (my ($aliases) = $line =~ /^Alias(?:es)?: (.*)$/) {
        $aliases{$_}{doc}++ for split ' ', $aliases;

    } elsif (($v) = $line =~ /Removed in ([0-9]\.[0-9]+)/) {
        ok($pod_construct, 'Removal in a correct section');
        $constructs{$pod_construct}{podremove}{$v}++;

    } elsif ($in_alias
             and my ($alias, $name) = $line =~ /'(\S+)' => ['"](\S+)['"]/
    ) {
        $aliases{$alias}{alias}{$name}++;

    } elsif ($line =~ / (?:'(5\.[0-9]{3}(?:[0-9]{3})?)'|(old)) => \[qw\[$/) {
        my $v = $1 || $2;
        until ((my $l = <$IN>) =~ /\]\],$/) {
            for my $constr ($l =~ /(\S+)/g) {
                $constructs{$constr}{code}++;
                $constructs{$constr}{version}{$v}++;
            }
        }
    } elsif (my ($removed_construct, $rm_version)
             = $line =~ / '([^']*)' +=> '(5\.[0-9]{3}(?:[0-9]{3})?)',$/
    ) {
        $constructs{$removed_construct}{removed}{$rm_version}++;

    } elsif ($line =~ /my %alias = \(/) {
        $in_alias = 1;

    } elsif ($in_alias && $line =~ /\);/) {
        undef $in_alias;
    }
}

open my $TEST, '<', "$FindBin::Bin/../t/02-constructs.t" or die $!;
undef $version;
while (<$TEST>) {
    if (/^ +(?:'([.0-9]+)'|(old)) => \[$/) {
        $version = $1 || $2;
    }
    if (my ($constr) = /^ +\[ ['"](.+)['"],/) {
        $constructs{$constr}{test}++;
        $constructs{$constr}{version}{$version}++;
    }
}

for my $constr (sort keys %constructs) {
    is($constructs{$constr}{$_}, 1, "$_ for $constr") for qw( pod code test );

    my @versions = keys %{ $constructs{$constr}{version} };
    is(@versions, 1, "versions $constr");
    is($constructs{$constr}{version}{ $versions[0] }, 3, "version $constr");

    if ('old' eq $versions[0]) {
        --$count_old;
        is(keys %{ $constructs{$constr}{removed} }, 1, "$constr removed once");
    }

    if (exists $constructs{$constr}{removed}
        || exists $constructs{$constr}{podremove}
    ) {
        my @podremoved = keys %{ $constructs{$constr}{podremove} };
        is(@podremoved, 1, "$constr removal documented");
        is($constructs{$constr}{removed}{ $podremoved[0] }, 1,
           "$constr removed in correct version");
    }
}

is($count_old, 0, 'All old constructs tested');

for my $alias (keys %aliases) {
    ok(exists $aliases{$alias}{doc}, "$alias is documented");
    is($aliases{$alias}{doc}, 1, "$alias is documented once");

    ok(exists $aliases{$alias}{alias}, "$alias is declared");
    is(keys %{ $aliases{$alias}{alias} }, 1, "$alias is unique");
    is((values %{ $aliases{$alias}{alias} })[0], 1,
       "$alias is declared once");
    ok(exists $constructs{ (keys %{ $aliases{$alias}{alias} })[0] },
       "$alias resolves");
}
