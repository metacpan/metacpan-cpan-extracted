package OpenAI::API::Request::Image::Generation;

use strict;
use warnings;

use Types::Standard qw(Int Str Enum);

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Request';

has prompt => ( is => 'ro', isa => Str, required => 1, );

has n               => ( is => 'ro', isa => Int, );
has size            => ( is => 'ro', isa => Enum [ '256x256', '512x512', '1024x1024' ], );
has response_format => ( is => 'ro', isa => Enum [ 'url',     'b64_json' ], );
has user            => ( is => 'ro', isa => Str, );

sub endpoint { 'images/generations' }
sub method   { 'POST' }

1;

__END__

=head1 NAME

OpenAI::API::Request::Image::Generation - generates images from a prompt

=head1 SYNOPSIS

    use OpenAI::API::Request::Image::Generation;

    my $request = OpenAI::API::Request::Image::Generation->new(
        prompt => 'A cute baby sea otter',
        size   => '256x256',
    );

    my $res = $request->send();

=head1 DESCRIPTION

Creates an image given a prompt.

=head1 METHODS

=head2 new()

=over

=item * prompt

A text description of the desired image(s).

=item * n [optional]

The number of images to generate. Must be between 1 and 10. Defaults to 1.

=item * size [optional]

The size of the generated images. Must be one of C<256x256>, C<512x512>,
or C<1024x1024>. Defaults to C<1024x1024>.

=item * response_format [optional]

The format in which the generated images are returned. Must be one of
C<url> or C<b64_json>. Defaults to C<url>.

=item * user [optional]

A unique identifier representing your end-user.

=back

=head1 SEE ALSO

OpenAI API Documentation: L<Models|https://platform.openai.com/docs/api-reference/images>
