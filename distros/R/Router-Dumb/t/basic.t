use strict;
use warnings;
use Test::More;
use Test::Deep qw(all cmp_deeply methods subhashof superhashof);

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

# Canonicalize hash.  This is stupid.  I need it because Test::Deep doesn't yet
# have a way to do pairwise comparison. -- rjbs, 2011-07-13
sub _CH {
  my %hash = @_;
  return all( superhashof(\%hash), subhashof(\%hash) );
}

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
    _matches_href => _CH(),
  },

  '/images' => {
    target  => 'pages/images/INDEX',
    _matches_href => _CH(),
  },

  '/legal' => undef,

  '/legal/privacy' => {
    target  => 'pages/legal/privacy',
    _matches_href => _CH(),
  },

  '/citizen/1234/dob' => {
    target  => 'citizen/dob',
    _matches_href => _CH(num => 1234),
  },

  '/citizen/xyzzy/dob' => undef,

  '/blog/1231/2;34/your-mom' => {
    target  => 'blog',
    _matches_href => _CH(REST => '1231/2;34/your-mom'),
  },

  '/group/123/uid/321' => {
    target  => 'pants',
    _matches_href => _CH(group => 123, uid => 321),
  },

  '/group/abc/uid/321' => undef,
);

for (my $i = 0; $i < @tests; $i += 2) {
  my $path = $tests[ $i ];
  my $test = $tests[ $i + 1 ];

  my $want = $test ? methods(%$test) : undef;

  cmp_deeply(
    scalar $r->route($path),
    $want,
    "correct result for $path",
  );
}

done_testing;
