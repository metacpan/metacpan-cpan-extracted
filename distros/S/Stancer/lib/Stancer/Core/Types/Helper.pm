package Stancer::Core::Types::Helper;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Internal types helpers
our $VERSION = '1.0.3'; # VERSION

use DateTime;
use Scalar::Util qw(blessed);
use MooX::Types::MooseLike qw();

use namespace::clean;

use Exporter qw(import);

our @EXPORT_OK = qw(coerce_boolean coerce_date coerce_datetime coerce_instance create_instance_type error_message);
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);


sub coerce_boolean {
    return sub {
        my $value = shift;

        return if not defined $value;
        return 1 if "$value" eq 'true';
        return 0 if "$value" eq 'false';
        return $value;
    };
}


sub coerce_date {
    return sub {
        my $value = shift;
        my $blessed = blessed($value);

        return if not defined $value;

        if (defined $blessed) {
            return if $blessed ne 'DateTime';
            return $value->clone()->truncate(to => 'day');
        }

        my ($y, $m, $d) = split qr/-/sm, $value;

        return DateTime->new(year => $y, month => $m, day => $d)->truncate(to => 'day') if defined $d;
        return DateTime->from_epoch(epoch => $value)->truncate(to => 'day');
    };
}


sub coerce_datetime {
    return sub {
        my $value = shift;

        return if not defined $value;

        my $config = Stancer::Config->init();
        my %data = (
            epoch => $value,
        );
        my $blessed = blessed($value);

        if (defined $blessed) {
            return if $blessed ne 'DateTime';
            return $value;
        }

        if (defined $config && defined $config->default_timezone) {
            $data{time_zone} = $config->default_timezone;
        }

        return DateTime->from_epoch(%data);
    };
}


sub coerce_instance {
    my $class = shift;

    return sub {
        my $value = shift;
        my $blessed = blessed($value);

        return $value if not defined $value;

        if (defined $blessed) {
            return $value if $blessed eq $class;
            return;
        }

        return $class->new($value);
    };
}


sub create_instance_type {
    my $type = shift;
    my $class = 'Stancer::' . $type;
    my $name = $type;

    $name =~ s/:://gsm;

    return {
        name => $name . 'Instance',
        exception => 'Stancer::Exceptions::Invalid' . $name . 'Instance',
        test => sub {
            my $instance = shift;

            return if not defined $instance;
            return if not blessed $instance;
            return $instance->isa($class);
        },
        message => sub {
            my $instance = shift;

            return 'No instance given.' if not defined $instance;
            return sprintf '"%s" is not blessed.', $instance if not blessed $instance;
            return sprintf '%s is not an instance of "%s".', $instance, $class;
        },
    };
}


sub error_message {
    my $message = shift;

    return sub {
        my $value = shift;

        if (defined $value) {
            $value = q/"/ . $value . q/"/;
        } else {
            $value = 'undef';
        }

        return sprintf $message, $value, @_;
    };
}


sub register_types {
    my ($defs, $package) = @_;

    for my $def (@{ $defs }) {
        if (defined $def->{exception}) {
            my $class = $def->{exception};
            my $message = $def->{message};

            $def->{message} = sub {
                if (ref $message eq 'CODE') {
                    $class->throw(message => $message->(@_));
                }

                $class->throw(message => $message);
            };
        }
    }

    return MooX::Types::MooseLike::register_types($defs, $package);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Core::Types::Helper - Internal types helpers

=head1 VERSION

version 1.0.3

=head1 FUNCTIONS

=head2 C<< coerce_boolean() : I<CODE> >>

Helper function for C<Bool> type attribute.

=head2 C<< coerce_date() : I<CODE> >>

Helper function for C<DateTime> type attribute.

=head2 C<< coerce_datetime() : I<CODE> >>

Helper function for C<DateTime> type attribute.

=head2 C<< coerce_instance() : I<CODE> >>

Helper function for instances type attribute.

=head2 C<< create_instance_type(I<$prefix>) >>

Helper function to create an "InstanceOf" type.

=head2 C<< error_message(I<$message>) >>

=head2 C<< error_message(I<$message>, I<@args>) >>

Helper function to be used in a type definition:

    {
        ...
        message => error_message('%s is not an integer'),
        ...
    }

It will produce:

    '"something" is not an integer'
    # or with an undefined value
    'undef is not an integer'

If I<@args> is provided, it will passed to C<sprintf> internal function.

    {
        ...
        name => 'Char',
        message => error_message('Must be exactly %2$d characters, tried with %1$s.'),
        ...
    }

Will produce for a C<Char[20]> attribute:

    'Must be exactly 20 characters, tried with "something".'

=head2 C<< register_types( I<$types>, I<$package> ) >>

Install the given types within the package.

This will use C< MooX::Types::MooseLike::register_types() >.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Core::Types::Helper;

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
