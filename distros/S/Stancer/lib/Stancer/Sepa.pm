package Stancer::Sepa;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Representation of a SEPA account
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(coerce_date coerce_datetime Bic Char Iban InstanceOf Maybe SepaCheckInstance Varchar);
use Try::Tiny;

use Moo;

extends 'Stancer::Core::Object';
with 'Stancer::Role::Country', 'Stancer::Role::Name';

use namespace::clean;

use Stancer::Sepa::Check;

has '+_date_only' => (
    default => sub{ [qw(date_birth)] },
);

has '+endpoint' => (
    default => 'sepa',
);

has '+_json_ignore' => (
    default => sub{ [qw(check endpoint created populated country last4)] },
);


has bic => (
    is => 'rw',
    isa => Maybe[Bic],
    builder => sub { $_[0]->_attribute_builder('bic') },
    coerce => sub {
        my $value = shift;

        return unless defined $value;

        $value =~ s/\s//gsm;

        return uc $value;
    },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('bic') },
);


has check => (
    is => 'rwp',
    isa => Maybe[SepaCheckInstance],
    builder => sub {
        my $self = shift;
        my $check;

        try {
            $check = Stancer::Sepa::Check->new($self->id)->populate() if defined $self->id;
        }
        catch {
            $_->throw() unless $_->isa('Stancer::Exceptions::Http::NotFound');
        };

        return $check;
    },
    lazy => 1,
    predicate => 1,
);


has date_birth => (
    is => 'rw',
    isa => Maybe[InstanceOf['DateTime']],
    builder => sub { $_[0]->_attribute_builder('date_birth') },
    coerce => coerce_date(),
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('date_birth') },
);


has date_mandate => (
    is => 'rw',
    isa => Maybe[InstanceOf['DateTime']],
    builder => sub { $_[0]->_attribute_builder('date_mandate') },
    coerce => coerce_datetime(),
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('date_mandate') },
);


sub formatted_iban {
    my $this = shift;
    my $iban = $this->iban;

    return undef if not defined $iban;

    $iban =~ s/(.{1,4})/$1 /gsm;
    $iban =~ s/\s*$//sm;

    return $iban;
}


has iban => (
    is => 'rw',
    isa => Maybe[Iban],
    builder => sub { $_[0]->_attribute_builder('iban') },
    coerce => sub {
        my $value = shift;

        return unless defined $value;

        $value =~ s/\s//gsm;

        return uc $value;
    },
    lazy => 1,
    predicate => 1,
    trigger => sub {
        my $this = shift;

        $this->_add_modified('iban');
        $this->_set_last4(substr $this->iban, -4);
    },
);


has last4 => (
    is => 'rwp',
    isa => Maybe[Char[4]],
    builder => sub { $_[0]->_attribute_builder('last4') },
    lazy => 1,
    predicate => 1,
);


has mandate => (
    is => 'rw',
    isa => Maybe[Varchar[3, 35]],
    builder => sub { $_[0]->_attribute_builder('mandate') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('mandate') },
);


sub validate {
    my $self = shift;
    my $check = Stancer::Sepa::Check->new(sepa => $self);

    $self->_set_check($check->send());
    $self->_set_id($self->check->id);

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Sepa - Representation of a SEPA account

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<bic>

Read/Write string.

BIC code, also called SWIFT code.

=head2 C<check>

Read-only instance of C<Stancer::SepaMail>.

Verification results.

=head2 C<country>

Read-only string.

Account country

=head2 C<date_birth>

Read/Write instance of C<DateTime>.

A DateTime object representing the user birthdate.

This value is mandatory to use Sepa check service.

=head2 C<date_mandate>

Read/Write instance of C<DateTime>.

A DateTime object representing the mandate signature date.

This value is mandatory if a C<mandate> is provided.

=head2 C<formatted_iban>

Read-only string.

Account number but formatted in 4 characters blocs separated with spaces.

=head2 C<iban>

Read/Write string.

Account number

=head2 C<last4>

Read-only 4 characters string.

Last four account number

=head2 C<name>

Read/Write 4 to 64 characters.

Customer name

=head2 C<mandate>

Read/Write 3 to 35 characters.

The mandate referring to the payment

=head1 METHODS

=head2 C<< Stancer::Sepa->new() : I<self> >>

=head2 C<< Stancer::Sepa->new(I<$token>) : I<self> >>

=head2 C<< Stancer::Sepa->new(I<%args>) : I<self> >>

=head2 C<< Stancer::Sepa->new(I<\%args>) : I<self> >>

This method accept an optional string, it will be used as an entity ID for API calls.

    # Get an empty new sepa account
    my $new = Stancer::Sepa->new();

    # Get an existing sepa account
    my $exist = Stancer::Sepa->new($token);

=head2 C<validate>

Will ask for SEPA validation.

See L<sepa/check> for more information.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Sepa;

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
