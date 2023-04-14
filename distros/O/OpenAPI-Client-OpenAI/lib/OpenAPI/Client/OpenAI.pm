package OpenAPI::Client::OpenAI;

use strict;
use warnings;

use Carp;
use File::ShareDir ':ALL';
use File::Spec::Functions qw(catfile);

use Mojo::Base 'OpenAPI::Client';
use Mojo::URL;

our $VERSION = '0.01';

sub new {
    my ( $class, $specification ) = ( shift, shift );
    my $attrs = @_ == 1 ? shift : {@_};

    if ( !$ENV{OPENAI_API_KEY} ) {
        Carp::croak('OPENAI_API_KEY environment variable must be set');
    }

    if ( !$specification ) {
        eval {
            $specification = dist_file( 'OpenAPI-Client-OpenAI', 'openapi.yaml' );
            1;
        } or do {
            # Fallback to local share directory during development
            warn $@;
            $specification = catfile( 'share', 'openapi.yaml' );
        };
    }

    my $self = $class->SUPER::new( $specification, %{$attrs} );

    $self->ua->on(
        start => sub {
            my ( $ua, $tx ) = @_;
            $tx->req->headers->header( 'Authorization' => "Bearer $ENV{OPENAI_API_KEY}" );
        }
    );

    return $self;
}

# install snake case aliases

{
    my %snake_case_alias = (
        createChatCompletion => 'create_chat_completion',
        createCompletion     => 'create_completion',
        createEdit           => 'create_edit',
        createEmbedding      => 'create_embedding',
        createImage          => 'create_image',
        createModeration     => 'create_moderation',
        listModels           => 'list_models',
    );

    for my $camel_case_method ( keys %snake_case_alias ) {
        no strict 'refs';
        *{"$snake_case_alias{$camel_case_method}"} = sub {
            my $self = shift;
            $self->$camel_case_method(@_);
        }
    }
}

1;

__END__

=head1 NAME

OpenAPI::Client::OpenAI - A client for the OpenAI API

=head1 SYNOPSIS

  use OpenAPI::Client::OpenAI;

  my $client = OpenAPI::Client::OpenAI->new(); # see ENVIRONMENT VARIABLES

  my $tx = $client->create_completion(...);

  my $response_data = $tx->res->json;

  #print Dumper($response_data);

=head1 DESCRIPTION

OpenAPI::Client::OpenAI is a client for the OpenAI API built on
top of L<OpenAPI::Client>. This module automatically handles the API
key authentication according to the provided environment.

=head1 METHODS

=head2 Constructor

=head3 new

    my $client = OpenAPI::Client::OpenAI->new( $specification, %options );

Create a new OpenAI API client. The following options can be provided:

=over

=item * C<$specification>

The path to the OpenAPI specification file (YAML). Defaults to the
"openai.yaml" file in the distribution's "share" directory.

=back

Additional options are passed to the parent class, OpenAPI::Client.

=head2 Completions

=head3 createCompletion

Creates a completion for the provided prompt and parameters.

=head2 Chat Completions

=head3 createChatCompletion

Creates a completion for the chat message.

=head2 Edits

=head3 createEdit

Creates a new edit for the provided input, instruction, and parameters.

=head2 Images

=head3 createImage

Creates an image given a prompt.

=head3 createImageEdit

Creates an edited or extended image given an original image and a prompt.

=head3 createImageVariation

Creates a variation of a given image.

=head2 Embeddings

=head3 createEmbedding

Creates an embedding vector representing the input text.

=head2 Audio

=head3 createTranscription

Transcribes audio into the input language.

=head3 createTranslation

Translates audio into English.

=head2 Search

=head3 createSearch

The search endpoint computes similarity scores between provided query
and documents. Documents can be passed directly to the API if there are
no more than 200 of them.

To go beyond the 200 document limit, documents can be processed offline
and then used for efficient retrieval at query time. When file is set,
the search endpoint searches over all the documents in the given file
and returns up to the max_rerank number of documents. These documents
will be returned along with their search scores.

The similarity score is a positive score that usually ranges from 0 to
300 (but can sometimes go higher), where a score above 200 usually means
the document is semantically similar to the query.

=head2 Files

=head3 listFiles

Returns a list of files that belong to the user's organization.

=head3 createFile

Upload a file that contains document(s) to be used across various
endpoints/features.

=head3 deleteFile

Delete a file.

=head3 retrieveFile

Returns information about a specific file.

=head3 downloadFile

Returns the contents of the specified file.

=head2 Answers

=head3 createAnswer

Answers the specified question using the provided documents and examples.

The endpoint first searches over provided documents or files to find
relevant context. The relevant context is combined with the provided
examples and question to create the prompt for completion.

=head2 Classifications

=head3 createClassification

Classifies the specified query using provided examples.

The endpoint first searches over the labeled examples to select the ones
most relevant for the particular query. Then, the relevant examples are
combined with the query to construct a prompt to produce the final label
via the completions endpoint.

Labeled examples can be provided via an uploaded file, or explicitly
listed in the request using the examples parameter for quick tests and
small scale use cases

=head2 Fine-tunes

=head3 createFineTune

Creates a job that fine-tunes a specified model from a given dataset.

Response includes details of the enqueued job including job status and
the name of the fine-tuned models once complete.

=head3 listFineTunes

List your organization's fine-tuning jobs.

=head3 retrieveFineTune

Gets info about the fine-tune job.

=head3 cancelFineTune

Immediately cancel a fine-tune job.

=head3 listFineTuneEvents

Get fine-grained status updates for a fine-tune job.

=head2 Models

=head3 listModels

Lists the currently available models, and provides basic information
about each one such as the owner and availability.

=head3 retrieveModel

Retrieves a model instance, providing basic information about the model
such as the owner and permissioning.

=head3 deleteModel

Delete a fine-tuned model. You must have the Owner role in your
organization.

=head2 Moderations

=head3 createModeration

Classifies if text violates OpenAI's Content Policy.


=head1 ENVIRONMENT VARIABLES

The following environment variables are used by this module:

=over 4

=item * OPENAI_API_KEY

The API key used to authenticate requests to the OpenAI API.

=back

=head1 SEE ALSO

L<OpenAPI::Client>

=head1 AUTHOR

Nelson Ferraz, E<lt>nferraz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Nelson Ferraz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
