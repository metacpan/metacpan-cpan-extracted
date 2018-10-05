# ABSTRACT: get document details
use strict;
use warnings;

package Smartcat::App::Command::document;
use Smartcat::App -command;

sub opt_spec {
    my ($self) = @_;

    my @opts = $self->SUPER::opt_spec();

    push @opts,
      [ 'document-ids|document-id:s@' => 'Document Ids' ],
      [ 'delete'                      => 'Delete documents' ];

    return @opts;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->SUPER::validate_args( $opt, $args );
    $self->usage_error("'document_id' is required")
      unless defined $opt->{document_ids};
}

sub get_and_print_document_details {
    my ( $self, $document_id ) = @_;
    my $document = $self->app->document_api->get_document($document_id);

    printf(
"Document Details\n  Name: '%s'\n  Id: '%s'\n  Status: '%s'\n  DisassemblingStatus: '%s'\n",
        $document->name, $document->id, $document->status,
        $document->document_disassembling_status );
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    if ( defined $opt->{delete} ) {
        $self->app->document_api->delete_documents( $opt->{document_ids} );
        exit 0;
    }
    $self->get_and_print_document_details($_) for @{ $opt->{document_ids} };
}

1;
