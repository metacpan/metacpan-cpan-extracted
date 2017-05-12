package OAuthomatic::ServerDef::BitBucket;
# ABSTRACT: OAuth parameters for BitBucket

use strict;
use warnings;
use OAuthomatic::Server;


sub server {
    return OAuthomatic::Server->new(
        oauth_temporary_url => 'https://bitbucket.org/api/1.0/oauth/request_token',
        oauth_authorize_page => 'https://bitbucket.org/api/1.0/oauth/authenticate',
        oauth_token_url  => 'https://bitbucket.org/api/1.0/oauth/access_token',

        site_name => 'BitBucket',
        site_client_creation_desc => "BitBucket OAuth management page",
        # No simple URL
        # site_client_creation_page => https://bitbucket.org/account/user/YOUR-BITBUCKET-NICK/api
        site_client_creation_help => <<"END",
Log into BitBucket.  Select <Manage accont> (from the popup on your
avatar in right-top corner), then <OAuth> (Access Management section
in the left menu).  Click <Add consumer> button and fill the form. Use
<Key> as client key and <Secret> as client secret.",
END
       );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::ServerDef::BitBucket - OAuth parameters for BitBucket

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

Definition of L<OAuthomatic::Server> for L<http://bitbucket.org>. Allows
one to specify C<server =E<gt> 'BitBucket'> while constructing L<OAuthomatic> objects.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
