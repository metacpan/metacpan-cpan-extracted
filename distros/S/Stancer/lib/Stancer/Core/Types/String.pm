package Stancer::Core::Types::String;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Internal strings types
our $VERSION = '1.0.3'; # VERSION

our @EXPORT_OK = ();
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

use Stancer::Core::Types::Helper qw(error_message);

use Stancer::Exceptions::InvalidDescription;
use Stancer::Exceptions::InvalidEmail;
use Stancer::Exceptions::InvalidExternalId;
use Stancer::Exceptions::InvalidMobile;
use Stancer::Exceptions::InvalidName;
use Stancer::Exceptions::InvalidOrderId;
use Stancer::Exceptions::InvalidUniqueId;

use namespace::clean;

use Exporter qw(import);

sub _create_type {
    my ($name, $params) = @_;

    return {
        name => $name,
        exception => $params->{exception},
        test => sub {
            my ($value, $min, $max) = @_;

            $min = $params->{min} if defined $params->{min};
            $max = $params->{max} if defined $params->{max};

            return 0 if not defined $value;

            $max = 0 if not defined $max;
            $min = 0 if not defined $min;

            if ($min > $max) {
                ($min, $max) = ($max, $min);
            }

            return length($value) >= $min && length($value) <= $max;
        },
        message => sub {
            my ($value, $min, $max) = @_;

            $min = $params->{min} if defined $params->{min};
            $max = $params->{max} if defined $params->{max};

            if (defined $value) {
                $value = q/"/ . $value . q/"/;
            } else {
                $value = 'undef';
            }

            if (not defined $max) {
                return 'Must be at maximum ' . $min . ' characters, tried with ' . $value . q/./;
            }

            if (not defined $min) {
                return 'Must be at maximum ' . $max . ' characters, tried with ' . $value . q/./;
            }

            if ($min > $max) {
                ($min, $max) = ($max, $min);
            }

            return 'Must be an string between ' . $min . ' and ' . $max . ' characters, tried with ' . $value . q/./;
        },
    };
}

my @defs = ();

push @defs, {
    name => 'Char',
    test => sub {
        my ($value, $param) = @_;

        if (not defined $value) {
            return 0;
        }

        length($value) == $param;
    },
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    message => error_message('Must be exactly %2$d characters, tried with %1$s.'),
    ## use critic
};

push @defs, _create_type('Varchar');

push @defs, _create_type('Description', { min => 3, max => 64, exception => 'Stancer::Exceptions::InvalidDescription' });
push @defs, _create_type('Email', { min => 5, max => 64, exception => 'Stancer::Exceptions::InvalidEmail' });
push @defs, _create_type('ExternalId', { max => 36, exception => 'Stancer::Exceptions::InvalidExternalId' });
push @defs, _create_type('Mobile', { min => 8, max => 16, exception => 'Stancer::Exceptions::InvalidMobile' });
push @defs, _create_type('Name', { min => 4, max => 64, exception => 'Stancer::Exceptions::InvalidName' });
push @defs, _create_type('OrderId', { max => 36, exception => 'Stancer::Exceptions::InvalidOrderId' });
push @defs, _create_type('UniqueId', { max => 36, exception => 'Stancer::Exceptions::InvalidUniqueId' });

Stancer::Core::Types::Helper::register_types(\@defs, __PACKAGE__);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Core::Types::String - Internal strings types

=head1 VERSION

version 1.0.3

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Core::Types::String;

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
