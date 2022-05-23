package Tapper::Installer::Precondition::Repository;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Installer::Precondition::Repository::VERSION = '5.0.1';
use strict;
use warnings;

use File::Basename;
use Moose;
extends 'Tapper::Installer::Precondition';





sub git_get {
        my ($self, $repo) = @_;

        return "no url given to git_get" if not $repo->{url};
        if (not $repo->{target}) {
                $repo->{target} = basename($repo->{url},(".git"));
        }
        $repo->{target} = $self->cfg->{paths}{base_dir}.$repo->{target};

        my ($error, $retval) = $self->log_and_exec("git","clone","-q",$repo->{url},$repo->{target});
        return($retval) if $error;

        if ($repo->{revision}) {
                chdir ($repo->{target});
                ($error,$retval) = $self->log_and_exec("git","checkout",$repo->{revision});
                return($retval) if $error;
        }
        return(0);
}


sub hg_get {
        my ($self, $repo) = @_;

        return "no url given to hg_get" if not $repo->{url};
        if (not $repo->{target}) {
                $repo->{target} = basename($repo->{url},(".hg"));
        }
        $repo->{target} = $self->cfg->{paths}{base_dir}.$repo->{target};

        my ($error, $retval) = $self->log_and_exec("hg","clone","-q",$repo->{url},$repo->{target});
        return($retval) if $error;

        if ($repo->{revision}) {
                ($error, $retval) = $self->log_and_exec("hg","update",$repo->{revision});
                return($retval) if $error;
        }
        return(0);
}


sub svn_get {
        my ($self, $repo) = @_;

        $self->log->error("unimplemented");
}



sub install {
        my ($self, $repository) = @_;

        return "No repository type given" if not $repository->{type};
        if ($repository->{type} eq "git") {
                return $self->git_get($repository);
        } elsif ($repository->{type} eq "hg") {
                return $self->hg_get($repository);
        } elsif ($repository->{type} eq "svn") {
                return $self->svn_get($repository);
        } else {
                return ("Unknown repository type:",$repository->{type});
        }
        return "Bug: Repository::install() got after if/else.";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Installer::Precondition::Repository

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Repository;

=head1 NAME

Tapper::Installer::Precondition::Repository - Install a repository to a given location

=head1 FUNCTIONS

=head2 git_get

This function encapsulates getting data out of a git repository.

@param hash reference - repository data

@retval success - 0
@retval error   - error string

=head2 hg_get

This function encapsulates getting data out of a mercurial repository.

@param hash reference - repository data

@retval success - 0
@retval error   - error string

=head2 svn_get

This function encapsulates getting data out of a subversion repository.

@param hash reference - repository data

@retval success - 0
@retval error   - error string

=head2 install

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
