package Module::Provision::Base;

use namespace::autoclean;

use Class::Usul::Constants qw( EXCEPTION_CLASS NUL SPC TRUE );
use Class::Usul::Functions qw( app_prefix class2appdir classdir
                               distname first_char io is_arrayref throw );
use Class::Usul::Time      qw( time2str );
use CPAN::Meta;
use English                qw( -no_match_vars );
use File::DataClass::Types qw( ArrayRef Directory HashRef NonEmptySimpleStr
                               Object OctalNum Path PositiveInt
                               SimpleStr Undef );
use Module::Metadata;
use Perl::Version;
use Try::Tiny;
use Type::Utils            qw( enum );
use Unexpected::Functions  qw( Unspecified );
use Moo;
use Class::Usul::Options;

extends q(Class::Usul::Programs);

my %BUILDERS = ( 'DZ' => 'dist.ini', 'MB' => 'Build.PL', );
my $BUILDER  = enum 'Builder' => [ qw( DZ MB ) ];
my $VCS      = enum 'VCS'     => [ qw( git none svn ) ];

# Override defaults in base class
has '+config_class' => default => sub { 'Module::Provision::Config' };

# Object attributes (public)
#   Visible to the command line
option 'base'       => is => 'lazy', isa => Path, format => 's',
   documentation    => 'Directory containing new projects',
   builder          => sub { $_[ 0 ]->config->base }, coerce => TRUE;

option 'branch'     => is => 'lazy', isa => SimpleStr, format => 's',
   documentation    => 'The name of the initial branch to create', short => 'b';

option 'builder'    => is => 'lazy', isa => $BUILDER, format => 's',
   documentation    => 'Which build system to use: DZ or MB';

option 'license'    => is => 'ro',   isa => NonEmptySimpleStr, format => 's',
   documentation    => 'License used for the project',
   builder          => sub { $_[ 0 ]->config->license };

option 'perms'      => is => 'ro',   isa => OctalNum, format => 'i',
   documentation    => 'Default permission for file / directory creation',
   default          => '640', coerce => TRUE;

option 'plugins'    => is => 'ro',   isa => ArrayRef[NonEmptySimpleStr],
   documentation    => 'Name of optional plugins to load, comma separated list',
   builder          => sub { [] }, format => 's', short => 'M',
   coerce           => sub { (is_arrayref $_[ 0 ])
                                ? $_[ 0 ] : [ split m{ , }mx, $_[ 0 ] ] };

option 'project'    => is => 'lazy', isa => NonEmptySimpleStr, format => 's',
   documentation    => 'Package name of the new projects main module';

option 'repository' => is => 'ro',   isa => NonEmptySimpleStr, format => 's',
   documentation    => 'Directory containing the SVN repository',
   builder          => sub { $_[ 0 ]->config->repository };

option 'vcs'        => is => 'lazy', isa => $VCS, format => 's',
   documentation    => 'Which VCS to use: git, none, or svn';

#   Ingnored by the command line
has 'appbase'         => is => 'lazy', isa => Path, coerce => TRUE;

has 'appldir'         => is => 'lazy', isa => Path, coerce => TRUE;

has 'branch_file'     => is => 'lazy', isa => Path, coerce => TRUE,
   builder            => sub { [ $_[ 0 ]->appbase, '.branch' ] };

has 'binsdir'         => is => 'lazy', isa => Path, coerce => TRUE,
   builder            => sub { [ $_[ 0 ]->appldir, 'bin' ] };

has 'default_branch'  => is => 'lazy', isa => SimpleStr;

has 'dist_module'     => is => 'lazy', isa => Path, coerce => TRUE,
   builder            => sub { [ $_[ 0 ]->homedir.'.pm' ] };

has 'dist_version'    => is => 'lazy', isa => Object, clearer => TRUE;

has 'distname'        => is => 'lazy', isa => NonEmptySimpleStr,
   builder            => sub { distname $_[ 0 ]->project };

has 'exec_perms'      => is => 'lazy', isa => PositiveInt;

has 'homedir'         => is => 'lazy', isa => Path, coerce => TRUE;

has 'incdir'          => is => 'lazy', isa => Path, coerce => TRUE,
   builder            => sub { [ $_[ 0 ]->appldir, 'inc' ] };

has 'initial_wd'      => is => 'ro',   isa => Directory,
   builder            => sub { io()->cwd };

has 'libdir'          => is => 'lazy', isa => Path, coerce => TRUE,
   builder            => sub { [ $_[ 0 ]->appldir, 'lib' ] };

has 'license_keys'    => is => 'lazy', isa => HashRef;

has 'manifest_paths'  => is => 'lazy', isa => ArrayRef, init_arg => undef;

has 'module_abstract' => is => 'lazy', isa => NonEmptySimpleStr;

has 'module_metadata' => is => 'lazy', isa => Object | Undef, builder => sub {
   Module::Metadata->new_from_file
      ( $_[ 0 ]->dist_module->abs2rel( $_[ 0 ]->appldir ), collect_pod => 1 ) },
   clearer            => TRUE;

has 'project_file'    => is => 'lazy', isa => NonEmptySimpleStr;

has 'stash'           => is => 'lazy', isa => HashRef;

has 'testdir'         => is => 'lazy', isa => Path, coerce => TRUE,
   builder            => sub { [ $_[ 0 ]->appldir, 't' ] };

# Private functions
my $_builders = sub {
   return (sort keys %BUILDERS);
};

my $_get_module_from = sub { # Return main module name from project file
   return
      (map    { s{ [-] }{::}gmx; $_ }
       map    { m{ \A [q\'\"] }mx ? eval $_ : $_ }
       map    { m{ \A \s* (?:module_name|module|name)
                      \s+ [=]?[>]? \s* ([^,;]+) [,;]? }imx }
       grep   { m{ \A \s*   (module|name) }imx }
       split m{ [\n] }mx, $_[ 0 ])[ 0 ];
};

my $_parse_manifest_line = sub { # Robbed from ExtUtils::Manifest
   my $line = shift; my ($file, $comment);

   # May contain spaces if enclosed in '' (in which case, \\ and \' are escapes)
   if (($file, $comment) = $line =~ m{ \A \' (\\[\\\']|.+)+ \' \s* (.*) }mx) {
      $file =~ s{ \\ ([\\\']) }{$1}gmx;
   }
   else {
       ($file, $comment) = $line =~ m{ \A (\S+) \s* (.*) }mx;
   }

   return [ $file, $comment ];
};

my $_get_project_file = sub {
   my $dir = shift; my $prev;

   while (not $prev or $prev ne $dir) { # Search for dist.ini first
      for my $file (map { $dir->catfile( $BUILDERS{ $_ } ) } $_builders->()) {
         $file->exists and return $file
      }

      $prev = $dir; $dir = $dir->parent;
   }

   return;
};

# Construction
sub BUILD {
   my $self = shift;

   for my $plugin (@{ $self->plugins }) {
      if (first_char $plugin eq '+') { $plugin = substr $plugin, 1 }
      else { $plugin = "Module::Provision::TraitFor::${plugin}" }

      try   { Role::Tiny->apply_roles_to_object( $self, $plugin ) }
      catch {
         $_ =~ m{ \ACan\'t \s+ locate }mx
            and throw 'Package [_1] not found in @INC', [ $plugin ];
         throw $_;
      };
   }

   return;
}

sub _build_appbase { # Base + distname
   my $self    = shift;
   my $base    = $self->base->absolute( $self->initial_wd );
   my $appbase = $base->catdir( $self->distname );

   $appbase->exists and return $appbase;

   # This is so you can rename the dist directory
   my $file         = $_get_project_file->( $self->initial_wd );
   my $grand_parent = $file && $file->parent && $file->parent->parent;

   $grand_parent and $grand_parent !~ m{ \.build \z }mx
      and $grand_parent->exists and return $grand_parent;

   return $appbase;
}

sub _build_appldir {
   my $self = shift; my $appbase = $self->appbase; my $branch = $self->branch;

   my $home = $self->config->my_home; my $vcs = $self->vcs;

  (my $rel_appbase = $appbase) =~ s{ \Q$home\E [\\/] }{}mx;

   $self->debug and $self->info
      ( "Appbase: ${rel_appbase}, Branch: ${branch}, VCS: ${vcs}" );

   return $vcs eq 'none'                      ? $appbase
        : $appbase->catdir( '.git'  )->exists ? $appbase
        : $appbase->catdir( '.svn'  )->exists ? $appbase
        : $appbase->catdir( $branch )->exists ? $appbase->catdir( $branch )
                                              : undef;
}

sub _build_branch {
   my $self = shift; my $branch = $ENV{BRANCH}; $branch and return $branch;

   $self->branch_file->exists and return $self->branch_file->chomp->getline;

   return $self->default_branch;
}

sub _build_builder {
   my $self = shift; my $appldir = $self->appldir;

   for (map { [ $appldir->catfile( $BUILDERS{ $_ } ), $_ ] } $_builders->()) {
      $_->[ 0 ]->exists and return $_->[ 1 ];
   }

   return;
}

sub _build_default_branch {
   return $_[ 0 ]->config->default_branches->{ $_[ 0 ]->vcs } // NUL;
}

sub _build_dist_version {
   my $self = shift; my $meta = $self->module_metadata;

   return Perl::Version->new( $meta ? $meta->version : '0.1.1' );
}

sub _build_exec_perms {
   return (($_[ 0 ]->perms & oct '0444') >> 2) | $_[ 0 ]->perms;
}

sub _build_homedir {
   return [ $_[ 0 ]->libdir, classdir $_[ 0 ]->project ];
}

sub _build_license_keys {
   return {
      perl       => 'Perl_5',
      perl_5     => 'Perl_5',
      apache     => [ map { "Apache_$_" } qw( 1_1 2_0 ) ],
      artistic   => 'Artistic_1_0',
      artistic_2 => 'Artistic_2_0',
      lgpl       => [ map { "LGPL_$_" } qw( 2_1 3_0 ) ],
      bsd        => 'BSD',
      gpl        => [ map { "GPL_$_" } qw( 1 2 3 ) ],
      mit        => 'MIT',
      mozilla    => [ map { "Mozilla_$_" } qw( 1_0 1_1 ) ], };
}

sub _build_manifest_paths {
   my $self = shift;

   return [ grep { $_->exists }
            map  { io( $_parse_manifest_line->( $_ )->[ 0 ] ) }
            grep { not m{ \A \s* [\#] }mx }
            $self->appldir->catfile( 'MANIFEST' )->chomp->getlines ];
}

sub _build_module_abstract {
   my $self = shift; my $meta = $self->module_metadata; my $abstract = NUL;

   $meta and ($abstract = $meta->pod( 'Name' ) // NUL)
      =~ s{ \A [^\-]+ \s* [\-] \s* }{}mx; chomp $abstract;

   return $self->loc( $abstract || $self->config->module_abstract );
}

sub _build_project {
   my $self   = shift;
   my $file   = $_get_project_file->( $self->initial_wd )
      or throw 'Path [_1] contains no project file', [ $self->initial_wd ];
   my $module = $_get_module_from->( $file->all )
      or throw 'File [_1] contains no module name', [ $file ];

   return $module;
}

sub _build_project_file {
   return $BUILDERS{ $_[ 0 ]->builder };
}

sub _build_stash {
   my $self = shift; my $config = $self->config; my $author = $config->author;

   my $project = $self->project; my $perl_ver = $self->config->min_perl_ver;

   my $perl_code = $self->method eq 'dist' ? "use ${perl_ver};" : NUL;

   return { abstract        => $self->module_abstract,
            appdir          => class2appdir $self->distname,
            author          => $author,
            author_email    => $config->author_email,
            author_id       => $config->author_id,
            author_ID       => uc $config->author_id,
            copyright       => $ENV{ORGANIZATION} || $author,
            copyright_year  => time2str( '%Y' ),
            creation_date   => time2str,
            dist_module     => $self->dist_module->abs2rel( $self->appldir ),
            dist_version    => NUL.$self->dist_version,
            distname        => $self->distname,
            first_name      => lc ((split SPC, $author)[ 0 ]),
            home_page       => $config->home_page,
            initial_wd      => NUL.$self->initial_wd,
            last_name       => lc ((split SPC, $author)[ -1 ]),
            lc_distname     => lc $self->distname,
            license         => $self->license,
            license_class   => $self->license_keys->{ $self->license },
            module          => $project,
            perl            => $perl_ver,
            prefix          => (split m{ :: }mx, lc $project)[ -1 ],
            project         => $project,
            pub_repo_prefix => $config->pub_repo_prefix,
            use_perl        => $perl_code,
            version         => $self->VERSION, };
}

sub _build_vcs {
   my $self = shift; my $appbase = $self->appbase;

   return $appbase->catdir( '.git'            )->exists ? 'git'
        : $appbase->catdir( 'master', '.git'  )->exists ? 'git'
        : $appbase->catdir( '.svn'            )->exists ? 'svn'
        : $appbase->catdir( 'trunk', '.svn'   )->exists ? 'svn'
        : $appbase->catdir( $self->repository )->exists ? 'svn'
                                                        : 'none';
}

# Public methods
sub chdir {
   my ($self, $dir) = @_;

         $dir or throw Unspecified, [ 'directory' ];
   chdir $dir or throw 'Directory [_1] cannot chdir: [_2]', [ $dir, $OS_ERROR ];
   return $dir;
}

sub load_meta {
   my ($self, $dir) = @_;

   not $dir and $self->builder eq 'DZ'
            and $dir = io $self->distname.'-'.$self->dist_version;

   my $path = $dir ? $dir->catfile( 'META.json' ) : 'META.json';

   return CPAN::Meta->load_file( "${path}" );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Module::Provision::Base - Immutable data object

=head1 Synopsis

   use Moose;

   extends 'Module::Provision::Base';

=head1 Description

Creates an immutable data object required by the methods in the applied roles

=head1 Configuration and Environment

Defines the following list of attributes which can be set from the
command line;

=over 3

=item C<base>

The directory which will contain the new project. Defaults to the users
home directory

=item C<branch>

The name of the initial branch to create. Defaults to F<master> for
Git and F<trunk> for SVN

=item C<builder>

Which of the two build systems to use. Set to C<MB>
for L<Module::Build> or C<DZ> for L<Dist::Zilla>

=item C<config_class>

The name of the configuration class

=item C<initial_wd>

The working directory when the command was invoked

=item C<license>

The name of the license used on the project. Defaults to C<perl>

=item C<perms>

Permissions used to create files. Defaults to C<644>. Directories and
programs have the execute bit turned on if the corresponding read bit
is on

=item C<plugins>

Optional trait to load and apply

=item C<project>

The class name of the new project. Should be the first extra argument on the
command line

=item C<repository>

Name of the directory containing the SVN repository. Defaults to F<repository>

=item C<vcs>

The version control system to use. Defaults to C<none>, can be C<git>
or C<svn>

=back

=head1 Subroutines/Methods

=head2 BUILD

Load and apply optional traits

=head2 chdir

   $directory = $self->chdir( $directory );

Changes the current working directory to the one supplied and returns it.
Throws if the operation was not successful

=head2 load_meta

   $cpan_meta_object = $self->load_meta( $optional_directory );

Loads the F<META.json> file and returns and object

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<File::DataClass>

=item L<Module::Metadata>

=item L<Module::Provision::Config>

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
