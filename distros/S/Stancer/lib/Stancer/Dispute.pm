package Stancer::Dispute;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Dispute representation
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(coerce_instance Maybe OrderId PaymentInstance Varchar);

use Stancer::Core::Iterator::Dispute;
use Stancer::Payment;
use Scalar::Util qw(blessed);

use Moo;

extends 'Stancer::Core::Object';
with qw(
    Stancer::Role::Amount::Read
);

use namespace::clean;

has '+endpoint' => (
    default => 'disputes',
);


has order_id => (
    is => 'rwp',
    isa => Maybe[OrderId],
    builder => sub { $_[0]->_attribute_builder('order_id') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('order_id') },
);


has payment => (
    is => 'rwp',
    isa => Maybe[PaymentInstance],
    builder => sub { $_[0]->_attribute_builder('payment') },
    coerce => coerce_instance('Stancer::Payment'),
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('payment') },
);


has response => (
    is => 'rwp',
    isa => Maybe[Varchar[2, 4]],
    builder => sub { $_[0]->_attribute_builder('response') },
    lazy => 1,
    predicate => 1,
);


sub list {
    my ($class, @args) = @_;

    return Stancer::Core::Iterator::Dispute->search(@args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Dispute - Dispute representation

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<amount>

Read-only integer.

Dispute amount.

=head2 C<currency>

Read-only string.

Dispute currency.

=head2 C<order_id>

Read-only string.

External order id.

=head2 C<payment>

Read-only instance of C<Stancer::Payment>.

Related payment object.

=head2 C<response>

Read-only 2 or 4 characters string.

API response code.

=head1 METHODS

=head2 C<< Stancer::Dispute->new() : I<self> >>

=head2 C<< Stancer::Dispute->new(I<$token>) : I<self> >>

=head2 C<< Stancer::Dispute->new(I<%args>) : I<self> >>

=head2 C<< Stancer::Dispute->new(I<\%args>) : I<self> >>

This method accept an optional string, it will be used as an entity ID for API calls.

    # Get an empty new payment
    my $new = Stancer::Dispute->new();

    # Get an existing payment
    my $exist = Stancer::Dispute->new($token);

=head2 C<< Dispute->list(I<%terms>) : I<DisputeIterator> >>

=head2 C<< Dispute->list(I<\%terms>) : I<DisputeIterator> >>

List all disputes.

C<%terms> must be an hash or a reference to an hash (C<\%terms>) with at least one of the following key :

=over

=item C<created>

Must be an unix timestamp, a C<DateTime> or a C<DateTime::Span> object which will filter payments
created after this value.
If a C<DateTime::Span> is passed, C<created_until> will be ignored and replaced with C<< DateTime::Span->end >>.

=item C<created_until>

Must be an unix timestamp or a C<DateTime> object which will filter payments created before this value.
If a C<DateTime::Span> is passed to C<created>, this value will be ignored.

=item C<limit>

Must be an integer between 1 and 100 and will limit the number of objects to be returned.
API defaults is to return 10 elements.

=item C<start>

Must be an integer and will be used as a pagination cursor, starts at 0.

=back

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Dispute;

You must import C<Log::Any::Adapter> before our libraries, to initialize the logger instance before use.

You can choose your log level on import directly:
    use Log::Any::Adapter (File => '/var/log/payment.log', log_level => 'info');

Read the L<Log::Any> documentation to know what other options you have.

=cut

=head1 SECURITY

=over

=item *

Never, never, NEVER register a card or a bank account number in your database.

=item *

Always uses HTTPS in card/SEPA in communication.

=item *

Our API will never give you a complete card/SEPA number, only the last four digits.
If you need to keep track, use these last four digit.

=back

=cut

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://gitlab.com/wearestancer/library/lib-perl/-/issues> or by email to
L<bug-stancer@rt.cpan.org|mailto:bug-stancer@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Joel Da Silva <jdasilva@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2024 by Stancer / Iliad78.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
