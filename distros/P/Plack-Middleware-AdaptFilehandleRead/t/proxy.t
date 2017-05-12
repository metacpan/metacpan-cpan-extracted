use Test::Most;
use IO::File;
use Plack::Middleware::AdaptFilehandleRead::Proxy;

## In this test was are testing the proxy object directly

ok my $lines = q{
some lines
with newlines!
Isn't 
it
cool?


} x 1000;

{
  ## In this test we leave $/ to the default /n

  ok my $fh = IO::File->new;
  ok open($fh, '<', \$lines)
    || die "Can't create filehandle for testing, you are doomed";

  ok my $proxy = Plack::Middleware::AdaptFilehandleRead::Proxy->new($fh);

  my $line;
  while(my $buff = $proxy->getline) {
    $line .= $buff
  }

  is $line, $lines;
}

{
  ## In this test we set $/ to fixed chunk lenths of 2 characters
  ok my $fh = IO::File->new;
  ok open($fh, '<', \$lines)
    || die "Can't create filehandle for testing, you are doomed";

  ok my $proxy = Plack::Middleware::AdaptFilehandleRead::Proxy->new($fh);

  local $/ = \"2";
  my $line;
  while(my $buff = $proxy->getline) {
    $line .= $buff
  }

  is $line, $lines;
}

done_testing;
