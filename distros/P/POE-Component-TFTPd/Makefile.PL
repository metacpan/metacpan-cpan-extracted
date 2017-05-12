use inc::Module::Install;

name q(POE-Component-TFTPd);
all_from q(lib/POE/Component/TFTPd.pm);

requires q(POE) => 1.284;
requires q(POE::Wheel::UDP) => 0.02;

test_requires q(Test::More) => 0.94;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-TFTPd);
homepage q(http://search.cpan.org/dist/POE-Component-TFTPd);
repository q(git://github.com//home/repositories/poe-component-tftpd.git);

# install_script glob('bin/*');
auto_install;
WriteAll;
