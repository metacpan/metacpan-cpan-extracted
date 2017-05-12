use inc::Module::Install;
name 'SVN-Hook';
version_from 'lib/SVN/Hook.pm';
requires 'Class::Accessor::Fast' => '0';
requires 'Path::Class'           => '0';

install_script 'bin/svnhook';

include('ExtUtils::AutoInstall');
auto_install();

makemaker_args( test => { TESTS => join ' ', "t/*.t", "t/*/*.t"});

WriteAll( sign => 1 );

