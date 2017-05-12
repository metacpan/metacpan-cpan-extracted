package t::TestPages;
use strict;
use warnings;
use base 'Sledgg::TestPages';

BEGIN {
    eval q[use base qw(Sledge::TestPages)];
    die $@ if $@;
};

use Sledge::SessionManager::MobileID;
sub create_manager { 
    my $self = shift;
    return Sledge::SessionManager::MobileID->new($self);
}

my $x;
$x = $t::TestPages::TEMPLATE_OPTIONS = [];
$x = $t::TestPages::TMPL_PATH = 't/tmpl';
$ENV{REQUEST_METHOD} = 'GET';

1;
