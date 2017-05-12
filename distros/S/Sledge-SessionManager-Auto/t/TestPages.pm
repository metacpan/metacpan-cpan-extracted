package t::TestPages;
use strict;
use warnings;
use base 'Sledgg::TestPages';
use HTTP::MobileAgent;

BEGIN {
    eval q[use base qw(Sledge::TestPages); use HTTP::MobileAgent;];
    die $@ if $@;
};

sub mobile_agent {
    my $self = shift;
    return $self->{_mobile_agent} ||= HTTP::MobileAgent->new;
}

use Sledge::SessionManager::Auto;
sub create_manager { 
    my $self = shift;
    return Sledge::SessionManager::Auto->new($self);
}

my $x;
$x = $t::TestPages::TEMPLATE_OPTIONS = [];
$x = $t::TestPages::TMPL_PATH = 't/tmpl';
$x = $t::TestPages::COOKIE_NAME = 'sid';
$ENV{HTTP_COOKIE} = 'sid=SID_COOKIE';
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'sid=SID_STICKY_QUERY';

1;
