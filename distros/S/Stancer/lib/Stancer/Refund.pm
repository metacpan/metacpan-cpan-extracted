package Stancer::Refund;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Representation of a refund
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(coerce_datetime coerce_instance InstanceOf Maybe PaymentInstance Str);

use Stancer::Payment;
use Scalar::Util qw(blessed);

use Moo;

extends 'Stancer::Core::Object';
with 'Stancer::Role::Amount::Write';

use namespace::clean;

use Stancer::Refund::Status;

has '+endpoint' => (
    default => 'refunds',
);


has date_bank => (
    is => 'rwp',
    isa => Maybe[InstanceOf['DateTime']],
    builder => sub { $_[0]->_attribute_builder('date_bank') },
    coerce => coerce_datetime(),
    lazy => 1,
    predicate => 1,
);


has date_refund => (
    is => 'rwp',
    isa => Maybe[InstanceOf['DateTime']],
    builder => sub { $_[0]->_attribute_builder('date_refund') },
    coerce => coerce_datetime(),
    lazy => 1,
    predicate => 1,
);


has payment => (
    is => 'rw',
    isa => Maybe[PaymentInstance],
    builder => sub { $_[0]->_attribute_builder('payment') },
    coerce => coerce_instance('Stancer::Payment'),
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('payment') },
);


has status => (
    is => 'rwp',
    isa => Maybe[Str],
    builder => sub { $_[0]->_attribute_builder('status') },
    lazy => 1,
    predicate => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Refund - Representation of a refund

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<amount>

Read/Write integer, must be at least 50.

Refunded amount.

=head2 C<currency>

Read/Write string, must be one of "AUD", "CAD", "CHF", "DKK", "EUR", "GBP", "JPY", "NOK", "PLN", "SEK" or "USD".

Refund currency.

=head2 C<date_bank>

Read-only instance of C<DateTime>.

Value date.

=head2 C<date_refund>

Read-only instance of C<DateTime>.

Date when the refund is sent to the bank.

=head2 C<payment>

Read/Write instance of C<Stancer::Payment>.

Related payment object.

=head2 C<status>

Read-only string.

Payment status.

=head1 METHODS

=head2 C<< Stancer::Refund->new(I<$token>) : I<self> >>

This method accept an optional string, it will be used as an entity ID for API calls.

    # Create a refund
    my $payment = Stancer::Payment->new($token);

    $payment->refund();

    my $refunds = $payment->refunds;

    # Get an existing refund
    my $exist = Stancer::Refund->new($token);

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Refund;

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
