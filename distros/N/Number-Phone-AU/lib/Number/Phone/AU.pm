package Number::Phone::AU;

use Carp;
use Mouse;
use Mouse::Util::TypeConstraints;

subtype 'Number::Phone::AU::StateCode'
    => as 'Str'
    => where { length $_ == 2 };

subtype 'Number::Phone::AU::NumericString'
    => as 'Str'
    => where { !/\D/  };

has 'orig_number'     => (is => 'rw', isa => 'Str', required => 1);
has 'stripped_number' => (is => 'rw', isa => 'Number::Phone::AU::NumericString');
has 'country_code'    => (is => 'rw', isa => 'Int');
has 'local_number'    => (is => 'rw', isa => 'Number::Phone::AU::NumericString');

has 'state_code' =>
    is  => 'rw',
    isa => 'Number::Phone::AU::StateCode',
    default => '00',
;

=head1 NAME

Number::Phone::AU - Validation for Australian Phone numbers

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Number::Phone::AU;

    my $valid_number = Number::Phone::AU->new( $number );

=head1 DESCRIPTION

This is a module for validating Australian phone numbers.

=head1 METHODS

=head2 new

    my $number = Number::Phone::AU->new( $input_number );

Returns an object representing the $number.

=cut

sub BUILDARGS {
    my ( $class, $number ) = @_;

    croak "The number is undefined"   if !defined $number;
    croak "The number is a reference" if ref $number;

    return { orig_number => $number };
}

sub BUILD {
    my $self = shift;

    my $number = $self->orig_number;

    $number =~ s/\D//g;
    $self->stripped_number( $number );

    # strip off country codes
    $number =~ s/^(61|672)//;
    $self->country_code( $1 || '61' );

    if ( length $number == 9 ) {
        $self->state_code( 0 . substr( $number, 0, 1, '' ) );
    }
    elsif ( length $number == 10 ) {
        $self->state_code( substr( $number, 0, 2, '') );
    }
    elsif( $number =~ s/^(13|18)// ) {
        $self->state_code( $1 );
    }

    $self->local_number($number);

    return;
}


=head2 is_valid_contact

    my $is_valid = $number->is_valid_contact;

Returns true if the $number is a valid Australian contact number for a
business or person.  Toll free numbers like 1300 and 1800 are valid as they
may be a business contact.

Emergency numbers and special codes are invalid.

=cut

sub is_valid_contact {
    my $self = shift;

    return $self->_is_valid_672 if $self->country_code == 672;
    return $self->_is_valid_13x if $self->state_code == 13;
    return $self->_is_valid_18x if $self->state_code == 18;

    return unless length $self->local_number == 8;

    # At this point we have a 9 or 10 digit clean number
    return $self->_has_valid_state_code;
}


# This assumes a sanitized number
sub _is_valid_672 {
    my $self = shift;
    return length $self->local_number == 6;
}


# This assumes a sanitized number
sub _is_valid_13x {
    my $self = shift;

    $DB::single = 1;
    my $number = $self->local_number;
    if ( $number =~ m/^00/ ) {
        return length $number == 8;
    }
    else {
        return length $number == 4;
    }
}


# This assumes a sanitized number
sub _is_valid_18x {
    my $self = shift;

    my $number = $self->local_number;
    if( $number =~ m/^00/ ) {
        return length $number == 8;
    }
    elsif( $number =~ m/^0/ ) {
        return length $number == 5;
    }
    else {
        return;
    }
}


# This assumes a sanitized 9 or 10 digit number
my @valid_state_codes = (2,3,4,5,7,8);
sub _has_valid_state_code {
    my $self = shift;

    return if $self->_is_fake;

    my $state_code = $self->state_code;
    return scalar grep { $state_code == $_ } @valid_state_codes;
}

sub _is_fake {
    my $self = shift;

    my $number = $self->local_number;

    return 1 if $self->state_code != 3 and $number =~ m/^5551/;
    return 1 if $number =~ m/^7010/;

    return;
}

=head1 INTERFACE NOTE

The interface of this module differs significantly from that set forth by
Number::Phone.  If you're used to using that module, please read the
documentation carefully.

=head1 AUTHOR

Josh Heumann, C<< <cpan at joshheumann.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-number-phone-au at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-Phone-AU>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Phone::AU


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Phone-AU>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Number-Phone-AU>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Number-Phone-AU>

=item * Search CPAN

L<http://search.cpan.org/dist/Number-Phone-AU/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Josh Heumann.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Number::Phone::AU
