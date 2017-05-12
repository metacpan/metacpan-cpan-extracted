use inc::Module::Install;
name 'Pushmi';
version_from 'lib/Pushmi.pm';
requires 'version'          => '0';
requires 'SVN::Core'        => '1.004003';
requires 'SVK'              => '2.0.0';
requires 'App::CLI'         => '0.06';
requires 'Cache::Memcached' => '0';
requires 'YAML::Syck'       => '0';
requires 'Log::Log4perl'    => '0';

build_requires 'IPC::Run3'    => '0';
build_requires 'RunApp'       => '0.13';

install_script 'bin/pushmi';

include('ExtUtils::AutoInstall');
auto_install();

makemaker_args( test => { TESTS => join ' ', "t/*.t", "t/*/*.t"});

WriteAll( sign => 1 );

warn <<EOF;
**********************************************************************
***** If you are using apache 2.2, you need to have Apache::AuthenHook
***** installed for relayed auth.  See README for configuration help.

EOF
