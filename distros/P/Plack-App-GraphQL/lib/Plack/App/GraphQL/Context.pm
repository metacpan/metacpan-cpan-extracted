package Plack::App::GraphQL::Context;

use Moo;

has ['request', 'app', 'data'] => (is=>'ro', required=>1);
has log => (is=>'ro', required=>0);

sub req { shift->request }

1;

=head1 NAME
 
Plack::App::GraphQL::Context - The Default Context

=head1 SYNOPSIS
 
    TBD

=head1 DESCRIPTION
 
This is a per request context that is passed to your resolvers in addition
to the root or local value.  Useful if you need to inspect some aspect of
the request.  Subclass or roll your own as needed.  For example you could
have a custom context with a user object for applications with user login
and security.
 
=head1 AUTHOR
 
John Napiorkowski

=head1 SEE ALSO
 
L<Plack::App::GraphQL>
 
=cut
