package Stancer::Core::Request;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Handle API request
our $VERSION = '1.0.3'; # VERSION

use Stancer::Config;
use Stancer::Core::Request::Call;
use Stancer::Exceptions::Http;
use JSON qw(decode_json);
use Log::Any qw($log);
use Try::Tiny;

use Moo;
use namespace::clean;


sub del {
    my $this = shift;
    my $object = shift;

    my $request = HTTP::Request->new(DELETE => $object->uri);

    return $this->_request($request);
}


sub get {
    my ($this, $object, @args) = @_;
    my $query;

    if (scalar @args == 1) {
        $query = $args[0];
    } else {
        $query = {@args};
    }

    my $uri = $object->uri;
    my @params;

    for my $key (keys %{$query}) {
        push @params, $key . q(=) . $query->{$key};
    }

    if (scalar @params) {
        $uri .= q(?) . join q(&), @params;
    }

    my $request = HTTP::Request->new(GET => $uri);

    return $this->_request($request);
}


sub patch {
    my $this = shift;
    my $object = shift;

    my $request = HTTP::Request->new(PATCH => $object->uri);

    $request->content($object->toJSON());

    return $this->_request($request, $object);
}


sub post {
    my $this = shift;
    my $object = shift;

    my $request = HTTP::Request->new(POST => $object->uri);

    $request->content($object->toJSON());

    return $this->_request($request, $object);
}

sub _clean_request {
    my $this = shift;
    my $request = shift;
    my $object = shift;

    if ($object && $object->isa('Stancer::Payment')) {
        if ($object->card && $object->card->number) {
            my $content = $request->content;
            my $number = $object->card->number;
            my $last4 = ('x' x (length($number) - 4)) . $object->card->last4;

            $content =~ s/$number/$last4/sm;

            $request->content($content);
        }

        if ($object->sepa && $object->sepa->iban) {
            my $content = $request->content;
            my $number = $object->sepa->iban;
            my $last4 = ('x' x (length($number) - 4)) . $object->sepa->last4;

            $content =~ s/$number/$last4/sm;

            $request->content($content);
        }
    }

    return $request;
}

sub _request {
    my $this = shift;
    my $request = shift;
    my $object = shift;

    my $config = Stancer::Config->init();
    my $ua = $config->lwp;

    $ua->timeout($config->timeout) if defined $config->timeout;
    $ua->agent($config->user_agent);

    $request->header('Content-Type' => 'application/json');
    $request->authorization_basic($config->secret_key, q//);

    $log->debug(sprintf 'API call: %s %s', $request->method, $request->url);

    my $response = $ua->request($request);

    if ($response->is_error) {
        $this->_clean_request($request, $object);

        my %params = (
            request => $request,
            response => $response,
        );

        try {
            my $content = decode_json $response->decoded_content;

            if (ref $content eq 'HASH' && exists $content->{error}) {
                $params{message} = $content->{error}->{message};

                if (ref $content->{error}->{message} eq 'HASH') {
                    if (exists $content->{error}->{message}->{id}) {
                        $params{message} = $content->{error}->{message}->{id};
                    }

                    if (exists $content->{error}->{message}->{error}) {
                        $params{message} = $content->{error}->{message}->{error};

                        if (exists $content->{error}->{message}->{id}) {
                            $params{message} .= q/ (/ . $content->{error}->{message}->{id} . q/)/;
                        }
                    }
                }
            }
        };

        my $error = Stancer::Exceptions::Http->factory($response->code, %params);
        my $level = $error->log_level;

        $log->$level(sprintf 'HTTP %d - %s', $response->code, $error->message);

        if ($config->debug) {
            push @{ $config->calls }, Stancer::Core::Request::Call->new(
                exception => $error,
                request => $request,
                response => $response,
            );
        }

        $error->throw();
    }

    if ($config->debug) {
        push @{ $config->calls }, Stancer::Core::Request::Call->new(
            request => $this->_clean_request($request, $object),
            response => $response,
        );
    }

    return $response->decoded_content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Core::Request - Handle API request

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

Handle request to the API.

It uses L<LWP::UserAgent module|LWP::UserAgent> as API consumer.

You should not have to use this class directly, everything is done internally.

=head1 METHODS

=head2 C<< $request->del($object) : I<undef> >>

Delete an object on the API.

=head2 C<< $request->get($object) : I<string> >>

Get data available on the API.

=head2 C<< $request->patch($object) : I<string> >>

Update data on the API.

=head2 C<< $request->post($object) : I<string> >>

Send data to the API.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Core::Request;

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
