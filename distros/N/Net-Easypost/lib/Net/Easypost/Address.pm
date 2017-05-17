package Net::Easypost::Address;
$Net::Easypost::Address::VERSION = '0.20';
use Carp qw/croak/;
use JSON::MaybeXS;
use Scalar::Util;
use overload
    '""'     => sub { $_[0]->as_string },
    '0+'     => sub { Scalar::Util::refaddr($_[0]) },
    fallback => 1;
use Types::Standard qw(Bool Enum HashRef InstanceOf Str Undef);


use Moo;
with qw/Net::Easypost::PostOnBuild/;
with qw/Net::Easypost::Resource/;
use namespace::autoclean;

has [qw/street1
     street2
     city
     state
     zip
     country
     carrier_facility
     name
     company
     phone
     email
     federal_tax_id
     state_tax_id/
] => (
    is  => 'rw',
    isa => Str|Undef
);

has 'residential' => (
    is     => 'rw',
    isa    => Bool|InstanceOf['JSON::PP::Boolean'],
    coerce => sub { $_[0] ? JSON->true : JSON->false }
);

has 'verifications' => (
    is  => 'rw',
    isa => HashRef
);

has 'verify_adress' => (
    is  => 'rw',
    isa => Enum[qw/zip4 delivery/]
);

sub _build_fieldnames {
    return [
	qw/
	street1
	street2
	city
	state
	zip
	country
	residential
	carrier_facility
	name
	company
	phone
	email
	federal_tax_id
	state_tax_id
	/
    ];
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

sub serialize {
   my ($self) = @_;

   # want a hashref of e.g., address[name] => foo from all defined attributes
   # verify[]=zip4|delivery - verify an address
   return {
       # (defined $self->verify_address ? "verify[]" => $self->verify : ()),
       (map  { $self->role . "[$_]" => $self->$_ }
       grep { defined $self->$_ } @{ $self->fieldnames })
   };
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

version 0.20

=head1 SYNOPSIS

 Net::Easypost::Address->new

=head1 NAME

 Net::Easypost::Address

=head1 ATTRIBUTES

=over 4

=item mode

 string: Set based on which api-key you used, either "test" or "production"

=item street1

 string: First line of the address

=item street2

 string: Second line of the address

=item city

 string: City the address is located in

=item state

 string: State or province the address is located in

=item zip

 string: ZIP or postal code the address is located in

=item country

 string: ISO 3166 country code for the country the address is located in

=item residential

 boolean: Whether or not this address would be considered residential

=item carrier_facility

 string: The specific designation for the address (only relevant if the address is a carrier facility)

=item name

 string: Name of the person. Both name and company can be included

=item company

 string: Name of the organization. Both name and company can be included

=item phone

 string: Phone number to reach the person or organization

=item email

 string: Email to reach the person or organization

=item federal_tax_id

 string: Federal tax identifier of the person or organization

=item state_tax_id

 string: State tax identifier of the person or organization

=item verifications

 *CURRENTLY NOT IMPLEMENTED* Verifications: The result of any verifications requested

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
