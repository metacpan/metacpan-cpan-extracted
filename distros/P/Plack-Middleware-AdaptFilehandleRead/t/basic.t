use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use IO::File;
use Plack::Middleware::AdaptFilehandleRead;
use Scalar::Util ();

ok my $lines = q{
some lines
with newlines!
Isn't 
it
cool?


} x 10000;

ok my $fh = IO::File->new;
ok open($fh, '<', \$lines)
  || die "Can't create filehandle for testing, you are doomed";

ok Scalar::Util::blessed($fh);

ok my $app = sub { return [ 200, [], $fh ] };
ok my $wrapped = Plack::Middleware::AdaptFilehandleRead->wrap($app, always_adapt=>1);

test_psgi $wrapped, sub {
  my $cb  = shift;
  my $res = $cb->(GET "/");
  is $res->content, $lines;
};

done_testing;


