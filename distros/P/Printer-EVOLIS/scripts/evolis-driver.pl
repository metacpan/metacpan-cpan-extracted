#!/usr/bin/perl

use warnings;
use strict;

my ( $front, $back ) = @ARGV;
die "usage: $0 front.pbm back.pbm\n" unless $front;

sub read_pbm;

sub cmd {
	my ( $cmd, $description ) = @_;
	print "\x1B",$cmd,"\r";
	$cmd =~ s/^(Db[\w\d;]+).+/$1_/s;
	warn sprintf "## %-10s %s\n", $cmd, $description;
}

cmd 'Pr;k' => 'ribbon: black';

# F = Feeder
# M = Manual
# B = Auto
cmd 'Pmi;F;s' => 'mode insertion: F';

cmd 'Pc;k;=;10' => 'contrast k = 10';

# FIXME ? only implemented in windows
#cmd 'Pdt;DU';
#cmd 'Mr;s';
#cmd 'Ppws;1281732635';

cmd 'Ss' => 'sequence start';

cmd 'Sr' => 'front side';

my $data = read_pbm $front;
cmd 'Db;k;2;' . $data => 'download front';

cmd 'Sv' => 'back side';

cmd 'Pc;k;=;10' => 'contrast k = 10';

$data = read_pbm $back;
cmd 'Db;k;2;' . $data => 'download back';

cmd 'Se' => 'sequence end';
print "\x00" x 64; # FIXME some padding?


sub read_pbm {
	my $path = shift;
	open(my $pbm, "pnmflip -rotate270 $path |");
	my $p4 = <$pbm>; chomp $p4;
	die "no P4 header in [$p4] from $path" unless $p4 eq 'P4';
	my $size = <$pbm>; chomp $size;
	local $/ = undef;
	my $data = <$pbm>;
	warn "# $path $size ", length($data), " bytes\n";
	if ( my $padding = ( 648 * 1016 / 8 - length($data) ) ) {
		warn "# adding $padding zero bytes padding\n";
		$data .= "\x00" x $padding;
	}
	return $data;
}
