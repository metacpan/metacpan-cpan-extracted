use 5.008;
use strict;
use warnings;
use Module::Build;


my $builder = Module::Build->new(
    module_name         => 'SQL::Abstract::More',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/SQL/Abstract/More.pm',
    requires => {
        'perl'                   => 5.008,
        'MRO::Compat'            => 0,
        'SQL::Abstract::Classic' => 0,
        'Params::Validate'       => 0,
        'parent'                 => 0,
        'namespace::clean'       => 0,
        'Scalar::Util'           => 0,
      },
    configure_requires => {
	'Module::Build'          => 0,
      },
    build_requires => {
        # dependencies below should really be 'test_requires' .. but it does not work in perl 5.10 :-(
        'Test::More'             => 0,
        'Test::Exception'        => 0,
        'SQL::Abstract::Test'    => 0,
        'List::MoreUtils'        => 0,
      },

    add_to_cleanup      => [ 'SQL-Abstract-More-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/SQL-Abstract-More',
       }
     },

);

$builder->create_build_script();



