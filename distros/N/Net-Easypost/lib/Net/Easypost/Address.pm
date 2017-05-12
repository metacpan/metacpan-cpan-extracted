package Net::Easypost::Address;
$Net::Easypost::Address::VERSION = '0.18';
use Moo;
with qw(Net::Easypost::PostOnBuild);
with qw(Net::Easypost::Resource);

use Carp qw/croak carp/;
use Scalar::Util;
use overload
    '""'     => sub { $_[0]->as_string },
    '0+'     => sub { Scalar::Util::refaddr($_[0]) },
    fallback => 1;

has [qw/street1 street2 city state zip phone name/] => (
    is => 'rw',
);

has 'country' => (
    is      => 'rw',
    default => 'US',
);

sub _build_fieldnames { 
    return [qw/name street1 street2 city state zip phone country/];
}

sub _build_role { 'address' }

sub _build_operation { '/addresses' }

sub clone {
    my ($self) = @_;

    return Net::Easypost::Address->new(
       map  { $_ => $self->$_ }
       grep { defined $self->$_ } @{ $self->fieldnames }
    );
}

sub as_string {
    my ($self) = @_;

    return join "\n",
        (map  { $self->$_ }
            grep { defined $self->$_ } qw(name phone street1 street2)),
        join " ",
            (map  { $self->$_ }
                grep { defined $self->$_ } qw(city state zip));
}

sub merge {
    my ($self, $old, $fields) = @_;

    map { $self->$_($old->$_) }
        grep { defined $old->$_ }
            @$fields;

    return $self;
}

sub verify {
    my ($self) = @_;
    
    if ($self->country ne 'US') {
        carp "Verifying addresses outside US is not supported";
        return $self;
    }
    my $verify_response =
       $self->requester->get( 
          join '/', $self->operation, $self->id, 'verify' 
       );

    croak 'Unable to verify address, failed with message: '
        . $verify_response->{error}
    if $verify_response->{error};

    my $new_address = Net::Easypost::Address->new(
        $verify_response->{address}
    );

    return $new_address->merge($self, [qw(phone name)]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Easypost::Address

=head1 VERSION

version 0.18

=head1 SYNOPSIS

 Net::Easypost::Address->new

=head1 NAME

 Net::Easypost::Address

=head1 ATTRIBUTES

=over 4

=item street1

A field for street information, typically a house number, a street name and a direction

=item street2

A field for any additional street information like an apartment or suite number

=item city

The city in the address

=item state

The U.S. state for this address

=item zip

The U.S. zipcode for this address

=item phone

Any phone number associated with this address.  Some carrier services like Next-Day or Express
require a sender phone number.

=item name

A name associated with this address.

=item country

The country code. Default to US.

=back

=head1 METHODS

=over 4

=item _build_fieldnames

Attributes that make up an Address, from L<Net::Easypost::Resource>

=item _build_role

Prefix to data when POSTing to the Easypost API about Address objects

=item _build_operation

Base API endpoint for operations on Address objects

=item clone

Make a new copy of this object and return it

=item as_string

Format this address as it might be seen on a mailing label. This class overloads
stringification using this method, so something like C<say $addr> should just work.

=item merge

This method takes a L<Net::Easypost::Address> object and an arrayref of fields to copy
into B<this> object. This method only merges fields that are defined on the other object.

=item verify

This method takes a L<Net::Easypost::Address> object and verifies its underlying
address.

If a non-US address is asked for verification, a warning will be
emitted and the object itself will be returned.

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>, Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
