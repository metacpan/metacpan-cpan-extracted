use inc::Module::Install;

name q(Mojolicious-Plugin-ValidateMoose);
all_from q(lib/Mojolicious/Plugin/ValidateMoose.pm);

requires q(Mojolicious) => 2.80;
requires q(Moose) => 2.00;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-ValidateMoose);
homepage q(https://metacpan.org/release/Mojolicious-Plugin-ValidateMoose);
repository q(git://github.com/mojolicious-plugin-validatemoose);

auto_install;
WriteAll;
