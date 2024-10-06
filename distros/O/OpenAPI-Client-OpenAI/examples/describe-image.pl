#!/usr/bin/env perl

use v5.40.0;
use warnings;

package Image::Describe::OpenAI;

use Carp;
use OpenAPI::Client::OpenAI;
use Path::Tiny qw(path);
use MIME::Base64;
use Moo;
use namespace::autoclean;

has system_message => (
    is => 'ro',
    default =>
      'You are an accessibility expert, able to describe images for the visually impaired'
);

# gpt-4o-mini is smaller and cheaper than gpt4o, but it's still very good.
# Also, it's multi-modal, so it can handle images and some of the older
# vision models have now been deprecated.
has model       => ( is => 'ro', default => 'gpt-4o-mini' );
has temperature => ( is => 'ro', default => .1 );
has prompt      => ( is => 'ro', builder => 1 );
has _client =>
  ( is => 'ro', default => sub { OpenAPI::Client::OpenAI->new } );

sub _build_prompt ($self) {
    return <<~'PROMPT';
      You are a helpful chatbot.

      Describe the image in detail, focusing on the following aspects:

      1. Main subject or focus of the image
      2. Spatial layout and composition
      3. Colors and lighting
      4. Textures and materials
      5. Any text or signage present
      6. Emotions or atmosphere conveyed
      7. Context or setting
      8. Actions or interactions occurring
      9. Unique or notable features

      Provide a clear, concise description that flows
      naturally, prioritizing the most important elements.
      Avoid making assumptions or interpretations beyond
      what is visually present. Use specific, vivid
      language to help create a mental image for the listener.

      Format your result as a paragraph or two of text. Do not use bullet
      points or lists.
      PROMPT
}

sub describe_image ( $self, $filename ) {
    my $filetype = $filename =~ /\.png$/ ? 'png' : 'jpeg';
    my $image    = $self->_read_image_as_base64($filename);
    my $message  = {
        body => {
            model    => 'gpt-4o-mini',    # $self->model,
            messages => [
                {
                    role    => 'system',
                    content => $self->system_message,
                },
                {
                    role    => 'user',
                    content => [
                        {
                            text => $self->prompt,
                            type => 'text'
                        },

                        {
                            type      => "image_url",
                            image_url => {
                                url => "data:image/$filetype;base64, $image"
                            }
                        }
                    ],
                }
            ],
            temperature => $self->temperature,
        },
    };
    my $response = $self->_client->createChatCompletion($message);
    return $self->_extract_description($response);
}

sub _extract_description ( $self, $response ) {
    if ( $response->res->is_success ) {
        my $result;
        try {
            my $json = $response->res->json;
            $result = $json->{choices}[0]{message}{content};
        }
        catch ($e) {
            croak("Error decoding JSON: $e");
        }
        return $result;
    }
    else {
        my $error = $response->res;
        croak( $error->to_string );
    }
}

sub _read_image_as_base64 ( $self, $file ) {
    my $content = Path::Tiny->new($file)->slurp_raw;

    # second argument is the line ending, which we don't
    # want as a newline because OpenAI doesn't like it
    return encode_base64( $content, '' );
}

package main;

my $filename = shift || 'examples/data/van-gogh.jpg';
my $chat     = Image::Describe::OpenAI->new;
my $response = $chat->describe_image($filename);
say $response;

__END__

=head1 NAME

describe-image.pl - Describe an image using the OpenAI API

=head1 SYNOPSIS

    perl describe-image.pl <image-file>

=head1 DESCRIPTION

This script allows you to describe an image using the OpenAI API.

Unlike chat.pl, this script uses the `gpt-4o-mini` model, which is
multi-modal and can handle images. Further, we don't keep a message
history, as we only need to send the image and the prompt.
