use strict;
use warnings;

package Smartcat::App::DocumentApi;

use Smartcat::Client::DocumentApi;

use Smartcat::Client::Object::BilingualFileImportSetingsModel;
use Smartcat::Client::Object::UploadDocumentPropertiesModel;
use Smartcat::App::Utils;

use Carp;
$Carp::Internal{ ('Smartcat::Client::DocumentApi') }++;
$Carp::Internal{ (__PACKAGE__) }++;

use Log::Any qw($log);

sub new {
    my ( $class, $api, $rundata ) = @_;

    my $self = bless(
        {
            api     => Smartcat::Client::DocumentApi->new($api),
            rundata => $rundata
        },
        $class
    );

    return $self;
}

sub update_document {
    my ( $self, $path, $document_id ) = @_;
    return unless $path && $document_id;

    my $settings =
      Smartcat::Client::Object::BilingualFileImportSetingsModel->new(
        confirmMode => "atLastStage" );
    my $doc_props =
      Smartcat::Client::Object::UploadDocumentPropertiesModel->new(
        bilingualFileImportSetings => $settings );

    $log->info("Updating document '$document_id' with '$path'...");
    my %args = (
        document_id           => $document_id,
        update_document_model => $doc_props,
        file                  => $path
    );
    $args{disassemble_algorithm_name} =
      $self->{rundata}->{disassemble_algorithm_name}
      if defined $self->{rundata}->{disassemble_algorithm_name};

    my $document = eval { $self->{api}->document_update(%args) };
    die $log->error(
        sprintf(
            "Failed to update document '%s' with '%s'.\nError:\n%s",
            $document_id, $path, format_error_message($@)
        )
    ) unless $document;
}

sub get_document {
    my ( $self, $document_id ) = @_;
    return unless $document_id;

    $log->info("Getting document '$document_id'...");
    my %args = ( document_id => $document_id, );

    my $document = eval { $self->{api}->document_get(%args); };
    die $log->error(
        sprintf(
            "Failed to get document '%s'.\nError:\n%s",
            $document_id, format_error_message($@)
        )
    ) unless $document;

    return $document;
}

sub delete_documents {
    my ( $self, $document_ids ) = @_;
    return unless $document_ids;

    $log->info( 'Deleting documents: ' . join( ', ', @$document_ids ) . '...' );
    my %args = ( document_ids => $document_ids, );

    eval { $self->{api}->document_delete(%args); };
    die $log->error(
        sprintf(
            "Failed to delete documents: %s.\nError:\n%s",
            join( ', ', @$document_ids ),
            format_error_message($@)
        )
    ) if $@;

    return;
}

1;
