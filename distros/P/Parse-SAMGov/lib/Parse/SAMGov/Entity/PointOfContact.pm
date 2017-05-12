package Parse::SAMGov::Entity::PointOfContact;
$Parse::SAMGov::Entity::PointOfContact::VERSION = '0.106';
use strict;
use warnings;
use 5.010;
use Parse::SAMGov::Mo;
extends 'Parse::SAMGov::Entity::Address';
use Email::Valid;

#ABSTRACT: Defines the Point of Contact object of the entity.


use overload
  fallback => 1,
  '""'     => sub {
    my $str = '';
    if (length $_[0]->first and length $_[0]->last) {
        $str .= $_[0]->first;
        $str .= ' ' . $_[0]->middle if length $_[0]->middle;
        $str .= ' ' . $_[0]->last;
        $str .= ', ' . $_[0]->title if length $_[0]->title;
        $str .= ', ' . $_[0]->address if length $_[0]->address;
        $str .= ', ' . $_[0]->city if length $_[0]->city;
        $str .= ', ' . $_[0]->state if length $_[0]->state;
        $str .= ', ' . $_[0]->country if length $_[0]->country;
        $str .= ' - ' . $_[0]->zip if length $_[0]->zip;
        $str .= '. Email: ' . $_[0]->email if $_[0]->email;
        $str .= '. Phone: ' . $_[0]->phone if $_[0]->phone;
        $str .= ' x' . $_[0]->phone_ext if $_[0]->phone_ext;
        $str .= '. Fax: ' . $_[0]->fax if $_[0]->fax;
        $str .= '. Phone(non-US): ' . $_[0]->phone_nonUS if $_[0]->phone_nonUS;
        $str .= '.';
    }
    return $str;
  };

has 'first' => default => sub { '' };
has 'middle' => default => sub { '' };
has 'last' => default => sub { '' };
has 'title';
has 'phone';
has 'phone_ext';
has 'phone_nonUS';
has 'fax';
has 'email' => coerce => sub { Email::Valid->address($_[0]); };

sub name {
    if (length $_[0]->middle) {
        return join(' ', $_[0]->first, $_[0]->middle, $_[0]->last);
    } else {
        return join(' ', $_[0]->first, $_[0]->last);
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Parse::SAMGov::Entity::PointOfContact - Defines the Point of Contact object of the entity.

=head1 VERSION

version 0.106

=head1 SYNOPSIS

    my $addr = Parse::SAMGov::Entity::PointOfContact->new(
        first => 'John',
        middle => 'F',
        last => 'Jameson',
        title => 'CEO',
        address => '123 Baker Street, Suite 1A',
        city => 'Boringville',
        state => 'ZB',
        country => 'USA',
        zip => '21900-1234',
        phone => '18888888888',
        phone_ext => '101',
        fax => '18887777777',
        phone_nonUS => '442222222222',
        email => 'abc@pqr.com',
    );

=head1 METHODS

=head2 new

Creates a new Point of Contact object for the entity or individual. This
inherits all the methods of the L<Parse::SAMGov::Entity::Address> object.

=head2 first

Get/Set the first name of the point of contact.

=head2 middle

Get/Set the middle initial of the point of contact.

=head2 last

Get/Set the last name of the point of contact.

=head2 name

Get the full name of the point of contact as a string.

=head2 title

Get/Set the title of the point of contact. Example is CEO, President, etc.

=head2 phone

Get/Set the U.S. Phone number of the point of contact.

=head2 phone_ext

Get/Set the U.S. Phone number extension of the point of contact if any.

=head2 phone_nonUS

Get/Set the non-U.S. phone number of the point of contact.

=head2 fax

Get/Set the fax number of the point of contact.

=head2 email

Get/Set the email of the point of contact.

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
