package MooX::Keyword::Readonly;

use 5.006; use strict; use warnings; our $VERSION = '1.00';
use Moo;
use Const::XS qw/make_readonly/;

use MooX::Keyword {
        readonly => {
                builder => sub {
                        my ($moo, $name, @args) = @_;
			$moo->has(
				$name, 
				is => 'ro', 
				coerce => sub { make_readonly($_[0]); $_[0] },
				@args
			);
                }
        }
};

1;

__END__

=head1 NAME

MooX::Keyword::Readonly - Truly readonly attributes

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

	package Abc;

	use Moo;
	use MooX::Keyword extends => '+Readonly';

	readonly "array";

	readonly hash => ( is => 'rw' );

...

	my $abc = Abc->new({ array => [1, 2, 3], hash => { a => 1, b => 2, c => 3 }});

	push @{ $abc->array }, 4; # dies as array is a readonly array
	$abc->hash->{d}; # dies as hash is a readonly hash with restricted keys


If you just want radonly attributes you are probably looking at the wrong module, L<MooX::Readonly::Attribute> works more transparently unless you are already using L<MooX::Keyword>.

=head1 KEYWORDS

=head2 readonly

Creates a truly read only attribute.

	readonly "array";

The behaviour is identical to the following Moo code.

	use Const::XS qw/make_readonly/;

	has array => (
		is => 'ro',
		coerce => sub { make_readonly($_[0]); $_[0] }
	);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-keyword-readonly at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Keyword-Readonly>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Keyword::Readonly

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Keyword-Readonly>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/MooX-Keyword-Readonly>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Keyword-Readonly>

=back


=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

L<Const::XS>

L<MooX::Readonly::Attribute>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of MooX::Keyword::Readonly
