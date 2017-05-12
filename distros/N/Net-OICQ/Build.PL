use strict;
use warnings;
use Module::Build;
# $Id: Build.PL,v 1.4 2007/01/16 17:33:50 tans Exp $

my $req = {
	'Crypt::OICQ' => 1.0,
	'Digest::MD5' => 0.1,
	'IO::Select'  => 0.1,
	'Test::More' => 0,
};

if ($^O eq 'MSWin32') {
	$req->{'Win32::GUI'} = '1.03';
} else {
	$req->{'IO::Select'} = '0.1',
	$req->{'Term::ANSIColor'} = '0.1';
	$req->{'Term::ReadKey'} = '2.30';
}

my $builder = Module::Build->new(
    module_name         => 'Net::OICQ',
    license             => 'perl',
    dist_author         => 'Shufeng Tan <shufengtan@gmail.com>',
    dist_version_from   => 'lib/Net/OICQ.pm',
    build_requires	=> $req,
    add_to_cleanup      => [ 'Net-OICQ-*' ],
);

$builder->create_build_script();
