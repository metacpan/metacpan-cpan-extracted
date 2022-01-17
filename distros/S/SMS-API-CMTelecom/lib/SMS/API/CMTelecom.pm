package SMS::API::CMTelecom;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use JSON;

=head1 NAME

SMS::API::CMTelecom - SMS API for cmtelecom.com

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

    use SMS::API::CMTelecom;
    my $sms = SMS::API::CMTelecom->new(
        product_token => '00000000-0000-0000-0000-000000000000',
    );

    $sms->send(
        sender     => '00480000111111111',
        message    => 'please call me!',
        recipients => '00490000000000000',
        reference  => 293854,
    );

    # bulk send to many recipients:
    $sms->send(
        sender     => '00480000111111111',
        message    => 'please call me!',
        recipients => ['00490000000000000', '00480000000000', '004300021651202'],
        reference  => 293854,
    );

    my $number = '00480000111111111';
    if ($sms->validate_number($number)) {
        print "$number is a valid phone number.\n"
    } else {
        print "$number is no valid phone number.\n"
    }

    my $number_details = $sms->number_details($number);
    print "$number was ported.\n" if $number_details->{ported};


=head1 METHODS

=head2 new(%options)

Instantiate and initialise object with the following options:

=over 4

=item C<< product_token => $product_token >>

The product token is required to authenticate with the CM Telecom API.

=item C<< sender => $sender >>

Optional. SMS sender number.

=back

=cut

sub new {
    my $class = shift;
    my %params = @_;
    die $class.'->new requires product_token parameter' if not exists $params{product_token};
    my $self = \%params;
    bless $self, $class;

    $self->{_ua} = LWP::UserAgent::->new();
    $self->{_ua}->agent('SMS::API::CMTelecom/'.$VERSION);
    if ($self->{_ua}->can('ssl_opts')) {
        $self->{_ua}->ssl_opts( verify_hostname => 0, );
    }

    return $self;
}

=head2 send

=over 4

=item C<< message => $message >>

Mandatory. Message text to send.

=item C<< recipients => $recipients >>

Mandatory. May be a scalar containing one phone number or an array reference
holding multiple scalars containing one phone number each.

=item C<< sender => $sender >>

Optional if already given as parameter to C<new>. Can also be set globally when construction the object with C<new()>.

=back

If sending fails, C<undef> is returned, otherwise a hashref with some status information:

    {
        messages => [
            {
                messageDetails => undef,
                parts          => 1,
                reference      => 51314,
                status         => "Accepted",
                to             => "0049123456784510",
            },
        ],
    }

You can retrieve the error message via

    my $msg = $sms->error_message();

=cut

sub send {
    my $self = shift;
    my %params = @_;

    $self->_reset_error_message();

    my @recipients = ref $params{recipients} eq 'ARRAY' ? @{ $params{recipients} } : ($params{recipients} || ());

    return $self->_set_error_message(ref($self).'->send requires at least one recipient number') if !@recipients;
    for my $recipient (@recipients) {
        return $self->_set_error_message('recipient may not be undefined') if !defined $recipient;
        return $self->_set_error_message('recipient must be a telephone number') if ref $recipient;
        return $self->_set_error_message('recipient may not be an empty string') if $recipient eq '';
    }

    my $sender = $params{sender} // $self->{sender};
    return $self->_set_error_message(ref($self).'->send requires a sender number') if !defined $sender;

    my $payload = {
        messages => {
            authentication => {
                producttoken => $self->{product_token},
            },
            msg => [
                {
                    from => $sender,
                    to   => [ map { +{ number => $self->_clean_number($_) } } @recipients ],
                    body => {
                        type    => 'AUTO',
                        content => $params{message},
                    },
                    exists $params{reference} ? (reference => $params{reference}) : (),
                },
            ],
        },
    };

    my $req = HTTP::Request->new(
        POST => 'https://gw.cmtelecom.com/v1.0/message',
        ['Content-Type' => 'application/json'],
        encode_json $payload,
    );
    my $res = $self->{_ua}->request( $req );

    if ($res->code == 200) {
        my $result = decode_json $res->content();
        return {
            messages => $result->{messages},
        };
    }

    my $result = eval { decode_json $res->content() };
    return $self->_set_error_message($result->{details}) if ref $result eq 'HASH';

    return $self->_set_error_message('HTTP request returned with status '.$res->code);
}

sub _clean_number {
    my ($self, $number) = @_;

    # strip all non-number chars
    $number =~ s/\D//g;

    return $number;
}

sub _set_error_message {
    my ($self, $message) = @_;
    $self->{error_message} = $message;
    return;
}

sub _reset_error_message {
    my ($self, $message) = @_;
    $self->{error_message} = undef;
    return;
}

=head2 validate_number $number

Checks if the given phone number is valid and provides additional information,
e.g. how the number should be formatted. Returns 1 if the number is valid, a
false value otherwise.

=cut

sub validate_number {
    my ($self, $number) = @_;

    my $req = HTTP::Request->new(
        POST => 'https://api.cmtelecom.com/v1.1/numbervalidation',
        [
            'Content-Type'      => 'application/json',
            'X-CM-PRODUCTTOKEN' => $self->{product_token},
        ],
        encode_json { phonenumber => $number },
    );

    my $res = $self->{_ua}->request( $req );
    if ($res->code == 200) {
        my $result = decode_json $res->content();
        return 1 if JSON::is_bool($result->{valid_number}) and $result->{valid_number};
        return 0;
    }
    return $self->_set_error_message('HTTP request returned with status '.$res->code);
}

=head2 number_details $number

Returns carrier, country, timezone and number type information about the given number.

=cut

sub number_details {
    my ($self, $number) = @_;

    my $req = HTTP::Request->new(
        POST => 'https://api.cmtelecom.com/v1.1/numbervalidation',
        [
            'Content-Type'      => 'application/json',
            'X-CM-PRODUCTTOKEN' => $self->{product_token},
        ],
        encode_json { phonenumber => $number },
    );

    my $res = $self->{_ua}->request( $req );

    if ($res->code == 200) {
        return decode_json $res->content();
    }
    return $self->_set_error_message('HTTP request returned with status '.$res->code);
}

=head2 error_message

Returns the last set error message.

=cut

sub error_message {
    return shift()->{error_message};
}


=head1 AUTHOR

Dominic Sonntag, C<< <dominic at s5g.de> >>

=head1 BUGS AND SUPPORT

Please report any bugs or feature requests on Github: L<https://github.com/sonntagd/SMS-API-CMTelecom/issues>


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of SMS::API::CMTelecom
