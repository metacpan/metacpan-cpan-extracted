# NAME

SMS::Send::Kannel::SMSbox - SMS::Send driver for Kannel SMSbox web service

# SYNOPSIS

Using [SMS::Send](https://metacpan.org/pod/SMS::Send) Driver API

    SMS-Send.ini
    [Kannel::SMSbox]
    host=mykannelserver
    username=myuser
    password=mypass

    use SMS::Send;
    my $service = SMS::Send->new('Kannel::SMSbox');
    my $success = $service->send_sms(
                                     to   => '+1-800-555-0000',
                                     text => 'Hello World!',
                                    );

# DESCRIPTION

SMS::Send driver for Kannel SMSbox web service.

# USAGE

    use SMS::Send::Kannel::SMSbox;
    my $service = SMS::Send::Kannel::SMSbox->new(
                                         username => $username,
                                         password => $password,
                                         host     => $host,
                                        );
    my $success = $service->send_sms(
                                     to   => '+18005550000',
                                     text => 'Hello World!',
                                    );

# METHODS

## send\_sms

Sends the SMS message and returns 1 for success and 0 for failure or die on critical error.

# PROPERTIES

## username

Sets and returns the username string value

Override in sub class

    sub _username_default {"myusername"};

Override in configuration

    [Kannel::SMSbox]
    username=myusername

## password

Sets and returns the password string value

Override in sub class

    sub _password_default {"mypassword"};

Override in configuration

    [Kannel::SMSbox]
    password=mypassword

## host

Default: 127.0.0.1

Override in sub class

    sub _host_default {"myhost.domain.tld"};

Override in configuration

    [Kannel::SMSbox]
    host=myhost.domain.tld

## protocol

Default: http

Override in sub class

    sub _protocol_default {"https"};

Override in configuration

    [Kannel::SMSbox]
    protocol=https

## port

Default: 13013

Override in sub class

    sub _port_default {443};

Override in configuration

    [Kannel::SMSbox]
    port=443

## script\_name

Default: /cgi-bin/sendsms

Override in sub class

    sub _script_name_default {"/path/file"};

Override in configuration

    [Kannel::SMSbox]
    script_name=/path/file

## url

Returns a [URI](https://metacpan.org/pod/URI) object based on above properties

## warnings

Default: 0

Override in sub class

    sub _warnings_default {1};

Override in configuration

    [Kannel::SMSbox]
    warnings=1

## debug

Default: 0

Override in sub class

    sub _debug_default {5};

Override in configuration

    [Kannel::SMSbox]
    debug=5

# BUGS

# SUPPORT

# AUTHOR

    Michael R. Davis

# COPYRIGHT and LICENSE

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

# SEE ALSO

[SMS::Send](https://metacpan.org/pod/SMS::Send), [SMS::Send::Driver::WebService](https://metacpan.org/pod/SMS::Send::Driver::WebService)
