use Test::More tests => 1;

BEGIN {
    use_ok('Mojolicious::Plugin::LinkedContent');
}

diag("Testing Mojolicious::Plugin::LinkedContent "
      . $Mojolicious::Plugin::LinkedContent::VERSION);
