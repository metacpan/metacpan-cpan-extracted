package MooseX::Types::Vehicle;
use 5.008;
use strict;
use warnings;

use MooseX::Types -declare => [qw/VIN17/];
use MooseX::Types::Moose qw/Str/;

our $VERSION = '0.03';

subtype VIN17 , as Str
	, where {
		my $vin = shift;

		return 0 unless defined $vin;

		## Straigt-1s is a test pattern
		## return 0 if $vin eq '11111111111111111';

		## Vin must be 17 characters and can not have OIQ
		if ( $vin =~ /[OIQ_\Wa-z]/  or length $vin != 17 ) {
			return 0;
		}

		my ( $wmi, $vds, $vis )             = unpack 'A3A6A8', $vin;
		my ( $attr, $check )                = unpack 'A5A1', $vds;
		my ( $model_yr, $plant_code, $seq ) = unpack 'A1A1A6', $vis;

		return 0
			if $model_yr eq 'U'
			|| $model_yr eq 'Z'
			|| $model_yr eq '0'
		;

		my $numify = $vin;
		## abcdefghjklmnprstuvwxyz ## 12345678123457823456789 ##
		$numify =~ tr/ABCDEFGHJKLMNPRSTUVWXYZ/12345678123457923456789/;

		my @values = split '', $numify;
		my @weights = qw/ 8 7 6 5 4 3 2 10 0 9 8 7 6 5 4 3 2 /;

		my $sum;
		foreach my $idx ( 0 .. $#values ) {
			my $product = $values[$idx] * $weights[$idx];
			$sum += $product;
		}

		my $new_check = $sum % 11;
		$new_check = 'X' if $new_check == 10;

		return 0
			if $new_check ne $check
		;

		return 1;

	}
	, message { "Invalid Vin: $_[0]" }
;
coerce VIN17
	, from Str , via {
		my $vin = shift;
		$vin =~ tr/qQoOiI/000011/;
  	$vin =~ s/\s+//g;
		return uc($vin);
	}
;

__END__

=head1 NAME

MooseX::Types::Vehicle - Moose Types for Vehicles (NHSTA 17 char VIN)

=head1 SYNOPSIS

This module provide the type B<VIN17>. This type can be used in Moose code.

    use MooseX::Types::Vehicle qw/VIN17/;

    has 'vin' => ( isa => VIN17, is => 'rw' );


Alternatively, you can have it automagically coerce to a VIN if possible:

    use MooseX::Types::Vehicle qw/VIN17/;
    
    has 'vin' => ( isa => VIN17, is => 'rw', coerce => 1 );

Lastly, all L<MooseX::Types> modules can export a function for is_TYPE and to_TYPE.

    use MooseX::Types::Vehicle qw/to_VIN17 is_VIN17/;
    
    ## Return a VIN number without spaces, with the 'O' (letter) as '0' (number zero)
    ## 'I' (letter) as '1' (number one) and without spaces.
    to_VIN17( '3D7KS28C26G 18OO4I  ' );

    ## Returns 1 or 0 if the VIN is valid.
    is_VIN17( '3D7KS28C26G180041' );

=head1 DESCRIPTION

This module currently only impliments the NHSTA 17 Digit VIN check and
applicable coercions. Applicable coercions include trimming whitespace, and
transliterating invalid characters to their valid coutnerparts "qQoO" (letter
'q' and 'o') to "0" (number zero), and "iI" (letter 'I') to '1' (number one).

This module assumes VINs must be uppercase to be valid. Lowercase characters
are uppercased in coercion.

A B<VIN check> is a checksum against the VIN.

For more information see the L</"SEE ALSO">. 

=head1 EXPORT

This module can export two functions both of which are explained in the
synopsis.

=over 4

=item to_VIN17

Takes a string, returns a coerced string.

=item is_VIN17

Determines whether or not a string is a valid 17 character VIN. Returns boolean 1 or 0.

=back

=head1 SEE ALSO

=over 4

=item L<MooseX::Types>

=item L<https://en.wikipedia.org/wiki/National_Highway_Traffic_Safety_Administration>

This is the website of the NHTSA. They created this VIN shit. I never read any
of their texts. Got any ideas on how to improve the VIN standard? I'm sure
they'll be glad to listen to your advice.

=item L<https://en.wikipedia.org/wiki/Vehicle_identification_number>

This is a great resource for more information about the VIN numbers.

=back

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-types-vehicle at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Types-Vehicle>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc MooseX::Types::Vehicle

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Types-Vehicle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Types-Vehicle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Types-Vehicle>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Types-Vehicle/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Evan Carroll L<http://www.evancarroll.com>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

