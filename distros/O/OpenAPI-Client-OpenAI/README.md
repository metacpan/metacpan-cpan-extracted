# NAME

OpenAPI::Client::OpenAI - A client for the OpenAI API

# SYNOPSIS

    use OpenAPI::Client::OpenAI;

    my $client = OpenAPI::Client::OpenAI->new(); # see ENVIRONMENT VARIABLES

    my $tx = $client->create_completion(...);

    my $response_data = $tx->res->json;

    #print Dumper($response_data);

# DESCRIPTION

OpenAPI::Client::OpenAI is a client for the OpenAI API built on
top of [OpenAPI::Client](https://metacpan.org/pod/OpenAPI%3A%3AClient). This module automatically handles the API
key authentication according to the provided environment.

# METHODS

## Constructor

### new

    my $client = OpenAPI::Client::OpenAI->new( $specification, %options );

Create a new OpenAI API client. The following options can be provided:

- `$specification`

    The path to the OpenAPI specification file (YAML). Defaults to the
    "openai.yaml" file in the distribution's "share" directory.

Additional options are passed to the parent class, OpenAPI::Client.

## Completions

### createCompletion

Creates a completion for the provided prompt and parameters.

## Chat Completions

### createChatCompletion

Creates a completion for the chat message.

## Edits

### createEdit

Creates a new edit for the provided input, instruction, and parameters.

## Images

### createImage

Creates an image given a prompt.

### createImageEdit

Creates an edited or extended image given an original image and a prompt.

### createImageVariation

Creates a variation of a given image.

## Embeddings

### createEmbedding

Creates an embedding vector representing the input text.

## Audio

### createTranscription

Transcribes audio into the input language.

### createTranslation

Translates audio into English.

## Search

### createSearch

The search endpoint computes similarity scores between provided query
and documents. Documents can be passed directly to the API if there are
no more than 200 of them.

To go beyond the 200 document limit, documents can be processed offline
and then used for efficient retrieval at query time. When file is set,
the search endpoint searches over all the documents in the given file
and returns up to the max\_rerank number of documents. These documents
will be returned along with their search scores.

The similarity score is a positive score that usually ranges from 0 to
300 (but can sometimes go higher), where a score above 200 usually means
the document is semantically similar to the query.

## Files

### listFiles

Returns a list of files that belong to the user's organization.

### createFile

Upload a file that contains document(s) to be used across various
endpoints/features.

### deleteFile

Delete a file.

### retrieveFile

Returns information about a specific file.

### downloadFile

Returns the contents of the specified file.

## Answers

### createAnswer

Answers the specified question using the provided documents and examples.

The endpoint first searches over provided documents or files to find
relevant context. The relevant context is combined with the provided
examples and question to create the prompt for completion.

## Classifications

### createClassification

Classifies the specified query using provided examples.

The endpoint first searches over the labeled examples to select the ones
most relevant for the particular query. Then, the relevant examples are
combined with the query to construct a prompt to produce the final label
via the completions endpoint.

Labeled examples can be provided via an uploaded file, or explicitly
listed in the request using the examples parameter for quick tests and
small scale use cases

## Fine-tunes

### createFineTune

Creates a job that fine-tunes a specified model from a given dataset.

Response includes details of the enqueued job including job status and
the name of the fine-tuned models once complete.

### listFineTunes

List your organization's fine-tuning jobs.

### retrieveFineTune

Gets info about the fine-tune job.

### cancelFineTune

Immediately cancel a fine-tune job.

### listFineTuneEvents

Get fine-grained status updates for a fine-tune job.

## Models

### listModels

Lists the currently available models, and provides basic information
about each one such as the owner and availability.

### retrieveModel

Retrieves a model instance, providing basic information about the model
such as the owner and permissioning.

### deleteModel

Delete a fine-tuned model. You must have the Owner role in your
organization.

## Moderations

### createModeration

Classifies if text violates OpenAI's Content Policy.

# ENVIRONMENT VARIABLES

The following environment variables are used by this module:

- OPENAI\_API\_KEY

    The API key used to authenticate requests to the OpenAI API.

# SEE ALSO

[OpenAPI::Client](https://metacpan.org/pod/OpenAPI%3A%3AClient)

# AUTHOR

Nelson Ferraz, <nferraz@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Nelson Ferraz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.
