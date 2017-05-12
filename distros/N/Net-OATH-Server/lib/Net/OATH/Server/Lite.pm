package Net::OATH::Server::Lite;
use strict;
use warnings;

1;
__END__

=encoding utf-8

=head1 NAME

Net::OATH::Server::Lite - Library for One Time Password Server

=head1 DESCRIPTION

For internal use, "Lite" module provides functions of user authentication and Create/Read/Update/Delete APIs on HTTP.
As a PSGI Application, you are able to implement two endpoints easily.

User's CRUD : L<Net::OATH::Server::Lite::Endpoint::User>
Authentication : L<Net::OATH::Server::Lite::Endpoint::Login>

=head3 DataHandler

To use these endpoints, you must inherit L<Net::OATH::Server::Lite::DataHandler> and implement the methods according to the interface contract.

    package YourDataHandler;

    use strict;
    use warnings;

    use parent 'Net::OATH::Server::Lite::DataHandler';

    # defined method
    sub create_id {
        my $class = shift;
        # ...
    }

    sub create_secret {
        my $class = shift;
        # ...
    }

    sub insert_user {
        my ($self, $user) = @_;
        # ...
    }

    # ...

=head3 Example psgi file

    use strict;
    use utf8;
    use lib 'lib';
    use Plack::Builder;

    use Net::OATH::Server::Lite::Endpoint::Login;
    use Net::OATH::Server::Lite::Endpoint::User;
    use YourDataHandler;

    # login endpoint
    my $login_endpoint = Net::OATH::Server::Lite::Endpoint::Login->new(
        data_handler => q{YourDataHandler}, 
    );

    # user endpoint
    my $user_endpoint = Net::OATH::Server::Lite::Endpoint::User->new(
        data_handler => q{YourDataHandler}, 
    );

    builder {
        mount "/login" => $login_endpoint;
        mount "/user" => $user_endpoint;
    };

=head3 Request and Response

    # Create user
    ## request
    POST /user HTTP/1.1
    Host: localhost
    Content-Type: application/json

    {
     "method":"create"
    }

    ## response
    HTTP/1.1 201 Created
    Content-Type: application/json;charset=UTF-8
    Cache-Control: no-store
    Pragma: no-cache
    {
     "id":"81c8feb9b54f632823fafea71966b5f89ad5cc92",
     "secret":"wtfb32iamxqbewsmg7vg3ifdtcr3ky3t",
     "type":"totp",
     "algorithm":"SHA1",
     "digits":6,
     "counter":0,
     "period":30
    }

    # Read user
    ## request
    POST /user HTTP/1.1
    Host: localhost
    Content-Type: application/json

    {
     "method":"read",
     "id":"81c8feb9b54f632823fafea71966b5f89ad5cc92"
    }

    ## response
    HTTP/1.1 200 OK
    Content-Type: application/json;charset=UTF-8
    Cache-Control: no-store
    Pragma: no-cache
    {
     "id":"81c8feb9b54f632823fafea71966b5f89ad5cc92",
     "secret":"wtfb32iamxqbewsmg7vg3ifdtcr3ky3t",
     "type":"totp",
     "algorithm":"SHA1",
     "digits":6,
     "counter":0,
     "period":30
    }

    # Update User
    ## request
    POST /user HTTP/1.1
    Host: localhost
    Content-Type: application/json

    {
     "method":"update",
     "id":"81c8feb9b54f632823fafea71966b5f89ad5cc92",
     "type":"hotp"
    }

    ## response
    HTTP/1.1 200 OK
    Content-Type: application/json;charset=UTF-8
    Cache-Control: no-store
    Pragma: no-cache
    {
     "id":"81c8feb9b54f632823fafea71966b5f89ad5cc92",
     "secret":"wtfb32iamxqbewsmg7vg3ifdtcr3ky3t",
     "type":"hotp",
     "algorithm":"SHA1",
     "digits":6,
     "counter":0,
     "period":30
    }

    # Delete User
    ## request
    POST /user HTTP/1.1
    Host: localhost
    Content-Type: application/json

    {
     "method":"delete",
     "id":"81c8feb9b54f632823fafea71966b5f89ad5cc92"
    }

    ## response
    HTTP/1.1 200 OK
    Content-Type: application/json;charset=UTF-8
    Cache-Control: no-store
    Pragma: no-cache
    {}

    # Authentication
    ## request
    POST /login HTTP/1.1
    Host: localhost
    Content-Type: application/json

    {
     "id":"81c8feb9b54f632823fafea71966b5f89ad5cc92",
     "password":"000000"
    }

    ## response
    HTTP/1.1 200 OK
    Content-Type: application/json;charset=UTF-8
    Cache-Control: no-store
    Pragma: no-cache
    {"id":"81c8feb9b54f632823fafea71966b5f89ad5cc92"}


=head1 LICENSE

Copyright (C) ritou.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ritou E<lt>ritou.06@gmail.comE<gt>

=cut

