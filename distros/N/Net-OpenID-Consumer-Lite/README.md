# NAME

Net::OpenID::Consumer::Lite - OpenID consumer library for minimalist

# SYNOPSIS

    use Net::OpenID::Consumer::Lite;
    my $csr = Net::OpenID::Consumer::Lite->new();

    # get check url
    my $check_url = Net::OpenID::Consumer::Lite->check_url(
        'https://mixi.jp/openid_server.pl',   # OpenID server url
        'http://example.com/back_to_here',    # return url
        {
            "http://openid.net/extensions/sreg/1.1" => { required => join( ",", qw/email nickname/ ) }
        }, # extensions(optional)
    );

    # handle response of OP
    Net::OpenID::Consumer::Lite->handle_server_response(
        $request => (
            not_openid => sub {
                die "Not an OpenID message";
            },
            setup_required => sub {
                my $setup_url = shift;
                # Redirect the user to $setup_url
            },
            cancelled => sub {
                # Do something appropriate when the user hits "cancel" at the OP
            },
            verified => sub {
                my $vident = shift;
                # Do something with the VerifiedIdentity object $vident
            },
            error => sub {
                my $err = shift;
                die($err);
            },
        )
    );

# DESCRIPTION

Net::OpenID::Consumer::Lite is limited version of OpenID consumer library.
This module works fast.This module works well on rental server/CGI.

This module depend to [LWP::UserAgent](http://search.cpan.org/perldoc?LWP::UserAgent), ([Net::SSL](http://search.cpan.org/perldoc?Net::SSL)|[IO::Socket::SSL](http://search.cpan.org/perldoc?IO::Socket::SSL)) and [URI](http://search.cpan.org/perldoc?URI).
This module doesn't depend to [Crypt::DH](http://search.cpan.org/perldoc?Crypt::DH)!!

# LIMITATION

    This module supports SSL OPs only.
    This module doesn't care the XRDS Location. Please pass me the real OpenID server path.
    This module doesn't supports XRI.
    This module doesn't supports Endpoind discovery.
    This module doesn't supports association for signature validation.

# How to solve SSL Certifications Error

If [Crypt::SSLeay](http://search.cpan.org/perldoc?Crypt::SSLeay) or [Net::SSLeay](http://search.cpan.org/perldoc?Net::SSLeay) says "Peer certificate not verified" or other error messages,
please see the manual of your SSL libraries =) This is SSL library's problem.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

# SEE ALSO

[Net::OpenID::Consumer](http://search.cpan.org/perldoc?Net::OpenID::Consumer)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
