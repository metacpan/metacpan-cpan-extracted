package Test::BrewBuild::Git;
use strict;
use warnings;

use Capture::Tiny qw(:all);
use Carp qw(croak);
use Logging::Simple;
use LWP::Simple qw(head);
use Test::BrewBuild::Regex;

our $VERSION = '2.20';

my $log;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $log = Logging::Simple->new(
        name => 'Git',
        level => 0
    );

    if (defined $args{debug}){
        $log->level($args{debug});
    }

    $log->child('new')->_5("instantiating new object");

    return $self;
}
sub git {
    my $self = shift;
    my $cmd;

    return $self->{git} if defined $self->{git};

    if ($^O =~ /MSWin/){
        for (split /;/, $ENV{PATH}){
            if (-x "$_/git.exe"){
                $cmd = "$_/git.exe";
                last;
            }
        }
    }
    else {
        $cmd = 'git';
    }

    $log->child('git')->_6("git command set to '$cmd'");

    $self->{git} = $cmd;

    return $cmd;
}
sub link {
    my $self = shift;
    my $git = $self->git;
    my $link = (split /\n/, `"$git" config --get remote.origin.url`)[0];
    $log->child('link')->_6("found $link for the repo");
    return $link
}
sub name {
    my ($self, $repo) = @_;

    $log->child('name')->_6("converting repository link to repo name");

    if ($repo =~ m!${ re_git('extract_repo_name') }!){
        $log->child('name')->_6("repo link converted to $1");
        return $1;
    }
}
sub clone {
    my ($self, $repo) = @_;

    $log->child('clone')->_7("initiating remote repo clone");

    if ($repo !~ /https/){
        $log->child('clone')->_2("git clone failed, repo doesn't exist");
        croak "repository $repo doesn't exist; can't clone...\n";
    }

    my $git = $self->git;

    my $output = capture_merged {
        `"$git" clone $repo`;
    };

    if ($output =~ /fatal/){
        croak "fatal error cloning $repo, can't clone...\n";
    }

    return $output;
}
sub pull {
    my $self = shift;
    my $git = $self->git;

    $log->child('clone')->_6("initiating git pull");

    my $output = `"$git" pull`;
    return $output;
}
sub revision {
    my ($self, %args) = @_;

    my $remote = $args{remote};
    my $repo = $args{repo};

    my $log = $log->child('revision');

    my $git = $self->git;

    $log->child('revision')->_6("initiating git revision");

    my $csum;

    if (! $remote) {
        $log->_6("local: 'rev-parse HEAD' sent");
        $csum = `"$git" rev-parse HEAD`;
    }
    else {
        if (! defined $repo){
            $log->_0(
                "Git::revision() requires a repo sent in while in remote " .
                "mode. Croaking."
            ); 
            croak "Git::revision() requires a repo sent in while in " .
                  "remote mode.";
        }

        $log->_6("remote: 'ls-remote $repo' sent");

        # void capture, as there's unneeded stuff going to STDERR
        # on the ls-remote call

        capture_stderr {
            my $sums = `"$git" ls-remote $repo`;
            if ($sums =~ /${ re_git('extract_commit_csum') }/){
                $csum = $1;
            }
        }
    }

    chomp $csum;
    $log->_5("commit checksum: $csum");
    return $csum;
}
sub status {
    my ($self) = @_;

    $log->child('status')->_7("checking git status");

    my $git = $self->git;

    my $status = `$git status`;

    if ($status =~ /Your branch is ahead/){
        return 0;
    }
    return 1;
}
sub _separate_url {
    # this method is actually not needed. Was going to be used if we used the
    # github API to fetch stuff...
    # eg:   https://api.github.com/repos/$user/$repo/commits

    my ($self, $repo) = @_;

    if (! defined $repo){
        $repo = $self->link;
    }

    my ($user, $repo_name) = (split /\//, $repo)[-2, -1];

    return ($user, $repo_name);
}

1;

=head1 NAME

Test::BrewBuild::Git - Git repository manager for the C<Test::BrewBuild> test
platform system.

=head1 SYNOPSIS

    use Test::BrewBuild::Git;

    my $git = Test::BrewBuild::Git->new;

    my $repo_link = $git->link;

    my $repo_name = $git->name($link);

    $git->clone($repo_link);

    $git->pull;

=head1 DESCRIPTION

Manages Git repositories, including gathering names, cloning, pulling etc.

=head1 METHODS

=head2 new

Returns a new C<Test::BrewBuild::Git> object.

Parameters:

    debug => $level

Optional, Integer. $level vary between 0-7, 0 being the least verbose.

=head2 git

Returns the C<git> command for the local platform.

=head2 link

Fetches and returns the full link to the master repository from your current
working directory. This is the link you used to originally clone the repo.

=head2 name($link)

Extracts the repo name from the full link path.

=head2 clone($repo)

Clones the repo into the current working directory.

=head2 pull

While in a repository directory, pull down any updates.

=head2 revision(remote => $bool, repo => $github_url)

Returns the current commit SHA1 for a repo, with ability to get the local commit
or remote commit SHA1 sum.

Parameters:

All parameters are passed in as a hash.

    repo

Optional, string. The Github url to the repo. If not sent in, we will attempt
to get this information from the current working directory. Mandatory if the
C<remote> parameter is sent in.

    remote

Optional, bool. If sent in, we'll fetch the current commit's SHA1 sum from
Github itself, else we'll get the sum from the most recent local, unpushed
commit. The C<repo> parameter is mandatory if this one is sent in.

=head2 status

Returns true of the repo we're working on is behind or equal to the remote
regarding commits, and false if we're ahead.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
 
