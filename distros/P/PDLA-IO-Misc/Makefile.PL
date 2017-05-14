use strict;
use warnings;
use ExtUtils::MakeMaker;

my $package = [qw(misc.pd Misc PDLA::IO::Misc)];

undef &MY::postamble; # suppress warning
my %hash;
eval {
  require PDLA::Core::Dev;
  *MY::postamble = sub { PDLA::Core::Dev::pdlpp_postamble($package); };
  %hash = PDLA::Core::Dev::pdlpp_stdargs($package);
};

for my $key (qw(BUILD_REQUIRES CONFIGURE_REQUIRES TEST_REQUIRES PREREQ_PM)) {
  $hash{$key}{'PDLA::Core'} = 0;
}
$hash{NAME} = $package->[2];
$hash{VERSION_FROM} = $package->[0];
$hash{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    repository => {
      type => 'git',
      url => 'git://github.com/PDLPorters/pdla-io-misc',
      web => 'https://github.com/PDLPorters/pdla-io-misc',
    },
  },
};

WriteMakefile(%hash);
