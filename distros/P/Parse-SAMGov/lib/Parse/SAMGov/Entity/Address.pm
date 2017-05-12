package Parse::SAMGov::Entity::Address;
$Parse::SAMGov::Entity::Address::VERSION = '0.106';
use strict;
use warnings;
use 5.010;
use Parse::SAMGov::Mo;

#ABSTRACT: Defines the Address object of the entity.


use overload
  fallback => 1,
  '""'     => sub {
    my $str = '';
    $str .= $_[0]->address . ', ' if length $_[0]->address;
    $str .= $_[0]->city           if length $_[0]->city;
    $str .= ', ' . $_[0]->state   if length $_[0]->state;
    $str .= ', ' . $_[0]->country if length $_[0]->country;
    $str .= ' - ' . $_[0]->zip    if length $_[0]->zip;
    return $str;
  };

has 'address';
has 'city';
has 'state';
has 'district';
has 'country';
has 'zip' => coerce => sub {
    chop $_[0] if ($_[0] =~ /-$/);
    return $_[0];
};

1;

=pod

=encoding UTF-8

=head1 NAME

Parse::SAMGov::Entity::Address - Defines the Address object of the entity.

=head1 VERSION

version 0.106

=head1 SYNOPSIS

    my $addr = Parse::SAMGov::Entity::Address->new(
        address => '123 Baker Street, Suite 1A',
        city => 'Boringville',
        state => 'ZB',
        country => 'USA',
        zip => '21900-1234',
    );

=head1 METHODS

=head2 new

Creates a new Address object for the entity or individual.

=head2 address

This fields holds the address information without the city/state/country and
postal/zip code.

=head2 city

The city name of the entity's address.

=head2 state

The state or province of the entity's address.

=head2 district

The congressional district number of the entity's address.

=head2 country

The three character country code for the entity's address.

=head2 zip

The zip or postal code of the entity's address.

=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Selective Intellect LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
### COPYRIGHT: Selective Intellect LLC.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
