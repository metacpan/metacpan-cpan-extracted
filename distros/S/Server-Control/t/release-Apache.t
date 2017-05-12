#!perl -w

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use Server::Control::t::Apache;
Test::Class::runtests(Server::Control::t::Apache->new);
