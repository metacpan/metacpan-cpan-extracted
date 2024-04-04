package Stancer::Auth;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Authentication configuration
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(Maybe Str Url);

use Moo;

extends 'Stancer::Core::Object';

use namespace::clean;

use Stancer::Auth::Status;


has redirect_url => (
    is => 'rwp',
    isa => Maybe[Url],
);


has return_url => (
    is => 'rw',
    isa => Maybe[Url],
    trigger => sub { $_[0]->_add_modified('return_url') },
);


has status => (
    is => 'rwp',
    isa => Maybe[Str],
    default => Stancer::Auth::Status::REQUEST,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Auth - Authentication configuration

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<redirect_url>

Read-only HTTPS url.

Location of the page which will start authentication process.

=head2 C<return_url>

Read/write HTTPS url.

Location of the page which will receive authentication response.

=head2 C<status>

Read-only string.

Authentication status.

=head1 METHODS

=head2 C<< Stancer::Auth->new() : I<self> >>

=head2 C<< Stancer::Auth->new(I<%args>) : I<self> >>

=head2 C<< Stancer::Auth->new(I<\%args>) : I<self> >>

This method accept an optional string, it will be used as an entity ID for API calls.

    # Get an empty new authentication configuration
    my $new = Stancer::Auth->new();

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Auth;

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
