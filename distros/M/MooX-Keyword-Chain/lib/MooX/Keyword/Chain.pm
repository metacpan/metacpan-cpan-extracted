package MooX::Keyword::Chain;
use 5.006; use strict; use warnings;
our $VERSION = '1.01';
use Moo; our %CHAINS;
use MooX::Keyword {
	chain => {
		builder => sub {
			my ($moo, $name, $chain, $cb) = @_;
			$moo->has($name, is => 'rw') if ! $CHAINS{$name}++;
			$moo->sub($chain, $cb);
			$moo->around($name, sub {
				my ($orig, $self, @args) = @_;
				@args = $self->$orig(@args);
				@args = eval {
					$cb->($self, @args);
				};
				die "${chain}: $@" if ($@);
				return wantarray ? @args : shift @args;
			});
		}
	}
};

1;

__END__

=head1 NAME

MooX::Keyword::Chain - Subroutine chains

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package Chains;

	use Moo;
	use MooX::Keyword extends => '+Chain';

	has items => (
		is => 'ro',
		default => sub { [ ] }
	);

	chain add => 'one' => sub {
		push @{ $_[0]->items }, 211;
	};

	chain add => 'two' => sub {
		push @{ $_[0]->items }, 19;
	};

	chain add => 'three' => sub {
		push @{ $_[0]->items }, 696;
	};

	1;

	...

	my $chains = Chains->new();

	$chains->add(); # [ 211, 19, 696 ];

=head1 DESCRIPTION

create a sub routine which chains from multiple other sub routines.

=head1 KEYWORDS

=head2 chain

Configure a chained sub routine.

	chain two => 'demo' => sub {
		...
	}

	chain two => 'show' => sub {
		...
	}

...

	$chains->two(); # will call demo and then show

You can also still call each sub routine independently.

	$chains->demo();
	$chains->show();

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-keyword-chain at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Keyword-Chain>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Keyword::Chain

You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Keyword-Chain>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Keyword-Chain>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of MooX::Keyword::Chain
