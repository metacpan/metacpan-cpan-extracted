package Phone::Valid::International::Loose;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use base 'Import::Export';

our %EX = (
	valid_phone => [qw/all/]
);

our $REGEX;
BEGIN {
	$REGEX = qr/\+(9[976]\d|8[987530]\d|6[987]\d|5[90]\d|42\d|3[875]\d|2[98654321]\d|9[8543210]|8[6421]|6[6543210]|5[87654321]|4[987654310]|3[9643210]|2[70]|7|1)\d{1,14}$/;
}

sub new {
	my ($self, $args) = @_;
	$args ||= {};
	bless $args, $self;
}

sub valid { goto &valid_phone; }

sub valid_phone {
	my $num = $_[1] ? $_[1] : $_[0];
	$num =~ $REGEX;
}

1;

__END__

=head1 NAME

Phone::Valid::International::Loose - loosely validate international phone numbers via a regex

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use Phone::Valid::International::Loose;

	my $phone = Phone::Valid::International::Loose->new();

	$phone->valid("+441111111111");

	...

	use Phone::Valid::International::Loose qw/valid_phone/;
	valid_phone("+441111111111");


=head1 EXPORT

=head2 valid_phone

Loosely validate an international phone number, with the area code prefixed.

	Phone::Valid::International::Loose::valid_phone("+441111111111");

=head1 SUBROUTINES/METHODS

=head2 valid

Loosely validate an international phone number, with the area code prefixed. (Object Orientation interfaace).

	my $phone = Phone::Valid::International::Loose->new();
	
	$phone->valid("+441111111111");

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-phone-valid-international-loose at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Phone-Valid-International-Loose>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Phone::Valid::International::Loose


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Phone-Valid-International-Loose>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Phone-Valid-International-Loose>

=item * Search CPAN

L<https://metacpan.org/release/Phone-Valid-International-Loose>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Phone::Valid::International::Loose
