
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;
use lib "$FindBin::Bin/blog/lib";

my $buffer = '';
{
  local $ENV{MOJO_LOG_LEVEL} = 'warn';
  open my $handle, '>', \$buffer;
  local *STDERR = $handle;
  require Blog;
  my $blog = Blog->new;
  $blog->startup();
}
like $buffer, qr/"routes" key must point to an ARRAY/,
  'right warning about ARRAY reference';

like $buffer, qr/No routes de.+missing.conf/,
  'right warning about missing definitions';

like $buffer, qr/"routes" key must point to an ARRAY.+AY\.conf/,
  'right warning about ARRAY reference in file';

like $buffer, qr/.+complex.+\.conf.+route initialisation method/ms,
  'right warning about missing route initialisation method';

like $buffer, qr/.+complex.+\.conf.+method "blah" via package/ms,
  'right warning about unknown method';

my $t;
$t = Test::Mojo->new('Blog');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);
$t->get_ok('/posts')->status_is(200)->content_like(qr/post5/);
$t->get_ok('/posts/index')->status_is(200)->content_like(qr/post5/);
$t->post_ok('/posts')->status_is(201)->content_is('');

done_testing();
