#!/usr/bin/perl -w
use strict;
use Test::More tests => 3;
use PerlIO::via::dynamic;

# $Filename$

our $unused_destroyed;
my $fname = $0;

sub run_test {
    my $o = bless {}, 'Unused';

    my $p = PerlIO::via::dynamic->new
	(untranslate =>
	 sub { $o->{fnord}++;
	       $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/"\$Filename: $fname\$"/e},
	 translate =>
	 sub { $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/\$Filename\$/});

    open my $fh, '<', $fname;
    $p->via ($fh);

    local $/;
    my $text = <$fh>;
    ok (1) if $text =~ m/^# \$Filename: $0\$/m;
}

run_test ();

ok ($unused_destroyed);

run_test ();

package Unused;

sub DESTROY {
    $main::unused_destroyed = 1;
}
