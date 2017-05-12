package VCP::Utils::svn ;

=head1 NAME

VCP::Utils::svn - utilities for dealing with the subversion command

=head1 SYNOPSIS

   use VCP::Utils::svn ;

=head1 DESCRIPTION

=cut

use strict ;

use Carp ;
use VCP::Debug qw( :debug :profile ) ;
use VCP::Utils qw( empty start_dir );
use File::Spec ;
use File::Temp qw( mktemp ) ;
use POSIX ":sys_wait_h" ;

=head1 METHODS

=over

=item cvs

Calls the cvs command with the appropriate cvsroot option.

=cut

sub _runsvn {
   my $self = shift ;

   if ( profiling ) {
      profile_group ref( $self ) . " svn ";
   }

   local $VCP::Debug::profile_category = ref( $self ) . " svn"
      if profiling;

   my $cmd = shift;
   my @args = @{shift()} ;

   return $self->run_safely( [ $cmd, @args ], @_ ) ;
}

sub svn {
    my $self = shift;
    die "should not run client command directly ".join(',',@{$_[0]});
    $self->_runsvn('svn', @_);
}

sub svnadmin {
    my $self = shift;
    die "should not run client command directly";
    $self->_runsvn('svnadmin', @_);
}

sub create_svn_workspace {
   my $self = shift ;
   my %options = @_;


   my $editor = new SVN::Delta::Editor
       SVN::Repos::get_commit_editor($self->{SVN_REPOS}, $self->{SVN_URI},
				     '/', 'vcp',
				     'repository layout', sub {warn 'layout'});

   my $rootbaton = $editor->open_root(0, $self->{SVN_POOL});
   $editor->add_directory ('trunk', $rootbaton, undef, 0, $self->{SVN_POOL});
   $editor->add_directory ('tags', $rootbaton, undef, 0, $self->{SVN_POOL});
   $editor->add_directory ('branches', $rootbaton, undef, 0, $self->{SVN_POOL});
   $editor->close_edit($self->{SVN_POOL});

   return if $self->{SVN_REPOS}; # direct access

   debug "try to create svn workspace" if debugging;

   confess "Can't create_workspace twice" if $self->revs->get ;

   $self->command_chdir( $self->tmp_dir ) ;

   my $output;
   $self->svn(
      [ "checkout", $self->repo_server, '.' ], undef, \$output
   ) ;
   my $revid = $1 if $output =~ m/Checked out revision (\d+)\./;

   if ($revid == 0) {
       $self->mkdir('trunk');
       $self->mkdir('branches');
       $self->mkdir('tags');
       $self->svn( [ 'add', 'trunk', 'branches', 'tags'] );
       $self->svn( [ 'commit', '-m', 'repository layout'] );
   }

   $self->work_root( $self->tmp_dir ) ;
}

=head1 AUTHOR

Chia-liang Kao <clkao@clkao.org>

=head1 COPYRIGHT

Copyright (c) 2003 Chia-liang Kao. All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1 ;
