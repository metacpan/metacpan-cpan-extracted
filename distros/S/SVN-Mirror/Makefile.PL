#!/usr/bin/perl
my $required_svn = '1.2.0';

use inc::Module::Install;

name		('SVN-Mirror');
author		('Chia-liang Kao <clkao@clkao.org>');
abstract	('Mirror remote repositories to local subversion repository');
license		('perl');
version_from	('lib/SVN/Mirror.pm');
install_script	('bin/svm');
clean_files	(qw't/repos* tmp vcp*');
requires(
        'SVN::Core'   => $required_svn,
        'URI::Escape' => '0',
        'URI::file' => '0',
        'Term::ReadKey' => '0',
        'SVN::Simple::Edit' => '0',
        'Date::Format' => '0',
        'File::chdir' => '0',
        'Class::Accessor' => '0',
);
features(
    'VCP support' => [
	-default => 0,
        'VCP' => '0.9',
        (($^O eq 'MSWin32') ? 'Win32API::GUID' : 'Data::UUID') => 0,
    ],
) unless $^O eq 'MSWin32'; # VCP support currently requires symlinks

include('ExtUtils::AutoInstall');
auto_install();
#sign(1);
WriteAll( sign => 1);

die "SVN::Core $required_svn must be manually installed"
    unless eval {require SVN::Core} && $SVN::Core::VERSION >= $required_svn;
