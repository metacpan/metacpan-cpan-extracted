package Number::Equation;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

our $offset = 0.5555555;
our $precision = 0;

# TODO
use overload
	'+' => \&add,
	'-' => \&subt,
	'/' => \&div,
	'*' => \&mult,
	'""' => sub {
		my $num = $_[0][0];
		return $num unless $precision;
		return $num >= 0 
			? $precision * int(($num + ($offset * $precision)) / $precision)
			: $precision * POSIX::ceil(($num - $offset * $precision) / $precision);
	},
	fallback => 1;

sub new {
	my $self = bless [ $_[1], [$_[1]] ],  $_[0];
	$precision = $_[2] if $_[2];
	$offset = $_[3] if $_[3];
	$self;
}

sub add {
	push @{ $_[0][-1] }, '+', $_[1];
	$_[0][0] += $_[1];
	$_[0];
}

sub mult {
	push @{ $_[0][-1] }, '*', $_[1];
	$_[0][0] *= $_[1];
	$_[0];
}

sub subt {
	if ($_[2]) {
		splice @{ $_[0] }, 1, 0, [$_[1], '-'];
		$_[0][0] = $_[1] - $_[0][0];
	} else {
		push @{ $_[0][-1] }, '-', $_[1];
		$_[0][0] = $_[0][0] - $_[1];
	}
	$_[0];
}


sub div {
	if ($_[2]) {
		splice @{ $_[0] }, 1, 0, [$_[1], '/'];
		$_[0][0] = $_[1] / $_[0][0];
	} else {
		push @{ $_[0][-1] }, '/', $_[1];
		$_[0][0] = $_[0][0] / $_[1];
	}
	$_[0];
}

sub equation {
	my $query = '';
	my $closing = 0;
	for (my $i = 1; $i <= scalar @{ $_[0] } - 1; $i++) {
		my $equation = $_[0]->[$i];
		$query .= '(' x ((scalar @{ $equation }) / 2) . $equation->[0];
		for (my $x = 1; $x <= scalar @{ $equation } - 1; $x++) {
			my $operator = $equation->[$x++];
			my $val = $equation->[$x];
			$query .=  ' ' . $operator . ' ' . (defined $val ? ($val . ')') : do { $closing++; "" });		
		}
	}
	$query .= ')' x $closing;
	$query .= ($precision ? ' ≈ ' : ' = ') . $_[0];
	return $query;
}

1; # End of Number::Equation

__END__;

=head1 NAME

Number::Equation - Track how a number is calculated progamically.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Number::Equation;

	my $foo = Number::Equation->new(42);

	my $n = Number::Equation->new(42);
	$n = $n - 2;
	$n /= 10;
	$n *= 3;
	$n += 1;
	my $m = 1 / $n;
	print $m->equation; # (1 / ((((42 - 2) / 10) * 3) + 1)) = 0.0769230769230769


	my $n = Number::Equation->new(42, .01);
	$n = $n - 2;
	$n /= 10;
	$n *= 3;
	$n += 1;
	my $m = 1 / $n;
	print $m->equation; # (1 / ((((42 - 2) / 10) * 3) + 1)) ≈ 0.08


BETA: currently only add, subtract, multiply and divide operations are supported.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-number-equation at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-Equation>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Equation

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Equation>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Number-Equation>

=item * Search CPAN

L<https://metacpan.org/release/Number-Equation>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

