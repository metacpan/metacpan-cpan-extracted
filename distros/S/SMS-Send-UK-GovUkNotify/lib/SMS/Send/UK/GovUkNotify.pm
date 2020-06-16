package SMS::Send::UK::GovUkNotify;

use warnings;
use strict;
use Carp;

=head1 NAME

SMS::Send::UK::GovUkNotify

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    # Instantiate a sender object
    my $sender = SMS::Send->new(
        'UK::GovUkNotify',
        _template_id => 'template_id',
        _key => 'key'
    );

    # Send a message
    my $sent = $sender->send_sms(
        to           => '0000000000' # In the format: +447312345679,
        text         => 'Dummy text'
    );

=head1 DESCRIPTION

L<SMS::Send::UK::GovUkNotify> is a L<SMS::Send> driver that provides
SMS message sending via the Gov.Uk Notify service.

Usage of this module requires the definition of a template with a single
placeholder ((text)) - the content of the text message sent will be
substituted in place of the placeholder

=head2 CAVEATS

You need a Gov.Uk Notify account in order to use this driver

=head1 METHODS

=cut

use base 'SMS::Send::Driver';
use LWP::UserAgent();
use JSON qw(encode_json);
use URI::Escape qw(uri_escape);
use Scalar::Util qw( looks_like_number );
use Crypt::JWT qw(encode_jwt);

=head2 new

    # Instantiate a sender object
    my $sender = SMS::Send->new(
        'UK::GovUkNotify',
        _key => 'key'
    );

The C<new> constructor accepts one parameter, which is required

The return value is a C<SMS::Send::UK::GovUkNotify> object.

=over 4

=item 'UK::GovUkNotify'

The parameter identifying the driver name

=item _key

The C<_key> parameter is the full API key, as supplied by Gov.Uk Notify
https://docs.notifications.service.gov.uk/rest-api.html#api-keys

=item _template_id

The C<_template_id> parameter as supplied by Gov.Uk Notify
https://docs.notifications.service.gov.uk/rest-api.html#template-id-required

=back

=cut

sub new {
    my $class = shift;
    my %params = @_;

    # Ensure we've been passed the parameters we're expecting
    my @expected = ( '_key', '_template_id' );
    foreach my $expect(@expected) {
        if (!exists $params{$expect}) {
            croak join(', ', @expected) . ' parameters must be supplied';
        }
    }

    # Extract the components we need to create the JWT
    my ($iss, $key) = $params{_key} =~ /^.+?-(.{36})-(.+)$/;
    my $iat = time();
    my $payload = {
        iss => $iss,
        iat => $iat
    };

    # Encode the JWT
    my $token = encode_jwt(payload => $payload, alg => 'HS256', key => $key);

    # Instantiate the object
    my $self = bless {
        token       => $token,
        template_id => $params{_template_id},
        base_url    => 'https://api.notifications.service.gov.uk'
    }, $class;

    return $self;
}

=head2 clean_to

    # Examine a passed phone number and attempt to return the number
    # in a format supported by the API,
    # croak if a conversion is not possible
    my $intl_number = clean_to($source_number);

The C<clean_to> method accepts a single required parameter:

The return value is the number in international format

=over 4

=item source_number

A string containing the number to be cleaned

=back

=cut

sub clean_number {
    my $source_number = shift;

    # The number may already be in the format we want
    if ($source_number =~ /^\+44/) {
        return $source_number;
    }
    # Replace a leading 44 with +44
    elsif ($source_number =~ /^44/) {
        $source_number =~ s/^44/+44/;
        return $source_number;
    }
    # Replace a leading 0 with +44
    elsif ($source_number =~ /^0/) {
        $source_number =~ s/^0/+44/;
        return $source_number;
    }
    # We can't do anything with this number
    else {
        croak 'Unrecognised number format: ' . $source_number;
    }
}

=head2 send_sms

    # Send a message
    my $sent = $sender->send_sms(
        text => 'dummy_text'
        to   => '0000000000' # In the format: +447312345679
    );

The C<send_sms> method accepts two parameters, both of which are required.

The return value is a 0 or 1 representing false or true, indicating whether
the send was successful.

=over 4

=item text

Although this is a required parameter by Send::SMS, we don't actually use it.
The Gov.Uk Notify service uses a template ID (which is passed in our
constructor) and placeholder values. So we just silently ignore what was
passed in 'text'

=item to

A numeric string representing the phone number of the recipient, in a valid
international format (i.e. country code followed by the number)

=back

=cut

sub send_sms {
    my $self = shift;
    my %params = @_;

    # Ensure we've been passed the parameters we're expecting
    my @expected = ('to', 'text');
    foreach my $expect(@expected) {
        if (!exists $params{$expect}) {
            croak join(', ', @expected) . ' parameters must be supplied';
        }
    }

    my $ua = LWP::UserAgent->new;
    my $to = clean_number($params{to});

    # Send the request
    my $body = encode_json({
        phone_number => $to,
        template_id  => $self->{template_id},
        personalisation => {
            text => $params{text}
        }
    });

    my $response = $ua->post(
        $self->{'base_url'} . '/v2/notifications/sms',
        'Content-Type' => 'application/json',
        Authorization  => 'Bearer ' . $self->{'token'},
        Content        => $body
    );

    # Check the send succeded
    if (!$response->is_success()) {
        croak('API request failed: ' . $response->status_line());
        return 0;
    }

    return 1;
}

=head1 AUTHOR

Andrew Isherwood C<< <andrew.isherwood at ptfs-europe.com> >>

=head1 BUGS

Please report any bugs or features to C<andrew.isherwood at ptfs-europe.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc SMS::Send::UK::GovUkNotify

=head1 COPYRIGHT & LICENSE

Copyright (C) 2020 PTFS Europe L<https://www.ptfs-europe.com/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself
 
Additionally, you are again reminded that this software comes with
no warranty of any kind, including but not limited to the implied
warranty of merchantability.
  
ANY use may result in charges on your Gov.Uk Notify bill, and you should
use this software with care. The author takes no responsibility for
any such charges accrued.

=head1 ACKNOWLEDGEMENTS

Many thanks to the authors of the following modules that served as
inspiration for this one:

=over 4

=item SMS::Send::US::TMobile


=item SMS::Send::US::Ipipi


=item SMS::Send::UK::Kapow

=back

=cut

1; # End of SMS::Send::UK::GovUkNotify

