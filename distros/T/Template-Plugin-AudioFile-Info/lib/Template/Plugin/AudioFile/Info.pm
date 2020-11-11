package Template::Plugin::AudioFile::Info;

use 5.006;
use strict;
use warnings;

use AudioFile::Info;
use Template::Plugin;

require Exporter;

our @ISA = qw(Exporter AudioFile::Info Template::Plugin);

our $VERSION = '2.0.1';

sub new {
  my ($class, $context, $file, $params) = @_;

  my $self = $class->SUPER::new($file, $params);

  return $self;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Template::Plugin::AudioFile::Info - Template Toolkit plugin for
AudioFile::Info

=head1 SYNOPSIS

  [% USE song = AudioFile.Info(file) %]
  Title:  [% song.title %]
  Artist: [% song.artist %]
  Album:  [% song.album %] (track [% song.track %])
  Year:   [% song.year %]
  Genre:  [% song.genre %]

=head1 ABSTRACT

Template::Plugin::AudioFile::Info is a Template Toolkit plugin module
which provides an interface to the AudioFile::Info module.
AudioFile::Info provides a simple way to extract various pieces of
information from audio files (both MP3 and Ogg Vorbis files).

=head1 DESCRIPTION

Template::Plugin::AudioFile::Info is intended to be used from with
a template that is going to be processed by the Template Toolkit.

A simple template might look like the one in the Synopsis above. In
this case you would need to define the C<file> variable in some way.
The simplest option would be to use the C<tpage> program that comes 
with the Template Toolkit, like this (assuming the template is in
a file called C<song.tt>).

  $ tpage --define file=some_song.mp3 song.tt

If you wanted to process each file in a directory thne you might
write a Perl program that processed the template multiple times
like this.

  use Template;

  my $tt = Template->new;

  foreach (</my/song/directory/*>) {
    next unless /\.(ogg|mp3)$/i;

    $tt->process('song.tt', { file => $_ })
      or die $tt->error;
  }

There are, of course, many other ways to do it.

=head1 METHODS

=head2 new

Constructor for this object. Simply delegates to AudioFile::Info.

=head1 SEE ALSO

=over 4

=item *

L<Template> (the Template Toolkit)

=item *

L<AudioFile::Info>

=back

=head1 AUTHOR

Dave Cross, E<lt>dave@dave.org.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Dave Cross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
