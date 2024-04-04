package Stancer::Sepa::Check;

use 5.020;
use strict;
use warnings;

# ABSTRACT: This will SEPAmail, a french service allowing to verify bank details on SEPA.
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(coerce_boolean Bool Maybe Num SepaInstance Str Varchar);
use Stancer::Sepa;

use Moo;

extends 'Stancer::Core::Object';

use namespace::clean;

use Stancer::Sepa::Check::Status;

has '+_boolean' => (
    default => sub{ [qw(date_birth)] },
);

has '+endpoint' => (
    default => 'sepa/check',
);


has date_birth => (
    is => 'rwp',
    isa => Maybe[Bool],
    builder => sub { $_[0]->_attribute_builder('date_birth') },
    coerce => coerce_boolean(),
    lazy => 1,
    predicate => 1,
);


has response => (
    is => 'rwp',
    isa => Maybe[Varchar[2, 4]],
    builder => sub { $_[0]->_attribute_builder('response') },
    lazy => 1,
    predicate => 1,
);


has sepa => (
    is => 'rwp',
    isa => Maybe[SepaInstance],
    builder => sub {
        my $self = shift;

        return unless $self->id;
        return Stancer::Sepa->new($self->id);
    },
    lazy => 1,
    predicate => 1,
);


has score_name => (
    is => 'rwp',
    isa => Maybe[Num],
    builder => sub { $_[0]->_attribute_builder('score_name') },
    coerce => sub {
        my $value = shift;

        return unless defined $value;
        return $value / 100;
    },
    lazy => 1,
    predicate => 1,
);


has status => (
    is => 'rwp',
    isa => Maybe[Str],
    builder => sub { $_[0]->_attribute_builder('status') },
    lazy => 1,
    predicate => 1,
);

sub TO_JSON {
    my $self = shift;

    return {} unless defined $self->sepa;
    return { id => $self->sepa->id } if defined $self->sepa->id;
    return $self->sepa->TO_JSON();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Sepa::Check - This will SEPAmail, a french service allowing to verify bank details on SEPA.

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<date_birth>

Read-only boolean.

Is the provided birth date verified ?

=head2 C<response>

Read-only 2 or 4 characters string.

API response code.

=head2 C<sepa>

Read-only instance of C<Stancer::Sepa>.

Verified SEPA.

=head2 C<score_name>

Read-only float.

Distance between provided name and account name.

Distance is a percentage, you will have a float between 0 and 1.

=head2 C<status>

Read-only string, should be a C<Stancer::Sepa::Check::Status> constants.

Verification status.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Sepa::Check;

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
