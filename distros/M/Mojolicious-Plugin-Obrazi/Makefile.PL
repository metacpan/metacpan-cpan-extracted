package Mojolicious::Plugin::Obrazi;
use 5.026000;
use ExtUtils::MakeMaker 7.24;
use strict;
use warnings;
use utf8;

my $module_file = 'lib/' .                       (__PACKAGE__ =~ s|::|/|gr) . '.pm';
my $git_url     = 'https://github.com/kberov/' . (__PACKAGE__ =~ s|::|-|gr);

WriteMakefile(
  NAME             => __PACKAGE__,
  VERSION_FROM     => $module_file,
  AUTHOR           => 'Красимир Беров <berov@cpan.org>',
  PREREQ_PM        => {'Mojolicious' => 9.17, 'Text::CSV_XS' => 1.46, 'Imager' => 1.012,},
  test             => {TESTS         => 't/*.t'},
  clean            => {FILES         => 'Mojolicious-Plugin-Obraz* READM*'},
  MIN_PERL_VERSION => '5.026000',
  META_MERGE       => {
    dynamic_config => 0,
    'meta-spec'    => {version   => 2},
    no_index       => {directory => ['t']},
    prereqs        => {runtime   => {requires => {perl => '5.026000'}}},
    resources      => {
      bugtracker => {web => "$git_url/issues"},
      homepage   => $git_url,
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {type => 'git', url => "$git_url.git", web => $git_url,},
    },
  },
);

sub MY::postamble {
  my $preop          = qq 'podselect $module_file > README.pod;';
  my @perltidy_files = qw(Makefile.PL);
  my $options        = {
    no_chdir => 1,
    wanted   => sub {
      push @perltidy_files, $_ if $_ =~ /\.(PL|pm|pl|t|conf)$/;
    }
  };
  File::Find::find($options, 'lib', 't');
  my $perltidy_files = join '\\' . $/ . "\t ", @perltidy_files;
  return <<"TARGETS";
readme ::
\t$preop
dist : readme

perltidy ::
\tperltidy -pro=.perltidyrc \\
\t$perltidy_files

TARGETS
}


