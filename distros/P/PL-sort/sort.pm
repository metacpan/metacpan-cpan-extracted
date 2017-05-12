package PL::sort;

use warnings;
use strict;
use vars qw( $VERSION @ISA @EXPORT_OK );
#----------------------------------------------------------------------
require Exporter;
#======================================================================
$VERSION = '0.2';
@ISA = qw(Exporter);
@EXPORT_OK = qw( plsort plcmp );
#======================================================================
my $c = 0;
my %pos = map { $_ => $c++ } 'A', 'a', "\x{104}", , "\x{105}", 'B', 'b', 'C', 'c', "\x{106}", "\x{107}", 'D', 'd', 'E', 'e', "\x{118}", "\x{119}", 'F', 'f', 'G', 'g', 'H', 'h', 'I', 'i', 'J', 'j', 'K', 'k', 'L', 'l', "\x{141}", "\x{142}", 'M', 'm', 'N', 'n', "\x{143}", "\x{144}", 'O', 'o', "\x{d3}", "\x{f3}", 'P', 'p', 'R', 'r', 'S', 's', "\x{15a}", "\x{15b}", 'T', 't', 'U', 'u', 'W', 'w', 'X', 'x', 'Y', 'y', 'Z', 'z', "\x{17b}", "\x{17c}", "\x{179}", "\x{17a}";
#======================================================================
sub plcmp {
	my ($sa, $sb) = @_;
	
	my @a = split( //o, $sa );
	my @b = split( //o, $sb );
		
		
	my $l = @a > @b ? @b : @a;
		
	for my $i ( 0 .. $#a ){
		my $r = exists $pos{ $a[ $i ] } && exists $pos{ $b[ $i ] } ? $pos{ $a[ $i ] } <=> $pos{ $b[ $i ] } : $a[ $i ] cmp $b[ $i ];
		return $r if $r;
	}
	
	return $sa cmp $sb;	
}
#======================================================================
sub plsort {
	return sort { plcmp($a, $b) } @_;
}
#======================================================================
1;

=head1 NAME

PL::Sort


=head1 SYNOPSIS

	use PL::Sort qw( plcmp plsort );

	my @sorted_1 = sort { plcmp( $a, $b ) } "N\x{f3}w", "Now", "N\x{f3}";
	my @sorted_2 = plsort( "N\x{f3}w", "Now", "N\x{f3}" );
	
=head1 DESCRIPTION

Implements polish sorting conventions, indepentent on current locales in effect, which are often bad. 

=head1 SUBROUTINES/METHODS

=over 4

=item B<plcmp( STRING1, STRING2 )>

Subroutine, that makes comparison of two strings.

=item B<plsort( LIST )>

Subroutine, that sort a list of a strings.

=back

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Strzelecki Łukasz <l.strzelecki@ita.wat.edu.pl>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

