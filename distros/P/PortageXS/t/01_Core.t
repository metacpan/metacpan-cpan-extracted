#!/usr/bin/perl -w

use Test::Simple tests => 32;

use PortageXS;
use Path::Tiny qw(path);
my $pxs = PortageXS->new();
ok(defined $pxs,'check if PortageXS->new() works');

# - getPortDir >
ok(-d $pxs->portdir(),'portdir: '.$pxs->portdir());

# - getFileContents >
{
	my $content = path('/etc/portage/make.conf')->slurp();
	ok($content ne '','getFileContents of /etc/portage/make.conf');
}

# - searchInstalledPackage >
{
	my @packages = $pxs->searchInstalledPackage('dev-lang/perl');
	ok($#packages==0,'searchInstalledPackage - dev-lang/perl: '.$packages[0]);
}

# - getParamFromFile >
{
	my $param = $pxs->config->getParam('CFLAGS','lastseen');
	ok($param ne '','getParamFromFile /etc/portage/make.conf - CFLAGS: '.$param);
}

# - getUseSettingsOfInstalledPackage >
{
	my @uses = $pxs->getUseSettingsOfInstalledPackage(($pxs->searchInstalledPackage('dev-lang/perl'))[0]);
	ok($#uses!=0,'getUseSettingsOfInstalledPackage - '.($pxs->searchInstalledPackage('dev-lang/perl'))[0].': '.join(' ',@uses));
}

# - getAvailableEbuilds >
{
	my @ebuilds = $pxs->getAvailableEbuilds('dev-lang/perl');
	ok($#ebuilds>-1,'getAvailableEbuilds - dev-lang/perl: '.join(' ',@ebuilds));
}

# - getPortageXScategorylist >
{
	my $oldpath = $pxs->{'PORTAGEXS_ETC_DIR'};
	$pxs->{'PORTAGEXS_ETC_DIR'}="./".$pxs->{'PORTAGEXS_ETC_DIR'};
	my @entries = $pxs->getPortageXScategorylist('perl');
	ok($#entries>0,'getPortageXScategorylist - perl: '.join(' ',@entries));
	$pxs->{'PORTAGEXS_ETC_DIR'}=$oldpath;
}

# - getAvailableArches >
{
	my @arches = $pxs->getAvailableArches();
	ok($#arches>-1,'getAvailableArches: '.join(' ',@arches));
}

# - getPackagesFromCategory >
{
	my @packages = $pxs->getPackagesFromCategory('dev-perl');
	ok($#packages>-1,'getPackagesFromCategory - dev-perl: '.($#packages+1).' packages found');
}

# - fileBelongsToPackage >
{
	my @packages = $pxs->fileBelongsToPackage('/etc/gentoo-release');
	ok($#packages==0,'fileBelongsToPackage - /etc/gentoo-release: '.$packages[0]);
}
ok(!$pxs->fileBelongsToPackage('/this/path/most/likely/does/not/exist'),'fileBelongsToPackage bogus test');

# - getFilesOfInstalledPackage >
{
	my @files = $pxs->getFilesOfInstalledPackage('dev-lang/perl');
	ok($#files>-1,'getFilesOfInstalledPackage: '.($#files+1).' files for dev-lang/perl found');
}

# - getEbuildVersion >
{
	ok($pxs->getEbuildVersion('mozilla-firefox-2.0_beta2.ebuild') eq '2.0_beta2','getEbuildVersion test 1');
	ok($pxs->getEbuildVersion('x11-drm-20060608.ebuild') eq '20060608','getEbuildVersion test 2');
	ok($pxs->getEbuildVersion('iproute2-2.6.15.20060110.ebuild') eq '2.6.15.20060110','getEbuildVersion test 3');
	ok($pxs->getEbuildVersion('traceroute-1.4_p12-r2.ebuild') eq '1.4_p12-r2','getEbuildVersion test 4');
}

# - getArch >
{
	my $arch = $pxs->getArch;
	ok($arch,'getArch returns a value: '.$arch);
}

# - getReponame >
{
	my $repo_name = $pxs->getReponame($pxs->portdir . '');
	ok($repo_name,'Reponame of '.$pxs->portdir().' is: '.$repo_name);
}

# - resolveMirror >
{
	my @mirrors = $pxs->resolveMirror('gentoo');
	ok(($#mirrors+1),'Mirrors for gentoo: '.($#mirrors+1));
}

# - getProfilePath >
{
	my $path = $pxs->getProfilePath();
	ok($path,'Profile path is: '.$path);
}

# - getCategories >
{
	my @cats = $pxs->getCategories($pxs->portdir());
	ok(($#cats+1),'Categories found: '.($#cats+1));
}

# - getPackagesFromWorld >
{
	my @packages = $pxs->getPackagesFromWorld();
	ok(($#packages+1),'Packages found in world: '.($#packages+1));
}

# - getEbuildName >
{
	ok($pxs->getEbuildName('mozilla-firefox-2.0_beta2.ebuild') eq 'mozilla-firefox','getEbuildName test 1');
	ok($pxs->getEbuildName('x11-drm-20060608.ebuild') eq 'x11-drm','getEbuildName test 2');
	ok($pxs->getEbuildName('iproute2-2.6.15.20060110.ebuild') eq 'iproute2','getEbuildName test 3');
	ok($pxs->getEbuildName('traceroute-1.4_p12-r2.ebuild') eq 'traceroute','getEbuildName test 4');
	ok($pxs->getEbuildName('mozilla-firefox-2.0_beta2') eq 'mozilla-firefox','getEbuildName test 5');
	ok($pxs->getEbuildName('x11-drm-20060608') eq 'x11-drm','getEbuildName test 6');
	ok($pxs->getEbuildName('iproute2-2.6.15.20060110') eq 'iproute2','getEbuildName test 7');
	ok($pxs->getEbuildName('traceroute-1.4_p12-r2') eq 'traceroute','getEbuildName test 8');
}

# - resetCaches >
{
	ok($pxs->resetCaches(),'resetCaches() returns a value');
}
