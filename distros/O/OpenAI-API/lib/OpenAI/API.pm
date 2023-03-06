package OpenAI::API;

use strict;
use warnings;

use Carp qw/croak/;

use JSON::MaybeXS;
use LWP::UserAgent;

use OpenAI::API::Request::Chat;
use OpenAI::API::Request::Completion;
use OpenAI::API::Request::Edit;
use OpenAI::API::Request::Embedding;
use OpenAI::API::Request::Moderation;

our $VERSION = 0.22;

my $DEFAULT_API_BASE = 'https://api.openai.com/v1';
my $DEFAULT_TIMEOUT  = 60;
my $DEFAULT_RETRIES  = 3;
my $DEFAULT_SLEEP    = 1;

sub new {
    my ( $class, %params ) = @_;
    my $self = {
        api_key  => $params{api_key}  // $ENV{OPENAI_API_KEY},
        api_base => $params{api_base} // $ENV{OPENAI_API_BASE} // $DEFAULT_API_BASE,
        timeout  => $params{timeout}  // $DEFAULT_TIMEOUT,
        retry    => $params{retry}    // $DEFAULT_RETRIES,
        sleep    => $params{sleep}    // $DEFAULT_SLEEP,
    };

    $self->{ua} = LWP::UserAgent->new( timeout => $params{timeout} );

    croak 'Missing OPENAI_API_KEY' if !defined $self->{api_key};
    return bless $self, $class;
}

sub chat {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Request::Chat->new( \%params );
    return $self->_post( $request );
}

sub completions {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Request::Completion->new( \%params );
    return $self->_post( $request );
}

sub edits {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Request::Edit->new( \%params );
    return $self->_post( $request );
}

sub embeddings {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Request::Embedding->new( \%params );
    return $self->_post( $request );
}

sub moderations {
    my ( $self, %params ) = @_;
    my $request = OpenAI::API::Request::Moderation->new( \%params );
    return $self->_post( $request );
}

sub _post {
    my ( $self, $request ) = @_;

    my $method = $request->endpoint();
    my %params = %{$request};

    my $req = HTTP::Request->new(
        POST => "$self->{api_base}/$method",
        [
            'Content-Type'  => 'application/json',
            'Authorization' => "Bearer $self->{api_key}",
        ],
        encode_json(\%params),
    );

    for my $attempt ( 1 .. $self->{retry} ) {
        my $res = $self->{ua}->request($req);

        if ( $res->is_success ) {
            return decode_json( $res->decoded_content );
        } elsif ( $res->code =~ /^(?:500|503|504|599)$/ && $attempt < $self->{retry} ) {
            sleep( $self->{sleep} );
        } else {
            die "Error retrieving '$method': " . $res->status_line;
        }
    }
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

More info: L<OpenAI::API::Request::Chat>

=head2 completions()

Given a prompt, the model will return one or more predicted completions.

Mandatory parameters:

=over 4

=item * model

=item * prompt

=back

More info: L<OpenAI::API::Request::Completion>

=head2 edits()

Creates a new edit for the provided input, instruction, and parameters.

Mandatory parameters:

=over 4

=item * model

=item * instruction

=item * input [optional, but often required]

=back

More info: L<OpenAI::API::Request::Edit>

=head2 embeddings()

Get a vector representation of a given input that can be easily consumed
by machine learning models and algorithms.

Mandatory parameters:

=over 4

=item * model

=item * input

=back

More info: L<OpenAI::API::Request::Embedding>

=head2 moderations()

Given a input text, outputs if the model classifies it as violating
OpenAI's content policy.

Mandatory parameters:

=over 4

=item * input

=back

More info: L<OpenAI::API::Request::Moderation>

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
