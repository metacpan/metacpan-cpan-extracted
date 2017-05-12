package Module::Provision::TraitFor::PrereqDifferences;

use namespace::autoclean;

use Class::Usul::Constants qw( FALSE NUL OK TRUE );
use Class::Usul::Functions qw( classfile ensure_class_loaded
                               is_member emit io );
use Config::Tiny;
use English                qw( -no_match_vars );
use Module::Metadata;
use Perl::Version;
use Moo::Role;

requires qw( appldir builder chdir debug libdir load_meta
             manifest_paths next_argv output project_file run_cmd );

# Private functions
my $_dist_from_module = sub {
   my $module = CPAN::Shell->expand( 'Module', $_[ 0 ] );

   return $module ? $module->distribution : undef;
};

my $_draw_line = sub {
    return emit '-' x ($_[ 0 ] // 60);
};

my $_extract_statements_from = sub {
   my $line = shift;

   return grep { length }
          map  { s{ \A \s+ }{}mx; s{ \s+ \z }{}mx; $_ } split m{ ; }mx, $line;
};

my $_looks_like_version = sub {
    my $ver = shift;

    return defined $ver && $ver =~ m{ \A v? \d+ (?: \.[\d_]+ )? \z }mx;
};

my $_parse_list = sub {
   my $string = shift;

   $string =~ s{ \A q w* [\(/] \s* }{}mx;
   $string =~ s{ \s* [\)/] \z }{}mx;
   $string =~ s{ [\'\"] }{}gmx;
   $string =~ s{ , }{ }gmx;

   return grep { length && !m{ [^\.:\w] }mx } split m{ \s+ }mx, $string;
};

my $_read_non_pod_lines = sub {
   my $path = shift; my $p = Pod::Eventual::Simple->read_file( $path );

   return join "\n", map  { $_->{content} }
                     grep { $_->{type} eq 'nonpod' } @{ $p };
};

my $_recover_module_name = sub {
   my $id = shift;  my @parts = split m{ [\-] }mx, $id; my $ver = pop @parts;

   return  join '::', @parts;
};

my $_version_diff = sub {
   my ($prereq, $depend) = @_;

   $prereq =~ s{ (\. [0-9]+?) 0+ \z }{$1}mx;
   $depend =~ s{ (\. [0-9]+?) 0+ \z }{$1}mx;

   my $oldver = Perl::Version->new( $prereq ); $oldver->components( 2 );
   my $newver = Perl::Version->new( $depend ); $newver->components( 2 );

   return $oldver != $newver ? TRUE : FALSE;
};

my $_emit_diffs = sub {
   my $diffs = shift; $_draw_line->();

   for my $table (sort keys %{ $diffs }) {
      emit $table; $_draw_line->();

      for (sort keys %{ $diffs->{ $table } }) {
         emit "${_} = ".$diffs->{ $table }->{ $_ };
      }

      $_draw_line->();
   }

   return;
};

my $_parse_depends_line = sub {
   my $line = shift; my $modules = [];

   for my $stmt ($_extract_statements_from->( $line )) {
      if ($stmt =~ m{ \A (?: use | require ) \s+ }mx) {
         my (undef, $module, $rest) = split m{ \s+ }mx, $stmt, 3;

         # Skip common pragma and things that don't look like module names
         $module =~ m{ \A (?: lib | strict | warnings ) \z }mx and next;
         $module =~ m{ [^\.:\w] }mx and next;

         push @{ $modules }, $module eq 'base' || $module eq 'parent'
                          ? ($module, $_parse_list->( $rest )) : $module;
      }
      elsif ($stmt =~ m{ \A (?: with | extends ) \s+ (.+) }mx) {
         push @{ $modules }, $_parse_list->( $1 );
      }
      elsif ($stmt =~ m{ ensure_class_loaded [\(]? \s* (.+?) \s* [\)]? }mx) {
         my $module = $1;
            $module = $module =~ m{ \A [q\'\"] }mx ? eval $module : $module;

         push @{ $modules }, $module;
      }
   }

   return $modules;
};

# Private methods
my $_is_perl_source = sub {
   my ($self, $path) = @_;

   $path =~ m{ (?: \.pm | \.t | \.pl ) \z }imx and return TRUE;

   my $line = io( $path )->getline; $line or return FALSE;

   return $line =~ m{ \A \#! (?: .* ) perl (?: \s | \z ) }mx ? TRUE : FALSE;
};

my $_prereq_data = sub {
   my $self = shift; $self->chdir( $self->appldir );

   if ($self->builder eq 'DZ') {
      my $cfg = Config::Tiny->read( 'dist.ini' );

      return { build_requires     => $cfg->{ 'Prereqs / BuildRequires' },
               configure_requires => $cfg->{ 'Prereqs / ConfigureRequires' },
               recommends         => $cfg->{ 'Prereqs / Recommends' },
               requires           => $cfg->{ 'Prereqs' }, };

   }
   elsif ($self->builder eq 'MB') {
      my $cmd  = "${EXECUTABLE_NAME} Build.PL; ./Build prereq_data";

      return eval $self->run_cmd( $cmd )->stdout;
   }

   return {};
};

my $_source_paths = sub {
   return [ grep { $_[ 0 ]->$_is_perl_source( $_ ) }
                @{ $_[ 0 ]->manifest_paths } ];
};

my $_version_from_module = sub {
   my ($self, $module) = @_;

   my $inc  = [ $self->libdir, @INC ];
   my $info = Module::Metadata->new_from_module( $module, inc => $inc );
   my $ver; $info and $info->version and $ver = $info->version;

   return $ver ? Perl::Version->new( $ver ) : undef;
};

my $_compare_prereqs_with_used = sub {
   my ($self, $field, $depends) = @_;

   my $file       = $self->project_file;
   my $prereqs    = $self->$_prereq_data->{ $field };
   my $add_key    = "Would add these to the ${field} in ${file}";
   my $remove_key = "Would remove these from the ${field} in ${file}";
   my $update_key = "Would update these in the ${field} in ${file}";
   my $result     = {};

   for (grep { defined $depends->{ $_ } } keys %{ $depends }) {
      if (exists $prereqs->{ $_ }) {
         if ($_version_diff->( $prereqs->{ $_ }, $depends->{ $_ } )) {
            $result->{ $update_key }->{ $_ }
               = $prereqs->{ $_ }.' => '.$depends->{ $_ };
         }
      }
      else { $result->{ $add_key }->{ $_ } = $depends->{ $_ } }
   }

   for (grep { not exists $depends->{ $_ } } keys %{ $prereqs }) {
      my $ver   = $self->$_version_from_module( $_ );
      my $vdiff = $_version_diff->( $prereqs->{ $_ }, $ver );

      $result->{ $remove_key }->{ $_ }
         = $prereqs->{ $_ }.($vdiff ? " => ${ver}" : NUL);
   }

   return $result;
};

my $_consolidate = sub {
   my ($self, $used) = @_; my (%dists, %result);

   for my $used_key (keys %{ $used }) {
      my ($curr_dist, $module, $used_dist); my $try_module = $used_key;

      while ($curr_dist = $_dist_from_module->( $try_module ) and
             (not $used_dist or $curr_dist->base_id eq $used_dist->base_id)) {
         $module = $try_module;
         $used_dist or $used_dist = $curr_dist;
         $try_module =~ m{ :: }mx or last;
         $try_module =~ s{ :: [^:]+ \z }{}mx;
      }

      if ($used_dist
          and (not $curr_dist or $used_dist->base_id ne $curr_dist->base_id)) {
         my $was = $module;

         $module = $_recover_module_name->( $used_dist->base_id );
         $self->debug and $self->output( "Recovered ${module} from ${was}" );
      }

      if ($module) {
         not exists $dists{ $module }
            and $dists{ $module } = $self->$_version_from_module( $module );
      }
      else { $result{ $used_key } = $used->{ $used_key } }
   }

   $result{ $_ } = $dists{ $_ } for (keys %dists);

   return \%result;
};

my $_dependencies = sub {
   my ($self, $paths) = @_; my $used = {};

   for my $path (@{ $paths }) {
      my $lines = $_read_non_pod_lines->( $path );

      for my $line (split m{ \n }mx, $lines) {
         my $modules = $_parse_depends_line->( $line ); $modules->[ 0 ] or next;

         for (@{ $modules }) {
            $_looks_like_version->( $_ ) and $used->{perl} = $_ and next;

            not exists $used->{ $_ }
               and $used->{ $_ } = $self->$_version_from_module( $_ );
         }
      }
   }

   return $used;
};

my $_filter_dependents = sub {
   my ($self, $used) = @_; my $excludes = 't::boilerplate';

   my $perl_version = $used->{perl} // 5.008_008;
   my $core_modules = $Module::CoreList::version{ $perl_version };
   my $provides     = $self->load_meta->provides;

   return $self->$_consolidate( { map   { $_ => $used->{ $_ }              }
                                  grep  { not exists $core_modules->{ $_ } }
                                  grep  { not exists $provides->{ $_ }     }
                                  grep  { not m{ \A $excludes \z }mx }
                                  keys %{ $used } } );
};

sub _filter_build_requires_paths {
   return [ grep { m{ (?: \.pm | \.t ) \z }mx }
            grep { m{ \A t \b }mx } @{ $_[ 1 ] } ];
}

sub _filter_configure_requires_paths {
   my $file = $_[ 0 ]->project_file;

   return [ grep { m{ \A inc }mx || $_ eq $file } @{ $_[ 1 ] } ];
}

sub _filter_requires_paths {
   my $file    = $_[ 0 ]->project_file;
   my $pattern = $file eq 'dist.ini' ? '(?: Build.PL | Makefile.PL )' : $file;

   return [ grep {     not m{ \A (?: inc | t ) \b }mx
                   and not m{ \A $pattern \z }mx } @{ $_[ 1 ] } ];
}

# Public methods
sub prereq_diffs : method {
   my $self = shift;

   ensure_class_loaded 'CPAN';
   ensure_class_loaded 'Module::CoreList';
   ensure_class_loaded 'Pod::Eventual::Simple';

   my $field   = $self->next_argv // 'requires';
   my $filter  = "_filter_${field}_paths";
   my $sources = $self->$filter( $self->$_source_paths );
   my $depends = $self->$_filter_dependents( $self->$_dependencies( $sources ));

   $_emit_diffs->( $self->$_compare_prereqs_with_used( $field, $depends ) );
   return OK;
}

1;

__END__

=pod

=encoding utf8

=head1 Name

Module::Provision::TraitFor::PrereqDifferences - Displays a prerequisite difference report

=head1 Synopsis

   use Moose;

   extends 'Module::Provision::Base';
   with    'Module::Provision::TraitFor::PrereqDifferences';

=head1 Description

Displays a prerequisite difference report

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 prereq_diffs - Displays a prerequisite difference report

   $exit_code = $self->prereq_diffs;

Shows which dependencies should be added to, removed from, or updated
in the the distributions project file

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<CPAN>

=item L<Module::CoreList>

=item L<Moose::Role>

=item L<Pod::Eventual::Simple>

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
