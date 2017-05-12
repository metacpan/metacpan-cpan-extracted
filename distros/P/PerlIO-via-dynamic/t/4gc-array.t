#!/usr/bin/perl -w
use strict;
use PerlIO::via::dynamic;
use File::Temp;
use Test::More tests => 1;

our $unused_destroyed;

sub run_test {
    my $o = bless {}, 'Unused';

    my $p = PerlIO::via::dynamic->new
	(untranslate =>
	 sub { $o->{fnord}++; });

    my $fh = File::Temp->new;
    $p->via ($fh);
    print $fh "Foobar\n";

}

run_test ();
ok ($unused_destroyed);

package Unused;

sub DESTROY {
    $main::unused_destroyed = 1;
}
