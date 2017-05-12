use Test::More tests=>8;

BEGIN {
  use_ok qw( Symbol::Glob);
}


TestMe::run_it();

package TestMe;
use Symbol::Glob;
use Test::More;
use Test::Exception;

sub run_it {
  my $glob;
  dies_ok { $glob = Symbol::Glob->new() } "no args";

  lives_ok { $glob = Symbol::Glob->new({ name => 'foo' }) } "local symbol";

  lives_ok { $glob = Symbol::Glob->new({ name => 'foo',
                                         sub  => sub { 'foo' } }) } "sub";

  lives_ok { $glob = Symbol::Glob->new({ name => 'foo',
                                         hash  => { 'foo' => 'bar' } }) } "hash";

  lives_ok { $glob = Symbol::Glob->new({ name => 'foo',
                                       array  => [ 'foo', 'bar' ] }) } "array";
  isa_ok $glob, "Symbol::Glob", "right class";
  can_ok $glob, qw(scalar hash array sub delete);

}


