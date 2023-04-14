package OpenAI::API::Request::Moderation;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Request';

use Types::Standard qw(Bool Str Num Int Map);

has input => ( is => 'rw', isa => Str, required => 1, );

has model => ( is => 'rw', isa => Str, );

sub endpoint { 'moderations' }
sub method   { 'POST' }

1;

__END__

=head1 NAME

OpenAI::API::Request::Moderation - Request class for OpenAI API content moderation

=head1 SYNOPSIS

    use OpenAI::API::Request::Moderation;

    my $request = OpenAI::API::Request::Moderation->new(
        input => "I like turtles",
    );

    my $res = $request->send();

    if ( $res->{results}[0]{flagged} ) {
        die "Input violates our Content Policy";
    }

=head1 DESCRIPTION

This module provides a request class for interacting with the OpenAI API's
content moderation endpoint. It inherits from L<OpenAI::API::Request>.

=head1 ATTRIBUTES

=head2 input

The content to be moderated. Required.

=head2 model

The model to use for content moderation. Optional.

=head1 METHODS

=head2 endpoint

This method returns the API endpoint for content moderation.

=head2 method

This method returns the HTTP method for content moderation.

=head1 INHERITED METHODS

This module inherits the following methods from L<OpenAI::API::Request>:

=head2 send(%args)

=head2 send_async(%args)

=head1 SEE ALSO

L<OpenAI::API::Request>, L<OpenAI::API::Config>
