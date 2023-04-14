package OpenAI::API;

use strict;
use warnings;

use OpenAI::API::Config;

our $VERSION = 0.37;

BEGIN {
    my %module_dispatcher = (
        chat           => 'OpenAI::API::Request::Chat',
        completions    => 'OpenAI::API::Request::Completion',
        edits          => 'OpenAI::API::Request::Edit',
        embeddings     => 'OpenAI::API::Request::Embedding',
        files          => 'OpenAI::API::Request::File::List',
        file_retrieve  => 'OpenAI::API::Request::File::Retrieve',
        image_create   => 'OpenAI::API::Request::Image::Generation',
        models         => 'OpenAI::API::Request::Model::List',
        model_retrieve => 'OpenAI::API::Request::Model::Retrieve',
        moderations    => 'OpenAI::API::Request::Moderation',
    );

    for my $sub_name ( keys %module_dispatcher ) {
        my $module = $module_dispatcher{$sub_name};

        eval "require $module" or die $@;

        no strict 'refs';
        *{"$sub_name"} = sub {
            my $self   = shift;
            my %params = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

            my $request = $module->new( %params, config => $self->config );
            return $request->send();
        };
    }
}

sub new {
    my $class = shift;

    my %param = ref $_[0] ? %{ $_[0] } : @_;

    my $self = bless \%param, ref $class || $class;

    $self->{config} = OpenAI::API::Config->new(%param);

    return $self;
}

sub config {
    my ( $self, %param ) = @_;
    return $self->{config};
}

1;

__END__

=head1 NAME

OpenAI::API - Perl interface to OpenAI API

=for readme plugin version

=head1 SYNOPSIS

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

=head1 DESCRIPTION

OpenAI::API is a Perl module that provides an interface to the OpenAI API,
which allows you to generate text, translate languages, summarize text,
and perform other tasks using the language models developed by OpenAI.

To use the OpenAI::API module, you will need an API key, which you can obtain by
signing up for an account on the L<OpenAI website|https://platform.openai.com>.

=begin :readme

=head1 INSTALLATION

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

If your perl is system-managed, you can create a L<local::lib> in your
home directory to install modules to. For details, see the
L<local::lib documentation|https://metacpan.org/pod/local::lib>.

=head1 DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc OpenAI::API

=end :readme

=for readme stop

=head1 METHODS

OpenAI::API acts as a high-level interface for the OpenAI API, handling
different actions while utilizing the configuration class.

=head2 new()

Creates a new OpenAI::API object.

=over 4

=item * config [optional]

An OpenAI::API::Config object including the following properties:

=over 4

=item * api_key [optional]

Your API key. Default: C<$ENV{OPENAI_API_KEY}>.

Attention: never commit API keys to your repository. Use the C<OPENAI_API_KEY>
environment variable instead.

See: L<Best Practices for API Key Safety|https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety>.

=item * api_base [optional]

The api_base URL for the OpenAI API. Default: 'https://api.openai.com/v1/'.

=item * timeout [optional]

The timeout value, in seconds. Default: 60 seconds.

=back

=back

=head2 chat()

L<Chat|OpenAI::API::Request::Chat> request.

=head2 completions()

L<Completion|OpenAI::API::Request::Completion> request.

=head2 edits()

L<Edit|OpenAI::API::Request::Edit> request.

=head2 embeddings()

L<Embedding|OpenAI::API::Request::Embedding> request.

=head2 files()

L<File List|OpenAI::API::Request::File::List> request.

=head2 file_retrieve()

L<File Retrieve|OpenAI::API::Request::File::Retrieve> request.

=head2 image_create()

L<Image Generation|OpenAI::API::Request::Image::Generation> request.

=head2 models()

L<Model List|OpenAI::API::Request::Model::List> request.

=head2 model_retrieve()

L<Model Retrieve|OpenAI::API::Request::Model::Retrieve> request.

=head2 moderations()

L<Moderation|OpenAI::API::Request::Moderation> request.

=for readme start

=head1 RESOURCES

=over

=item * L<OpenAI::API::Request::Chat>

=item * L<OpenAI::API::Request::Completion>

=item * L<OpenAI::API::Request::Edit>

=item * L<OpenAI::API::Request::Embedding>

=item * L<OpenAI::API::Request::File::List>

=item * L<OpenAI::API::Request::File::Retrieve>

=item * L<OpenAI::API::Request::Image::Generation>

=item * L<OpenAI::API::Request::Model::List>

=item * L<OpenAI::API::Request::Model::Retrieve>

=item * L<OpenAI::API::Request::Moderation>

=back

=for readme stop

=head1 SEE ALSO

L<OpenAI Reference Overview|https://platform.openai.com/docs/api-reference/overview>

=for readme start

=head1 AUTHOR

Nelson Ferraz E<lt>nferraz@gmail.comE<gt>

=head1 SUPPORT

This module is developed on
L<GitHub|https://github.com/nferraz/perl-openai-api>.

Send ideas, feedback, tasks, or bugs to
L<GitHub Issues|https://github.com/nferraz/perl-openai-api/issues>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, 2023 by Nelson Ferraz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.2 or,
at your option, any later version of Perl 5 you may have available.

=for readme stop

=cut
