package Module::Provision::TraitFor::VCS;

use namespace::autoclean;

use Class::Usul::Constants qw( EXCEPTION_CLASS FALSE OK TRUE );
use Class::Usul::Functions qw( io is_win32 throw );
use Class::Usul::Types     qw( Bool HashRef Str );
use Perl::Version;
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( Unspecified );
use Moo::Role;
use Class::Usul::Options;

requires qw( add_leader appbase appldir branch build_distribution chdir config
             cpan_upload default_branch dist_version distname editor exec_perms
             extra_argv generate_metadata get_line loc next_argv output quiet
             run_cmd test_upload update_version vcs );

# Attribute constructors
my $_build_cmd_line_flags = sub {
   my $self = shift; my $opts = {};

   for my $k (qw( release test upload nopush )) {
      $self->extra_argv->[ 0 ] and $self->extra_argv->[ 0 ] eq $k
          and $self->next_argv and $opts->{ $k } = TRUE;
   }

   return $opts;
};

# Public attributes
option 'no_auto_rev' => is => 'ro',   isa => Bool, default => FALSE,
   documentation     => 'Do not turn on Revision keyword expansion';

has 'cmd_line_flags' => is => 'lazy', isa => HashRef[Bool],
   builder           => $_build_cmd_line_flags;

# Private attributes
has '_new_version'   => is => 'rwp',  isa => Str;

# Private functions
my $_get_state_file_name = sub {
   return (map  { m{ load-project-state \s+ [\'\"](.+)[\'\"] }mx; }
           grep { m{ eval: \s+ \( \s* load-project-state }mx }
           io( $_[ 0 ] )->getlines)[ -1 ];
};

my $_tag_from_version = sub {
   my $ver = shift; return $ver->component( 0 ).'.'.$ver->component( 1 );
};

# Private methods
my $_add_git_hooks = sub {
   my ($self, @hooks) = @_;

   for my $hook (grep { -e ".git${_}" } @hooks) {
      my $dest = $self->appldir->catfile( '.git', 'hooks', $hook );

      $dest->exists and $dest->unlink; link ".git${hook}", $dest;
      chmod $self->exec_perms, ".git${hook}";
   }

   return;
};

my $_add_tag_to_git = sub {
   my ($self, $tag) = @_;

   my $message = $self->loc( $self->config->tag_message );
   my $sign    = $self->config->signing_key; $sign and $sign = "-u ${sign}";

   $self->run_cmd( "git tag -d v${tag}", { err => 'null', expected_rv => 1 } );
   $self->run_cmd( "git tag ${sign} -m '${message}' v${tag}" );
   return;
};

my $_add_to_git = sub {
   my ($self, $target, $type) = @_;

   my $params = $self->quiet ? {} : { out => 'stdout' };

   $self->run_cmd( "git add ${target}", $params );
   return;
};

my $_add_to_svn = sub {
   my ($self, $target, $type) = @_;

   my $params = $self->quiet ? {} : { out => 'stdout' };

   $self->run_cmd( "svn add ${target} --parents", $params );
   $self->run_cmd( "svn propset svn:keywords 'Id Revision Auth' ${target}",
                   $params );
   $type and $type eq 'program'
      and $self->run_cmd( "svn propset svn:executable '*' ${target}", $params );
   return;
};

my $_commit_release_to_git = sub {
   my ($self, $msg) = @_;

   $self->run_cmd( 'git add .' ); $self->run_cmd( "git commit -m '${msg}'" );

   return;
};

my $_commit_release_to_svn = sub {
   # TODO: Fill this in
};

my $_get_rev_file = sub {
   my $self = shift; ($self->no_auto_rev or $self->vcs ne 'git') and return;

   return $self->appldir->parent->catfile( lc '.'.$self->distname.'.rev' );
};

my $_get_svn_repository = sub {
   my $self = shift; my $info = $self->run_cmd( 'svn info' )->stdout;

   return (split m{ : \s }mx, (grep { m{ \A Repository \s Root: }mx }
                               split  m{ \n }mx, $info)[ 0 ])[ 1 ];
};

my $_get_version_numbers = sub {
   my ($self, @args) = @_; $args[ 0 ] and $args[ 1 ] and return @args;

   my $prompt = '+Enter major/minor 0 or 1';
   my $comp   = $self->get_line( $prompt, 1, TRUE, 0 );
      $prompt = '+Enter increment/decrement';
   my $bump   = $self->get_line( $prompt, 1, TRUE, 0 ) or return @args;
   my ($from, $ver);

   if ($from = $args[ 0 ]) { $ver = Perl::Version->new( $from ) }
   else {
      $ver  = $self->dist_version or return @args;
      $from = $_tag_from_version->( $ver );
   }

   $ver->component( $comp, $ver->component( $comp ) + $bump );
   $comp == 0 and $ver->component( 1, 0 );

   return ($from, $_tag_from_version->( $ver ));
};

my $_initialize_svn = sub {
   my $self = shift; my $class = blessed $self; $self->chdir( $self->appbase );

   my $repository = $self->appbase->catdir( $self->repository );

   $self->run_cmd( "svnadmin create ${repository}" );

   my $branch = $self->branch;
   my $url    = 'file://'.$repository->catdir( $branch );
   my $msg    = $self->loc( 'Initialised by [_1]', $class );

   $self->run_cmd( "svn import ${branch} ${url} -m '${msg}'" );

   my $appldir = $self->appldir; $appldir->rmtree;

   $self->run_cmd( "svn co ${url}" );
   $appldir->filter( sub { $_ !~ m{ \.git }msx and $_ !~ m{ \.svn }msx } );

   for my $target ($appldir->deep->all_files) {
      $self->run_cmd( "svn propset svn:keywords 'Id Revision Auth' ${target}" );
   }

   $msg = $self->loc( 'Add RCS keywords to project files' );
   $self->run_cmd( "svn commit ${branch} -m '${msg}'" );
   $self->chdir( $self->appldir );
   $self->run_cmd( 'svn update' );
   return;
};

my $_push_to_git_remote = sub {
   my $self = shift; my $info = $self->run_cmd( 'git remote -v' )->stdout;

   (grep { m{ \(push\) \z }mx } split m{ \n }mx, $info)[ 0 ] or return;

   my $params = $self->quiet ? {} : { out => 'stdout' };

   $self->run_cmd( 'git push --all',  $params );
   $self->run_cmd( 'git push --tags', $params );
   return;
};

my $_push_to_remote = sub {
   my $self = shift;

   $self->vcs eq 'git' and $self->$_push_to_git_remote;
   return;
};

my $_svn_ignore_meta_files = sub {
   my $self = shift; $self->chdir( $self->appldir );

   my $ignores = "LICENSE\nMANIFEST\nMETA.json\nMETA.yml\nREADME\nREADME.md";

   $self->run_cmd( "svn propset svn:ignore '${ignores}' ." );
   $self->run_cmd( 'svn commit -m "Ignoring meta files" .' );
   $self->run_cmd( 'svn update' );
   return;
};

my $_wrap = sub {
   my $self = shift; my $method = shift; return not $self->$method( @_ );
};

my $_add_tag_to_svn = sub {
   my ($self, $tag) = @_; my $params = $self->quiet ? {} : { out => 'stdout' };

   my $repo    = $self->$_get_svn_repository;
   my $from    = "${repo}/trunk";
   my $to      = "${repo}/tags/v${tag}";
   my $message = $self->loc( $self->config->tag_message )." v${tag}";
   my $cmd     = "svn copy --parents -m '${message}' ${from} ${to}";

   $self->run_cmd( $cmd, $params );
   return;
};

my $_commit_release = sub {
   my ($self, $tag) = @_; my $msg = $self->config->tag_message." v${tag}";

   $self->vcs eq 'git' and $self->$_commit_release_to_git( $msg );
   $self->vcs eq 'svn' and $self->$_commit_release_to_svn( $msg );
   return;
};

my $_initialize_git = sub {
   my $self = shift;
   my $msg  = $self->loc( 'Initialised by [_1]', blessed $self );

   $self->chdir( $self->appldir ); $self->run_cmd( 'git init' );

   $self->add_hooks; $self->$_commit_release_to_git( $msg );

   return;
};

my $_reset_rev_file = sub {
   my ($self, $create) = @_; my $file = $self->$_get_rev_file;

   $file and ($create or $file->exists)
         and $file->println( $create ? '1' : '0' );
   return;
};

my $_reset_rev_keyword = sub {
   my ($self, $path) = @_;

   my $zero = 0; # Zero variable prevents unwanted Rev keyword expansion

   $self->$_get_rev_file and $path->substitute
      ( '\$ (Rev (?:ision)?) (?:[:] \s+ (\d+) \s+)? \$', '$Rev: '.$zero.' $' );
   return;
};

my $_add_tag = sub {
   my ($self, $tag) = @_;

   $tag or throw Unspecified, [ 'VCS tag version' ];
   $self->output( 'Creating tagged release v[_1]', { args => [ $tag ] } );
   $self->vcs eq 'git' and $self->$_add_tag_to_git( $tag );
   $self->vcs eq 'svn' and $self->$_add_tag_to_svn( $tag );
   return;
};

my $_initialize_vcs = sub {
   my $self = shift;

   $self->vcs ne 'none' and $self->output( 'Initialising VCS' );
   $self->vcs eq 'git'  and $self->$_initialize_git;
   $self->vcs eq 'svn'  and $self->$_initialize_svn;
   return;
};

# Construction
around 'dist_post_hook' => sub {
   my ($next, $self, @args) = @_; $self->$_initialize_vcs;

   my $r = $self->$next( @args );

   $self->vcs eq 'git' and $self->$_reset_rev_file( TRUE );
   $self->vcs eq 'svn' and $self->$_svn_ignore_meta_files;
   return $r;
};

around 'release_distribution' => sub {
   my ($orig, $self) = @_;

   $self->cmd_line_flags->{test}
      and $self->$_wrap( 'build_distribution' )
      and $self->$_wrap( 'test_upload', $self->dist_version );

   return $orig->( $self );
};

around 'release_distribution' => sub {
   my ($orig, $self) = @_; my $res = $orig->( $self );

   $self->cmd_line_flags->{upload}
      and $self->$_wrap( 'build_distribution' )
      and $self->$_wrap( 'cpan_upload' )
      and $self->$_wrap( 'clean_distribution' );

   return $res;
};

around 'release_distribution' => sub {
   my ($orig, $self) = @_; my $res = $orig->( $self );

   $self->cmd_line_flags->{nopush} or $self->$_push_to_remote;

   return $res;
};

around 'substitute_version' => sub {
   my ($next, $self, $path, @args) = @_; my $r = $self->$next( $path, @args );

   $self->vcs eq 'git' and $self->$_reset_rev_keyword( $path );
   return $r;
};

around 'update_version_pre_hook' => sub {
   my ($next, $self, @args) = @_;

   return $self->$next( $self->$_get_version_numbers( @args ) );
};

around 'update_version_post_hook' => sub {
   my ($next, $self, @args) = @_;

   $self->_set__new_version( $args[ 1 ] );
   $self->clear_dist_version; $self->clear_module_metadata;

   my $result = $self->$next( @args );

   $self->vcs eq 'git' and $self->$_reset_rev_file( FALSE );

   return $result;
};

# Public methods
sub add_hooks : method {
   my $self = shift;

   $self->vcs eq 'git' and $self->$_add_git_hooks( @{ $self->config->hooks } );

   return OK;
}

sub add_to_vcs {
   my ($self, $target, $type) = @_;

   $target or throw Unspecified, [ 'VCS target' ];
   $self->vcs eq 'git' and $self->$_add_to_git( $target, $type );
   $self->vcs eq 'svn' and $self->$_add_to_svn( $target, $type );
   return;
}

sub get_emacs_state_file_path {
   my ($self, $file) = @_; my $home = $self->config->my_home;

   return $home->catfile( '.emacs.d', 'config', "state.${file}" );
}

sub release : method {
   my $self = shift; $self->release_distribution; return OK;
}

sub release_distribution {
   my $self = shift;

   $self->update_version;
   $self->generate_metadata;
   $self->$_commit_release( $self->_new_version );
   $self->$_add_tag( $self->_new_version );
   return TRUE;
}

sub set_branch : method {
   my $self = shift; my $bfile = $self->branch_file;

   my $old_branch = $self->branch;
   my $new_branch = $self->next_argv // $self->default_branch;

   not $new_branch and $bfile->exists and $bfile->unlink and return OK;
       $new_branch and $bfile->println( $new_branch );

   my $method = 'get_'.$self->editor.'_state_file_path';

   $self->can( $method ) or return OK;

   my $sfname = $_get_state_file_name->( $self->project_file );
   my $sfpath = $self->$method( $sfname );
   my $sep    = is_win32 ? "\\" : '/';

   $sfpath->substitute( "${sep}\Q${old_branch}\E${sep}",
                        "${sep}${new_branch}${sep}" );
   return OK;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Module::Provision::TraitFor::VCS - Version Control

=head1 Synopsis

   use Module::Provision::TraitFor::VCS;
   # Brief but working code examples

=head1 Description

Interface to Version Control Systems

=head1 Configuration and Environment

Modifies
L<Module::Provision::TraitFor::CreatingDistributions/dist_post_hook>
where it initialises the VCS, ignore meta files and resets the
revision number file

Modifies
L<Module::Provision::TraitFor::UpdatingContent/substitute_version>
where it resets the Revision keyword values

Modifies
L<Module::Provision::TraitFor::UpdatingContent/update_version_pre_hook>
where it prompts for version numbers and creates tagged releases

Modifies
L<Module::Provision::TraitFor::UpdatingContent/update_version_post_hook>
where it resets the revision number file

Requires these attributes to be defined in the consuming class;
C<appldir>, C<distname>, C<vcs>

Defines the following command line options;

=over 3

=item C<no_auto_rev>

Do not turn on automatic Revision keyword expansion. Defaults to C<FALSE>

=back

=head1 Subroutines/Methods

=head2 add_hooks - Adds and re-adds any hooks used in the VCS

   $exit_code = $self->add_hooks;

Returns the exit code

=head2 add_to_vcs

   $self->add_to_vcs( $target, $type );

Add the target file to the VCS

=head2 get_emacs_state_file_path

   $io_object = $self->get_emacs_state_file_path( $file_name );

Returns the L<File::DataClass::IO> object for the path to the Emacs editor's
state file

=head2 release - Update version, commit and tag

   $exit_code = $self->release;

Calls L</release_distribution>. Will optionally install the distribution
on a test server, upload the distribution to CPAN and push the repository
to the origin

=head2 release_distribution

Updates the distribution version, regenerates the metadata, commits the change
and tags the new release

=head2 set_branch - Set the VCS branch name

   $exit_code = $self->set_branch;

Sets the current branch to the value supplied on the command line

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Moose::Role>

=item L<Perl::Version>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
