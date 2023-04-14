package OpenAI::API::Request::Embedding;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Request';

use Types::Standard qw(Bool Str Num Int Map);

has model => ( is => 'rw', isa => Str, required => 1, );
has input => ( is => 'rw', isa => Str, required => 1, );

has user => ( is => 'rw', isa => Str, );

sub endpoint { 'embeddings' }
sub method   { 'POST' }

1;

__END__

=head1 NAME

OpenAI::API::Request::Embedding - embeddings endpoint

=head1 SYNOPSIS

    use OpenAI::API::Request::Embedding;

    my $request = OpenAI::API::Request::Embedding->new(
        model => "text-embedding-ada-002",
        input => 'The quick brown fox jumps over the lazy dog.',
    );

    my $res = $request->send();    # or: my $res = $request->send(%args);

=head1 DESCRIPTION

This module provides a request class for interacting with the OpenAI
API's embedding endpoint. It inherits from L<OpenAI::API::Request>.

Get a vector representation of a given input that can be easily consumed
by machine learning models and algorithms.

=head1 ATTRIBUTES

=head2 model

The model to use for generating embeddings.

=head2 input

The input content for which to generate embeddings.

=head2 user [optional]

The user identifier for the request.

=head1 INHERITED METHODS

This module inherits the following methods from L<OpenAI::API::Request>:

=head2 send

=head2 send_async

=head1 SEE ALSO

L<OpenAI::API::Request>, L<OpenAI::API::Config>
