package Module::Install::Repository;

use strict;
use 5.005;
use vars qw($VERSION);
$VERSION = '0.06';

use base qw(Module::Install::Base);

sub _execute {
    my ($command) = @_;
    `$command`;
}

sub auto_set_repository {
    my $self = shift;

    return unless $Module::Install::AUTHOR;

    my $repo = _find_repo(\&_execute);
    if ($repo) {
        $self->repository($repo);
    } else {
        warn "Cannot determine repository URL\n";
    }
}

sub _find_repo {
    my ($execute) = @_;

    if (-e ".git") {
        # TODO support remote besides 'origin'?
        if ($execute->('git remote show -n origin') =~ /URL: (.*)$/m) {
            # XXX Make it public clone URL, but this only works with github
            my $git_url = $1;
            $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;
            return $git_url;
        } elsif ($execute->('git svn info') =~ /URL: (.*)$/m) {
            return $1;
        }
    } elsif (-e ".svn") {
        if (`svn info` =~ /URL: (.*)$/m) {
            return $1;
        }
    } elsif (-e "_darcs") {
        # defaultrepo is better, but that is more likely to be ssh, not http
        if (my $query_repo = `darcs query repo`) {
            if ($query_repo =~ m!Default Remote: (http://.+)!) {
                return $1;
            }
        }

        open my $handle, '<', '_darcs/prefs/repos' or return;
        while (<$handle>) {
            chomp;
            return $_ if m!^http://!;
        }
    } elsif (-e ".hg") {
        if ($execute->('hg paths') =~ /default = (.*)$/m) {
            my $mercurial_url = $1;
            $mercurial_url =~ s!^ssh://hg\@(bitbucket\.org/)!https://$1!;
            return $mercurial_url;
        }
    } elsif (-e "$ENV{HOME}/.svk") {
        # Is there an explicit way to check if it's an svk checkout?
        my $svk_info = `svk info` or return;
        SVK_INFO: {
            if ($svk_info =~ /Mirrored From: (.*), Rev\./) {
                return $1;
            }

            if ($svk_info =~ m!Merged From: (/mirror/.*), Rev\.!) {
                $svk_info = `svk info /$1` or return;
                redo SVK_INFO;
            }
        }

        return;
    }
}

1;
__END__

=encoding utf-8

=for stopwords github.com META.yml Darcs

=head1 NAME

Module::Install::Repository - Automatically sets repository URL from svn/svk/Git checkout

=head1 SYNOPSIS

  # in Makefile.PL
  use inc::Module::Install;
  auto_set_repository;

=head1 DESCRIPTION

Module::Install::Repository is a Module::Install plugin to
automatically figure out repository URL and set it via I<repository()>
which then will be added to resources under I<META.yml>.

=head1 CAVEATS

The regular expression to rewrite Git repository URL to public clone
URL is dependent on the server side directory layout, which means this
module currently works only with github.com style.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Darcs support by Shawn M Moore

git-svn support by Tokuhiro Matsuno

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Module::Install>

=cut
