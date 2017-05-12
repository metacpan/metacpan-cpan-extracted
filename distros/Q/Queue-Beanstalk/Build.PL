use Module::Build;
my $build = Module::Build->new
  (
   module_name => 'Queue::Beanstalk',
   license => 'perl',
   dist_abstract => 'Client library for the beanstalkd server',
   dist_author => [ 'Håkon Nessjøen, Loopback Systems AS, E<lt>lunatic@cpan.orgE<gt>' ],
   requires => {
		'perl'	=> '5.6.0',
		'Carp'	=> 0,
		'IO::Handle' => 0,
		},
		create_makefile_pl => 'passthrough',
  );
$build->create_build_script;
