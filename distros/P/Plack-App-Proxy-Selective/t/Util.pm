use warnings;
use strict;

package t::Util;
our @EXPORT = qw/test_app_dir/;
use base qw/Exporter/;

use File::Temp qw/tempdir/;
use Plack::App::Directory;
use Plack::App::Proxy::Test;
use Path::Class;

sub test_app_dir {
  my ($code, $proxy) = @_;

  my $app_dir = Plack::App::Directory->new(+{ root => file(__FILE__)->dir });
  warn file(__FILE__)->dir;

  test_proxy(
    app => $app_dir,
    proxy => sub { $proxy },
    client => sub {
      $code->(shift);
    }
  );
}

1;
