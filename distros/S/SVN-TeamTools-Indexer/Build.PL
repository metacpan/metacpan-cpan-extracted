use 5.008008; # NOT 5.8.8 - needed by CPAN testers

use Module::Build;


my $builder = Module::Build->new( 
		module_name => 'SVN::TeamTools::Indexer',
		dist_abstract => 'SVN::TeamTools::Indexer creates and updates a Lucy index for SubVersion repositories',
		license => 'gpl',
		configure_requires => {
			Time::HiRes => 0,
			CGI => 0,
		},
		test_requires => {
			Test::More => 0,
		},
		requires => { 
			perl => '5.8.8',
			Carp => 0,
			Data::Dumper => 0,
			DateTime => 0,
			Error => 0,
			Exporter => 0,
			File::Path => 0,
			Getopt::Long => 0,
			HTML::Template => 0,
			List::Util => 0,
			Log::Log4perl => 0,
			Log::Dispatch::File => 0,
			Lucy => 0,
			LucyX::Search::Filter => 0,
			Module::Build => 0,
			Net::SMTP => 0,
			URI::Escape => 0,
			XML::Simple => 0,
			SVN::Look => 0,
		},
		dist_version => '0.002',
		script_files => ['script/Indexer'],
		install_path => {conf=> '/etc/svnteamtools/', log=>'/var/log/svnteamtools/', lucy=>'/var/svnteamtools/svnrepo'},
		conf_files => {'extra/conf/system.conf'=>'conf/system.conf'},
		log_files => {'extra/log/messages.log'=>'log/messages.log'},
		lucy_files => {'extra/lucy/README.lucy'=>'lucy/README.lucy'},
		create_makefile_pl => 'traditional'
         );
$builder->add_build_element('log');
$builder->add_build_element('conf');
$builder->add_build_element('lucy');
$builder->create_build_script;  #generate Build

