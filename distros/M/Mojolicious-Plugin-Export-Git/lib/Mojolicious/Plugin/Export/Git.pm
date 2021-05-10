package Mojolicious::Plugin::Export::Git;
our $VERSION = '0.003';
# ABSTRACT: Export a Mojolicious site to a Git repository

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     get '/' => 'index';
#pod     get '/secret' => 'secret';
#pod     plugin 'Export::Git' => {
#pod         pages => [qw( / /secret )],
#pod         branch => 'gh-pages',
#pod     };
#pod     app->start;
#pod
#pod =head1 DESCRIPTION
#pod
#pod Deploy a Mojolicious webapp to a Git repository.
#pod
#pod This plugin requires Git version 1.7.2 (released July 21, 2010) or later.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod This class inherits from L<Mojolicious::Plugin::Export> and adds the
#pod following attributes:
#pod
#pod =head1 METHODS
#pod
#pod This class inherits from L<Mojolicious::Plugin::Export> and adds the
#pod following methods:
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious::Plugin::Export>, L<Git::Repository>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin::Export';
use Mojo::File qw( path );
use Git::Repository;

#pod =attr branch
#pod
#pod The Git branch to deploy to. Defaults to "master". If you're building
#pod a Github Pages site for a project, you probably want to use the
#pod "gh-pages" branch.
#pod
#pod =cut

has branch => sub { 'master' };

#pod =attr remote
#pod
#pod The name of the remote to deploy to. Defaults to 'origin'.
#pod
#pod =cut

has remote => sub { 'origin' };

#pod =attr clean
#pod
#pod If true, will completely remove all existing files before exporting. This
#pod ensures that any deleted files will be deleted from the repository.
#pod
#pod Defaults to true if L</branch> isn't the current branch.
#pod
#pod =cut

has clean => sub { undef };

sub export {
    my ( $self, $opt ) = @_;
    for my $key ( qw( to quiet branch remote clean ) ) {
        $opt->{ $key } //= $self->$key;
    }

    # Find the repository root
    my $repo_root = path( $opt->{to} );
    until ( -e $repo_root->child( '.git' ) || $repo_root->to_abs eq '/' ) {
        $repo_root = $repo_root->dirname;
    }
    if ( !-e $repo_root->child( '.git' ) ) {
        die qq{Export path "$opt->{to}" is not in a git repository\n};
    }
    my $deploy_dir = path( $opt->{to} );
    my $rel_path = $deploy_dir->to_rel( $repo_root );
    my $git = Git::Repository->new( work_tree => "$repo_root" );

    # Switch to the right branch for export
    my $current_branch = _git_current_branch( $git );
    if ( !$current_branch ) {
        die qq{Repository has no branches. Please create a commit before deploying\n};
    }
    if ( !_git_has_branch( $git, $opt->{branch} ) ) {
        # Create a new, orphan branch
        # Orphan branches were introduced in git 1.7.2
        say sprintf '    [git] Creating deploy branch "%s"', $opt->{branch}
            unless $opt->{quiet};
        $self->_run( $git, checkout => '--orphan', $opt->{branch} );
        $self->_run( $git, 'rm', '-r', '-f', '.' );
        $opt->{ clean } = 0;
    }
    else {
        say sprintf '    [git] Checkout deploy branch "%s"', $opt->{branch}
            unless $opt->{quiet};
        $self->_run( $git, checkout => $opt->{branch} );
    }

    $opt->{ clean } //= $current_branch ne $opt->{branch};
    if ( $opt->{ clean } ) {
        if ( $current_branch eq $opt->{branch} ) {
            die qq{Using "clean" on the same branch as deploy will destroy all content. Stopping.\n};
        }
        say sprintf '    [git] Cleaning old content in branch "%s"', $opt->{branch}
            unless $opt->{quiet};
        $self->_run( $git, 'rm', '-r', '-f', '.' );
    }

    # Export the site
    $self->SUPER::export( $opt );

    # Check to see which files were changed
    # --porcelain was added in 1.7.0
    my @status_lines = $git->run(
        status => '--porcelain', '--ignore-submodules', '--untracked-files',
    );

    my %in_status;
    for my $line ( @status_lines ) {
        my ( $status, $path ) = $line =~ /^\s*(\S+)\s+(.+)$/;
        $in_status{ $path } = $status;
    }

    # ; use Data::Dumper;
    # ; say Dumper \%in_status;

    # Commit the files
    my @files = map { $_->[0] }
                grep { -e $_->[1] }
                map { [ $_, path( $repo_root, $_ )->to_rel( $rel_path ) ] }
                keys %in_status;

    # ; say "Files to commit: " . join "; ", @files;
    if ( @files ) {
        say sprintf '    [git] Deploying %d changed files', scalar @files
            unless $opt->{quiet};
        $self->_run( $git, add => @files );
        $self->_run( $git, commit => -m => $opt->{message} || "Site update" );
    }
    else {
        say sprintf '    [git] No changes to commit' unless $opt->{quiet};
    }

    if ( _git_has_remote( $git, $opt->{remote} ) ) {
        $self->_run( $git, push => $opt->{remote} => join ':', ($opt->{branch})x2 );
    }
    else {
        say sprintf '    [git] Remote "%s" does not exist. Not pushing.', $opt->{remote}
            unless $opt->{quiet};
    }

    # Tidy up
    $self->_run( $git, checkout => $current_branch );
};

# Run the given git command on the given git repository, logging the
# command for those running in debug mode
sub _run {
    my ( $self, $git, @args ) = @_;
    # ; $self->_app->log->debug( "Running git command: " . join " ", @args );
    return _git_run( $git, @args );
}

sub _git_run {
    my ( $git, @args ) = @_;
    my $cmdline = join " ", 'git', @args;
    my $cmd = $git->command( @args );
    my $stdout = join( "\n", readline( $cmd->stdout ) ) // '';
    my $stderr = join( "\n", readline( $cmd->stderr ) ) // '';
    $cmd->close;
    my $exit = $cmd->exit;

    if ( $exit ) {
        die "git $args[0] exited with $exit\n\n-- CMD --\n$cmdline\n\n-- STDOUT --\n$stdout\n\n-- STDERR --\n$stderr\n";
    }

    return $cmd->exit;
}

sub _git_current_branch {
    my ( $git ) = @_;
    my @branches = map { s/^\*\s+//; $_ } grep { /^\*/ } $git->run( 'branch' );
    return $branches[0];
}

sub _git_has_branch {
    my ( $git, $branch ) = @_;
    return !!grep { $_ eq $branch } map { s/^[\*\s]\s+//; $_ } $git->run( 'branch' );
}

sub _git_has_remote {
    my ( $git, $remote ) = @_;
    return !!grep { $_ eq $remote } map { s/^[\*\s]\s+//; $_ } $git->run( 'remote' );
}

sub _git_version {
    my $output = `git --version`;
    my ( $git_version ) = $output =~ /git version (\d+[.]\d+[.]\d+)/;
    return unless $git_version;
    my $v = sprintf '%i.%03i%03i', split /[.]/, $git_version;
    return $v;
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Export::Git - Export a Mojolicious site to a Git repository

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Mojolicious::Lite;
    get '/' => 'index';
    get '/secret' => 'secret';
    plugin 'Export::Git' => {
        pages => [qw( / /secret )],
        branch => 'gh-pages',
    };
    app->start;

=head1 DESCRIPTION

Deploy a Mojolicious webapp to a Git repository.

This plugin requires Git version 1.7.2 (released July 21, 2010) or later.

=head1 ATTRIBUTES

This class inherits from L<Mojolicious::Plugin::Export> and adds the
following attributes:

=head2 branch

The Git branch to deploy to. Defaults to "master". If you're building
a Github Pages site for a project, you probably want to use the
"gh-pages" branch.

=head2 remote

The name of the remote to deploy to. Defaults to 'origin'.

=head2 clean

If true, will completely remove all existing files before exporting. This
ensures that any deleted files will be deleted from the repository.

Defaults to true if L</branch> isn't the current branch.

=head1 METHODS

This class inherits from L<Mojolicious::Plugin::Export> and adds the
following methods:

=head1 SEE ALSO

L<Mojolicious::Plugin::Export>, L<Git::Repository>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
