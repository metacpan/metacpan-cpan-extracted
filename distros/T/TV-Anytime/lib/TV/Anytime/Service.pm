package TV::Anytime::Service;
use strict;
use warnings;
use base 'Class::Accessor::Chained::Fast';
__PACKAGE__->mk_accessors(qw(
anytime
genres_ref
id
logo
name
owner
));

sub events {
  my $self = shift;
  my($programs, $events) = $self->anytime->_programs($self->id);
  return @$events;
}

sub genres {
  my $self = shift;
  return @{$self->genres_ref};
}

sub is_television {
  my $self = shift;
  foreach my $genre ($self->genres) {
    if ($genre->name eq 'MediaType') {
      return $genre->value eq 'Audio and video';
    }
  }
  return 0;
}

sub is_radio {
  my $self = shift;
  foreach my $genre ($self->genres) {
    if ($genre->name eq 'MediaType') {
      return $genre->value eq 'Audio only';
    }
  }
  return 0;
}

sub programs {
  my $self = shift;
  my($programs, $events) = $self->anytime->_programs($self->id);
  return @$programs;
}

1;

__END__

=head1 NAME

TV::Anytime::Service - Represent a television or radio service

=head1 SYNOPSIS

  print "Name is "  . $service->name . "\n";
  print "Owner is " . $service->owner . "\n";
  print "Logo is "  . $service->logo . "\n";
  print "Is tv\n" if $service->is_television;
  print "Is radio\n" if $service->is_radio;
  my @genres = $service->genres;

  my @programs = $service->programs;
  my @events   = $service->events;

=head1 DESCRIPTION

The L<TV::Anytime::Service> represents a television or radio

=head1 METHODS

=head2 events

This returns a list of L<TV::Anytime::Event> objects which represent
transmissions on the service:

  my @events   = $service->events;

=head2 genres

This returns a list of L<TV::Anytime::Genre> objects which apply to the
service:

  my @genres = $service->genres;

=head2 is_radio

This returns if the service is a radio station:

  print "Is radio\n" if $service->is_radio;

=head2 is_television

This returns if the service is a television station:

  print "Is tv\n" if $service->is_television;

=head2 logo

This returns a URL to a logo for the service:

  print "Logo is "  . $service->logo . "\n";

=head2 name

This returns the name of the service:

  print "Name is "  . $service->name . "\n";

=head2 owner

This returns the owner of the service:

  print "Owner is " . $service->owner . "\n";

=head2 programs

This returns a list of L<TV::Anytime::Program> objects which represent
the various programs on the service:

  my @programs = $service->programs;

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