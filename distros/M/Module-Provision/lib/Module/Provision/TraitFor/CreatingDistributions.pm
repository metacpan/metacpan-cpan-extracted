package Module::Provision::TraitFor::CreatingDistributions;

use namespace::autoclean;

use Class::Usul::Constants qw( FAILED FALSE OK SPC TRUE );
use Class::Usul::Functions qw( emit emit_to io trim );
use Class::Usul::Types     qw( ArrayRef NonEmptySimpleStr );
use English                qw( -no_match_vars );
use IO::Handle;
use Moo::Role;
use Class::Usul::Options;

requires qw( appbase appldir branch builder chdir config exec_perms
             homedir incdir method output next_argv project_file
             quiet render_templates run_cmd stash testdir vcs );

# Object attributes (public)
option 'editor'     => is => 'lazy', isa => NonEmptySimpleStr,
   documentation    => 'Which text editor to use',
   default          => sub { $_[ 0 ]->config->editor }, format => 's';

# Private functions
my $_set_env_false = sub {
   $ENV{ $_ } = FALSE for (@_); return;
};

my $_set_env_true = sub {
   $ENV{ $_ } = TRUE for (@_); return;
};

# Private methods
my $_create_mask = sub {
   return oct '0777' ^ $_[ 0 ]->exec_perms;
};

my $_get_cover_command = sub {
   my $self = shift;

   ($self->builder eq 'DZ' or $self->builder eq 'MB')
      and return 'perl Build.PL && ./Build testcover';

   return;
};

my $_get_cover_build_command = sub {
   my $self = shift;

   $self->builder eq 'DZ' and return 'dzil build';

   return;
};

my $_get_test_command = sub {
   return $_[ 1 ]                  ? 'prove -lv '.$_[ 1 ]
        : $_[ 0 ]->builder eq 'DZ' ? 'dzil test'
                                   : 'prove t';
};

my $_project_file_path = sub {
   return $_[ 0 ]->appldir->catfile( $_[ 0 ]->project_file );
};

# Construction
around '_build_appbase' => sub {
   my ($orig, $self, @args) = @_; my $appbase = $orig->( $self, @args );

   return $self->method eq 'dist'
        ? $self->base->absolute( $self->initial_wd )->catdir( $self->distname )
        : $appbase;
};

around '_build_appldir' => sub {
   my ($next, $self, @args) = @_; my $appldir = $self->$next( @args );

   return !$appldir && $self->method eq 'dist'
        ? $self->appbase->catdir( $self->branch ) : $appldir ;
};

around '_build_builder' => sub {
   my ($next, $self, @args) = @_; my $builder = $self->$next( @args );

   return !$builder && $self->method eq 'dist'
        ? $self->config->builder : $builder;
};

around '_build_project' => sub {
   my ($next, $self, @args) = @_; my $project;

   $self->method eq 'dist' and $project = $self->next_argv and return $project;

   return $self->$next( @args );
};

around '_build_vcs' => sub {
   my ($next, $self, @args) = @_; my $vcs = $self->$next( @args );

   return $vcs eq 'none' && $self->method eq 'dist' ? $self->config->vcs : $vcs;
};

# Public Methods
sub build_distribution : method {
   my ($self, $verbose) = @_;

   if ($self->builder eq 'DZ') {
      $self->run_cmd( 'dzil build', $verbose ? { out => 'stdout' } : {} );
   }
   elsif ($self->builder eq 'MB') {
      $self->run_cmd( 'perl Build.PL' );
      $self->run_cmd( './Build dist', $verbose ? { out => 'stdout' } : {} );
   }

   return OK;
}

sub clean_distribution : method {
   my ($self, $verbose) = @_;

   if ($self->builder eq 'DZ') { $self->run_cmd( 'dzil clean' ) }
   elsif ($self->builder eq 'MB') { $self->run_cmd( './Build distclean' ) }

   return OK;
}

sub cover : method {
   my $self = shift; $self->chdir( $self->appldir );

   $self->quiet or
      $self->output( 'Testing coverage [_1]', { args => [ $self->appldir ] } );

   my $cmd = $self->$_get_cover_build_command;

   $cmd and $self->run_cmd( $cmd, $self->quiet ? {} : { out => 'stdout' } );
   $_set_env_true->( @{ $self->config->test_env_vars } );
   $ENV{DEVEL_COVER_OPTIONS} = '-ignore,MyModuleBuilder.pm,/home';
   $self->builder eq 'DZ'
      and $self->chdir( $self->distname.'-'.$self->dist_version );
   $cmd = $self->$_get_cover_command;
   $cmd and $self->run_cmd( $cmd, $self->quiet ? {} : { out => 'stdout' } );
   $self->chdir( $self->appldir );
   $_set_env_false->( @{ $self->config->test_env_vars } );
   delete $ENV{DEVEL_COVER_OPTIONS};
   return OK;
}

sub create_directories {
   my $self = shift; my $perms = $self->exec_perms;

   $self->quiet or $self->output( 'Creating directories' );
   $self->appldir->exists or $self->appldir->mkpath( $perms );
   $self->builder eq 'MB'
      and ($self->incdir->exists or $self->incdir->mkpath( $perms ));
   $self->testdir->exists or $self->testdir->mkpath( $perms );
   $self->homedir->parent->exists or $self->homedir->parent->mkpath( $perms );
   return;
}

sub dist : method {
   my $self = shift;

   $self->dist_pre_hook;
   $self->create_directories;
   $self->render_templates;
   $self->dist_post_hook;
   return OK;
}

sub dist_post_hook {
   my $self = shift;

   $self->generate_metadata( TRUE ); $self->prove;

   return;
}

sub dist_pre_hook {
   my $self = shift; umask $self->$_create_mask;

   $self->appbase->exists or $self->appbase->mkpath( $self->exec_perms );
   $self->stash->{abstract} = $self->next_argv || $self->stash->{abstract};
   $self->chdir( $self->appbase );
   return;
}

sub edit_project : method {
   my $self = shift; my $path = $self->$_project_file_path;

   $self->run_cmd( $self->editor.SPC.$path, { async => TRUE } );
   return OK;
}

sub generate_metadata {
   my ($self, $create) = @_; $self->chdir( $self->appldir );

   my $verbose = $create ? FALSE : TRUE; my $mdf = 'README.md';

      if ($self->builder eq 'DZ') { $self->build_distribution( $verbose ) }
   elsif ($self->builder eq 'MB') {
      $self->run_cmd( 'perl '.$self->project_file );
      $self->run_cmd( './Build manifest', $verbose ? { out => 'stdout' } : {} );
      $self->run_cmd( './Build distmeta', $verbose ? { out => 'stdout' } : {} );
   }

   $self->clean_distribution( $verbose );
   return $create ? $mdf : undef;
}

sub metadata : method {
   my $self = shift; $self->generate_metadata( FALSE ); return OK;
}

sub prove : method {
   my $self = shift; $self->chdir( $self->appldir );

   my $cmd = $self->$_get_test_command( $self->next_argv );

   $_set_env_true->( @{ $self->config->test_env_vars } );

   $self->output ( 'Testing [_1]', { args => [ $self->appldir ] } );
   $self->run_cmd( $cmd, $self->quiet ? {} : { out => 'stdout' } );

   $_set_env_false->( @{ $self->config->test_env_vars } );
   return OK;
}

sub select_project : method {
   my $self     = shift;
   my @projects = $self->base->all_dirs;
   my @options  = map { $_->basename } @projects;
   my $prompt   = 'Select a project from the following list';
   my $index    = $self->get_option( $prompt, undef, TRUE, undef, \@options );

   $index < 0 and return FAILED;

   my $name     = $projects[ $index ]->basename;
   my $project  = Module::Provision->new
      ( noask => TRUE, project => $name, quiet => TRUE );

   $self->chdir( my $dir = $project->appldir );

   io()->fdopen( 3, 'w' )->print( $dir )->close;

   return Module::Provision->new
      ( method => 'edit_project', noask => TRUE, quiet => TRUE )->run;
}

sub show_tab_title : method {
   my $self = shift;
   my $file = $self->next_argv || $self->$_project_file_path;
   my $text = (grep { m{ tab-title: }msx } io( $file )->getlines)[ -1 ]
           || ':'.$self->distname;

   emit trim( (split m{ : }msx, $text, 2)[ 1 ] ).SPC.$self->appbase;
   return OK;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Module::Provision::TraitFor::CreatingDistributions - Create distributions

=head1 Synopsis

   use Moose;

   extends 'Module::Provision::Base';
   with    'Module::Provision::TraitFor::CreatingDistributions';

=head1 Description

Create distributions using either Git or SVN for the VCS

=head1 Configuration and Environment

Requires these attributes to be defined in the consuming class;
C<appbase>, C<appldir>, C<builder>, C<exec_perms>, C<homedir>,
C<incdir>, C<project_file>, C<render_templates>, C<stash>, C<testdir>,
and C<vcs>

Defines the following attributes;

=over 3

=item <editor>

Which text editor to use. It is a read only, lazily evaluated, simple
string that cannot be null. It defaults to the C<editor> configuration
variable

=back

=head1 Subroutines/Methods

=head2 build_distribution - Build a CPAN distribution tarball

   $self->build_distribution( $verbose );

Builds a CPAN distribution tarball

=head2 clean_distribution - Cleans up after a distribution build

   $self->clean_distribution( $verbose );

Cleans up after a distribution build

=head2 cover - Create test coverage statistics

   $exit_code = $self->cover;

Returns the exit code. Runs the distributions coverage tests

=head2 create_directories

   $self->create_directories;

Creates the required directories for the new distribution. If subclassed this
method can be modified to include additional directories

=head2 dist - Create a new distribution

   $exit_code = $self->dist;

The distributions main module name is specified on the command line

=head2 dist_post_hook

   $self->dist_post_hook;

Runs after the new distribution has been created. If subclassed this method
can be modified to perform additional actions after the templates have been
rendered

=head2 dist_pre_hook

   $self->dist_pre_hook;

Runs before the new distribution is created. If subclassed this method
can be modified to perform additional actions before the project directories
are created

=head2 edit_project - Edit the project file

   $exit_code = $self->edit_project;

The project file is one of; F<dist.ini>, F<Build.PL>, or
F<Makefile.PL> in the current directory

=head2 generate_metadata

   $markdown_file = $self->generate_metadata( $create_flag );

Generates the distribution metadata files. If the create_flag is C<TRUE>
returns the name of the F<README.md> file

=head2 metadata - Generate the distribution metadata files

   $exit_code = $self->metadata;

Calls L</generate_metadata> with the create flag set to C<FALSE>

=head2 prove - Runs the tests for the distribution

   $exit_code = $self->prove;

Returns the exit code. Runs the distributions tests. If a specific test file
is given on the command line, run only that that test

=head2 select_project - List available projects and select one to edit

   $exit_code = $self->select_project

Use from the shell like this:

   cd $(module_provision -q select_project 2>&1 1>/dev/tty)

Display a list of projects, select one and edit it's project file

=head2 show_tab_title - Display the tab title for the current distribution

   $exit_code = $self->show_tab_title;

Print the tab title for the current project to C<STDOUT>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Moose::Role>

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
