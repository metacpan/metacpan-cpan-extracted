	# $Id: Makefile.PL,v 1.16 2010-02-17 17:21:14 ubuntu Exp $
	# Load the Module::Install bundled in ./inc/
	use inc::Module::Install;
	use 5.006;

	# Define metadata
	name 'PLUTO';
	author 'IBM';
	license 'eclipse';
    version '0.30';
	
	all_from 'lib/ODO.pm';

	# Specific dependencies
	requires 'Error'                     => '0.17';
	requires 'Exception::Class'          => '1.22';
	requires 'Exception::Class::DBI'     => '0.94';
	requires 'Class::ISA'                => '0.32';
	requires 'Class::Accessor'           => '0.25';
	requires 'Class::Base'               => '0.02';
	requires 'Class::Interfaces'         => '0.04';
	requires 'Class::ParamParser'        => '1.041';
	requires 'Aspect'                    => '0.10';
	requires 'URI'                       => '1.35';
	requires 'XML::SAX'                  => '0.96';
	requires 'XML::LibXML'               => '1.70';
	requires 'XML::RegExp'               => '0.02';
	requires 'XML::Namespace'            => '0.02';
	requires 'Time::HiRes'               => '1.20';
	requires 'SQL::Library'              => '0.0.3';
	requires 'Digest::MD5'               => '2.34';
	requires 'Module::Load::Conditional' => '0.38';
	requires 'Module::Load'              => '0.10';
	requires 'Params::Check'             => '0.23';
	requires 'Parse::RecDescent'         => '1.93';
	requires 'Template'                  => '2.15';
	
	# install DBD::mysql iff user has mysql running
#	if (`mysql --version 2>&1` =~ m/^mysql\s+Ver\s+.*$/) {
#	   requires 'DBD::mysql'                => '4';	
#	} else {
#		print STDOUT 'DBD::mysql not required since mysql doesnt seem to be accessible!' . "\n";
#	}
	
	
	no_index directory => 'examples';
	
	auto_install;
    WriteAll;
