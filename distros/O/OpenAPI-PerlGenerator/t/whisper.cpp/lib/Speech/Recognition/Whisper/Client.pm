package Speech::Recognition::Whisper::Client 0.01;
use 5.020;
use Moo 2;
use experimental 'signatures';

extends 'Speech::Recognition::Whisper::Client::Impl';

=head1 NAME

Speech::Recognition::Whisper::Client - Client for Speech::Recognition::Whisper

=head1 SYNOPSIS

  use 5.020;
  use Speech::Recognition::Whisper::Client;

  my $client = Speech::Recognition::Whisper::Client->new(
      server => 'http://localhost:8080/',
  );
  my $res = $client->someMethod()->get;
  say $res;

=head1 METHODS

=head2 C<< inference >>

  my $res = $client->inference()->get;

Perform inference on a WAV file

Returns a L<< Speech::Recognition::Whisper::Transcription >>.
Returns a L<< Speech::Recognition::Whisper::Error >>.

=cut

=head2 C<< load >>

  my $res = $client->load()->get;

Load a model

Returns a L<< Speech::Recognition::Whisper::SuccessfulLoad >>.
Returns a L<< Speech::Recognition::Whisper::Error >>.

=cut

1;
