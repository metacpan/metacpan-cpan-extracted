use Test::More;

my $TEMPLATE = <<'EOF';
package %s;
use Moo;
use MooX::StrictHas;
has attr => (is => 'ro', %s);
EOF

package main;

my $pkg = 'MyMod00';
sub test_with_attr {
  my ($attr, $expected) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  local $@;
  eval sprintf $TEMPLATE, ++$pkg, $attr;
  like $@, $expected, $attr;
  return if $@; # blew up, stop
  my $obj = eval { $pkg->new(attr => 1) };
  is $@, '', "'$attr': instantiated Ok";
  eval { $obj->attr };
  is $@, '', "'$attr': accessor Ok";
}

test_with_attr('', qr/^$/);
test_with_attr('auto_deref => 1', qr/auto_deref/);
test_with_attr('lazy_build => 1', qr/lazy_build/);
test_with_attr('auto_deref => 1, lazy_build => 1', qr/auto_deref.*lazy_build/s);

done_testing;
