use inc::Module::Install;

name q(Net-UpYun);

all_from q(lib/Net/UpYun.pm);

requires q(Digest::MD5) => 0;
requires q(HTTP::Date) => 0;
requires q(HTTP::Response) => 0;
requires q(Moose) => 2.0401;
requires q(Moose::Object) => 2.0401;
requires q(WWW::Curl::Easy) => 4.15;
requires q(feature) => 1.16;
requires q(namespace::autoclean) => 0;

test_requires q(Data::Dumper) => 0;
test_requires q(HTTP::Date) => 0;
test_requires q(Test::More) => 0;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-UpYun);
homepage q(http://search.cpan.org/dist/Net-UpYun);
repository q(origin);

# install_script glob('bin/*');
auto_install;
WriteAll;
