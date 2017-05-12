use inc::Module::Install;

name q(Plack-Middleware-SSI);
all_from q(lib/Plack/Middleware/SSI.pm);

requires q(File::Basename) => 2.70;
requires q(HTTP::Date) => 5.831;
requires q(HTTP::Message) => 5.82;
requires q(HTTP::Request) => 5.82;
requires q(HTTP::Response) => 5.82;
requires q(POSIX) => 1.10;
requires q(Plack) => 0.98;
requires q(base) => 2.10;

test_requires q(Test::More) => 0.98;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-SSI);
homepage q(http://search.cpan.org/dist/Plack-Middleware-SSI);
repository q(git://github.com/jhthorsen/plack-middleware-ssi.git);

# install_script glob('bin/*');
auto_install;
WriteAll;
