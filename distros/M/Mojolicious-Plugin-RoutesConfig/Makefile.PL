use 5.020000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $module_file = 'lib/Mojolicious/Plugin/RoutesConfig.pm';
my $git_url     = 'https://github.com/kberov/Mojolicious-Plugin-RoutesConfig';
my $preop       = qq'pod2text $module_file > README;'
  . qq'pod2markdown $module_file > README.md';
WriteMakefile(
     NAME          => 'Mojolicious::Plugin::RoutesConfig',
     VERSION_FROM  => $module_file,
     AUTHOR        => 'Красимир Беров (berov@cpan.org)',
     ABSTRACT_FROM => $module_file,
     PREREQ_PM     => {'Mojolicious' => '7.70', perl => '5.020000'},
     test       => {TESTS => 't/*.t'},
     clean      => {FILES => 'Mojolicious-Plugin-*'},
     dist       => {PREOP => $preop},
     META_MERGE => {
       dynamic_config => 0,
       'meta-spec'    => {version => 2},
       no_index       => {directory => ['t']},
       prereqs        => {runtime => {requires => {perl => '5.020000'}}},
       resources      => {
         bugtracker => {web => "$git_url/issues"},
         homepage   => $git_url,
         license => ['http://www.opensource.org/licenses/artistic-license-2.0'],
         repository => {type => 'git', url => "$git_url.git", web => $git_url,},
       },
     },
);

