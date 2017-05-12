[![Build Status](https://travis-ci.org/xaicron/p5-Net-APNs-Extended.svg?branch=master)](https://travis-ci.org/xaicron/p5-Net-APNs-Extended)
# NAME

Net::APNs::Extended - Client library for APNs that support the extended format.

# SYNOPSIS

    use Net::APNs::Extended;

    my $apns = Net::APNs::Extended->new(
        is_sandbox => 1,
        cert_file  => 'apns.pem',
    );

    # send notification to APNs
    $apns->send($device_token, {
        aps => {
            alert => "Hello, APNs!",
            badge => 1,
            sound => "default",
        },
        foo => [qw/bar baz/],
    });

    # if you want to handle the error
    if (my $error = $apns->retrieve_error) {
        die Dumper $error;
    }

# DESCRIPTION

Net::APNs::Extended is client library for APNs. The client is support the extended format.

# METHODS

## new(%args)

Create a new instance of `Net::APNs::Extended`.

Supported arguments are:

- is\_sandbox : Bool

    Default: 1

- cert\_file : Str
- cert : Str

    Required.

    Sets certificate. You can not specify both `cert` and `cert_file`.

- key\_file : Str
- key : Str

    Sets private key. You can not specify both `key` and `key_file`.

- password : Str

    Sets private key password.

- read\_timeout : Num

    Sets read timeout.

- write\_timeout : Num

    Sets write timeout.

## $apns->send($device\_token, $payload \[, $extra \])

Send notification for APNs.

    $apns->send($device_token, {
        aps => {
            alert => "Hello, APNs!",
            badge => 1,
            sound => "default",
        },
        foo => [qw/bar baz/],
    });

## $apns->send\_multi(\[ \[ $device\_token, $payload \[, $extra \] \], \[ ... \] ... \])

Send notification for each data. The data chunk is same as `send()` arguments.

## $apns->retrieve\_error()

Gets error data from APNs. If there is no error will not return anything.

    if (my $error = $apns->retrieve_error) {
        die Dumper $error;
    }

# AUTHOR

xaicron &lt;xaicron {@} cpan.org>

# COPYRIGHT

Copyright 2012 - xaicron

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
