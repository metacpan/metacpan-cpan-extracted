package Rope::Chain;

my (%PRO);

BEGIN {
	%PRO = (
		keyword => sub {
			my ($caller, $method, $cb) = @_;
			no strict 'refs';
			*{"${caller}::${method}"} = $cb;
		},
	);
}

sub import {
	my ($caller) = (scalar caller);
	$PRO{keyword}($caller, 'chain', sub {
		my ($name, @factory) = @_;

		my ($meta, $chain, $exists) = (Rope->get_meta($caller), [], 0);
		if ($meta->{properties}->{$name}) {
			$chain = $meta->{properties}->{$name}->{after} || [];
			$exists = 1;
		}
		my ($prop, $cb) = (shift(@factory), shift(@factory)); 
		if ($meta->{properties}->{$prop}) {
			die 'Cannot extend Object($caller) with a chain property ($prop) as a property with that name is already defined';
		}
		$caller->property($prop, 
			value => sub { $cb->(@_); }
		);
		if (!$exists) {
			$caller->property($name,
				value => $cb,
			);
		} else {
			$caller->after($name, $cb);
		} 
	});
}

1;

__END__

=head1 NAME

Rope::Type - Rope chained properties

=head1 VERSION

Version 0.27

=cut

=head1 SYNOPSIS

	package Church;

	use Rope;
	use Rope::Autoload;
	use Rope::Chain;

	prototyped (
		been_cannot_find => [],
		found => []
	);

	chain add => 'ephesus' => sub {
  	      push @{ $_[0]->been_cannot_find }, 'Ephesus';
	};
 
	chain add => 'smyrna' => sub {
		push @{ $_[0]->been_cannot_find }, 'Smyrna';
	};
	 
	chain add => 'pergamon' => sub {
		push @{ $_[0]->been_cannot_find }, 'Pergamon';
	};

	chain add => 'thyatira' => sub {
		push @{ $_[0]->been_cannot_find }, 'Thyatira';
		return $_[0]->been_cannot_find;
	};

	...

	1;

...

	my $k = Church->new();

	say $k->add(); # [ 'Ephesus', 'Smyrna', 'Pergamon', 'Thyatira' ]


=head1 Exports

=cut

=head2 chain

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
