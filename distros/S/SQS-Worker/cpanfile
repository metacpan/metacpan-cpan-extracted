requires 'Paws';
requires 'Moose';
requires 'JSON::MaybeXS';
requires 'Log::Log4perl';
requires 'SNS::Notification';
requires 'Module::Runtime';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::Exception';
  requires 'Test::Spec';
  requires 'Test::Pod';
};

on 'develop' => sub {
  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::VersionFromModule';
  requires 'Dist::Zilla::PluginBundle::Git';
  requires 'Dist::Zilla::Plugin::UploadToCPAN';
  requires 'Dist::Zilla::Plugin::RunExtraTests';
  requires 'Dist::Zilla::Plugin::Test::Compile';
}
