package Stancer::Exceptions::Http;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Abstract exception for every HTTP errors
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(InstanceOf);
use HTTP::Status qw(status_message);

use Moo;

extends 'Stancer::Exceptions::Throwable';

use namespace::clean;

has '+log_level' => (
    default => 'warning',
);

has '+message' => (
    default => sub {
        my $this = shift;
        my $code = $this->status;

        return status_message($code) if defined $code;
        return $this->_default_message;
    },
    lazy => 1,
);

has '_default_message' => (
    is => 'ro',
    default => 'HTTP error',
);


has request => (
    is => 'ro',
    isa => InstanceOf['HTTP::Request'],
);


has response => (
    is => 'ro',
    isa => InstanceOf['HTTP::Response'],
);



has status => (
    is => 'ro',
    builder => sub {
        my $this = shift;
        my @parts = split m/::/sm, ref $this;
        my $class = $parts[-1];

        $class =~ s/([[:upper:]])/_$1/xgsm;

        my $constant = 'HTTP' . uc $class;

        return HTTP::Status->$constant if HTTP::Status->can($constant);
    },
);


sub factory {
    my ($class, $status, @args) = @_;
    my $data;

    if (scalar @args == 1) {
        $data = $args[0];
    } else {
        $data = {@args};
    }

    $data->{status} = $status;

    my $instance = Stancer::Exceptions::Http->new($data);

    require Stancer::Exceptions::Http::BadRequest;
    require Stancer::Exceptions::Http::ClientSide;
    require Stancer::Exceptions::Http::Conflict;
    require Stancer::Exceptions::Http::InternalServerError;
    require Stancer::Exceptions::Http::NotFound;
    require Stancer::Exceptions::Http::ServerSide;
    require Stancer::Exceptions::Http::Unauthorized;

    $instance = Stancer::Exceptions::Http::ClientSide->new($data) if $status >= 400;
    $instance = Stancer::Exceptions::Http::ServerSide->new($data) if $status >= 500;

    $instance = Stancer::Exceptions::Http::BadRequest->new($data) if $status == 400;
    $instance = Stancer::Exceptions::Http::Unauthorized->new($data) if $status == 401;
    $instance = Stancer::Exceptions::Http::NotFound->new($data) if $status == 404;
    $instance = Stancer::Exceptions::Http::Conflict->new($data) if $status == 409;
    $instance = Stancer::Exceptions::Http::InternalServerError->new($data) if $status == 500;

    return $instance;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Exceptions::Http - Abstract exception for every HTTP errors

=head1 VERSION

version 1.0.3

=head1 ATTRIBUTES

=head2 C<request>

Read-only HTTP::Request instance.

The request that resulted that error.

=head2 C<response>

Read-only HTTP::Response instance.

The response that resulted that error.

=head2 C<status>

Read-only integer.

HTTP status code

=head1 METHODS

=head2 C<< Stancer::Exceptions::Http->factory( I<$status> ) >>

=head2 C<< Stancer::Exceptions::Http->factory( I<$status>, I<%args> ) >>

=head2 C<< Stancer::Exceptions::Http->factory( I<$status>, I<\%args> ) >>

Return an instance of HTTP exception depending on C<$status>.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Exceptions::Http;

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
