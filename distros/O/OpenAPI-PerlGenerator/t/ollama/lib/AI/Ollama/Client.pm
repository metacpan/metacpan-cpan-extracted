package AI::Ollama::Client 0.01;
use 5.020;
use Moo 2;
use experimental 'signatures';

extends 'AI::Ollama::Client::Impl';

=head1 NAME

AI::Ollama::Client - Client for AI::Ollama

=head1 SYNOPSIS

  use 5.020;
  use AI::Ollama::Client;

  my $client = AI::Ollama::Client->new(
      server => 'https://example.com/',
  );
  my $res = $client->someMethod()->get;
  say $res;

=head1 METHODS

=head2 C<< checkBlob >>

  my $res = $client->checkBlob()->get;

Check to see if a blob exists on the Ollama server which is useful when creating models.


=cut

=head2 C<< createBlob >>

  my $res = $client->createBlob()->get;

Create a blob from a file. Returns the server file path.


=cut

=head2 C<< generateChatCompletion >>

  my $res = $client->generateChatCompletion()->get;

Generate the next message in a chat with a provided model.

Returns a L<< AI::Ollama::GenerateChatCompletionResponse >>.

=cut

=head2 C<< copyModel >>

  my $res = $client->copyModel()->get;

Creates a model with another name from an existing model.


=cut

=head2 C<< createModel >>

  my $res = $client->createModel()->get;

Create a model from a Modelfile.

Returns a L<< AI::Ollama::CreateModelResponse >>.

=cut

=head2 C<< deleteModel >>

  my $res = $client->deleteModel()->get;

Delete a model and its data.


=cut

=head2 C<< generateEmbedding >>

  my $res = $client->generateEmbedding()->get;

Generate embeddings from a model.

Returns a L<< AI::Ollama::GenerateEmbeddingResponse >>.

=cut

=head2 C<< generateCompletion >>

  my $res = $client->generateCompletion()->get;

Generate a response for a given prompt with a provided model.

Returns a L<< AI::Ollama::GenerateCompletionResponse >>.

=cut

=head2 C<< pullModel >>

  my $res = $client->pullModel()->get;

Download a model from the ollama library.

Returns a L<< AI::Ollama::PullModelResponse >>.

=cut

=head2 C<< pushModel >>

  my $res = $client->pushModel()->get;

Upload a model to a model library.

Returns a L<< AI::Ollama::PushModelResponse >>.

=cut

=head2 C<< showModelInfo >>

  my $res = $client->showModelInfo()->get;

Show details about a model including modelfile, template, parameters, license, and system prompt.

Returns a L<< AI::Ollama::ModelInfo >>.

=cut

=head2 C<< listModels >>

  my $res = $client->listModels()->get;

List models that are available locally.

Returns a L<< AI::Ollama::ModelsResponse >>.

=cut

1;
