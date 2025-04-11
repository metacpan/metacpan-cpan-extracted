# NAME

OpenAPI::Client::OpenAI - A client for the OpenAI API

# SYNOPSIS

      use OpenAPI::Client::OpenAI;

      # The OPENAI_API_KEY environment variable must be set
      # See https://platform.openai.com/api-keys and ENVIRONMENT VARIABLES below
      my $client = OpenAPI::Client::OpenAI->new();

      my $tx = $client->createCompletion(
          {
              body => {
                  model       => 'gpt-3.5-turbo-instruct',
                  prompt      => 'What is the capital of France?'
                  temperature => 0, # optional, between 0 and 1, with 0 being the least random
                  max_tokens  => 100, # optional, the maximum number of tokens to generate
              }
          }
      );

    my $response_data = $tx->res->json;

    print Dumper($response_data);

# DESCRIPTION

OpenAPI::Client::OpenAI is a client for the OpenAI API built on
top of [OpenAPI::Client](https://metacpan.org/pod/OpenAPI%3A%3AClient). This module automatically handles the API
key authentication according to the provided environment.

Note that the OpenAI API is a paid service. You will need to sign up for an
account.

See [OpenAI::Client::OpenAI::Path](https://metacpan.org/pod/OpenAI%3A%3AClient%3A%3AOpenAI%3A%3APath) for a list of all available paths and methods.

See the `examples/` directory in the distribution for more examples, along
with the tests.

# WARNING

Due to the extremely rapid development of OpenAI's API, this module may may
not be up-to-date with the latest changes. Further releases of this module may
break your code if OpenAI changes their API.

# METHODS

## Constructor

### new

    my $client = OpenAPI::Client::OpenAI->new( $specification, %options );

Create a new OpenAI API client. The following options can be provided:

- `$specification`

    The path to the OpenAPI specification file (YAML). Defaults to the
    "openai.yaml" file in the distribution's "share" directory.

    You can find the latest version of this file at
    [https://github.com/openai/openai-openapi](https://github.com/openai/openai-openapi).

    Examples can be found in the `t/` and `examples/` directories of the
    distribution.

Additional options are passed to the parent class, OpenAPI::Client, with the
exception of the following extra options:

## Other Methods

Other methods are documented in [OpenAPI::Client::OpenAI::Methods](https://metacpan.org/pod/OpenAPI%3A%3AClient%3A%3AOpenAI%3A%3AMethods). These
method are deprecated and will be removed in a future version.

See [OpenAPI::Client::OpenAI::Path](https://metacpan.org/pod/OpenAPI%3A%3AClient%3A%3AOpenAI%3A%3APath) for an index of all paths available. You
can click through each of them for more detail.

# DEPRECATED METHODS

The following methods are deprecated and will be removed in a future release:

- create\_chat\_completion

    Replaced with `createChatCompletion`.

- create\_completion

    Replaced with `createCompletion`.

- create\_embedding

    Replaced with `createEmbedding`.

- create\_image

    Replaced with `createImage`.

- create\_moderation

    Replaced with `createModeration`.

- list\_models

    Replaced with `listModels`.

Originally, these methods were named using `snake_case`, but to simplify the
code, we retained the `camelCase` names in the main module.

# ENVIRONMENT VARIABLES

The following environment variables are used by this module:

- OPENAI\_API\_KEY

    The API key used to authenticate requests to the OpenAI API.

# SEE ALSO

[OpenAI::API](https://metacpan.org/pod/OpenAI%3A%3AAPI) - the deprecated precursor to this module.

# AUTHOR

Nelson Ferraz, <nferraz@gmail.com>

# CONTRIBUTORS

- Curtis "Ovid" Poe, https://github.com/Ovid
- Veesh Goldman, https://github.com/rabbiveesh
- Graham Knop, https://github.com/haarg

# COPYRIGHT AND LICENSE

Copyright (C) 2023-2024 by Nelson Ferraz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.
