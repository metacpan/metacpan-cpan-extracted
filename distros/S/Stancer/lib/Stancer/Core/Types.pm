package Stancer::Core::Types;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Internal types
our $VERSION = '1.0.3'; # VERSION

use base qw(Exporter);
our @EXPORT_OK = ();

use namespace::clean;

use Exporter qw(import);
use Stancer::Core::Types::ApiKeys qw(:all);
use Stancer::Core::Types::Bank qw(:all);
use Stancer::Core::Types::Bases qw(:all);
use Stancer::Core::Types::Dates qw(:all);
use Stancer::Core::Types::Helper qw(:all);
use Stancer::Core::Types::Network qw(:all);
use Stancer::Core::Types::Object qw(:all);
use Stancer::Core::Types::String qw(:all);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    api => \@Stancer::Core::Types::ApiKeys::EXPORT_OK,
    bank => \@Stancer::Core::Types::Bank::EXPORT_OK,
    bases => \@Stancer::Core::Types::Bases::EXPORT_OK,
    dates => \@Stancer::Core::Types::Dates::EXPORT_OK,
    helper => \@Stancer::Core::Types::Helper::EXPORT_OK,
    network => \@Stancer::Core::Types::Network::EXPORT_OK,
    object => \@Stancer::Core::Types::Object::EXPORT_OK,
    str => \@Stancer::Core::Types::String::EXPORT_OK,
);

push @EXPORT_OK, map { @{$_} } values %EXPORT_TAGS;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Core::Types - Internal types

=head1 VERSION

version 1.0.3

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Core::Types;

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
