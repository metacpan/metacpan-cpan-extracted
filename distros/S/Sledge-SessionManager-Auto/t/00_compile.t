use strict;
use Test::More;

BEGIN {
    eval q[use Sledge::SessionManager::Cookie; use Sledge::SessionManager::StickyQuery; use Sledge::SessionManager::MobileID;];
    plan skip_all => "Sledge::TestPages required for testing base" if $@;
    plan tests => 1;
    use_ok 'Sledge::SessionManager::Auto';
}
