package Rope::Type;

use strict; use warnings;
use Types::Standard;
use Rope::Pro;
my (%PRO);

BEGIN {
	%PRO = Rope::Pro->new(
		type_map => {
			int => 'Int',
			bool => 'Bool',
			str => 'Str',
			hash => 'HashRef',
			array => 'ArrayRef',
			scalar => 'ScalarRef',
			code => 'CodeRef',
			file => 'FileHandle',
			obj => 'Object'
		}
	);
}

sub import {
	my ($caller, $pkg, @types) = (scalar caller, @_);

	@types = keys %{$PRO{type_map}} unless scalar @types;

	for (@types) {
		no strict 'refs'; 
		my $type = &{"Types::Standard::$PRO{type_map}{$_}"};
		$PRO{keyword}($caller, $_, sub {
			my (@params) = @_;
			my $count = scalar @params;
			return $type unless $count;
			if ($count <= 2) {
				$caller->property($params[0],
					type => $type,
					initable => 1,
					enumerable => 1,
					writeable => 1,
					(defined $params[1] ? (value => $params[1]) : ()),
				);
			} else {
				my $name = shift @params;
				$caller->property($name, @params, type => $type);
			}
			return;
		});
	}
}

1;

__END__

=head1 NAME

Rope::Type - Rope with Type::Tiny

=head1 VERSION

Version 0.43

=cut

=head1 SYNOPSIS

	package Knot;

	use Rope;
	use Rope::Type qw/int/;
	
	int loops => 1;
	int hitches => 10;
	int bends => (
		value => 10,
		configurable => 1,
		enumerable => 1,
	);

	function add_loops => sub {
		my ($self, $loop) = @_;
		$self->{loops} += int->($loop);
	};

	1;

...

	my $k = Knot->new();

	say $k->{loops}; # 1;

	$k->{loops} = 'kaput'; # errors as Str is not an Int


=head1 Exports

=cut

=head2 int

Int

=cut

=head2 bool

Bool

=cut

=head2 str

Str

=cut

=head2 hash

HashRef

=cut

=head2 array

ArrayRef

=cut

=head2 scalar

ScalarRef

=cut

=head2 code

CodeRef

=cut

=head2 file

FileHandle

=cut

=head2 obj

Object

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rope at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rope>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rope

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rope>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rope>

=item * Search CPAN

L<https://metacpan.org/release/Rope>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
