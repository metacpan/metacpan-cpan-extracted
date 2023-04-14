# NAME

OpenAI::API - Perl interface to OpenAI API

# VERSION

0.37

# SYNOPSIS

    use OpenAI::API;

    my $openai = OpenAI::API->new();    # uses OPENAI_API_KEY environment variable

    my $res = $openai->chat(
        messages => [
            { "role" => "system",    "content" => "You are a helpful assistant." },
            { "role" => "user",      "content" => "How can I access OpenAI's APIs in Perl?" },
            { "role" => "assistant", "content" => "You can use the OpenAI::API module." },
            { "role" => "user",      "content" => "Where can I find this module?" },
        ],
        max_tokens  => 20,
        temperature => 0,
    );

    my $message = $res->{choices}[0]{message};    # or simply: my $message = "$res";

# DESCRIPTION

OpenAI::API is a Perl module that provides an interface to the OpenAI API,
which allows you to generate text, translate languages, summarize text,
and perform other tasks using the language models developed by OpenAI.

To use the OpenAI::API module, you will need an API key, which you can obtain by
signing up for an account on the [OpenAI website](https://platform.openai.com).

# INSTALLATION

If you have cpanm, you only need one line:

    % cpanm OpenAI::API

Alternatively, if your CPAN shell is set up, you should just be able
to do:

    % cpan OpenAI::API

As a last resort, you can manually install it:

    perl Makefile.PL
    make
    make test
    make install

If your perl is system-managed, you can create a [local::lib](https://metacpan.org/pod/local%3A%3Alib) in your
home directory to install modules to. For details, see the
[local::lib documentation](https://metacpan.org/pod/local::lib).

# DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc OpenAI::API

# RESOURCES

- [OpenAI::API::Request::Chat](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3AChat)
- [OpenAI::API::Request::Completion](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3ACompletion)
- [OpenAI::API::Request::Edit](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3AEdit)
- [OpenAI::API::Request::Embedding](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3AEmbedding)
- [OpenAI::API::Request::File::List](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3AFile%3A%3AList)
- [OpenAI::API::Request::File::Retrieve](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3AFile%3A%3ARetrieve)
- [OpenAI::API::Request::Image::Generation](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3AImage%3A%3AGeneration)
- [OpenAI::API::Request::Model::List](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3AModel%3A%3AList)
- [OpenAI::API::Request::Model::Retrieve](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3AModel%3A%3ARetrieve)
- [OpenAI::API::Request::Moderation](https://metacpan.org/pod/OpenAI%3A%3AAPI%3A%3ARequest%3A%3AModeration)

# AUTHOR

Nelson Ferraz <nferraz@gmail.com>

# SUPPORT

This module is developed on
[GitHub](https://github.com/nferraz/perl-openai-api).

Send ideas, feedback, tasks, or bugs to
[GitHub Issues](https://github.com/nferraz/perl-openai-api/issues).

# COPYRIGHT AND LICENSE

Copyright (C) 2022, 2023 by Nelson Ferraz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.2 or,
at your option, any later version of Perl 5 you may have available.
