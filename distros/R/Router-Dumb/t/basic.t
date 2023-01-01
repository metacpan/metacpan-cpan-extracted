use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Deep::UnorderedPairs;

use Moose::Util::TypeConstraints qw(find_type_constraint);
use Path::Class;
use Router::Dumb;
use Router::Dumb::Helper::FileMapper;
use Router::Dumb::Helper::RouteFile;

my $r = Router::Dumb->new;

Router::Dumb::Helper::FileMapper->new({
  root => 'templates/pages',
  target_munger => sub {
    my ($self, $filename) = @_;
    dir('pages')->file( file($filename)->relative($self->root) )
                ->as_foreign('Unix')
                ->stringify;
  },
})->add_routes_to($r);

Router::Dumb::Helper::RouteFile->new({ filename => 'eg/extras' })
                               ->add_routes_to($r);

$r->add_route(
  Router::Dumb::Route->new({
    parts       => [ qw(group :group uid :uid) ],
    target      => 'pants',
    constraints => {
      group => find_type_constraint('Int'),
    },
  }),
);

my @tests = (
  '/' => {
    target  => 'pages/INDEX',
    matches => samehash(),
  },

  '/images' => {
    target  => 'pages/images/INDEX',
    matches => samehash(),
  },

  '/legal' => undef,

  '/legal/privacy' => {
    target  => 'pages/legal/privacy',
    matches => samehash(),
  },

  '/citizen/1234/dob' => {
    target  => 'citizen/dob',
    matches => samehash(num => 1234),
  },

  '/citizen/xyzzy/dob' => undef,

  '/blog/1231/2;34/your-mom' => {
    target  => 'blog',
    matches => samehash(REST => '1231/2;34/your-mom'),
  },

  '/group/123/uid/321' => {
    target  => 'pants',
    matches => samehash(group => 123, uid => 321),
  },

  '/group/abc/uid/321' => undef,
);

for (my $i = 0; $i < @tests; $i += 2) {
  my $path = $tests[ $i ];
  my $test = $tests[ $i + 1 ];

  my $want = $test
    ?
        all(
            methods    (map { ref $test->{$_} ? () : ( $_ => $test->{$_} ) } keys %$test),
            listmethods(map { ref $test->{$_} ? ( $_ => $test->{$_} ) : () } keys %$test),
        )
    : undef;

  cmp_deeply(
    scalar $r->route($path),
    $want,
    "correct result for $path",
  );
}

done_testing;
