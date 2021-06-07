requires 'perl', 'v5.16';

on test => sub {
	requires 'Test2::V0', '0.000121';
};

on 'develop' => sub {
	requires "Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes";
	requires "Dist::Zilla::Plugin::ExecDir";
	requires "Dist::Zilla::Plugin::Git::Commit";
	requires "Dist::Zilla::Plugin::Git::GatherDir";
	requires "Dist::Zilla::Plugin::Git::NextVersion";
	requires "Dist::Zilla::Plugin::Git::Push";
	requires "Dist::Zilla::Plugin::Git::Tag";
	requires "Dist::Zilla::Plugin::GitHub::Meta";
	requires "Dist::Zilla::Plugin::GitHub::UploadRelease";
	requires "Dist::Zilla::Plugin::MetaJSON";
	requires "Dist::Zilla::Plugin::OurPkgVersion";
	requires "Dist::Zilla::Plugin::PodWeaver";
	requires "Dist::Zilla::Plugin::Prereqs::FromCPANfile";
	requires "Dist::Zilla::Plugin::ReadmeAnyFromPod";
	requires "Dist::Zilla::Plugin::StaticInstall";
	requires "Dist::Zilla::Plugin::Test::Compile";
	requires "Dist::Zilla::Plugin::Test::ReportPrereqs";
	requires "Dist::Zilla::PluginBundle::Basic";
	requires "Dist::Zilla::PluginBundle::Filter";
	requires "Software::License::MIT";
};
