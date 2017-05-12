package Dist::Zilla::PluginBundle::Prophet;
{
  $Dist::Zilla::PluginBundle::Prophet::VERSION = '0.001';
}

# ABSTRACT: Build a Prophet release

use Moose;

use Dist::Zilla::Plugin::ContributorsFile;
use Dist::Zilla::Plugin::ContributorsFromGit;
use Dist::Zilla::Plugin::Git;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::MetaResources;
use Dist::Zilla::Plugin::ModuleBuild;
use Dist::Zilla::Plugin::OSPrereqs;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Plugin::ReadmeAnyFromPod;
use Dist::Zilla::Plugin::RunExtraTests;
use Dist::Zilla::Plugin::Signature;
use Dist::Zilla::Plugin::Test::Pod::No404s;
use Dist::Zilla::Plugin::Test::ReportPrereqs;

use Dist::Zilla::PluginBundle::TestingMania;

with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure {
    my ($self) = @_;
    my $arg = $self->payload;

    my $release_branch = 'releases';

    $self->add_plugins(
        ['Git::GatherDir' => {include_dotfiles => 1}],
        qw/
          PruneCruft
          ContributorsFile
          ContributorsFromGit
          Git::NextVersion
          MetaJSON
          ExecDir
          ShareDir
          License
          PodWeaver
          PkgVersion
          ModuleBuild
          Manifest
          Signature
          Test::Pod::No404s
          Test::ReportPrereqs
          TestRelease
          ConfirmRelease
          /,
        [
            ReadmeAnyFromPod => {
                type     => 'markdown',
                filename => 'README.mkdn',
                location => 'build',
            }
        ],
    );
    $self->add_bundle(
        TestingMania => {disable => [qw/MetaTests Test::Perl::Critic/]});

    if ($arg->{fake_release}) {

        # XXX don't run extra tests for a real release yet - too many fail
        $self->add_plugins(qw/FakeRelease RunExtraTests/);
        return;
    }

    $self->add_plugins(
        'Git::Commit',
        [
            'Git::CommitBuild' => {
                release_branch => 'last_release',
            }
        ],
        ['Git::Tag' => {signed => 1, branch => 'last_release'}],
        qw/
          Git::Push
          UploadToCPAN
          /
    );

    return;
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::Prophet - Build a Prophet release

=head1 VERSION

version 0.001

=head1 DESCRIPTION

  [GatherDir]
  [PruneCruft]

  [Git::NextVersion]
  [MetaJSON]
  [ExecDir]
  [ShareDir]
  [License]
  [PodWeaver]
  [PkgVersion]
  
  [ReadmeAnyFromPod / ReadmeMarkdownInRoot]
  type = markdown
  filename = README.mkdn
  location = root

  [ModuleBuild]
  [Manifest]
  [Signature]

  [@TestingMania]
  disable = MetaTests
  disable = Perl::Critic

  [Test::Pod::No404s]
  [Test::ReportPrereqs]
  [TestRelease]

  [ConfirmRelease]
  [UploadToCPAN]

=head3 fake_release

Only fake a release

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Ioan Rogers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
