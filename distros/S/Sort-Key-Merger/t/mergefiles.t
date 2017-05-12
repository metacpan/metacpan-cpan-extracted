#!/usr/bin/perl

use strict;
use warnings;

use constant sizes => 1, 4, 32, 128;

use Test::More tests => 30;

use Sort::Key::Merger qw(nfilekeymerger);
use Sort::Key qw(nkeysort);

# use Scalar::Quote ':short';

my $merger1 = nfilekeymerger { (split)[0] } qw(t/data1 t/data2 t/data3);
my $merger2 = nfilekeymerger{ (split)[0] } qw(t/data4);

my (@all1, @all2, $lkey);
while (defined (my $current = $merger1->())) {
    push @all1, $current;
    my $key = (split(" ", $current))[0];

    ok($key >= $lkey, "sorted") if (defined $lkey);

    $lkey=$key;
}

@all2 = nkeysort { (split)[0] } $merger2->();

is_deeply(\@all1, \@all2, "all");


__END__

