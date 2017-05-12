package RPC::ExtDirect::Server::Patch::HTTPServerSimple;

use strict;
use warnings;
no  warnings 'redefine';

# This monkey patching is required for HTTP::Server::Simple <= 0.51;
# CGI.pm < 3.36 does not support HTTP_COOKIE environment variable with
# multiple values separated by commas instead of semicolons.
#
# The code is copied from HTTP::Server::Simple::CGI::Environment,
# with a fix applied.

use HTTP::Server::Simple::CGI::Environment;

sub HTTP::Server::Simple::CGI::Environment::header {
    my $self  = shift;
    my $tag   = shift;
    my $value = shift;

    $tag = uc($tag);
    $tag =~ s/^COOKIES$/COOKIE/;
    $tag =~ s/-/_/g;
    $tag = "HTTP_" . $tag
        unless $tag =~ m/^CONTENT_(?:LENGTH|TYPE)$/;

    if ( exists $ENV{$tag} ) {
        # This line is fixed
        $ENV{$tag} .= $tag eq 'HTTP_COOKIE' ? "; $value" : ", $value";
    }
    else {
        $ENV{$tag} = $value;
    }
}

1;

