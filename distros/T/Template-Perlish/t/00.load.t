use Test::More tests => 1;

BEGIN {
   use_ok('Template::Perlish') or BAIL_OUT('does not compile');
}

diag("Testing Template::Perlish $Template::Perlish::VERSION");
