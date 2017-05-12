package String::CyclicRotation;

use strict;
use warnings;

use Exporter;
use Carp;

our @ISA = qw(Exporter);
our @EXPORT = qw();
our %EXPORT_TAGS = ( 'all' => [ qw(is_rotation) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'}} );

our $VERSION = '0.01';


=head1 NAME

String::CyclicRotation - Checks if a string is a cyclic rotation of another string.

=head1 SYNOPSIS

    use String::CyclicRotation qw(is_rotation);
    my $res = is_rotation("table", "ablet"); #true

=head1 DESCRIPTION

Checks if a string is a cyclic rotation of another string. This test is done in O(n).

=cut

=head1 METHODS

=head2 is_rotation

Checks if a string is a cyclic rotation of another string.

=cut

sub is_rotation {
    croak "Incorrect number of parameters." if @_ != 2;

    my ($str1, $str2) = @_;
    my @res;

    #trivial cases
    return 0 if length $str1 != length $str2;
    return 1 if ! length $str1;

    _compute_z($str1 . $str2, \@res);

    return _is_rotation($str1 . $str2, \@res);
}

sub _is_rotation {
    my ($str, $res) = @_;
    my $i;

    for my $k (length($str)/2..$#{$res}) {
	do {
	    $i = $k;
	    last;
	} if $res->[$k] == ($#{$res} - $k);
    }

    my $str1 = substr($str, (length($str) / 2), (length($str) / 2) - $res->[$i]); 
    my $str2 = substr($str, $res->[$i], (length($str) / 2) - $res->[$i]);
    return 1 if $str1 eq $str2 || $str1 eq reverse $str2;
    return 0;
}

sub _compare {
    my ($str, $left, $right) = @_;
    my $length = 0;

    while ($right < length $str && (substr $str, $left, 1) eq (substr $str, $right, 1)) {
	$length++;
	$left++;
	$right++;
    }
    $length;
}

sub _compute_z {
    my ($str, $res) = @_;
    my ($k, $r, $l) = (0, -1, 0);

    for my $k (1..length $str) {
	if ($k > $r) {
	    my $length = _compare ($str, 0, $k);

	    $res->[$k] = $length;
	    if ($res->[$k] > 0) {
		$r = $k + $res->[$k] - 1;   # update right side of v-box
		$l = $k;                    # update left side of v-box
	    }
	} 
	else {
	    my ($z2, $beta) = ($res->[$k - $l], $r - $k + 1);

	    if ($z2 < $beta) {
		$res->[$k] = $z2;
	    }

	    else {
		# $s->[$k..$r] is a prefix of $$s
		my $length = _compare ($str, $r + 1, $beta);
		my $pos = $length + $r + 1; # position of mismatch
		$res->[$k] = $pos - $k;
		$r = $pos - 1;
		$l = $k;
	    }
	}
    }
}

1;

__END__

=head1 More Information

You can check more information about the used algorithm in  the book "Algorithms on strings, trees and sequences".

=head1 Author

JoE<atilde>o Carreira, C<< <joao.carreira@ist.utl.pt> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 JoE<atilde>o Carreira, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

