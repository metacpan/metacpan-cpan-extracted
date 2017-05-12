use strict;
use warnings;

use Test::More tests => 3;

use String::RewritePrefix;

# testing this method directly seems excessive -- rjbs, 2009-11-30
my $rewriter = String::RewritePrefix->_new_rewriter(undef, {
  prefixes => {
    '-' => 'Tet::',
    '@' => 'KaTet::',
    '+' => sub { $_[0] . '::Foo::' },
    '!' => sub { return undef },
  },
});

my @results = $rewriter->(qw(
  -Corporation
  @Roller
  Plinko
  -@Oops
  +Bar
  !None
));

is_deeply(
  \@results,
  [ qw(Tet::Corporation KaTet::Roller Plinko Tet::@Oops Bar::Foo::Bar None) ],
  "rewrote prefices",
);

my @to_load = String::RewritePrefix->rewrite(
  { '' => 'MyApp::', '+' => '' },
  qw(Plugin Mixin Addon +Corporate::Thinger),
);

is_deeply(
  \@to_load,
  [ qw(MyApp::Plugin MyApp::Mixin MyApp::Addon Corporate::Thinger) ],
  "from synopsis, code okay",
);

{
  String::RewritePrefix->import(
    rewrite => { -as => 'pfx_rw', prefixes => {
      '-' => 'minus ',
      '+' => 'plus ',
      ''  => 'plus ',
    } }
  );
  
  is_deeply(
    [ pfx_rw(qw(+10 10 -10 0)) ],
    [ 'plus 10', 'plus 10', 'minus 10', 'plus 0' ],
    'rewrote with import',
  );
}

