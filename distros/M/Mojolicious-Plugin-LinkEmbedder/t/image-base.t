use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$t->get_ok('/embed?url=http://catoverflow.com/cats/r4cIt4z.gif')
  ->element_exists('img[src="http://catoverflow.com/cats/r4cIt4z.gif"][alt="http://catoverflow.com/cats/r4cIt4z.gif"]');

$t->get_ok('/embed?url=https://gravatar.com/avatar/806800a3aeddbad6af673dade958933b')->element_exists('img')
  ->element_exists(
  'img[src="https://gravatar.com/avatar/806800a3aeddbad6af673dade958933b"][alt="https://gravatar.com/avatar/806800a3aeddbad6af673dade958933b"]'
  );

done_testing;
