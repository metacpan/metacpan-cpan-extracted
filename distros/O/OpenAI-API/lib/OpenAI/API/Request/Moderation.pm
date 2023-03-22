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

OpenAI::API::Request::Moderation - moderations endpoint

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

Given a input text, outputs if the model classifies it as violating
OpenAI's content policy.

=head1 METHODS

=head2 new()

=over 4

=item * input

=item * model [optional]

=back

=head2 send()

Sends the request and returns a data structured similar to the one
documented in the API reference.

=head2 send_async()

Send a request asynchronously. Returns a L<Promises> promise that will
be resolved with the decoded JSON response. See L<OpenAI::API::Request>
for an example.

=head1 SEE ALSO

OpenAI API Reference: L<Moderations|https://platform.openai.com/docs/api-reference/moderations>
