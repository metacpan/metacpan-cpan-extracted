package String::Mask;
use 5.006; use strict; use warnings;
use base 'Import::Export';

our $VERSION = '1.02';
our %EX = (
	mask => [qw/all/]
);

sub mask {
	my ($string, $pos, $length, $mask_char) = @_;
	$pos ||= 'start';
	$length = int(length($string) / 2) unless $length;
	if ($pos eq 'end') {
		$string =~ s/(.*)(.{$length})$/_mask($1, $mask_char).$2/es;
	} elsif ($pos eq 'middle') {
		my $half = int((length($string) - $length) / 2);
		$string =~ s/(.{$half})(.{$length})(.*)/_mask($1, $mask_char).$2._mask($3, $mask_char)/e;
	} elsif ($pos eq 'email') {
		$string =~ s/(.*)(.{$length}\@.*)$/$1._mask($2, $mask_char)/e;
	} else {
		$string =~ s/(\w{$length})(.*)/$1._mask($2, $mask_char)/e;
	}
	return $string;
}

sub _mask {
	my ($string, $char) = @_;
	$char ||= '*';
	$string =~ s/[^.@]/$char/g;
	return $string;
}

1;

__END__

=head1 NAME

String::Mask - mask sensitive data

=head1 VERSION

Version 1.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use String::Mask qw/mask/;

	mask('thisusedtobeanemail@gmail.com'); # thisusedtobean*****@*****.***
	mask('thisusedtobeanemail@gmail.com', 'start', 5); # 'thisu**************@*****.***'
	mask('thisusedtobeanemail@gmail.com', 'end'); # '***************mail@gmail.com'
	mask('thisusedtobeanemail@gmail.com', 'end', 5); # '*******************@****l.com'
	mask('thisusedtobeanemail@gmail.com', 'middle'); # '*******dtobeanemail@g****.***'
	mask('thisusedtobeanemail@gmail.com', 'middle', 5); # '************anema**@*****.***'
	mask('thisusedtobeanemail@gmail.com', 'email'); # 'thisu**************@*****.***'
	mask('thisusedtobeanemail@gmail.com', 'email', 2); # 'thisusedtobeanema**@*****.***'

	mask('9991234567'); # '99912*****'
	mask('9991234567', 'start', 3); # '999*******'
	mask('9991234567', 'end'); # '*****34567'
	mask('9991234567', 'end', 3); # '*******567'
	mask('9991234567', 'middle'); # '**91234***'
	mask('9991234567', 'middle', 4); # '***1234***'

	mask('9991234567', 'middle', 4, '_'); # '___1234___'

=head1 Description

Data masking or data obfuscation is the process of hiding original data with modified content (characters or other data). The main reason for applying masking to a string is to protect data that is classified as personally identifiable information, sensitive personal data, or commercially sensitive data. However, the data must remain usable for the purposes of undertaking valid test cycles. It must also look real and appear consistent. 

=head1 EXPORT

=head2 mask

This function accepts 4 arguments:

	mask($string, $position, $length, $char);

=over

=item string

The text that you like to mask.

=item position

The position you would like to be visible. Currently you have four options start, middle, end or email. The default is start.

=item length

The number of characters that should remain visible. The default is half the length of the passed string.

=item mask character

The mask character that will replace any masked text. The default is *.

=back

=cut

=head1 BENCHMARK

	use Benchmark qw(:all);
	use lib '.';
	use String::Mask;
	use String::Mask::XS;

	timethese(10000000, {
		'Mask' => sub {
			my $string = 'thisusedtobeanemail@gmail.com';
			String::Mask::mask($string);
		},
		'XS' => sub {
			my $string = 'thisusedtobeanemail@gmail.com';
			String::Mask::XS::mask($string);
		}
	});

...

	Benchmark: timing 10000000 iterations of Mask, XS...
		Mask: 17 wallclock secs (16.78 usr +  0.00 sys = 16.78 CPU) @ 595947.56/s (n=10000000)
		XS:  0 wallclock secs ( 1.43 usr +  0.00 sys =  1.43 CPU) @ 6993006.99/s (n=10000000)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-mask at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Mask>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Mask

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Mask>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/String-Mask>

=item * Search CPAN

L<https://metacpan.org/release/String-Mask>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020->2021 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of String::Mask
