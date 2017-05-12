use strict;
use warnings;
package TestMexp;

use Sub::Exporter::ForMethods qw(method_installer);
use Sub::Exporter -setup => {
  exports   => [ qw(foo blessed_method) ],
  installer => method_installer,
};

use Carp ();

sub foo {
  my ($self, @arg) = @_;

  Carp::longmess("$self -> foo ( @_ )");
}

BEGIN {
  my $sub = sub { };
  bless $sub, __PACKAGE__;
  *blessed_method = $sub;
}

1;
