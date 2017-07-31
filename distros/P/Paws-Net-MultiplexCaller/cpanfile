requires 'Paws';

on test => sub {
  requires 'Paws::Kinesis::MemoryCaller';
  requires 'Test::More';
  requires 'Test::Exception';
};

on develop => sub {
  requires 'Pod::Markdown';

  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::VersionFromModule';
  requires 'Dist::Zilla::PluginBundle::Git';
};
