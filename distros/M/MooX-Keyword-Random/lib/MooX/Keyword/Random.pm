package MooX::Keyword::Random;
use 5.006; use strict; use warnings;
our $VERSION = '0.02';
use Moo;
use MooX::Keyword {
	random => {
		builder => sub {
			my ($moo, $name, $random) = @_;
			$moo->has($name, is => 'rw');
			if (!ref $random && $random =~ m/\d+/) {
				$random = [ 0 .. $random + 1 ];
			}
			$moo->around($name, sub {
				my ($orig, $self, @args) = @_;
				return $random->[int(rand(scalar @{$random}))];
			});
		}
	}
};

1;

=head1 NAME

MooX::Keyword::Random - return a random result!

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package Holiday::Hospital;

	use Moo;
	use MooX::Keyword extends => '+Random';

	random bed => 21;

	random doctorse => ['a' .. 'z'];

	random food => [ 'pizza', 'burger', 'kebab', 'fruit', 'toast' ];

	1;

	... 

	my $h = Holiday::Hospital->new();

	my $room = $h->bed(); # a random number between 0 and 21.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-keyword-random at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Keyword-Random>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MooX::Keyword::Random

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Keyword-Random>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/MooX-Keyword-Random>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Keyword-Random>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of MooX::Keyword::Random
