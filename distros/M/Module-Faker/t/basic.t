use strict;
use warnings;

use Test::More;

use Module::Faker;
use File::Temp ();

my $MF = 'Module::Faker';

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

$MF->make_fakes({
  source => './eg',
  dest   => $tmpdir,
});

ok(
  -e "$tmpdir/Mostly-Auto-0.01.tar.gz",
  "we got the mostly-auto dist",
);


is((stat("$tmpdir/Mostly-Auto-0.01.tar.gz"))[9], 100, "got mtime set");

subtest "from YAML file" => sub {
  my $dist = Module::Faker::Dist->from_file('./eg/RJBS-Dist.yml');
  is($dist->cpan_author, 'RJBS', "get cpan author from Faker META section");
};

subtest "from .dist file" => sub {
  my $dist = Module::Faker::Dist->from_file('./eg/RJBS_Another-Dist-1.24.tar.gz.dist');
  is($dist->cpan_author, 'RJBS', "get cpan author from .dist filename");

  is($dist->name, 'Another-Dist', "correct dist name");
  is($dist->version, '1.24', "correct version");
};

subtest "from struct, with undef version" => sub {
  my $dist = Module::Faker::Dist->new({name => 'Some-Dist', version => undef});
  is($dist->name, 'Some-Dist', "correct dist name");
  is($dist->version, undef, "correct version");
  is($dist->archive_basename, 'Some-Dist-undef', "correct basename");
};

done_testing;
