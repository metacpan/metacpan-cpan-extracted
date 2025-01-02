# Examples

The examples in this directory are to show the basics of how to use this
module.

# Example Models

Inside the examples, we generally specify a particular OpenAI model we wish to
use, such as `gpt-3.5-turbo`. Because there are costs associated with calling
the API, we generally use the least expensive model available for a given
task. To run `example/chat.pl`, you get `gpt-3.5-turbo` and a short chat
session might cost less than a penny.

However, this is the least powerful model available and chat results might be
disappointing. Consult [the
schema](https://metacpan.org/pod/OpenAPI%3A%3AClient%3A%3AOpenAI%3A%3ASchema)
to see a list of models available for any given request and choose the one
most appropriate for your needs.

# Do Not Use the Code Directly

If you use this in production code, however, you do _not_ want to call these
directly from your business logic. For example, consider the code to
transcribe an audio file to text:

    my $client = OpenAPI::Client::OpenAI->new;
    $client->ua->inactivity_timeout( 60 * 10 );    # ten minutes
    my $response = $client->createTranscription(
        {},
        file_upload => {
            file     => $audio_file,
            model    => 'whisper-1',
            language => 'en',
        },
    );

    if ( $response->res->is_success ) {
        try {
            my $result = decode_json( $response->res->content->asset->slurp );
            say $result->{text};
        } catch ($e) {
            die "Error decoding JSON: $e\n";
        }
    } else {
        warn Dumper( $response->res );
    }

Instead, in your business logic, you probably want something like this:

    my $text = await { $llm->transcribe( audio => $audio_file ) };

The above assumes that your version of the `transcribe` method returns a
promise. If it does not, simply omit the `await`

By abstracting away the `transcribe` method's implementation, you can easily
change it, later. You can pull a cached transcription. You an switch to a
local LLM.  If the OpenAI spec changes and you need to adjust the call, so be
it.

As AI grows in capabilities, you will want your high-level code to remain as
static as possible and only make the smallest changes necessary to make your
code work.
