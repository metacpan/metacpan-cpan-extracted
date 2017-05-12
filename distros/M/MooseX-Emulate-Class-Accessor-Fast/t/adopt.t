#!perl
use strict;
use lib 't/lib';
use Test::More tests => 13;

#1,2
require_ok("MooseX::Adopt::Class::Accessor::Fast");
use_ok('TestAdoptCAF');

#3-6
ok(TestAdoptCAF->can('meta'), 'Adopt seems to work');
ok(TestAdoptCAF->meta->find_attribute_by_name($_), "attribute $_ created")
  for qw(foo bar baz);

{
  my $ok = eval {
    local $SIG{__WARN__} = sub { 
      die "Warning generated when new was called with no arguments: " . 
        join("; ", @_);
    };
    TestAdoptCAF->new(());
  };
  ok( ref($ok), ref($ok) ? "no warnings when instantiating object" : $@);
}
#7-9
my $t = TestAdoptCAF->new(foo => 100, bar => 200, groditi => 300);
is($t->{foo},     100, '$self->{foo} set');
is($t->{bar},     200, '$self->{bar} set');
is($t->{groditi}, 300, '$self->{groditi} set');

#10-12
my $u = TestAdoptCAF->new({foo => 100, bar => 200, groditi => 300});
is($u->{foo},     100, '$self->{foo} set');
is($u->{bar},     200, '$self->{bar} set');
is($u->{groditi}, 300, '$self->{groditi} set');

