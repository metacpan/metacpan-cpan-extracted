#!/usr/bin/perl

# Simulate EVOLIS Dualys printer

use warnings;
use strict;

use Data::Dump qw(dump);

die "usage: $0 evolis.commands\n" unless @ARGV;
my $name = shift @ARGV;

local $/ = "\r";

my $page = 1;

sub save_pbm;

open(my $e, '<', $name) || die "$name: $!";
sub bitmap {
	my ($data,$len) = @_;
warn "# tell ",tell($e),"\n";
	$data =~ s/D.+;\d+;//;
	$data =~ s/\r$//;
	my $l = length $data;
	warn "# bitmap $l $len\n";
	return $data if length $data == $len;
	$data .= "\r";
	my $rest;
	my $l = $len - length $data;
	read $e, $rest, $l;
	warn "# slurp $l got ",length($rest);
	return $data . $rest;
}

while(<$e>) {
	die "no escape at beginning",dump($_) unless s/^(\x00*)\x1B//;
	warn "WARNING: ", length($1), " extra nulls before ESC\n" if $1;
	my @a = split(/;/,$_);
	my $c = shift @a;
	chomp $c;
	if ( $c eq 'Pmi' ) {
		print "$_ mode insertion @a\n";
	} elsif ( $c eq 'Pc' ) {
		print "$_ contrast @a\n";
	} elsif ( $c eq 'Pl' ) {
		print "$_ luminosity @a\n";
	} elsif ( $c eq 'Ps' ) {
		print "$_ speed @a\n";
	} elsif ( $c eq 'Pr' ) {
		print "$_ ribbon $a[0]\n";
	} elsif ( $c eq 'Ss' ) {
		print "$_ sequence start\n";
	} elsif ( $c eq 'Se' ) {
		print "$_ sequence end\n";
	} elsif ( $c eq 'Sr' ) {
		print "$_ sequence recto - card side\n";
	} elsif ( $c eq 'Sv' ) {
		print "$_ sequence verso - back side\n";
	} elsif ( $c eq 'Db' ) {
		my ( $color, $two ) = @a;
		print "$c;$color;$two;... bitmap ",length($_), " bytes\n";
		$two eq '2' or die 'only 2 colors supported';
		my $path = "$name-Db-$color-$page.pbm"; $page++;
		save_pbm $path, 648, 1016, bitmap( $_, 648 * 1016 / 8 );
	} elsif ( $c eq 'Dbc' ) { # XXX not in cups
		my ( $color, $line, $len ) = @a;
		print "$c;$color;$line;$len;... download bitmap compressed\n";
		my $comp = bitmap( $_, $len );

		die "compression not supported" unless $color =~ m/[ko]/;

		my $data;
		my $i = 0;
		while ( $i < length $comp ) {
			my $first = substr($comp,$i++,1);
			if ( $first eq "\x00" ) {
				$data .= "\x00" x 81;
			} elsif ( $first eq "\xFF" ) {
				$data .= "\xFF" x 81;
			} else {
				my $len = ord $first;
				$data .= substr($comp,$i,$len);
				my $padding = 81 - $len;
#warn "# $len + $padding\n";
				$data .= "\x00" x $padding;
				$i += $len;
			}
		}

		my $path = "$name-Dbc-$color-$page.pbm"; $page++;
		save_pbm $path, 648, 1016, $data;

	} elsif ( $c eq 'Mr' ) {
		print "$_ motor ribbon @a\n";
	} else {
		print "FIXME: $_\n";
	}
}

sub save_pbm {
	my ( $path, $w, $h, $data ) = @_;
	open(my $pbm, '>', $path);
	print $pbm "P4\n$w $h\n", $data;
	close($pbm);
	print "saved $path $w * $h size ", -s $path, "\n";
}
