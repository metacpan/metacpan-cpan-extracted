package Stancer::Role::Payment::Page;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Payment page relative role
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(Maybe Url);

use Stancer::Config;
use Stancer::Exceptions::MissingReturnUrl;
use Stancer::Exceptions::MissingPaymentId;
use Stancer::Exceptions::MissingApiKey;
use Try::Tiny;

use Moo::Role;

requires qw(_add_modified _attribute_builder id);

use namespace::clean;


has return_url => (
    is => 'rw',
    isa => Maybe[Url],
    builder => sub { $_[0]->_attribute_builder('return_url') },
    lazy => 1,
    predicate => 1,
    trigger => sub { $_[0]->_add_modified('return_url') },
);


sub payment_page_url {
    my ($this, @args) = @_;
    my $data;

    if (scalar @args == 1) {
        $data = $args[0];
    } else {
        $data = {@args};
    }

    my $config = Stancer::Config->init();

    if (not defined $this->return_url) {
        my $message = 'You must provide a return URL before going to the payment page.';

        Stancer::Exceptions::MissingReturnUrl->throw(message => $message);
    }

    if (not defined $this->id) {
        my $message = 'A payment ID is mandatory to obtain a payment page URL. Maybe you forgot to send the payment.';

        Stancer::Exceptions::MissingPaymentId->throw(message => $message);
    }

    my $pattern = 'https://%s/%s/%s';
    my $host = $config->host;
    my $url;

    $host =~ s/api/payment/sm;

    try {
        $url = sprintf $pattern, $host, $config->public_key, $this->id;
    }
    catch {
        my $message = 'A public API key is needed to obtain a payment page URL.';

        Stancer::Exceptions::MissingApiKey->throw(message => $message);
    };

    my @params = ();

    push @params, 'lang=' . $data->{'lang'} if defined $data->{'lang'};

    if (scalar @params) {
        $url .= q/?/ . join q/&/, @params;
    }

    return $url;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Role::Payment::Page - Payment page relative role

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<return_url>

Read/Write string.

URL used to return to your store when using the payment page.

=head1 METHODS

=head2 C<< $payment->payment_page_url() >>

=head2 C<< $payment->payment_page_url( I<%params> ) >>

=head2 C<< $payment->payment_page_url( I<\%params> ) >>

External URL for Stancer payment page.

Maybe used as an iframe or a redirection page if you needed it.

C<%terms> must be an hash or a reference to an hash (C<\%terms>) with at least one of the following key :

=over

=item C<lang>

To force the language of the page.

The page uses browser language as default language.
If no language available matches the asked one, the page will be shown in english.

=back

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Role::Payment::Page;

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
