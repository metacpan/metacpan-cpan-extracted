use strict;
use warnings;

package Smartcat::App::DocumentExportApi;

use File::Spec::Functions qw(catfile);
use IO::Uncompress::Unzip qw($UnzipError);
use Log::Any qw($log);

use Smartcat::Client::DocumentExportApi;

use Smartcat::App::Constants qw(
  EXPORT_ZIP_FILES_COUNT
  TOTAL_ITERATION_COUNT
  ITERATION_WAIT_TIMEOUT
);
use Smartcat::App::Utils;

use Carp;
$Carp::Internal{ ('Smartcat::Client::DocumentExportApi') }++;
$Carp::Internal{ (__PACKAGE__) }++;

use Log::Any qw($log);

use Data::Dumper;

sub new {
    my ( $class, $api, $rundata ) = @_;

    my $self = bless(
        {
            api     => Smartcat::Client::DocumentExportApi->new($api),
            rundata => $rundata
        },
        $class
    );

    return $self;
}

sub export_files {
    my ( $self, $documents ) = @_;

    my $api     = $self->{api};
    my $rundata = $self->{rundata};
    my %docs    = map { $_->id => $_ } @$documents;
    my @doc_ids = keys %docs;
    my @tasks;
    while ( $#doc_ids >= 0 ) {
        my @task_doc_ids = splice( @doc_ids, 0, EXPORT_ZIP_FILES_COUNT );
        my $task = eval {
            $api->document_export_request_export(
                document_ids => \@task_doc_ids );
        };
        die $log->error(
            sprintf(
"Failed to register a task for exporting documents: '%s'.\nError:\n%s",
                join( ', ', @task_doc_ids ),
                format_error_message($@)
            )
        ) unless ($task);
        push @tasks, $task;
    }

    foreach my $task (@tasks) {
        my $single_file_export = $#{ $task->document_ids } == 0;
        my $response;
        my $counter = 0;

        #die $task->id;
        $log->info( sprintf( "Processing task '%s'...", $task->id ) );
        while ( $counter < TOTAL_ITERATION_COUNT ) {
            $log->info("Downloading exported files...");
            $response = eval {
                $api->document_export_download_export_result(
                    task_id => $task->id );
            };
            unless ($response) {
                die $log->error(
                    sprintf(
"Failed to download exported files for task '%s'.\nError:\n%s",
                        $task->id, format_error_message($@)
                    )
                );
            }

            last if $response->code != 204;
            $log->info("Export is not ready...");
            $counter++;
            sleep ITERATION_WAIT_TIMEOUT * $counter;
        }
        die $log->error(
            sprintf( "Cannot download exported files: %s",
                join( ', ', @{ $task->document_ids } ) )
        ) if $counter == TOTAL_ITERATION_COUNT;
        if ($single_file_export) {
            my $doc  = $docs{ @{ $task->document_ids }[0] };
            my $name = $doc->name;
            $log->info("Processing document '$name'...");
            my $filename = prepare_file_name( $name, $doc->target_language,
                $rundata->{filetype} );
            my $filepath = catfile( $rundata->{project_workdir},
                $doc->target_language, $filename );
            save_file( $filepath, $response->content );
            $log->info("Saved to '$filepath'.");
        }
        else {
            $self->_save_exported_files_from_zip( $task, $response->content );
        }
    }
}

sub _save_exported_files_from_zip {
    my ( $self, $task, $content ) = @_;

    my $u = new IO::Uncompress::Unzip \$content
      or die $log->error(
        "Cannot open downloaded content of $task->id: $UnzipError");
    my $rundata = $self->{rundata};
    my $status  = 0;
    $log->info("Processing zipped exported file...");
    do {
        my $name = $u->getHeaderInfo()->{Name};
        die $log->error(
"Cannot parse '$name' (filetype='$rundata->{filetype}') to get filename and target_language"
        ) unless $name =~ m/(.*)\((.*)\)$rundata->{filetype}$/;
        $log->info("Processing member '$name'...");
        my $target_language = $2;
        my $filename =
          prepare_file_name( $1, $target_language, $rundata->{filetype} );
        my $filepath =
          catfile( $rundata->{project_workdir}, $target_language, $filename );

        #print Dumper $self;
        open( my $fh, '>', $filepath )
          or die $log->error("Could not open file '$filepath' $!");
        binmode($fh);
        print $fh $_ while <$u>;
        close $fh;
        $log->info("Saved to '$filepath'.");
    } while ( ( $status = $u->nextStream() ) > 0 );
    die $log->error("Error processing downloaded content of $task->id: $!")
      if $status < 0;
}

1;
