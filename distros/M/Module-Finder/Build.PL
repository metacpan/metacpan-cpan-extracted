
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Module::Finder',
  license             => 'perl',
  requires => {
    'Class::Accessor::Classy' => 'v0.1.3',
    'Module::Build'           => 0.26,
    'Test::More'              => 0,
  },
  add_to_cleanup      => [ qw(Module-Finder-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Finder',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/Module-Finder/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta

