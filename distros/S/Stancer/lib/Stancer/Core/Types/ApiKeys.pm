package Stancer::Core::Types::ApiKeys;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Internal ApiKeys types
our $VERSION = '1.0.3'; # VERSION

our @EXPORT_OK = ();
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

use Stancer::Core::Types::Helper qw(error_message);

use namespace::clean;

use Exporter qw(import);

my @defs = ();

push @defs, {
    name => 'ApiKey',
    test => sub {
        my $value = shift;

        return if not defined $value;
        return if length $value != 30;

        ## no critic (RegularExpressions::RequireExtendedFormatting)
        $value =~ m/[sp](?:test|prod)_\w+/sm;
        ## use critic
    },
    message => error_message('%s is not a valid API key.'),
};

push @defs, {
    name => 'PublicLiveApiKey',
    subtype_of => 'ApiKey',
    from => __PACKAGE__,
    test => sub { $_[0] =~ m/^pprod_\w+/sm },
    message => error_message('%s is not a valid public API key for live mode.'),
};

push @defs, {
    name => 'PublicTestApiKey',
    subtype_of => 'ApiKey',
    from => __PACKAGE__,
    test => sub { $_[0] =~ m/^ptest_\w+/sm },
    message => error_message('%s is not a valid public API key for test mode.'),
};

push @defs, {
    name => 'SecretLiveApiKey',
    subtype_of => 'ApiKey',
    from => __PACKAGE__,
    test => sub { $_[0] =~ m/^sprod_\w+/sm },
    message => error_message('%s is not a valid secret API key for live mode.'),
};

push @defs, {
    name => 'SecretTestApiKey',
    subtype_of => 'ApiKey',
    from => __PACKAGE__,
    test => sub { $_[0] =~ m/^stest_\w+/sm },
    message => error_message('%s is not a valid secret API key for test mode.'),
};

Stancer::Core::Types::Helper::register_types(\@defs, __PACKAGE__);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Core::Types::ApiKeys - Internal ApiKeys types

=head1 VERSION

version 1.0.3

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Core::Types::ApiKeys;

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
