# ABSTRACT: push translation files to Smartcat
use strict;
use warnings;

package Smartcat::App::Command::push;
use Smartcat::App -command;

use File::Basename;
use File::Spec::Functions qw(catfile catdir);
use File::Find qw(find);
use List::Util qw(first);

use Smartcat::App::Constants qw(
  MAX_ITERATION_WAIT_TIMEOUT
  ITERATION_WAIT_TIMEOUT
  DOCUMENT_DISASSEMBLING_SUCCESS_STATUS
);
use Smartcat::App::Utils;

use Carp;
use Log::Any qw($log);

# How many documents to delete at a time
# (there's a limitation on the number of the document due to
# the fact that all document IDs are specified in a URL,
# and URLs itself have length limitations).
my $DELETE_BATCH_SIZE = 20;

sub opt_spec {
    my ($self) = @_;

    my @opts = $self->SUPER::opt_spec();

    push @opts,
      [ 'disassemble-algorithm-name:s' =>
          'Optional disassemble file algorithm' ],
      [ 'preset-disassemble-algorithm:s' =>
          'Optional disassemble algorithm preset' ],
      [ 'delete-not-existing' => 'Delete not existing documents' ],
      [ 'auto-assign' => 'Auto-sign executives after uploading new documents' ],
      [ 'internal-assign-stages' => 'Comma separated list of internal workflow stage numbers for auto-assign' ],
      $self->project_id_opt_spec,
      $self->project_workdir_opt_spec,
      $self->file_params_opt_spec,
      ;

    return @opts;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->SUPER::validate_args( $opt, $args );
    $self->validate_project_id( $opt, $args );
    $self->validate_project_workdir( $opt, $args );
    $self->validate_file_params( $opt, $args );

    my $app = $self->app;

    $app->{rundata}->{disassemble_algorithm_name} =
      $opt->{disassemble_algorithm_name}
      if defined $opt->{disassemble_algorithm_name};
    $app->{rundata}->{preset_disassemble_algorithm} =
      $opt->{preset_disassemble_algorithm}
      if defined $opt->{preset_disassemble_algorithm};
    $app->{rundata}->{delete_not_existing} =
      defined $opt->{delete_not_existing} ? $opt->{delete_not_existing} : 0;
    $app->{rundata}->{auto_assign} =
      defined $opt->{auto_assign} ? $opt->{auto_assign} : 0;

    if ( defined $opt->{internal_assign_stages} ) {
        $self->usage_error(
"--internal-assign-stages option must be set together with --auto-assign only"
        ) unless $app->{rundata}->{auto_assign};
        $self->usage_error(
"wrong value '$opt->{internal_assign_stages}' for --internal-assign-stages option"
        ) unless $opt->{internal_assign_stages} =~ m/^(\d+,?)+$/;

        $app->{rundata}->{internal_assign_stages} = $opt->{internal_assign_stages};
    }

    $app->{rundata}->{internal_assign_stages} =
      defined $opt->{internal_assign_stages} ? grep {$_ ne ""} split(",", $opt->{internal_assign_stages}) : qw/1/;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $app     = $self->app;
    my $rundata = $app->{rundata};
    $log->info(
        sprintf(
"Running 'push' command for project '%s' and translation files from '%s'...",
            $rundata->{project_id},
            $rundata->{project_workdir}
        )
    );

    my $project = $app->project_api->get_project;
    $app->project_api->update_project_external_tag( $project, "source:Serge" ) if ($#{ $project->documents } >= 0);
    my %documents;
    for ( @{ $project->documents } ) {
        my $key =
            $rundata->{language_file_tree}
          ? $_->name
          : &get_document_key( $_->name, $_->target_language );
        $documents{$key} = [] unless defined $documents{$key};
        push @{ $documents{$key} }, $_;
    }

    my %ts_files;
    find(
        sub {
            if (   -f $File::Find::name
                && !m/^\.$/
                && m/$rundata->{filetype}$/ )
            {
                s/$rundata->{filetype}$//;
                my $name = catfile( dirname($File::Find::name), $_ );
                my $key =
                  $rundata->{language_file_tree} ? $_ : &get_ts_file_key($name);
                $ts_files{$key} = [] unless defined $ts_files{$key};
                push @{ $ts_files{$key} }, $File::Find::name;
            }

        },
        $rundata->{project_workdir}
    );

    my %stats;
    $stats{$_}++ for ( keys %documents, keys %ts_files );

    my ( @upload, @obsolete, @update, @skip );
    push @{
        !$self->_check_if_files_are_empty( $ts_files{$_} )
        ? defined $documents{$_} ? \@update : \@upload
        : defined $documents{$_} ? \@obsolete : \@skip
      },
      $_
      for ( keys %stats );

    $log->info(
        sprintf(
"State:\n  Upload [%d]\n    %s\n  Update [%d]\n    %s\n  Obsolete [%d]\n    %s\n  Skip [%d]\n    %s\n",
            scalar @upload,
            join( ', ', map { "'$_'" } @upload ),
            scalar @update,
            join( ', ', map { "'$_'" } @update ),
            scalar @obsolete,
            join( ', ', map { "'$_'" } @obsolete ),
            scalar @skip,
            join( ', ', map { "'$_'" } @skip )
        )
    );

    $self->upload( $project, $ts_files{$_} ) for @upload;
    $self->update( $project, $documents{$_}, $ts_files{$_} ) for @update;

    if ($rundata->{delete_not_existing}) {
        my @document_ids;
        push( @document_ids, map { $_->id } @{ $documents{$_} } ) for @obsolete;

        # work in batches
        while (scalar(@document_ids) > 0) {
            my @batch = splice(@document_ids, 0, $DELETE_BATCH_SIZE);
            $self->delete( \@batch );
        }
    }

    $log->info(
        sprintf(
"Finished 'push' command for project '%s' and translation files from '%s'.",
            $rundata->{project_id},
            $rundata->{project_workdir}
        )
    );
}

sub delete {
    my ( $self, $document_ids ) = @_;

    $self->app->document_api->delete_documents($document_ids);
}

sub update {
    my ( $self, $project, $documents, $ts_files ) = @_;

    my $app     = $self->app;
    my $api     = $app->document_api;
    my $rundata = $app->{rundata};

    my @target_languages =
      map { &get_language_from_ts_filepath($_) } @$ts_files;
    my @project_target_languages = @{ $project->target_languages };
    my %lang_pairs;
    my @files_without_documents;

    #print Dumper $ts_files;
    for (@$ts_files) {

        #print $_."\n";
        my $lang = get_language_from_ts_filepath($_);
        my $doc = first { $_->target_language eq $lang } @$documents;

        #p $doc;
        if ( defined $doc ) {
            $lang_pairs{$lang} = [ $_, $doc->id ];
        }
        else {
            push @files_without_documents, $_;
        }
    }
    my @documents_without_files =
      grep { !exists $lang_pairs{ $_->target_language } } @$documents;

    $log->warn(
        "No files for documents:"
          . join( ', ',
            map { $_->name . '(' . $_->target_language . ') [' . $_->id . ']' }
              @documents_without_files )
    ) if @documents_without_files;

    $log->warn(
        "No documents for files:" . join( ', ', @files_without_documents ) )
      if @files_without_documents;

    unless ( $rundata->{language_file_tree} ) {
        $api->update_document( @{ $lang_pairs{$_} } ) for ( keys %lang_pairs );
    }
    else {
        $self->_update_tree_document( $ts_files, $documents );
    }
}

sub _check_if_files_are_empty {
    my ($self, $filepaths) = @_;

    my $rundata = $self->app->{rundata};

    if ($rundata->{filetype} eq ".po") {
        return are_po_files_empty($filepaths);
    }

    return 0;
}

sub _upload_tree_document {
    my ( $self, $ts_files, $target_languages ) = @_;

    #my $path = $ts_files->[0];
    my $path = shift @$ts_files;
    my $documents =
      $self->app->project_api->upload_file( $path, basename($path),
        $target_languages );

    $log->info( "Created documents ids:\n  "
          . join( ', ', map { $_->id } @$documents ) );

    $self->_update_tree_document( $ts_files, $documents );
}

sub _update_tree_document {
    my ( $self, $ts_files, $documents ) = @_;

    my $document_api = $self->app->document_api;
    for (@$ts_files) {
        sleep ITERATION_WAIT_TIMEOUT * 5;
        my $lang    = get_language_from_ts_filepath($_);
        my $doc     = first { $_->target_language eq $lang } @$documents;
        my $counter = 0;
        while ( $counter < MAX_ITERATION_WAIT_TIMEOUT ) {
            my $d = $document_api->get_document( $doc->id );
            last
              if $d->document_disassembling_status eq
              DOCUMENT_DISASSEMBLING_SUCCESS_STATUS;
            $log->info(
                sprintf(
"Document '%s' is not disassembled (disassemblingStatus='%s').",
                    $doc->id, $d->document_disassembling_status
                )
            );
            $counter++;
            sleep ITERATION_WAIT_TIMEOUT * 5 * $counter;
        }
        die $log->error( sprintf( "Cannot update document %s.", $doc->id ) )
          if $counter == MAX_ITERATION_WAIT_TIMEOUT;
        $document_api->update_document( $_, $doc->id );
    }
}

sub upload {
    my ( $self, $project, $ts_files ) = @_;

    my $app = $self->app;
    my $rundata = $app->{rundata};
    my $document_api = $app->document_api;

    my @target_languages =
      map { &get_language_from_ts_filepath($_) } @$ts_files;
    my @project_target_languages = @{ $project->target_languages };

    if ( $rundata->{language_file_tree} ) {
        $log->warn(
            sprintf(
"Project target languages do not match translation files.\n  files: %s\n  project: %s",
                join( ', ', @target_languages ),
                join( ', ', @project_target_languages )
            )
        ) unless @target_languages == @project_target_languages;
        $self->_upload_tree_document( $ts_files, \@target_languages );
    }
    else {
        croak("Conflict: one target language to one file expected.")
          unless @$ts_files == 1 && @target_languages == 1;
        my $path     = shift @$ts_files;
        my $filename = prepare_document_name( $path, $rundata->{filetype},
            $target_languages[0] );
        my $documents = $app->project_api->upload_file( $path, $filename,
            \@target_languages );
        my @ids = map { $_->id } @$documents;
        $log->info( "Created documents ids:\n  "
              . join( ', ', @ids ) );

        if ( $rundata->{auto_assign} ) {
            for my $stage_number ( $rundata->{internal_assign_stages} ) {
                $log->info( "Assign documents [" . join(", ", @ids) . "] to MyTeam" );
                $document_api->assign_documents_to_my_team(\@ids, $stage_number);
            }
        }
    }
}

1;
