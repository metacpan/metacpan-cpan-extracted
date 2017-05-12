# For license, docs, see the POD documentation at the end of this file

package Games::Roguelike::Utils;

use strict;

# this breaks under perl < 5.8
# use Exporter qw(import);

# Direction helpers

our $VERSION = '0.4.' . [qw$Revision: 236 $]->[1];

our $DIRN = 8;                                                                   # number of ways to move (don't count ".")
our @DIRS = ('n','s','e','w','ne','se','nw','sw', '.');                          # names of dirs (zero indexed array)
our @DD = ([0,-1],[0,1],[1,0],[-1,0],[1,-1],[1,1],[-1,-1],[-1,1],[0,0]);         # map offsets caused by moving in these dirs
our %DD = ('n'=>[0,-1],'s'=>[0,1],'e'=>[1,0],'w'=>[-1,0],'ne'=>[1,-1],'se'=>[1,1],'nw'=>[-1,-1],'sw'=>[-1,1], '.'=>[0,0]);       # name/to/offset map
our %DI = ('n'=>0,'s'=>1,'e'=>2,'w'=>3,'ne'=>4,'se'=>5,'nw'=>6,'sw'=>7,'.'=>8);          # name/to/index map
our @CWDIRS = ('n','ne','e','se','s','sw','w','nw');				 #clockwise directions

BEGIN {
	require Exporter;
	*{import} = \&Exporter::import;
	our @EXPORT_OK = qw(min max ardel rarr distance randsort intify randi $DIRN @DD %DD %DI @DIRS @CWDIRS round rpad);
	our %EXPORT_TAGS = (all=>\@EXPORT_OK);
}

use Games::Roguelike::Area;

# try to load C version for speed
eval 'use Games::Roguelike::Utils::Pov_C';

if (!defined(&distance)) {
	eval('
        sub distance {
                return sqrt(($_[0]-$_[2])*($_[0]-$_[2])+($_[1]-$_[3])*($_[1]-$_[3]));
        }
	');
}

sub intify {
        for (@_) {
                $_=int($_);
        }
}

sub randsort {
        my @a = @_;
        my @d;
        while (@a) {
                push @d, splice(@a, rand()*scalar(@a), 1);
        }
        return @d;
}

sub round {
	return int($_[0]+0.5);
}

sub randi {
	my ($a, $b) = @_;
	if ($b) {
		# rand num between a and b, inclusive
		return $a+int(rand()*($b-$a+1));
	} else {
		# rand num between 0 and a-1
		return int(rand()*$a);
	}
}

sub ardel {
	my ($ar, $t) = @_;
	for (my $i=0;$i<=$#{$ar};++$i) {
		splice(@{$ar},$i,1) if $ar->[$i] eq $t;
	}
}

sub max {
	my ($a, $b) = @_;
	return $a >= $b ? $a : $b;
}

sub min {
	my ($a, $b) = @_;
	return $a <= $b ? $a : $b;
}

sub rarr {
	my ($arr) = @_;
	return $arr->[$#{$arr}*rand()];
}

sub rpad {
	my ($str, $len, $char) = @_;
	$char = ' ' if $char eq '';
	$str .= $char x ($len - length($str));
	return $str;
}

=head1 NAME

Games::Roguelike::Utils - Convenience functions and exports for roguelikes

=head1 SYNOPSIS

 use Games::Roguelike::Utils qw(:all);

=head1 DESCRIPTION

Non-object oriented functions that are generally helpful for roguelike programming, and are used by other roguelike modules.

=head2 FUNCTIONS

=over

=item min (a, b)

=item max (a, b)

Returns min/max of 2 passed values

=item distance(x1, y1, x2, y2);

Returns the distance between 2 points, uses Inline C version if available

=item randsort(array);

Randomly sorts its arguments and returns the random array.

=item randi (a[, b])

With 2 arguments, returns a random integer from a to b, inclusive.

With 1 argument, returns a random integer form 0 to a-1.

=item rpad (string, length [, char])

Pads string out to length using spaces or "char" if one is specified.

=back

=head2 VARIABLES

=over

=item %DD - direction delta hash

Hash mapping direction names to array ref offsets.  

	'n' =>[0,-1], # north decreases y, and leaves x alone
	...
	'se'=>[1, 1], # southeast increases y, and increases x

=item @DD - direction delta list

Array with delta entries as above, sorted as: 'n','s','e','w','ne','se','nw','sw', '.'

=item @DIRS - direction list

The array ('n','s','e','w','ne','se','nw','sw','.')

=item @CWDIRS - clockwise direction list

The array ('n','ne','e','se','s','sw','w','nw'), used in door-ok and other quadrant-scanning algorithms.

=item @DI - direction index

Maps 0=>'n', 1=>'s' ... etc. as in @DIRS

=item @DIRN - number of directions (8)

=back
 
=head1 SEE ALSO

L<Games::Roguelike::World>

=head1 AUTHOR

Erik Aronesty C<earonesty@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html> or the included LICENSE file.

=cut

1;
