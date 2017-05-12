package Module::Provision::TraitFor::Rendering;

use namespace::autoclean;

use Class::Usul::Constants qw( EXCEPTION_CLASS FALSE NUL OK TRUE );
use Class::Usul::Functions qw( app_prefix is_arrayref distname io throw );
use File::DataClass::Types qw( ArrayRef Bool Directory Path SimpleStr );
use File::ShareDir           ( );
use Scalar::Util           qw( blessed weaken );
use Template;
use Unexpected::Functions  qw( Unspecified );
use Moo::Role;
use Class::Usul::Options;

requires qw( add_leader appldir builder config dist_module exec_perms file
             incdir initial_wd loc log perms stash testdir vcs yorn );

# Object attributes (public)
option 'force'        => is => 'ro',   isa => Bool,
   documentation      => 'Overwrite files if they already exist',
   default            => FALSE, short => 'f';

option 'templates'    => is => 'ro',   isa => SimpleStr, format => 's',
   documentation      => 'Non default location of the code templates',
   default            => NUL;

has 'template_dir'    => is => 'lazy', isa => Directory, coerce => TRUE,
   init_arg           => undef;

has 'template_list'   => is => 'lazy', isa => ArrayRef, init_arg => undef;

# Object attributes (private)
has '_template_index' => is => 'lazy', isa => Path, coerce => TRUE,
   init_arg           => undef;

# Private methods
my $_deref_tmpl = sub {
   my ($self, $car) = @_; '_' ne substr $car, 0, 1 and return $car;

   my $reader = substr $car, 1; return $self->$reader();
};

my $_merge_lists = sub {
   my ($self, $args) = @_; my $list = $args->{templates};

   push @{ $list }, @{ $args->{builders}->{ $self->builder } };
   $self->vcs ne 'none' and push @{ $list }, @{ $args->{vcs}->{ $self->vcs } };

   return $list;
};

my $_template_args = sub {
   my $self = shift; weaken( $self ); my $args = { ABSOLUTE => TRUE, };

   $args->{VARIABLES}->{loc} = sub { $self->loc( @_ ) };

   return $args;
};

# Construction
sub _build_template_dir {
   my $self  = shift;
   my $class = blessed $self;
   my $tgt   = $self->templates
             ? io( [ $self->templates ] )->absolute( $self->initial_wd )
             : io( [ $self->config->my_home, '.'.(app_prefix $class) ] );

   $tgt->exists and return $tgt; $tgt->mkpath( $self->exec_perms );

   my $dist  = io( File::ShareDir::dist_dir( distname $class ) );

   $_->copy( $tgt ) for ($dist->all_files);

   return $tgt;
}

sub _build__template_index {
   return $_[ 0 ]->template_dir->catfile( $_[ 0 ]->config->template_index );
}

sub _build_template_list {
   my $self = shift; my $index = $self->_template_index;

   my $data; $index->exists and $data = $self->file->data_load
      ( paths => [ $index ], storage_class => 'Any' )
      and return $self->$_merge_lists( $data );
   my $builders  = {
      DZ => [ [ 'dist.ini',      '_appldir' ],
              [ 'DZ_Build.PL', [ '_appldir', '.build.PL' ], ], ],
      MB => [ [ 'Build.PL',      '_appldir' ], ], };
   my $templates = [ [ 'Changes',         '_appldir'     ],
                     [ 'MANIFEST.SKIP',   '_appldir'     ],
                     [ 'travis.yml',    [ '_appldir', '.travis.yml' ] ],
                     [ 'perl_module.pm',  '_dist_module' ],
                     [ '02pod.t',         '_testdir'     ],
                     [ '03podcoverage.t', '_testdir'     ],
                     [ '05kwalitee.t',    '_testdir'     ],
                     [ '06yaml.t',        '_testdir'     ],
                     [ '07podspelling.t', '_testdir'     ],
                     [ '10test_script.t', '_testdir'     ],
                     [ 'boilerplate.pm',  '_testdir'     ], ];
   my $vcs = {
      git => [ [ 'gitcommit-msg', [ '_appldir', '.gitcommit-msg' ] ],
               [ 'gitignore',     [ '_appldir', '.gitignore'     ] ],
               [ 'gitpre-commit', [ '_appldir', '.gitpre-commit' ] ], ],
      svn => [], };

   $self->output( 'Creating index [_1]', { args => [ $index ] } );
   $data = { builders => $builders, templates => $templates, vcs => $vcs };
   $self->file->data_dump
      ( data => $data, path => $index, storage_class => 'Any' );
   return $self->$_merge_lists( $data );
}

# Public methods
sub dump_stash : method {
   my $self = shift; $self->dumper( $self->stash ); return OK;
}

sub expand_tuple {
   my ($self, $tuple) = @_;

   for (my $i = 0, my $max = @{ $tuple }; $i < $max; $i++) {
      if (is_arrayref $tuple->[ $i ]) {
         $tuple->[ $i ]->[ 0 ] = $self->$_deref_tmpl( $tuple->[ $i ]->[ 0 ] );
         $tuple->[ $i ] = io( $tuple->[ $i ] );
      }
      else {
         $tuple->[ $i ] = $self->$_deref_tmpl( $tuple->[ $i ] );
      }
   }

   return $tuple;
}

sub init_templates : method {
   my $self = shift; $self->template_list; return OK;
}

sub render_template {
   my ($self, $template, $target) = @_;

   $template or throw Unspecified, [ 'Template' ];
   $target   or throw Unspecified, [ 'Template target' ];

   $target->exists and $target->is_dir
      and $target = $target->catfile( $template );
   $template = $self->template_dir->catfile( $template );

   $template->exists or
      return $self->log->warn( $self->loc( 'Path [_1] not found', $template ) );

   my $file  = $target->filename; my $prompt;

   $target->exists and not $self->force
      and $prompt = $self->loc( 'File [_1] exists, overwrite?', $file )
      and not $self->yorn( $self->add_leader( $prompt ), FALSE, TRUE )
      and return $target;

   my $tmplt = Template->new( $self->$_template_args )
      or throw $Template::ERROR;
   my $text  = NUL;

   $tmplt->process( $template->pathname, $self->stash, \$text )
      or throw $tmplt->error();
   $target->perms( $self->perms )->print( $text ); $target->close;
   return $target;
}

sub render_templates {
   my $self = shift; $self->quiet or $self->output( 'Rendering templates' );

   for my $tuple (map { $self->expand_tuple( $_ ) } @{ $self->template_list }) {
      $self->render_template( @{ $tuple } );
   }

   return;
}

1;

__END__

=pod

=encoding utf8

=head1 Name

Module::Provision::TraitFor::Rendering - Renders Templates

=head1 Synopsis

   use Moose;

   extends 'Module::Provision::Base';
   with    'Module::Provision::TraitFor::Rendering';

=head1 Description

Renders templates. Uses a list stored in the index file F<index.json> which
by default is in the F<~/.module_provision> directory

=head1 Configuration and Environment

Requires the consuming class to define the attributes; C<appldir>,
C<builder>, C<dist_module>, C<incdir>, C<initial_wd>, C<stash>,
C<testdir>, and C<vcs>

Defines the following attributes;

=over 3

=item C<force>

Overwrite the output files if they already exist

=item C<templates>

Location of the code templates in the users home directory. Defaults to
F<.module_provision>

=item C<template_dir>

Directory where the templates live

=item C<template_list>

Data structure that maps the files in the template directory to the files
in the project directory

=back

=head1 Subroutines/Methods

=head2 dump_stash - Dump the hash ref used to render a template

   $exit_code = $self->dump_stash;

Uses the internal dumper method to produce a pretty coloured listing

=head2 expand_tuple

   $tuple = $self->expand_tuple( $tuple );

Expands the references in the passed tuple

=head2 init_templates - Initialise the template directory

   $exit_code = $self->init_templates;

Initialise the F<.module_provision> directory and create the F<index.json> file

=head2 render_template

   $target = $self->render_template( $template, $target );

Renders a single template using L<Template>

=head2 render_templates

   $self->render_templates;

Renders the list of templates in C<< $self->template_list >> be
repeatedly calling calling L</render_template>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<File::DataClass>

=item L<File::ShareDir>

=item L<Moose::Role>

=item L<Template>

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
