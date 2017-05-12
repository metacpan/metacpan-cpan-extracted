package TV::Anytime::Event;
use strict;
use warnings;
use base 'Class::Accessor::Chained::Fast';
__PACKAGE__->mk_accessors(qw(
start stop crid program
));

sub duration {
  my $self = shift;
  return $self->stop - $self->start;
}

1;

__END__

=head1 NAME

TV::Anytime::Event - Represent a television or radio program event

=head1 SYNOPSIS

  foreach my $event ($service->events) {
    print $event->start->datetime . " -> "
      . $event->stop->datetime . ": "
      . $event->program->title . "\n";
  }

=head1 DESCRIPTION

The L<TV::Anytime::Event> represents a television or radio event.

=head1 METHODS

=head2 duration

Returns the duration of the event, as a L<DateTime::Duration> object:

  my $duration = $event->duration;

=head2 program

Returns the program linked to the event as a L<TV::Anytime::Program> object:

  print $event->program->title . "\n";
  
=head2 start

Returns the start time and date of the event as a L<DateTime> object:

  my $start = $event->start;

=head2 stop

Returns the stop time and date of the event as a L<DateTime> object:

  my $stop = $event->stop;

=head1 SEE ALSO 

L<TV::Anytime>, L<TV::Anytime::Event>, L<TV::Anytime::Service>

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