requires 'Moose';

on 'test' => sub {
  requires 'Data::Printer';
  requires 'Test::More';
  requires 'Test::Exception';
  requires 'Types::Standard';
};
on 'develop' => sub {
  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::Git::GatherDir';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::VersionFromModule';
  requires 'Dist::Zilla::PluginBundle::Git';
};
