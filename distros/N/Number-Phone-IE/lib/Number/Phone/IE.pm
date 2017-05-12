package Number::Phone::IE;

use strict;
use warnings;
use diagnostics;

use Scalar::Util 'blessed';

use Number::Phone::IE::Data;

use base 'Number::Phone';

our $VERSION = '0.2';

$Number::Phone::subclasses{country_code()} = __PACKAGE__;

my $cache = {};

=head1 NAME

Number::Phone::IE - Republic of Ireland-specific methods for Number::Phone

=head1 SYNOPSIS

    use Number::Phone;

    $dermots_phone = Number::Phone->new('IE', '017654321');

=cut

sub new {
    my $class = shift;
    my $number = shift;
    die("No number given to ".__PACKAGE__."->new()\n") unless($number);

    return bless(\$number, $class) if(is_valid($number));
}

=head1 METHODS

The following methods from Number::Phone are overridden:

=over 4

=item is_valid

The number is valid within the national numbering scheme.  It may or may
not yet be allocated, or it may be reserved.  Any number which returns
true for any of the following methods will also be valid.

=cut

sub is_valid {
    my $number = shift;

    # if called as an object method, it *must* be valid otherwise the
    # object would never have been instantiated.
    return 1 if(blessed($number) && $number->isa(__PACKAGE__));

    # otherwise we have to validate

    # if we've seen this number before, use cached result
    return 1 if($cache->{$number}->{is_valid});

    my $parsed_number = $number;
    my %digits;
    $parsed_number =~ s/[^0-9+]//g;               # strip non-digits/plusses
    $parsed_number =~ s/^\+353//;                  # remove leading +353
    $parsed_number =~ s/^0//;                     # kill leading zero

    @digits{qw(A B C D E F)} = split(//, $parsed_number, 6);

    my @retards = map { substr($parsed_number, 0, $_) } reverse 1..6;

    # and quickly check length
    $cache->{$number}->{is_valid} = (length($parsed_number) > 6 && length($parsed_number) < 12) ? 1 : 0;
    return 0 unless($cache->{$number}->{is_valid});

	# All prefices in data file currently refer either to full numbers (112 et al)
	# or to full "area-code" prefices.
	my %numberTypes =
	(
		geographic		=>	'geo_prefices',
		network_service		=>	'network_svc_prefices',
		tollfree		=>	'free_prefices',
		pager			=>	'pager_prefices',
		mobile			=>	'mobile_prefices',
		specialrate		=>	'special_prefices',
		adult			=>	'adult_prefices',
		ipphone			=>	'ip_prefices'
	);
	
	my $prefix;
	foreach my $type (keys %numberTypes)
	{
		my $dataSource = $numberTypes{$type};
		
		($prefix) = grep { $Number::Phone::IE::Data::{$dataSource}{$_} } @retards;
		if($prefix)
		{
			$cache->{$number}->{"is_$type"} = 1;
			last;
		}
	}

    $cache->{$number}->{is_fixed_line} = $cache->{$number}->{is_geographic};
	$cache->{$number}->{is_network_service} = 1 if &isDirectoryInquiry($number);

	# Without a mapping to actual allocations, use the next best indicator
	# (might be better not to mention it at all...)

    $cache->{$number}->{is_allocated} = ($cache->{$number}->{is_fixed_line} or $cache->{$number}->{is_mobile}
		or $cache->{$number}->{is_network_service} or $cache->{$number}->{is_tollfree}
		or $cache->{$number}->{is_pager} or $cache->{$number}->{is_specialrate}
		or $cache->{$number}->{is_adult} or $cache->{$number}->{is_ipphone});
		
    if($cache->{$number}->{is_allocated}) {

		if($prefix and $prefix ne $number)
		{
			$cache->{$number}->{areacode} = $prefix;
			$cache->{$number}->{subscriber} = substr($parsed_number, length($prefix));
			$cache->{$number}->{areaname} = $Number::Phone::IE::Data::areanames{$prefix} if $Number::Phone::IE::Data::areanames{$prefix};
			$cache->{$number}->{areaname} = &refineAreaName($cache->{$number}->{areacode}, $cache->{$number}->{subscriber}, $cache->{$number}->{areaname})
				if $cache->{$number}->{areaname} and $cache->{$number}->{is_geographic};
		}
    }
    return $cache->{$number}->{is_valid};
}

# now define the is_* methods that we over-ride

foreach my $is (qw(
    fixed_line geographic network_service tollfree 
    pager mobile specialrate adult allocated 
)) {
    no strict 'refs';
    *{__PACKAGE__."::is_$is"} = sub {
        my $self = shift;
	$self = shift if($self eq __PACKAGE__);
	$self = __PACKAGE__->new($self)
	    unless(blessed($self) && $self->isa(__PACKAGE__));
	$cache->{${$self}}->{"is_$is"};
    }
}

# define the other methods

foreach my $method (qw(operator areacode areaname subscriber)) {
    no strict 'refs';
    *{__PACKAGE__."::$method"} = sub {
        my $self = shift;
        $self = (blessed($self) && $self->isa(__PACKAGE__)) ?
            $self :
            __PACKAGE__->new($self);
        return $cache->{${$self}}->{$method};
    }
}

=item is_allocated

The number has been allocated to a telco for use.  It may or may not yet
be in use or may be reserved. Not currently implemented.

=item is_geographic

The number refers to a geographic area.

=item is_fixed_line

The number, when in use, can only refer to a fixed line.

=item is_mobile

The number, when in use, can only refer to a mobile phone.

=item is_pager

The number, when in use, can only refer to a pager.

=item is_tollfree

Callers will not be charged for calls to this number under normal circumstances.

=item is_specialrate

The number, when in use, attracts special rates.  For instance, national
dialling at local rates, or premium rates for services.

=item is_adult

The number, when in use, goes to a service of an adult nature, such as porn.

=item is_network_service

The number is some kind of network service such as a human operator, directory
enquiries, emergency services etc

=item country_code

Returns 353.

=cut

sub country_code { 353; }

=item regulator

Returns some text in an appropriate character set saying who the telecoms
regulator is, with optional details such as their web site or phone number.

=cut

sub regulator { 'Comreg, http://www.comreg.ie/'; }

=item areacode

Return the area code - if applicable - for the number.  If not applicable,
returns undef.

=item areaname

Return the area name - if applicable - for the number, or undef.

=item subscriber

Return the subscriber part of the number

=item operator

Return the name of the telco operating this number, in an appropriate
character set and with optional details such as their web site or phone
number. Not currently implemented.

=item format

Return a sanely formatted version of the number, complete with IDD code, eg
for the Irish number (021) 765-4321 it would return +353 21 7654321.

=cut

sub format {
    my $self = shift;
    $self = (blessed($self) && $self->isa(__PACKAGE__)) ?
        $self :
        __PACKAGE__->new($self);
    my $format = $cache->{${$self}}->{format};
    return '+'.country_code().' '.
        ($self->areacode() ? $self->areacode().' ' : '').
	$self->subscriber();
}

=item country

If the number is_international, return the two-letter ISO country code.

NYI

=back

=head1 LIMITATIONS/BUGS/FEEDBACK

Strictly sppeaking, this kind of duplication of the Number::Phone::UK class is bad.
A tidy-up is in order, though it may emerge that a completely new implemantation is
better.

The results are only as accurate as my own investigations into current allocations.
User feedback welcome.

While the names of the nominal owners of mobile prefixes are given, number
portability makes this information unreliable.

Please report bugs by email, including, if possible, a test case.             

I welcome feedback from users.

=head1 LICENCE

You may use, modify and distribute this software under the same terms as
perl itself.

=head1 AUTHOR

Dermot McNally E<lt>dermotm@gmail.comE<gt>
cloned from the UK equivalent by David Cantrell E<lt>david@cantrell.org.ukE<gt>

Copyright 2004

=cut

sub isDirectoryInquiry
{
	my $number = shift;
	return 1 if $number =~ /^118/;
}

sub refineAreaName
{
	my $areaCode = shift;
	my $subscriberNumber = shift;
	my $roughName = shift;
	
	return $roughName unless exists $Number::Phone::IE::Data::areaDetail->{$areaCode};
	
	my $lookup = $Number::Phone::IE::Data::areaDetail->{$areaCode};
	foreach my $rangeStart (sort keys %$lookup)
	{
		my $rangeEnd = $lookup->{$rangeStart}->{end};
		last if $rangeStart > $subscriberNumber;
		next if $rangeEnd < $subscriberNumber;
		return $lookup->{$rangeStart}->{location} if $subscriberNumber >= $rangeStart;
	}
	return $roughName . '*';
}

1;

