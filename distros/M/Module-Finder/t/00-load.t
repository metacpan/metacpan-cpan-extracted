use Test::More tests => 1;

BEGIN {
  use_ok('Module::Finder') or
    BAIL_OUT("Module::Finder failed to load...STOP");
}

diag( "Testing Module::Finder $Module::Finder::VERSION" );

# vi:syntax=perl:ts=2:sw=2:et:sta
