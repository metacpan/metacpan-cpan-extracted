package SMS::Send::Mocean;

use 5.008_005;
use strict;
use warnings;
use utf8;

use Carp;
use HTTP::Request::Common qw(POST);
use JSON qw(decode_json);
use LWP::UserAgent;
use URL::Encode qw(url_decode);
use XML::Hash::LX qw(xml2hash);

use base 'SMS::Send::Driver';

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my $args = { @_ };

    _required($args, qw(_api_key _api_secret));

    my $opts = {
        _endpoint => 'https://rest.moceanapi.com/rest/1/sms',
        %{$args}
    };

    my $self = bless $opts, $class;

    $self->{ua} = LWP::UserAgent->new(
        agent => __PACKAGE__ . q| v| . $SMS::Send::Mocean::VERSION,
        timeout => 10,
    );

    return $self;
}

sub send_sms {
    my $self = shift;
    my $args = { @_ };

    _required($args, qw(to text _from));

    my @extra_args = qw(
        _udh
        _coding
        _dlr_mask
        _dlr_url
        _schedule
        _mclass
        _alt_dcs
        _charset
        _validity
        _resp_format
    );

    my @extra_params;
    foreach (@extra_args) {
        push @extra_params, _to_mocean_field_name($_) => $args->{$_}
            if (defined $args->{$_});
    }

    my $request = POST($self->{_endpoint}, [
        'mocean-api-key' => $self->{_api_key},
        'mocean-api-secret' => $self->{_api_secret},
        'mocean-to' => $args->{to},
        'mocean-text' => $args->{text},
        'mocean-from' => $args->{_from},
        @extra_params
    ]);

    my $format = defined $args->{_resp_format} && lc($args->{_resp_format}) eq 'json'
        ? 'json' : 'xml';

    my $response = $self->{ua}->request($request);

    if ($response->is_success) {
        my $content = ($format eq 'json')
            ? decode_json($response->decoded_content)
            : xml2hash $response->decoded_content;

        return $content->{result}->{message};
    }
    else {
        my ($error_code, $error_msg) = ('', '');

        if ($format eq 'json') {
            my $content = decode_json($response->decoded_content);
            $error_code = $content->{status};
            $error_msg = url_decode($content->{err_msg});
        }
        else {
            my $content = xml2hash $response->decoded_content;
            $error_code = $content->{result}->{status};
            $error_msg = url_decode($content->{result}->{err_msg});
        }

        croak sprintf "\n%s (error code: %d)", $error_msg, $error_code;
    }
}

sub _required {
    my ($args, @required_args) = @_;

    foreach (@required_args) {
        croak "'$_' parameter required" unless $args->{$_}
    }
    return;
}

sub _to_mocean_field_name {
    my ($name) = @_;

    $name =~ tr/_/-/;

    return qq|mocean$name|;
}


1;
__END__

=encoding utf-8

=for stopwords mocean sms

=head1 NAME

SMS::Send::Mocean - SMS::Send driver to send messages via Mocean,
https://moceanapi.com/.

=head1 SYNOPSIS

    use SMS::Send;

    my $gateway = SMS::Send->new(
        'Mocean',
        '_api_key' => 'foo',
        '_api_secret' => 'bar'
    );

    $gateway->send_sms(
        to => '+60123456789',
        ext => 'Hello',
        _from => 'foobar'
    );

=head1 DESCRIPTION

SMS::Send::Mocean is a driver for L<SMS::Send|SMS::Send> to send message via Mocean,
https://moceanapi.com/.

=head1 DEVELOPMENT

Source repository at L<https://github.com/kianmeng/send-sms-mocean|https://github.com/kianmeng/sms-send-mocean>.

How to contribute? Follow through the L<CONTRIBUTING.md|https://github.com/kianmeng/sms-send-mocean/blob/master/CONTRIBUTING.md> document to setup your development environment.

=head1 METHODS

=head2 new(_api_key, _api_secret)

Construct a new SMS::Send instance.

    my $gateway = SMS::Send->new(
        'Mocean',
        '_api_key' => 'foo',
        '_api_secret' => 'bar'
    );

=head3 _api_key

Compulsory. The API access key used to make request through web service.

=head3 _api_secret

Compulsory. The API secret key.

=head2 send_sms(to, text, _from, [%params])

Send the SMS text to a mobile user.

    # Default parameters with XML response format if the '_resp_format' field
    # is not defined.
    $gateway->send_sms(
        to => '+60123456789',
        ext => 'Hello',
        _from => 'foobar',
    );

    # With JSON response format.
    $gateway->send_sms(
        to => '+60123456789',
        ext => 'Hello',
        _from => 'foobar',
        _resp_format => 'json',
    );

=head3 to

Compulsory. The required field needed by SMS::Send. Only accept leading-plus
number in the format of "+99 999 9999".

=head3 text

Compulsory. The required field needed by SMS::Send. The content of the SMS
message. Depends on the language of the content, there is a limit of characters
that can be sent.

=head3 _from

Compulsory. The login username of the Mocean API portal.

=head3 [%params]

Optional. Additional parameters that can be used when sending SMS. Check the
Mocean API documentation on the L<available parameters|https://moceanapi.com/docs/#sms-api>.
Due to the design constraints of L<SMS::Send::Driver|SMS::Send::Driver>, all
parameters name must start with underscore. For example, '_resp_format'. This
driver will convert the parameter name to equivalent format used by Mocean. In
this case, '_foo_bar' will be formatted as 'mocean-resp-format'.

    $gateway->send_sms(
        to => '+60123456789',
        ext => 'Hello',
        _from => 'foobar',
        _resp_format => 'json',
        _charset => 'utf-8',
    );

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<SMS::Driver|SMS::Driver>
