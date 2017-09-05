use strict;
use File::Spec;
use File::Basename qw(dirname);

my @tests = ();

for my $table (qw(pager m2m)) {
    my $file = File::Spec->rel2abs("$table.t", dirname(__FILE__));
    open my $fh, '<', $file or die $!;
    while (my $line = <$fh>) {
        next if $line !~ /^\s*ok\(/;
        push @tests, $line;
    }
    close $fh;
}

my $test_count = scalar(@tests) + 1;

eval qq{ use Test::More tests => $test_count; };
warn $@ if $@;

use_ok('Number::Phone::JP', 'pager', 'm2m');

my $tel = Number::Phone::JP->new;

for my $test (@tests) {
    eval $test;
    warn $@ if $@;
}
