use inc::Module::Install;

name q(Parallel-QueueWorker);
all_from q(lib/Parallel/QueueWorker.pm);

requires q(Moose) => 2.0401;
requires q(Moose::Object) => 2.0401;
requires q(Parallel::ForkManager) => 0;
requires q(Test::More) => 0.98;
requires q(YAML::Any) => 0.77;
requires q(feature) => 1.16;

test_requires q(Test::More) => 0.98;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parallel-QueueWorker);
homepage q(http://search.cpan.org/dist/Parallel-QueueWorker);
repository q(origin);

# install_script glob('bin/*');
auto_install;
WriteAll;
