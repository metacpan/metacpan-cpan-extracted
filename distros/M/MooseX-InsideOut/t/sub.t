use strict;
use warnings;
use Test::More tests => 56;

use lib 't/lib';
my @classes = qw(IO Array Hash Moose);

for my $c (@classes) {
  my $base = "InsideOut::Base$c";
  my $sub  = "InsideOut::Sub$c";
  eval "require $base;1" or die $@;
  eval "require $sub;1" or die $@;

  my $obj = eval { $sub->new(base_foo => 17) };
  is($@, "", "$c: no errors creating object");

  my $get = eval { $obj->base_foo };
  is($@, "", "$c: no errors getting attribute");
  {
    local $TODO = "don't clobber superclass' meta's create_instance"
      if $c eq 'Moose';
    is($get, 17, "$c: base_foo is 17");
  }

  my $set_base = eval {
    $obj->base_foo(18);
    $obj->base_foo;
  };
  is($@, "", "$c: no errors setting base class attribute");
  is($set_base, 18, "$c: base_foo is 18");
  
  my $set_sub = eval {
    $obj->sub_foo(23);
    $obj->sub_foo;
  };
  is($@, "", "$c: no errors setting attribute");
  is($set_sub, 23, "$c: sub_foo is 23");

#  diag MooseX::InsideOut::Meta::Instance->__dump($obj);
#  use Data::Dumper;
#  diag Dumper($obj);

  $sub->meta->make_immutable(
    allow_mutable_ancestors => 1,
    inline_constructor => ($c ne 'Hash' and $c ne 'Array')
  ), redo if $sub->meta->is_mutable;
}
