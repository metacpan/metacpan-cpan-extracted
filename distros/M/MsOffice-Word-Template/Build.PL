use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
  module_name         => 'MsOffice::Word::Template',
  license             => 'artistic_2',
  dist_author         => q{DAMI <dami@cpan.org>},
  dist_version_from   => 'lib/MsOffice/Word/Template.pm',
  release_status      => 'stable',
  configure_requires => {
    'Module::Build' => '0.4004',
  },
  test_requires => {
    'Test::More' => '0',
  },
  requires => {
    perl                        => '5.24.0',
    'Carp'                      => undef,
    'HTML::Entities'            => undef,
    'Moose'                     => undef,
    'MooseX::StrictConstructor' => undef,
    'MooseX::AbstractMethod'    => undef,
    'MsOffice::Word::Surgeon'   => '2.0',
    'Template::AutoFilter'      => undef,
    'namespace::clean'          => undef,
  },
  add_to_cleanup     => [ 'MsOffice-Word-Template-*' ],
  meta_merge => {
    resources => {
      repository => 'https://github.com/damil/MsOffice-Word-Template',
    }
   },
);


$builder->add_build_element('docx');
$builder->create_build_script();
