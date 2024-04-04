package Stancer::Payment::Status;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Payment status values
our $VERSION = '1.0.3'; # VERSION

use Moo;
use namespace::clean;

use constant {
    AUTHORIZE => 'authorize',
    AUTHORIZED => 'authorized',
    CANCELED => 'canceled',
    CAPTURE => 'capture',
    CAPTURE_SENT => 'capture_sent',
    CAPTURED => 'captured',
    DISPUTED => 'disputed',
    EXPIRED => 'expired',
    FAILED => 'failed',
    TO_CAPTURE => 'to_capture',
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Payment::Status - Payment status values

=head1 VERSION

version 1.0.3

=head1 Constants

=head2 authorize

Ask the authorization.

=head2 authorized

The bank authorized the payment but the transaction will only be processed when the capture will be set to C<true>.

=head2 canceled

The payment will not be performed, no money will be captured.

=head2 capture

Ask to authorize and capture the payment.

=head2 capture_sent

The capture operation is being processed, the payment can not be cancelled anymore,
refunds must wait the end of the capture process.

=head2 captured

The amount of the payment have been credited to your account.

=head2 disputed

The customer declined the payment after it have been captured on your account.

=head2 expired

The authorisation was not captured and expired after 7 days.

=head2 failed

The payment has failed, refer to the response field for more details.

=head2 refused

The payment has been refused.

=head2 to_capture

The bank authorized the payment, money will be processed within the day.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Payment::Status;

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
