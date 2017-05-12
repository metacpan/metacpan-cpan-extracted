package Plack::Middleware::GitStatus;
use strict;
use warnings;
our $VERSION = '0.02';

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(path git_dir);
use Plack::Util;

use Cache::FileCache;
use Cwd;
use Git::Repository 'Log';
use Time::Piece;
use Try::Tiny;

our $CACHE = Cache::FileCache->new({
    namespace          => 'Plack::Middleware::GitStatus',
    default_expires_in => 24 * 60 * 60,  # 1 day
});
our $CACHE_KEY = 'git-status';

our $WORKTREE;

sub prepare_app {
    my $self = shift;

    try {
        $WORKTREE = Git::Repository->new(work_tree => $self->{git_dir} || getcwd);
    } catch {
        $self->{error} ||= $_;
    };

    # reset git message cache when restating app
    $CACHE->clear;
    $CACHE->set($CACHE_KEY => $self->_git_message || '');
}

sub call {
    my ($self, $env) = @_;

    if ($self->path && $env->{PATH_INFO} eq $self->path) {
        my $body = $CACHE->get($CACHE_KEY) || do {
            $CACHE->set($CACHE_KEY => $self->_git_message || '');
        };

        if ($self->{error}) {
            return [500, ['Content-Type' => 'text/plain'], [ $self->{error} ]];
        }

        return [200, ['Content-Type' => 'text/plain'], [ $body ]];
    }

    return $self->app->($env);
}

sub _git_message {
    my $self = shift;

    return undef unless defined $WORKTREE;

    my ($brach_name, $last_commit);
    try {
        $brach_name  = $self->_current_branch;
        $last_commit = $self->_last_commit;
    } catch {
        $self->{error} ||= $_;
        return undef;
    };

    my $msg  = "CurrentBranch: $brach_name\n";
       $msg .= sprintf "Commit: %s\n",  $last_commit->{commit};
       $msg .= sprintf "Author: %s\n",  $last_commit->{author};
       $msg .= sprintf "Date: %s\n",    $last_commit->{date};
       $msg .= sprintf "Message: %s",   $last_commit->{message};

    return $msg;
}

sub _current_branch {
    my $self = shift;
    my (@lines) = $WORKTREE->run('status');
    $lines[0] =~ /branch (.+)$/;
    return $1;
}

sub _last_commit {
    my $self = shift;

    my ($log) = Git::Repository->log('-1');
    return +{
        commit  => $log->commit,
        author  => $log->author,
        message => $log->message,
        date    => _unixtime_to_date($log->author_localtime),
    };
}

sub _unixtime_to_date {
    my $lt = localtime($_[0]);
    my $t  = gmtime($lt->epoch);
    return $t;
}

1;
__END__

=head1 NAME

Plack::Middleware::GitStatus - Provide Git status via HTTP

=head1 SYNOPSIS

    use Plack::Builder;

    builder {

        enable "Plack::Middleware::GitStatus", (
            path  => '/git-status', git_dir => '/path/to/repository'
        ) if $ENV{PLACK_ENV} eq 'staging';

        $app;
    };

    % curl http://server:port/git-status
    CurrentBranch: feature/something-interesting
    Commit: a7c24106ac453c10f1a460f52e95767803076dde
    Author: y_uuki
    Date: Tue Feb 12 06:06:41 2013
    Message: Hello World

=head1 DESCRIPTION

Plack::Middleware::GitStatus provides Git status such as current branch and last commit via HTTP.
On a remote server such as staging environment, it is sometimes troublesome to check a current branch and last commit information of a working web application.
Plack::Middleware::GitStatus add URI location displaying the information to your Plack application.

=head1 CONFIGURATIONS

=over 4

=item path

    path => '/git-status',

location that displays git status

=item git_dir

    git_dir => '/path/to/repository'

git direcotry path like '/path/to/deploy_dir/current'

=back

=head1 AUTHOR

Yuuki Tsubouchi E<lt>yuuki {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Plack::Middleware::ServerStatus::Lite>

L<Plack::Middleware::GitBlame|https://github.com/shumphrey/Plack-Middleware-GitBlame>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
