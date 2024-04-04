package Stancer::Role::Payment::Refund;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Payment refund relative role
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(ArrayRef RefundInstance);

use Stancer::Exceptions::InvalidAmount;
use Stancer::Exceptions::MissingPaymentId;
use Stancer::Refund::Status;
use Log::Any qw($log);
use Scalar::Util qw(blessed);

use Moo::Role;

requires qw(_attribute_builder amount currency id);

use namespace::clean;


sub refundable_amount {
    my $this = shift;
    my $amount = $this->amount;

    for (@{$this->refunds}) {
        $amount -= $_->{amount};
    }

    return $amount;
}


has refunds => (
    is => 'rwp',
    isa => ArrayRef[RefundInstance],
    builder => sub { $_[0]->_attribute_builder('refunds') },
    coerce => sub {
        my $data = shift;
        my @refunds = ();

        if (defined $data) {
            for my $refund (@{$data}) {
                next if not defined $refund;

                if (blessed($refund) and blessed($refund) eq 'Stancer::Refund') {
                    push @refunds, $refund;
                } else {
                    push @refunds, Stancer::Refund->new($refund);
                }
            }
        }

        return \@refunds;
    },
    lazy => 1,
    predicate => 1,
);


sub refund {
    my ($this, $amount) = @_;
    my $refund = Stancer::Refund->new(payment => $this);
    my $refunds = $this->refunds;

    Stancer::Exceptions::MissingPaymentId->throw() unless defined $this->id;

    if (defined $amount) {
        if ($amount > $this->refundable_amount) {
            my $refunded = $this->amount - $this->refundable_amount;
            my $pattern = 'You are trying to refund (%.02f %s) more than paid (%.02f %s).';
            my @params = (
                $amount / 100,
                uc $this->currency,
                $this->amount / 100,
                uc $this->currency,
            );

            if ($refunded != 0) {
                $pattern = 'You are trying to refund (%.02f %s) more than paid (%.02f %s with %.02f %s already refunded).';

                push @params, $refunded / 100;
                push @params, uc $this->currency;
            }

            my $message = sprintf $pattern, @params;

            Stancer::Exceptions::InvalidAmount->throw(message => $message);
        }

        $refund->amount($amount);
    }

    $refund->send();

    push @{$refunds}, $refund;
    $this->_set_refunds($refunds);

    my $message = sprintf 'Refund of %.02f %s on payment "%s"', (
        $refund->amount / 100,
        uc $refund->currency,
        $this->id,
    );

    $log->info($message);

    if ($refund->status ne Stancer::Refund::Status::TO_REFUND) {
        $this->_set_populated(0);
        $this->populate();

        for my $item (@{ $this->refunds }) {
            $item->payment($this);
        }
    }

    return $this;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Role::Payment::Refund - Payment refund relative role

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<refundable_amount>

Read-only integer.

Paid amount available for a refund.

=head2 C<refunds>

Read-only array of C<Stancer::Refund> instance.

List of refund made on the payment.

=head1 METHODS

=head2 C<< $payment->refund() : I<self> >>

=head2 C<< $payment->refund(I<$amount>) : I<self> >>

Refund a payment, or part of it.

I<$amount>, if provided, must be at least 50. If not present, all paid amount we be refund.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Role::Payment::Refund;

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
