package Stancer;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Stancer Perl library
our $VERSION = '1.0.3'; # VERSION

use namespace::clean;

use Stancer::Auth;
use Stancer::Card;
use Stancer::Config;
use Stancer::Customer;
use Stancer::Device;
use Stancer::Dispute;
use Stancer::Payment::Status;
use Stancer::Refund;
use Stancer::Sepa;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer - Stancer Perl library

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

    Stancer::Config->init($secret_key);

    my $payment = Stancer::Payment->new(amount => 100, currency = 'eur');
    $payment->send();

=head1 DESCRIPTION

This module provides common bindings for the Stancer API.

Every API object has a module representation:

=over

=item L<Auth|Stancer::Auth>

=item L<Card|Stancer::Card>

=item L<Customer|Stancer::Customer>

=item L<Device|Stancer::Device>

=item L<Dispute|Stancer::Dispute>

=item L<Payment|Stancer::Payment>

=item L<Refund|Stancer::Refund>

=item L<Sepa|Stancer::Sepa>

=back

=head1 REPOSITORY

L<https://gitlab.com/wearestancer/library/lib-perl>

=head1 SEE ALSO

Documentation L<http://stancer.com/documentation/>

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer;

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

=head1 CONTRIBUTORS

=for stopwords Joël DA SILVA Nicolas VINOT

=over 4

=item *

Joël DA SILVA <jdasilva@corp.free.fr>

=item *

Nicolas VINOT <nvinot@stancer.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2024 by Stancer / Iliad78.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
