package Dist::Zilla::Plugin::GitHub::Create;
# ABSTRACT: Create a new GitHub repo on dzil new
use strict;
use warnings;

our $VERSION = '0.49';

use JSON::MaybeXS;
use Moose;
use Try::Tiny;
use Git::Wrapper;
use File::Basename;

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::AfterMint';
with 'Dist::Zilla::Role::TextTemplate';

has org => (
    is      => 'ro',
    isa     => 'Maybe[Str]'
);

has public => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has prompt => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has has_issues => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has has_wiki => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has has_downloads => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

#pod =head1 SYNOPSIS
#pod
#pod Configure git with your GitHub credentials:
#pod
#pod     $ git config --global github.user LoginName
#pod     $ git config --global github.password GitHubPassword
#pod
#pod Alternatively you can install L<Config::Identity> and write your credentials
#pod in the (optionally GPG-encrypted) C<~/.github> file as follows:
#pod
#pod     login LoginName
#pod     password GitHubpassword
#pod
#pod (if only the login name is set, the password will be asked interactively)
#pod
#pod then, in your F<profile.ini>:
#pod
#pod     # default config
#pod     [GitHub::Create]
#pod
#pod     # to override publicness
#pod     [GitHub::Create]
#pod     public = 0
#pod
#pod     # use a template for the repository name
#pod     [GitHub::Create]
#pod     repo = {{ lc $dist->name }}
#pod
#pod See L</ATTRIBUTES> for more options.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This Dist::Zilla plugin creates a new git repository on GitHub.com when
#pod a new distribution is created with C<dzil new>.
#pod
#pod It will also add a new git remote pointing to the newly created GitHub
#pod repository's private URL. See L</"ADDING REMOTE"> for more info.
#pod
#pod =cut

sub after_mint {
    my $self   = shift;
    my ($opts) = @_;

    return if $self->prompt and not $self->_confirm;

    my $root = $opts->{mint_root};

    my $repo_name;

    if ($opts->{repo}) {
        $repo_name = $opts->{repo};
    } elsif ($self->repo) {
        $repo_name = $self->fill_in_string(
            $self->repo, { dist => \($self->zilla) },
        );
    } else {
        $repo_name = $self->zilla->name;
    }

    my $http = HTTP::Tiny->new;

    $self->log([ "Creating new GitHub repository '%s'", $repo_name ]);

    my ($params, $headers, $content);

    $params->{name}   = $repo_name;
    $params->{public} = $self->public;
    $params->{description} = $opts->{descr} if $opts->{descr};

    $params->{has_issues} = $self->has_issues;
    $self->log([ 'Issues are %s', $params->{has_issues} ?
                'enabled' : 'disabled' ]);

    $params->{has_wiki} = $self->has_wiki;
    $self->log([ 'Wiki is %s', $params->{has_wiki} ?
                'enabled' : 'disabled' ]);

    $params->{has_downloads} = $self->has_downloads;
    $self->log([ 'Downloads are %s', $params->{has_downloads} ?
                'enabled' : 'disabled' ]);

    my $url = $self->api;
    $url .= $self->org ? '/orgs/' . $self->org . '/' : '/user/';
    $url .= 'repos';

    $content = encode_json($params);

    $self->log_debug("Sending POST $url");
    my $response = $http->request('POST', $url, {
        content => $content,
        headers => $self->_auth_headers,
    });

    my $repo = $self->_check_response($response);

    return if not $repo;

    if ($repo eq 'redo') {
        $self->log("Retrying with two-factor authentication");
        $self->prompt_2fa(1);
        $repo = $self->after_mint($opts);
        return if not $repo;
    }

    my $git_dir = "$root/.git";
    my $rem_ref = $git_dir."/refs/remotes/".$self->remote;

    if ((-d $git_dir) && (not -d $rem_ref)) {
        my $git = Git::Wrapper->new($root);

        $self->log([ "Setting GitHub remote '%s'", $self->remote ]);
        $git->remote("add", $self->remote, $repo->{ssh_url});

        my ($branch) = try { $git->rev_parse(
            { abbrev_ref => 1, symbolic_full_name => 1 }, 'HEAD'
        ) };

        if ($branch) {
            try {
                $git->config("branch.$branch.merge");
                $git->config("branch.$branch.remote");
            } catch {
                $self->log([ "Setting up remote tracking for branch '%s'", $branch ]);

                $git->config("branch.$branch.merge", "refs/heads/$branch");
                $git->config("branch.$branch.remote", $self->remote);
            };
        }
    }
}

sub _confirm {
    my ($self) = @_;

    my $dist = $self->zilla->name;
    my $prompt = "Shall I create a GitHub repository for $dist?";

    return $self->zilla->chrome->prompt_yn($prompt, {default => 1} );
}

__PACKAGE__->meta->make_immutable;
1; # End of Dist::Zilla::Plugin::GitHub::Create

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitHub::Create - Create a new GitHub repo on dzil new

=head1 VERSION

version 0.49

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.password GitHubPassword

Alternatively you can install L<Config::Identity> and write your credentials
in the (optionally GPG-encrypted) C<~/.github> file as follows:

    login LoginName
    password GitHubpassword

(if only the login name is set, the password will be asked interactively)

then, in your F<profile.ini>:

    # default config
    [GitHub::Create]

    # to override publicness
    [GitHub::Create]
    public = 0

    # use a template for the repository name
    [GitHub::Create]
    repo = {{ lc $dist->name }}

See L</ATTRIBUTES> for more options.

=head1 DESCRIPTION

This Dist::Zilla plugin creates a new git repository on GitHub.com when
a new distribution is created with C<dzil new>.

It will also add a new git remote pointing to the newly created GitHub
repository's private URL. See L</"ADDING REMOTE"> for more info.

=head1 ATTRIBUTES

=over

=item C<repo>

Specifies the name of the GitHub repository to be created (by default the name
of the dist is used). This can be a template, so something like the following
will work:

    repo = {{ lc $dist->name }}

=item C<org>

Specifies the name of a GitHub organization in which to create the repository
(by default the repository is created in the user's account).

=item C<prompt>

Prompt for confirmation before creating a GitHub repository if this option is
set to true (default is false).

=item C<public>

Create a public repository if this option is set to true (default), otherwise
create a private repository.

=item C<remote>

Specifies the git remote name to be added (default 'origin'). This will point to
the newly created GitHub repository's private URL. See L</"ADDING REMOTE"> for
more info.

=item C<has_issues>

Enable issues for the new repository if this option is set to true (default).

=item C<has_wiki>

Enable the wiki for the new repository if this option is set to true (default).

=item C<has_downloads>

Enable downloads for the new repository if this option is set to true (default).

=item C<prompt_2fa>

Prompt for GitHub two-factor authentication code if this option is set to true
(default is false). If this option is set to false but GitHub requires 2fa for
the login, it'll be automatically enabled.

=back

=head1 ADDING REMOTE

By default C<GitHub::Create> adds a new git remote pointing to the newly created
GitHub repository's private URL B<if, and only if,> a git repository has already
been initialized, and if the remote doesn't already exist in that repository.

To take full advantage of this feature you should use, along with C<GitHub::Create>,
the L<Dist::Zilla::Plugin::Git::Init> plugin, leaving blank its C<remote> option,
as follows:

    [Git::Init]
    ; here goes your Git::Init config, remember
    ; to not set the 'remote' option
    [GitHub::Create]

You may set your preferred remote name, by setting the C<remote> option of the
C<GitHub::Create> plugin, as follows:

    [Git::Init]
    [GitHub::Create]
    remote = myremote

Remember to put C<[Git::Init]> B<before> C<[GitHub::Create]>.

After the new remote is added, the current branch will track it, unless remote
tracking for the branch was already set. This may allow one to use the
L<Dist::Zilla::Plugin::Git::Push> plugin without the need to do a C<git push>
between the C<dzil new> and C<dzil release>. Note though that this will work
only when the C<push.default> Git configuration option is set to either
C<upstream> or C<simple> (which will be the default in Git 2.0). If you are
using an older Git or don't want to change your config, you may want to have a
look at L<Dist::Zilla::Plugin::Git::PushInitial>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-GitHub>
(or L<bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-GitHub@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alessandro Ghedini.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
