package OAuthomatic::ServerDef::LinkedIn;
# ABSTRACT: OAuth parameters for LinkedIn

use strict;
use warnings;
use OAuthomatic::Server;


sub server {
    return OAuthomatic::Server->new(
        site_name => 'LinkedIn',

        oauth_temporary_url => 'https://api.linkedin.com/uas/oauth/requestToken',
        oauth_authorize_page => 'https://api.linkedin.com/uas/oauth/authenticate',
        oauth_token_url  => 'https://api.linkedin.com/uas/oauth/accessToken',

        site_client_creation_desc => "LinkedIn DeveloperNetwork",
        site_client_creation_page => 'https://www.linkedin.com/secure/developer',
        site_client_creation_help => <<"END",
Choose Add New Application and fill the form. 
Use <Consumer Key> as client key and <Consumer Secret> as client secret.
(note: DO NOT use <OAuth 1.0 User Token/Secret>, it does not work).
END
    );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::ServerDef::LinkedIn - OAuth parameters for LinkedIn

=head1 VERSION

version 0.0202

=head1 DESCRIPTION

Definition of L<OAuthomatic::Server> for L<http://linkedin.com>. Allows
one to specify C<server =E<gt> 'LinkedIn'> while constructing L<OAuthomatic> objects.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
