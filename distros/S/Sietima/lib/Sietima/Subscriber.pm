package Sietima::Subscriber;
use Moo;
use Sietima::Policy;
use Types::Standard qw(ArrayRef HashRef Object);
use Type::Params qw(compile);
use Sietima::Types qw(Address AddressFromStr);
use Email::Address;
use List::AllUtils qw(any);
use namespace::clean;

our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: a subscriber to a mailing list


has primary => (
    isa => Address,
    is => 'ro',
    required => 1,
    coerce => AddressFromStr,
    handles => [qw(address name original)],
);


my $address_array = ArrayRef[
    Address->plus_coercions(
        AddressFromStr
    )
];
has aliases => (
    isa => $address_array,
    is => 'lazy',
    coerce => $address_array->coercion,
);
sub _build_aliases { +[] }


has prefs => (
    isa => HashRef,
    is => 'ro',
    default => sub { +{} },
);


sub match {
    # we can't use the sub signature here, because we need the
    # coercion
    state $check = compile(Object,Address->plus_coercions(AddressFromStr));
    my ($self,$addr) = $check->(@_);

    return any { $addr->address eq $_->address }
        $self->primary, $self->aliases->@*;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Subscriber - a subscriber to a mailing list

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

This class holds the primary email address for a mailing list
subscriber, together with possible aliases and preferences.

=head1 ATTRIBUTES

All attributes are read-only.

=head2 C<primary>

Required L<< C<Email::Address> >> object, coercible from a string.

This is the primary address for the subscriber, the one where they
will receive messages from the mailing list.

=head2 C<aliases>

Arrayref of L<< C<Email::Address> >> objects, each coercible from a
string. Defaults to an empty arrayref.

These are secondary addresses that the subscriber may write
from. Subscriber-only mailing lists should accept messages from any of
these addresses as if they were from the primary. The L<< /C<match> >>
simplifies that task.

=head2 C<prefs>

A hashref. Various preferences that may be interpreted by Sietima
roles. Defaults to an empty hashref.

=head1 METHODS

=head2 C<match>

  if ($subscriber->match($address)) { ... }

Given a L<< C<Email::Address> >> object (or a string), this method
returns true if the address is equivalent to the
L</primary> or any of the L</aliases>.

This method should be used to determine whether an address belongs to
a subscriber.

=head2 C<address>

=head2 C<name>

=head2 C<original>

These methods delegate to L<< C<Email::Address> >>'s methods of the
same name, invoked on the L<primary address|/primary>.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
