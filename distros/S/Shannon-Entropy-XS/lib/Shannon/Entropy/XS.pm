package Shannon::Entropy::XS;

use 5.006;
use strict;
use warnings;

use base qw/Import::Export/;
 
our $VERSION = '1.00';
 
our %EX = (
        entropy => [qw/all/]
);

require XSLoader;
XSLoader::load("Shannon::Entropy::XS", $VERSION);

1;

__END__

=head1 NAME
 
Shannon::Entropy::XS - Calculate the Shannon entropy H of a given input string faster.
 
=head1 VERSION
 
Version 1.00
 
=cut
 
=head1 SYNOPSIS
 
Calculate the Shannon entropy H of a given input string.
 
        use Shannon::Entropy::XS qw/entropy/;
 
        entropy('1223334444'); # 1.8464393446710154
        entropy('0123456789abcdef'); # 4
 
=head2 entropy

=head1 BENCHMARK

	use Benchmark qw(:all);
	use Shannon::Entropy;
	use Shannon::Entropy::XS;

	timethese(10000000, {
		'Entropy' => sub {
			my $string = 'thisusedtobeanemail@gmail.com';
			Shannon::Entropy::entropy($string);
		},
		'XS' => sub {
			my $string = 'thisusedtobeanemail@gmail.com';
			Shannon::Entropy::XS::entropy($string);
		}
	});

...

	Benchmark: timing 10000000 iterations of Mask, XS...
     		Entropy: 35 wallclock secs (35.81 usr +  0.01 sys = 35.82 CPU) @ 279173.65/s (n=10000000)
      		XS:  2 wallclock secs ( 1.60 usr +  0.08 sys =  1.68 CPU) @ 5952380.95/s (n=10000000)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-shannon-entropy-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Shannon-Entropy-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Shannon::Entropy::XS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Shannon-Entropy-XS>

=item * Search CPAN

L<https://metacpan.org/release/Shannon-Entropy-XS>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Shannon::Entropy::XS
