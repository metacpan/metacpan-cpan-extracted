use Module::Build;
Module::Build->new(
   module_name => 'Net::IP::Match::Regexp',
   dist_author => 'Chris Dolan <cdolan@cpan.org>',
   license => 'perl',
   requires => {
      'perl' => '5.6.0',
   },
   build_requires => {
      'Test::More' => 0,
   },
   add_to_cleanup => [ 'Net-IP-Match-Regexp-*' ],
   create_readme => 1,
   create_makefile_pl => 'traditional',
)->create_build_script;
