package Number::Iterator::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.01';

require XSLoader;
XSLoader::load('Number::Iterator::XS', $VERSION);

1;

__END__

=head1 NAME

Number::Iterator::XS - iterate numbers faster

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS
 
        use Number::Iterator::XS;
 
        my $iter = Number::Iterator::XS->new(interval => 50);
 
        $iter++;
 
        $iter--;
 
        print "$iter";

=head1 METHODS

=head2 new

Instantiate a new Number::Iterator object. 

        my $iter = Number::Iterator::XS->new(
                interval => 50,
                iterate => sub {
                        my ($self) = @_;
                        ($self->{value} ||= 1) *= $self->{interval};
                },
                deiterate => sub {
                        my ($self) = @_;
                        $self->{value} /= $self->{interval};
                }
        );

=head2 iterate

	$iter++;
	$iter->iterate;

=head2 deiterate

	$iter--;
	$iter->deiterate;

=head2 value

	"$iter";
	$iter->value;

=head2 interval

	$iter->interval;
	$iter->interval(50);

=head1 BENCHMARK

	use Benchmark qw(:all);
	use Number::Iterator;
	use Number::Iterator::XS;

	timethese(10000000, {
		'Iterator' => sub {
			my $n = Number::Iterator->new(interval => 20);
			$n++;
			$n--;
			$n->value;
		},
		'XS' => sub {
			my $n = Number::Iterator::XS->new(interval => 20);
			$n++;
			$n--;
			$n->value;
		}
	});

...

	Benchmark: timing 10000000 iterations of Iterator, XS...
  		Iterator:  8 wallclock secs ( 7.56 usr +  0.00 sys =  7.56 CPU) @ 1322751.32/s (n=10000000)
        	XS:  4 wallclock secs ( 5.14 usr +  0.06 sys =  5.20 CPU) @ 1923076.92/s (n=10000000)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-number-iterator-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-Iterator-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Iterator::XS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Iterator-XS>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Number-Iterator-XS>

=item * Search CPAN

L<https://metacpan.org/release/Number-Iterator-XS>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Number::Iterator::XS
