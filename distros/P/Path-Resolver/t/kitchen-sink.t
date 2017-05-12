#!perl
use strict;
use warnings;
use Test::More 'no_plan';

use Path::Resolver;
use Path::Resolver::Resolver::AnyDist;
use Path::Resolver::Resolver::Archive::Tar;
use Path::Resolver::Resolver::DataSection;
use Path::Resolver::Resolver::DistDir;
use Path::Resolver::Resolver::FileSystem;
use Path::Resolver::Resolver::Mux::Prefix;
use Path::Resolver::Resolver::Mux::Ordered;

use Moose::Util::TypeConstraints;

use lib 't/lib';

my $prr  = 'Path::Resolver::Resolver';
my %resolver_for = (
  fs   => "$prr\::FileSystem"->new({ root => 't/eg/fs' }),
  dist => "$prr\::DistDir"->new({ dist_name => 'Path-Resolver' }),
  cpan => "$prr\::AnyDist"->new,
  data => "$prr\::DataSection"->new({ module => 'Test::Path::Resolver::DS' }),
  tar  => "$prr\::Archive::Tar"->new({
    archive => 't/eg/archive.tar',
    root    => 'fs',
  }),
);

for my $type (qw(fs data tar)) {
  like(
    ${ $resolver_for{ $type }->content_for('raven.txt') },
    qr{once upon a midnight dreary}i,
    "$type: found a file in a raven.txt",
  );

  is(
    ${ $resolver_for{ $type }->content_for('quotes/raven.txt') },
    "Nevermore!\n",
    "$type: and also quotes/raven.txt",
  );

  is(
    ${ $resolver_for{ $type }->content_for("$type.txt") },
    "Resolver of type $type\n",
    "$type: the unique $type.txt file",
  );

  my @content = $resolver_for{ $type }->content_for('404.html');
  is(@content, 0, "$type: return false for no-such-entry");
}

my $order = "$prr\::Mux::Ordered"->new({
  native_type => class_type('Path::Resolver::SimpleEntity'),
  resolvers   => [
    (map {; $resolver_for{$_} } qw(fs data tar)),
  ],
});

for my $type (qw(fs data tar)) {
  is(
    ${ $order->content_for("$type.txt") },
    "Resolver of type $type\n",
    "ordered: $type: the unique $type.txt file",
  );
}

is(
  ${ $order->content_for('now.playing') },
  "H. by Tool\n",
  'ordered: find fs before data',
);

my $rev_order = "$prr\::Mux::Ordered"->new({
  native_type => class_type('Path::Resolver::SimpleEntity'),
  resolvers   => [
    reverse (map {; $resolver_for{$_} } qw(fs data tar)),
  ],
});

is(
  ${ $rev_order->content_for('now.playing') },
  "Omaha by Counting Crows\n",
  'ordered: find data before fs',
);

my $prefix = "$prr\::Mux::Prefix"->new({
  native_type => class_type('Path::Resolver::SimpleEntity'),
  prefixes    => \%resolver_for,
});

is(
  ${ $prefix->content_for('/data/now.playing') },
  "Omaha by Counting Crows\n",
  'prefix: /data/now.playing -> DataSection resolver',
);

is(
  ${ $prefix->content_for('/fs/now.playing') },
  "H. by Tool\n",
  'prefix: /fs/now.playing -> FileSystem resolver',
);

is($prefix->content_for('now.playing'), undef, 'no content for relative name');

like(
  ${ $prefix->content_for('/cpan/File-ShareDir/sample.txt') },
  qr{\AThis is a sample shared file\.},
  "AnyDist works",
);

my $prefix_with_relative = "$prr\::Mux::Prefix"->new({
  native_type => class_type('Path::Resolver::SimpleEntity'),
  prefixes    => {
    %resolver_for,
    ''  => "$prr\::Mux::Ordered"->new({
      native_type => class_type('Path::Resolver::SimpleEntity'),
      resolvers   => [ (map {; $resolver_for{$_} } qw(fs data tar)) ],
    })
  },
});

is(
  ${ $prefix_with_relative->content_for('/data/now.playing') },
  "Omaha by Counting Crows\n",
  'prefix-with-rel: /data/now.playing -> DataSection resolver',
);

is(
  ${ $prefix_with_relative->content_for('/fs/now.playing') },
  "H. by Tool\n",
  'prefix-with-rel: /fs/now.playing -> FileSystem resolver',
);

is(
  ${ $prefix_with_relative->content_for('now.playing') },
  "H. by Tool\n",
  'prefix-with-rel: fs first'
);
