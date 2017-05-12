#!perl

requires 'perl', '5.8.5';

requires 'Compress::Zlib';
requires 'IO::Socket::INET6';
requires 'IO::Socket::SSL';
requires 'IO::String';
requires 'JSON';
requires 'Moose';

on 'test' => sub {
  requires 'Test::Pod';
#  requires 'Test::More';
#  requires 'File::Find';
};

on 'develop' => sub {
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::MetaProvides::Package';
  requires 'Dist::Zilla::Plugin::ChangelogFromGit';
  requires 'Dist::Zilla::Plugin::Git::NextVersion';
  requires 'Dist::Zilla::Plugin::OurPkgVersion';
  requires 'Dist::Zilla::Plugin::PodSyntaxTests';
  requires 'Dist::Zilla::Plugin::PodWeaver';
  requires 'Dist::Zilla::Plugin::Prereqs';
  requires 'Dist::Zilla::Plugin::Test::Perl::Critic';
  requires 'Dist::Zilla::PluginBundle::Basic';
  requires 'Dist::Zilla::PluginBundle::Git';
  requires 'Software::License::Apache_2_0';
};

