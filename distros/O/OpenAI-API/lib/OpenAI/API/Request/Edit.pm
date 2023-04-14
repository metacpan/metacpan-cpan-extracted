package OpenAI::API::Request::Edit;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Request';

use Types::Standard qw(Bool Str Num Int Map);

has model       => ( is => 'rw', isa => Str, required => 1, );
has instruction => ( is => 'rw', isa => Str, required => 1, );

has input       => ( is => 'rw', isa => Str, );
has temperature => ( is => 'rw', isa => Num, );
has top_p       => ( is => 'rw', isa => Num, );
has n           => ( is => 'rw', isa => Int, );

sub endpoint { 'edits' }
sub method   { 'POST' }

1;

__END__

=head1 NAME

OpenAI::API::Request::Edit - Request class for OpenAI API content editing

=head1 SYNOPSIS

    use OpenAI::API::Request::Edit;

    my $request = OpenAI::API::Request::Edit->new(
        model       => "text-davinci-edit-001",
        instruction => 'Correct the grammar in the following text:',
        input       => 'the cat sat on teh mat.',
    );

    my $res  = $request->send();            # or: my $res  = $request->send(%args)
    my $text = $res->{choices}[0]{text};    # or: my $text = "$res";

=head1 DESCRIPTION

This module provides a request class for interacting with the OpenAI
API's content editing endpoint. It inherits from L<OpenAI::API::Request>.

=head1 ATTRIBUTES

=head2 model

ID of the model to use. You can use the text-davinci-edit-001 or
code-davinci-edit-001 model with this endpoint.

=head2 input [optional]

The input text to use as a starting point for the edit.

=head2 instruction

The instruction that tells the model how to edit the prompt.

=head2 n [optional]

How many edits to generate for the input and instruction.

=head2 temperature [optional]

What sampling temperature to use, between 0 and 2.

=head2 top_p [optional]

An alternative to sampling with temperature.

=head1 INHERITED METHODS

This module inherits the following methods from L<OpenAI::API::Request>:

=head2 send(%args)

=head2 send_async(%args)

=head1 SEE ALSO

L<OpenAI::API::Request>, L<OpenAI::API::Config>
