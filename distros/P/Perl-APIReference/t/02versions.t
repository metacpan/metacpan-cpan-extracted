use strict;
use warnings;
use Perl::APIReference;

my @Perls;
BEGIN {
  @Perls = sort keys %Perl::APIReference::Perls;
}

use Test::More tests => scalar( @Perls ) * 2;

foreach my $version (@Perls) {
  my $err;
  my $obj;
  ok(
    eval {
      $obj = Perl::APIReference->new( perl_version => $version );
      1;
    } || do {$err = $@||'Zombie Error'; 0},
    $version
  )
  or warn "Caught exception: $err";

  ok($obj->index->{newRV_inc}, "Version $version has docs on newRV_inc");
}
