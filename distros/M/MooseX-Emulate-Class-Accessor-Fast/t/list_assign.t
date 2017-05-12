use strict;
use warnings;
use Test::More tests => 1;
use MooseX::Adopt::Class::Accessor::Fast;

{
  package Some::Class;
  use strict;
  use warnings;
  use base qw/Class::Accessor::Fast/;

  __PACKAGE__->mk_accessors(qw/ foo /);
}

my $i = bless {}, 'Some::Class';
$i->foo(qw/bar baz/);
is_deeply($i->foo, [qw/ bar baz /]);
