use strict;
use warnings;

use Test::More;

use Module::Faker::Dist;
use CPAN::Meta;
use CPAN::Meta::Requirements;

my $runtime_requires = {
  'Mostly::Auto'    => '1.00',
  'Provides::Inner' => '0',
  'Some::Other'     => '2.00',
};

my @cases = qw(
  Simple-Prereq.yml
  V2-Prereq.yml
);

plan tests => scalar @cases * (1 + scalar keys %$runtime_requires);

for my $c ( @cases ) {
  my $dist = Module::Faker::Dist->from_file("./eg/$c");
  my $dir = $dist->make_dist_dir;
  open my $fh, '<', "$dir/Makefile.PL" or die "Can't open $dir/Makefile.PL: $!";
  my $data = do { local $/; <$fh> };

  ($data) = $data =~ /^  PREREQ_PM => \{(.+?)\n  \}/ms;
  my %p = eval $data;
  die $@ if $@;
  is_deeply( \%p, $runtime_requires, "$c\: PREREQ_PM extracted");

  my $meta = CPAN::Meta->load_file("$dir/META.json");
  my $req = CPAN::Meta::Requirements->new;
  for my $phase ( qw/runtime build test/ ) {
    $req->add_requirements(
      $meta->effective_prereqs->requirements_for( $phase, 'requires' )
    )
  }
  for my $mod ( keys %$runtime_requires ) {
    my $mod_req = $req->requirements_for_module( $mod );
    is(
      $mod_req,
      $runtime_requires->{$mod},
      "$c\: $mod prereq in META"
    );
  }
}

# vim: ts=2 sts=2 sw=2 et:
