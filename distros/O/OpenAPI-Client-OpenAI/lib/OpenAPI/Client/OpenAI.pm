package OpenAPI::Client::OpenAI;

use Carp ();
use File::ShareDir 'dist_file';
use File::Spec::Functions qw(catfile);

use Mojo::Base 'OpenAPI::Client';

our $VERSION = '0.24';

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
    my %headers = ( 'Authorization' => "Bearer $ENV{OPENAI_API_KEY}", );
    if ( delete $attrs->{assistants} ) {
        $headers{'OpenAI-Beta'} = 'assistants=v2';
    }

    # 'message' => 'You must provide the \'OpenAI-Beta\' header to access the
    # Assistants API. Please try again by setting the header \'OpenAI-Beta:
    # assistants=v1\'.'

    my $self = $class->SUPER::new( $specification, %{$attrs} );

    # you use this via $client->createTranscription({}, file_upload => { file => $filename, model => ...})
    # note that you pass in a filename, so you don't have to read it yourself
    $self->ua->transactor->add_generator(
        file_upload => sub {
            my ( $t, $tx, $data ) = @_;
            return $t->_form( $tx, { %$data, file => { file => $data->{file} } } );
        }
    );

    $self->ua->on(
        start => sub {
            my ( $ua, $tx ) = @_;
            foreach my $header ( keys %headers ) {
                $tx->req->headers->header( $header => $headers{$header} );
            }
        }
    );

    return $self;
}

# install snake case aliases

{
    my %snake_case_alias = (
        createChatCompletion => 'create_chat_completion',
        createCompletion     => 'create_completion',
        createEmbedding      => 'create_embedding',
        createImage          => 'create_image',
        createModeration     => 'create_moderation',
        listModels           => 'list_models',
    );

    for my $camel_case_method ( keys %snake_case_alias ) {
        no strict 'refs';
        my $method = $snake_case_alias{$camel_case_method};
        *$method = sub {
            warn "Calling '$method' is deprecated. Please use '$camel_case_method' instead.";
            my $self = shift;
            $self->$camel_case_method(@_);
        }
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

OpenAPI::Client::OpenAI - A client for the OpenAI API

=head1 SYNOPSIS

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

=head1 DESCRIPTION

OpenAPI::Client::OpenAI is a client for the OpenAI API built on
top of L<OpenAPI::Client>. This module automatically handles the API
key authentication according to the provided environment.

Note that the OpenAI API is a paid service. You will need to sign up for an
account.

See L<OpenAI::Client::OpenAI::Path> for a list of all available paths and methods.

See the C<examples/> directory in the distribution for more examples, along
with the tests.

=head1 WARNING

Due to the extremely rapid development of OpenAI's API, this module may may
not be up-to-date with the latest changes. Further releases of this module may
break your code if OpenAI changes their API.

=head1 METHODS

=head2 Constructor

=head3 new

    my $client = OpenAPI::Client::OpenAI->new( $specification, %options );

Create a new OpenAI API client. The following options can be provided:

=over

=item * C<$specification>

The path to the OpenAPI specification file (YAML). Defaults to the
"openai.yaml" file in the distribution's "share" directory.

You can find the latest version of this file at
L<https://github.com/openai/openai-openapi>.

Examples can be found in the C<t/> and C<examples/> directories of the
distribution.

=back

Additional options are passed to the parent class, OpenAPI::Client, with the
exception of the following extra options:

=head2 Other Methods

Other methods are documented in L<OpenAPI::Client::OpenAI::Methods>. These
method are deprecated and will be removed in a future version.

See L<OpenAPI::Client::OpenAI::Path> for an index of all paths available. You
can click through each of them for more detail.

=head1 DEPRECATED METHODS

The following methods are deprecated and will be removed in a future release:

=over

=item * create_chat_completion

Replaced with C<createChatCompletion>.

=item * create_completion

Replaced with C<createCompletion>.

=item * create_embedding

Replaced with C<createEmbedding>.

=item * create_image

Replaced with C<createImage>.

=item * create_moderation

Replaced with C<createModeration>.

=item * list_models

Replaced with C<listModels>.

=back

Originally, these methods were named using C<snake_case>, but to simplify the
code, we retained the C<camelCase> names in the main module.

=head1 ENVIRONMENT VARIABLES

The following environment variables are used by this module:

=over 4

=item * OPENAI_API_KEY

The API key used to authenticate requests to the OpenAI API.

=back

=head1 SEE ALSO

L<OpenAI::API> - the deprecated precursor to this module.

=head1 AUTHOR

Nelson Ferraz, E<lt>nferraz@gmail.comE<gt>

=head1 CONTRIBUTORS

=over 4

=item * Curtis "Ovid" Poe, https://github.com/Ovid

=item * Veesh Goldman, https://github.com/rabbiveesh

=item * Graham Knop, https://github.com/haarg

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023-2024 by Nelson Ferraz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
