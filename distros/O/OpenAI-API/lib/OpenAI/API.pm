package OpenAI::API;

use strict;
use warnings;

use Carp qw/croak/;

use Types::Standard qw(Int Num Str);

use Moo;
use strictures 2;
use namespace::clean;

with 'OpenAI::API::ResourceDispatcherRole';

our $VERSION = 0.24;

my $DEFAULT_API_BASE = 'https://api.openai.com/v1';

has api_key  => ( is => 'rw', isa => Str, default => sub { $ENV{OPENAI_API_KEY} }, required => 1 );
has api_base => ( is => 'rw', isa => Str, default => sub { $ENV{OPENAI_API_BASE} // $DEFAULT_API_BASE }, );
has timeout  => ( is => 'rw', isa => Num, default => sub { 60 } );
has retry    => ( is => 'rw', isa => Int, default => sub { 3 } );
has sleep    => ( is => 'rw', isa => Num, default => sub { 1 } );

has user_agent => ( is => 'lazy' );

sub _build_user_agent {
    my ($self) = @_;
    $self->{user_agent} = LWP::UserAgent->new( timeout => $self->timeout );
}

1;

__END__

=head1 NAME

OpenAI::API - Perl interface to OpenAI API

=for readme plugin version

=head1 SYNOPSIS

    use OpenAI::API;

    my $openai = OpenAI::API->new(); # uses OPENAI_API_KEY environment variable

    my $chat = $openai->chat(
        model       => 'gpt-3.5-turbo',
        messages    => [ { "role" => "user", "content" => "Hello!" }, ],
    );

    my $completions = $openai->completions(
        model  => 'text-davinci-003',
        prompt => 'What is the capital of France?',
    );

    my $edits = $openai->edits(
        model       => 'text-davinci-edit-001',
        input       => 'What day of the wek is it?',
        instruction => 'Fix the spelling mistakes',
    );

    my $moderations = $openai->moderations(
        model => 'text-moderation-latest',
        input => 'I want to kill them.',
    );

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

=head2 new()

Creates a new OpenAI::API object.

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

=head2 chat()

Given a chat conversation, the model will return a chat completion response.

Mandatory parameters:

=over 4

=item * model

=item * messages

=back

More info: L<OpenAI::API::Resource::Chat>

=head2 completions()

Given a prompt, the model will return one or more predicted completions.

Mandatory parameters:

=over 4

=item * model

=item * prompt

=back

More info: L<OpenAI::API::Resource::Completion>

=head2 edits()

Creates a new edit for the provided input, instruction, and parameters.

Mandatory parameters:

=over 4

=item * model

=item * instruction

=item * input [optional, but often required]

=back

More info: L<OpenAI::API::Resource::Edit>

=head2 embeddings()

Get a vector representation of a given input that can be easily consumed
by machine learning models and algorithms.

Mandatory parameters:

=over 4

=item * model

=item * input

=back

More info: L<OpenAI::API::Resource::Embedding>

=head2 moderations()

Given a input text, outputs if the model classifies it as violating
OpenAI's content policy.

Mandatory parameters:

=over 4

=item * input

=back

More info: L<OpenAI::API::Resource::Moderation>

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
