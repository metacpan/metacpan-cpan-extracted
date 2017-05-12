
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Shebangml',
  license             => 'perl',
  dist_version_from   => 'lib/Shebangml.pm',
  requires => {
    perl                      => 5.006002,
    'XML::Parser::Expat'      => 2.36,
    'Class::Accessor::Classy' => 0,
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  configure_requires => {'Module::Build' => 0.31},
  add_to_cleanup      => [ qw(Shebangml-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Shebangml',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Shebangml/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
