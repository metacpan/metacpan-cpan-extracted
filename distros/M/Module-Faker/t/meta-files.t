use strict;
use warnings;

use Test::More tests => 2;

use CPAN::Meta;
use File::Temp ();
use JSON::PP;
use Module::Faker::Dist;
use Path::Class;

my @expected = qw(
  Makefile.PL
  META.yml
  META.json
);

my $MFD = 'Module::Faker::Dist';

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

subtest "dist without meta provides" => sub {
  my $dist = $MFD->from_file('./eg/Provides-Inner.yml');

  isa_ok($dist, $MFD);

  my $dir = $dist->make_dist_dir({ dir => $tmpdir });

  for my $f ( @expected ) {
    ok( -e "$dir/$f", "there's a $f");
  }

  my $content = file("$dir/META.json")->slurp;
  my $meta = JSON::PP->new->decode( $content );

  ok(
    ! exists $meta->{provides},
    "provides is absent"
  ) or note explain($meta->{provides});
};

subtest "dist with meta provides" => sub {
  my $dist = $MFD->from_file('./eg/Provides-Inner.yml');
  $dist->{include_provides_in_meta} = 1; # Violation! -- rjbs, 2019-04-25

  isa_ok($dist, $MFD);

  my $dir = $dist->make_dist_dir({ dir => $tmpdir });

  for my $f ( @expected ) {
    ok( -e "$dir/$f", "there's a $f");
  }

  my $content = file("$dir/META.json")->slurp;
  my $meta = JSON::PP->new->decode( $content );
  is_deeply(
    $meta->{provides},
    {
      'Provides::Inner' => {
        file => 'lib/Provides/Inner.pm',
        version => 0.001,
      },
      'Provides::Inner::Util' => {
        file => 'lib/Provides/Inner.pm',
        version => 0.867,
      },
      'Provides::Outer' => {
        file => 'lib/Provides/Outer.pm',
      },
    },
    "provides is correct"
  );
};
