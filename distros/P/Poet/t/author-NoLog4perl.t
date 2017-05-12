#!perl -w

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use Poet::t::NoLog4perl;
use Poet::Module::Mask;
my $mask = new Poet::Module::Mask('Log::Log4perl');
Poet::t::NoLog4perl->runtests;
