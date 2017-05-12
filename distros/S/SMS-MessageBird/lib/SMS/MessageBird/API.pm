package SMS::MessageBird::API;

use strict;
use warnings;

use LWP::UserAgent;
use JSON;

=head1 NAME

SMS::MessageBird::API - Provides API integration base for SMS::MessageBird.


=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 METHODS


=head2 new (contructor)

 In: %params - Various parameters for the API interface.

Creates a new instance of SMS::MessageBird.

=head3 Parameters

Parmeters are passed to the contructor as a hash. Required / acceptable keys
are as follows:

=over

=item api_key

Required. The MessageBird account API key used for authentication with
MessageBird's API.

=item originator

As per the MessageBird documentation, all sending functionality requires an
originator. This can be set once on the SMS::MessageBird object and passed to
all the module methods. This can be set later using the originator() mutator.

=item api_url

If for some reason you need to use some form of local HTTP proxy / forwarder
this parameter can be used to specifiy the alternate address. If it is omittied
the default is MessageBird's URL I<https://rest.messagebird.com>.

=back

=cut

sub new {
    my ($package, %params) = @_;

    if (!%params || !exists $params{api_key} || !$params{api_key}) {
        warn 'No API key suppied to SMS::MessageBird contructor';
        return undef;
    }

    my $self = bless {
        api_key => $params{api_key},
    } => ($package || 'SMS::MessageBird');

    $self->{originator} = $params{originator} if $params{originator};

    $self->{api_url}
        = $params{api_url} || 'https://rest.messagebird.com';

    $self->{ua} = LWP::UserAgent->new(
        agent           => "Perl/SMS::MessageBird/$VERSION",
        default_headers => HTTP::Headers->new(
            'content-type' => 'application/json',
            Accept         => 'application/json',
            Authorization  => 'AccessKey ' . $self->{api_key},
        ),
    );

    return $self;
}


=head2 originator

 In: $originator (optional) - New originator to set.
 Out: The currently set originator.

Mutator for the originator parameter. This parameter is the displayed
"From" in the SMS. It can be a phone number (including country code) or an
alphanumeric string of up to 11 characters.

This can be set for the lifetime of the object and used for all messages sent
using the instance or passed individually to each call.

You can pass the originator param to the constructor rather than use this
mutator, but it's here in case you want to send 2 batches of SMS from differing
originiators using the same object.

=cut

sub originator {
    my ($self, $originator) = @_;

    $self->{originator} = $originator if $originator;

    return $self->{originator};
}


=head2 api_url

 In: $api_url (optional) - New api_url to set.
 Out: The currently set api_url.

Mutator for the api_ul parameter. Should some form of network relay be required
this can be used to override the default I<https://rest.messagebird.com>.

=cut

sub api_url {
    my ($self, $api_url) = @_;

    if ($api_url) {
        $api_url =~ s{/$}{};
        $self->{api_url} = $api_url;
    }

    return $self->{api_url};
}



sub _api_request {
    my ($self, $method, $endpoint, $data) = @_;

    my %request_params;
    if ($data) {
        my $content_payload = JSON->new->encode($data);

        $request_params{'Content-Type'} = 'application/json',
        $request_params{Content} = $content_payload;
    }

    my $api_response = $self->{ua}->$method(
        $self->_full_endpoint($endpoint),
        %request_params,
    );

    return {
        ok      => ($api_response->is_success) ? 1 : 0,
        code    => $api_response->code,
        content => JSON->new->pretty(1)->decode($api_response->content),
    };
}

sub _full_endpoint {
    my ($self, $endpoint) = @_;

    return $self->{api_url} . $endpoint;
}

sub _no_param_supplied {
    my ($self, $param) = @_;

    return {
        http_code => undef,
        ok        => 0,
        content   => {
            errors => [
                { description => "No $param supplied" }
            ],
        },
    };
}


=head1 AUTHOR

James Ronan, C<< <james at ronanweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-messagebird at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-MessageBird>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

Alternatively you can raise an issue on the source code which is available on
L<GitHub|https://github.com/jamesronan/SMS-MessageBird>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 James Ronan.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

