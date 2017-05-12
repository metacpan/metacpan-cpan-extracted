package Number::Phone::BR;
# ABSTRACT: Brazilian phone numbers
use Moo;
use Carp qw/confess/;
use Number::Phone::BR::Areas qw/code2name mobile_phone_digits_by_area/;
extends 'Moo::Object', 'Number::Phone';

our $VERSION = '0.001'; # VERSION

sub country { 'BR' }
sub country_code { 55 }

has subscriber    => ( is => 'ro' );

has areacode      => ( is => 'ro' );
has areaname      => ( is => 'ro' );

has is_mobile     => ( is => 'ro' );
has is_valid      => ( is => 'ro' );
has is_fixed_line => ( is => 'ro' );

has _original_number => ( is => 'ro' );

sub BUILDARGS {
    my ($class, $number) = @_;
    my ($areacode, $subscriber);

    my %args = ( _original_number => $number );

    my $number_sane = _sanitize_number($number)
      or return \%args;

    $number_sane =~ s{ \( ([0-9]+) \) }{}x;

    if ( $areacode = $1 ) {
        $areacode =~ s/^0//;
        $subscriber = $number_sane;
    }
    else {
        $number_sane =~ s{^0}{};

        $areacode   = substr $number_sane, 0, 2;
        $subscriber = substr $number_sane, 2;
    }

    my $areaname = code2name($areacode)
      or return \%args;

    my $is_mobile     = _validate_mobile( $areacode, $subscriber );
    my $is_fixed_line = $is_mobile ? 0 : _validate_fixed_line( $subscriber );
    my $is_valid      = $is_mobile || $is_fixed_line;

    %args = (%args,
        areacode         => $areacode,
        areaname         => $areaname,
        subscriber       => $subscriber,
        is_mobile        => $is_mobile,
        is_fixed_line    => $is_fixed_line,
        is_valid         => $is_valid,
    ) if $is_valid;

    return \%args;
}

sub BUILD {
    my $self = shift;

    # Breaks compat with Number::Phone
    $self->is_valid
      or confess "Not a valid Brazilian phone number: " . $self->_original_number;
}

sub _sanitize_number {
    my $number = shift;

    return '' unless $number;

    my $number_sane = $number;

    # remove stuff we don't need
    $number_sane =~ s{[\- \s]}{}gx;

    # strip country code
    $number_sane =~ s{^\+55}{}gx;

    return '' if $number_sane =~ m|\+|;

    return $number_sane;
}

sub _validate_mobile {
    my ($code, $number) = @_;

    my $digits = mobile_phone_digits_by_area($code);

    my $f = substr $number, 0, 1;

    if ($digits == 9 && $f ne '9') {
        return 0;
    }

    if ($f ne '6' && $f ne '8' && $f ne '9') {
        return 0;
    }

    return $number =~ m|^[0-9]{$digits}$| ? 1 : 0;
}

sub _validate_fixed_line {
    my ($number) = @_;

    return $number =~ m|^[2-5][0-9]{7}$| ? 1 : 0;
}

# TODO: 0800, 0300 ?
sub is_tollfree { }

# TODO: 190, etc
sub is_network_service { }

# XXX: all of these return undef, because I have no idea how to implement them,
# or even if it is possible at all in Brazil.
sub is_allocated { }
sub is_in_use { }
sub is_geographic { }
sub is_pager { }
sub is_ipphone { }
sub is_isdn { }
sub is_specialrate { }
sub is_adult { }
sub is_international { }
sub is_personal { }
sub is_corporate { }
sub is_government { }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Number::Phone::BR - Brazilian phone numbers

=head1 SYNOPSIS

    # valid phone
    my $phone = Number::Phone::BR->new('(19) 3333-3333');
    say $phone->areaname;   # SP - Região Metropolitana de Campinas
    say $phone->subscriber; # 33333333
    say $phone->is_fixed_line ? "It's fixed!" : "It's mobile!"; # It's fixed

    # invalid phone:
    my $phone = Number::Phone::BR->new('xxx');
    # throws exception: "Not a valid Brazilian phone number: xxx", with stack
    # trace.

=head1 DESCRIPTION

This module is based on L<Number::Phone>. It implements most important features
defined there.

=head1 INCOMPATIBILITIES WITH NUMBER::PHONE

L<Number::Phone> requires the subclass to return undef from the constructor
when the number is not valid. We think this is poorly designed, and not
compatible with most modern Perl libraries in CPAN today. Additionally, we're
using L<Moo>, and we'd have to make ugly hacks to make the constructor behave
like that. The same would've happened if we were using Moose. Seems logical to
break compatibility on this point, and throw an exception when the number is
not valid.

=head1 METHODS

=head2 country()

The country of the phone: 'BR'.

=head2 country_code()

The country code of the phone: 55.

=head2 subscriber()

The subscriber part of the phone number.

=head2 areacode()

The area code of the phone number (DDD).

=head2 areaname()

Gets the name of the region to which the areacode belongs.

=head2 is_mobile()

Boolean. Is the phone a mobile phone?

=head2 is_valid()

Boolean. Is the phone a valid number?

=head2 is_fixed_line()

Boolean. Is the phone a fixed line?

=head1 NOT IMPLEMENTED

Number::Phone defines the following methods, which are not implemented in this
class:

=head2 is_tollfree()

=head2 is_network_service()

=head2 is_allocated()

=head2 is_in_use()

=head2 is_geographic()

=head2 is_pager()

=head2 is_ipphone()

=head2 is_isdn()

=head2 is_specialrate()

=head2 is_adult()

=head2 is_international()

=head2 is_personal()

=head2 is_corporate()

=head2 is_government()

=head1 SEE ALSO

L<Number::Phone>

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=for Pod::Coverage BUILD BUILDARGS
