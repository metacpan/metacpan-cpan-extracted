use strict;
use warnings;

use File::Spec;
use Test::More;

select STDERR;
$|=1;
select STDOUT;

$ENV{PATH} = '/usr/bin:/bin' if ${^TAINT};

sub is_windows { $^O =~ /MSWin32/i }

sub filediff {
    my ($a, $b) = @_;
    open my $fa, "<", $a
	or die "unable to open file $a";

    open my $fb, "<", $b
	or die "unable to open file $b";

    binmode $fa;
    binmode $fb;

    while (1) {
	my $la = read($fa, my $da, 2048);
	my $lb = read($fb, my $db, 2048);
	
	return 1 unless (defined $la and defined $lb);
	return 1 if $la != $lb;
	return 0 if $la == 0;
	return 1 if $la ne $lb;
    }
}

sub mktestfile {
    my ($fn, $count, $data) = @_;

    open DL, '>', $fn
	or die "unable to create test data file $fn";

    print DL $data for (1..$count);
    close DL;
}

1;
