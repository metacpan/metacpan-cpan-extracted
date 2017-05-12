use Test::More;

my @PM = qw(
  OS::Package
  OS::Package::Application
  OS::Package::Artifact
  OS::Package::Artifact::Role::Download
  OS::Package::Artifact::Role::Extract
  OS::Package::Artifact::Role::Validate
  OS::Package::CLI
  OS::Package::Config
  OS::Package::Factory
  OS::Package::Log
  OS::Package::Maintainer
  OS::Package::Plugin::Linux::deb
  OS::Package::Plugin::Linux::RPM
  OS::Package::Plugin::Solaris::IPS
  OS::Package::Plugin::Solaris::SVR4
  OS::Package::Role::Build
  OS::Package::Role::Clean
  OS::Package::Role::Prune
  OS::Package::System
);

foreach my $pm (@PM) {
    use_ok($pm);
}

can_ok(OS::Package::CLI, 'run');
done_testing;
