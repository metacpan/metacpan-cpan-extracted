package TV::Anytime::Program;
use strict;
use warnings;
use base 'Class::Accessor::Chained::Fast';
__PACKAGE__->mk_accessors(qw(
id title synopsis synopsis_long events_ref genres_ref
caption_language
url email audio_channels aspect_ratio
member_of
events
is_audio_described is_subtitled is_deaf_signed
));

sub events {
  my $self = shift;
  return @{$self->events_ref};
}

sub genres {
  my $self = shift;
  return @{$self->genres_ref};
}

# TODO url email member_of

1;

__END__

=head1 NAME

TV::Anytime::Program - Represent a television or radio program

=head1 SYNOPSIS

  print $program->title . "\n";
  print "  " . $program->synopsis . "\n";
  print "  " . $program->synopsis_long . "\n";
  print "  " . $program->audio_channels . "\n";
  print "  " . $program->aspect_ratio . "\n";
  print "  (Captioned in " . $program->caption_language . ")\n";
  print "  Subtitled\n" if $program->is_subtitled;
  print "  Audio-described\n" if $program->is_audio_described;
  print "  Deaf-signed\n" if $program->is_deaf_signed;
  foreach my $event ($program->events) {
    print "  "
      . $event->start->datetime . " -> "
      . $event->stop->datetime . " ("
      . $event->duration->minutes . " mins)\n";
  }
  my @genres = $program->genres;

=head1 DESCRIPTION

The L<TV::Anytime::Program> represents a television or radio program.
This might be shown at various times, called events.

=head1 METHODS

=head2 aspect_ratio

Returns the aspect ratio:

  print "  " . $program->aspect_ratio . "\n";
  
=head2 audio_channels

Returns the number of audio channels: 
  
  print "  " . $program->audio_channels . "\n";
  
=head2 caption_language

Returns what language the program was captioned in:
  
  print "  (Captioned in " . $program->caption_language . ")\n";
  
=head2 events

Returns events as L<TV::Anytime::Program> objects for which this program
is scheduled:

  foreach my $event (@{ $program->events }) {
    print "  "
      . $event->start->datetime . " -> "
      . $event->stop->datetime . " ("
      . $event->duration->minutes . " mins)\n";
  }

=head2 genres

Returns the genres of the program:

  my @genres = $program->genres;

=head2 is_deaf_signed

Returns true if the program is deaf-signed:

  print "  Deaf-signed\n" if $program->is_deaf_signed;
  
=head2 is_audio_described

Returns true if the program is audio-described:

  print "  Audio-described\n" if $program->is_audio_described;

=head2 is_subtitled

Returns true if the program is subtitled:

  print "  Subtitled\n" if $program->is_subtitled;
  
=head2 synopsis

Returns the synopsis of the program:

  print "  " . $program->synopsis . "\n";

=head2 synopsis

Returns the long synopsis of the program (not always present):

  print "  " . $program->synopsis_long . "\n";

=head2 title

Returns the title of the program:

  print $program->title . "\n";

=head1 SEE ALSO 

L<TV::Anytime>, L<TV::Anytime::Event>, L<TV::Anytime::Genre>,
L<TV::Anytime::Service>

=head1 BUGS                                                   
                                                                                
Please report any bugs or feature requests to                                   
C<bug-TV-Anytime@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  

=head1 AUTHOR

Leon Brocard C<acme@astray.com>

=head1 LICENCE AND COPYRIGHT                                                    
                                                                                
Copyright (c) 2005, Leon Brocard C<acme@astray.com>. All rights reserved.
                                                                                
This module is free software; you can redistribute it and/or                    
modify it under the same terms as Perl itself.  