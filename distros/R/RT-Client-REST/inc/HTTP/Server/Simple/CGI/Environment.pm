#line 1

package HTTP::Server::Simple::CGI::Environment;

use strict;
use warnings;
use HTTP::Server::Simple;

use vars qw(%ENV_MAPPING);

my %clean_env = %ENV;

#line 29

sub setup_environment {
    %ENV = (
        %clean_env,
        SERVER_SOFTWARE   => "HTTP::Server::Simple/$HTTP::Server::Simple::VERSION",
        GATEWAY_INTERFACE => 'CGI/1.1'
    );
}

#line 43

sub setup_server_url {
    $ENV{SERVER_URL}
        ||= ( "http://" . ($ENV{SERVER_NAME} || 'localhost') . ":" . ( $ENV{SERVER_PORT}||80) . "/" );
}

#line 57

%ENV_MAPPING = (
    protocol     => "SERVER_PROTOCOL",
    localport    => "SERVER_PORT",
    localname    => "SERVER_NAME",
    path         => "PATH_INFO",
    request_uri  => "REQUEST_URI",
    method       => "REQUEST_METHOD",
    peeraddr     => "REMOTE_ADDR",
    peername     => "REMOTE_HOST",
    peerport     => "REMOTE_PORT",
    query_string => "QUERY_STRING",
);

sub setup_environment_from_metadata {
    no warnings 'uninitialized';
    my $self = shift;

    # XXX TODO: rather than clone functionality from the base class,
    # we should call super
    #
    while ( my ( $item, $value ) = splice @_, 0, 2 ) {
        if ( my $k = $ENV_MAPPING{$item} ) {
            $ENV{$k} = $value;
        }
    }

    # Apache and lighttpd both do one layer of unescaping on
    # path_info; we should duplicate that.
    $ENV{PATH_INFO} =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
}

#line 94

sub header {
    my $self  = shift;
    my $tag   = shift;
    my $value = shift;

    $tag = uc($tag);
    $tag =~ s/^COOKIES$/COOKIE/;
    $tag =~ s/-/_/g;
    $tag = "HTTP_" . $tag
        unless $tag =~ m/^CONTENT_(?:LENGTH|TYPE)$/;

    if ( exists $ENV{$tag} ) {
        $ENV{$tag} .= $tag eq 'HTTP_COOKIE' ? "; $value" : ", $value";
    }
    else {
        $ENV{$tag} = $value;
    }
}

1;
