package MyApp::Pages;
use strict;
use Sledge::Pages::Compat;

use Sledge::Authorizer::Null;
use Sledge::Charset::Default;
use Sledge::SessionManager::Cookie;
use Sledge::Session::File;
use Sledge::Template::TT;
use Sledge::Constants;
use URI;

use MyApp::Config;

sub create_authorizer {
    my $self = shift;
    return Sledge::Authorizer::Null->new($self);
}

sub create_charset {
    my $self = shift;
    return Sledge::Charset::Default->new($self);
}

sub create_config {
    my $self = shift;
    return MyApp::Config->instance;
}

sub create_manager {
    my $self = shift;
    return Sledge::SessionManager::Cookie->new($self);
}

sub create_session {
    my($self, $sid) = @_;
    return Sledge::Session::File->new($self, $sid);
}

1;
