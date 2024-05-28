#!/usr/bin/env perl

use 5.016; # minimum version OpenAPI::Client supports
use strict;
use warnings;
use lib 'lib';
use OpenAPI::Client::OpenAI;
use Data::Dumper;
use JSON::XS qw( decode_json );
use Feature::Compat::Try;

my $file = @ARGV ? shift : 'examples/data/speech.mp3';
unless ( -e $file ) {
    die "File not found: $file\n";
}
my $client = OpenAPI::Client::OpenAI->new;

# Set the inactivity timeout to 10 minutes. For very short audio files, you
# don't need this, but for longer files, you might need to increase this.
# We show it here to demonstrate how to set it. You will need it if you use
# the 7.7M examples/data/englishminstershereford_1_grierson_64kb.mp3 file.
$client->ua->inactivity_timeout( 60 * 10 );    # ten minutes
my $response = $client->createTranscription(
    {},
    file_upload => {
        file     => $file,
        model    => 'whisper-1',
        language => 'en',
    },
);

if ( $response->res->is_success ) {
    try {
        my $result = decode_json( $response->res->content->asset->slurp );
        say $result->{text};
    } catch ($e) {
        die "Error decoding JSON: $e\n";
    }
} else {
    warn Dumper( $response->res );
}

__END__

=head1 NAME

transcribe-audio.pl - Transcribe an audio file

=head1 SYNOPSIS

    perl transcribe-audio.pl [FILE]

=head1 DESCRIPTION

This script transcribes an audio file using the OpenAI API using the `whisper-1` model.

It's more or less equivalent to the following curl command:

    curl https://api.openai.com/v1/audio/transcriptions \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: multipart/form-data" \
      -F file="@./examples/data/speech.mp3" \
      -F model="whisper-1"

In the C<examples/data> directory, you will find a sample audio file called
C<speech.mp3>. This is the default file used by the script. The script should run
in a second or two and print the following to the console:

    The quick brown fox jumped over the lazy dog.

OpenAI cost for this is less than a penny.

Alternatively, you can try this with C<examples/data/englishminstershereford_1_grierson_64kb.mp3>:

    perl transcribe-audio.pl examples/data/englishminstershereford_1_grierson_64kb.mp3

The above file is 7.7M, roughly 2,700 w0rds, and transcribes in less than a
minute. At this time, the cost to transcribe this text is about 10 cents. You
might want to redirect the output to a file for later processing.

    perl transcribe-audio.pl examples/data/englishminstershereford_1_grierson_64kb.mp3 > output.txt

=head1 SUPPORTED FORMATS

The OpenAI API supports the following audio formats:

=over 4

=item * flac

=item * m4a

=item * mp3

=item * mp4

=item * mpeg

=item * mpga

=item * oga

=item * ogg

=item * wav

=item * webm

=back
