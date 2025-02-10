package Rope::Factory;

use Factory::Sub;
use Coerce::Types::Standard;
use Rope::Pro;

my (%PRO);

BEGIN {
	%PRO = Rope::Pro->new;
}

sub import {
	my ($caller, $pkg, @types) = (scalar caller, @_);
	if (@types) {	
		Coerce::Types::Standard->import::into($caller, @types)
	}
	$PRO{keyword}($caller, 'factory', sub {
		my ($name, @factory) = @_;
		my ($meta, $ind, $fact, $exists, $extends) = (
			Rope->get_meta($caller),
			(! ref $factory[0] ? shift @factory : 0)
		);
		if ($meta->{properties}->{$name}) {
			if ($meta->{properties}->{$name}->{fact}->[$ind]) {
				$fact = $meta->{properties}->{$name}->{fact}->[$ind];
				$exists = 1;
			} else {
				$fact = Factory::Sub->new();
				$extends = 1;
			}
		} else {
			$fact = Factory::Sub->new();
		}
		while (@factory) {
			my ($check, $cb) = (shift(@factory), shift(@factory));
			if (ref $check eq 'CODE') {
				unshift @factory, $cb if $cb;
				$fact->add($check);
			} else {
				$fact->add(sub { $_[0];  }, @{$check}, $cb);
			}
		}
		if ($extends) {
			Rope->clear_property($caller, $name);
			my $prop = $meta->{properties}->{$name};
			push @{$prop->{fact}}, $fact;
			push @{$prop->{after}}, sub { $fact->(@_) };
			$caller->property($name, %{$prop});	
		} elsif (!$exists) {
			$caller->property($name,
				value => sub { $fact->(@_) },
				initable => 0,
				enumerable => 0,
				writeable => 0,
				fact => [$fact]
			);
		}
	});
}

1;

__END__

=head1 NAME

Rope::Factory - Rope factory properties

=head1 VERSION

Version 0.42

=cut

=head1 SYNOPSIS
	
	package Knot;

	use Rope;
	use Rope::Autoload;
	use Rope::Factory qw/Str HashRef ArrayRef/;

	factory loop => (
		[Str] => sub {
			return 'string';
		},
		[Str, Str] => sub {
			return 'string string';
		},		
		[Str, HashRef, ArrayRef] => sub {
			return 'string hashref arrayref'
		}
	);

	factory loop => (
		[Str, Str, Str] => sub {
			return 'string string string';
		}
	);

	factory loop => 1 => (
		[Str] => sub {
			return 'chained factory ' . $_[1];
		}
	);

	1;

...

	my $k = Knot->new();

	say $k->loop('abc'); # string;


=head1 Exports

=cut

=head2 factory

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
