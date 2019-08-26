# NAME

Net::POP3::XOAuth2 - It enables to use XOAUTH2 authentication with [Net::POP3](https://metacpan.org/pod/Net::POP3)

# SYNOPSIS

    use Net::POP3;
    use Net::POP3::XOAuth2;

    my $user = '<user_id>';
    my $token = '<token from xoauth2>';

    my $pop = Net::POP3->new('pop.gmail.com', Port => 995, Timeout => 30, SSL => 1, Debug => 1);
    $pop->xoauth2($user, $token);

# DESCRIPTION

Net::POP3::XOAuth2 is an extension for [Net::POP3](https://metacpan.org/pod/Net::POP3). This allows you to use SASL XOAUTH2.

# METHODS

- xauth2 ( USER, TOKEN )

    Authenticate with the server identifying as `USER` with OAuth2 access token `TOKEN`.

# LICENSE

Copyright (C) Kizashi Nagata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kizashi Nagata <kizashi1122@gmail.com>
