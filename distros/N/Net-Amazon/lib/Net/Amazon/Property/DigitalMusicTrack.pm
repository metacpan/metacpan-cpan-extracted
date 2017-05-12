######################################################################
package Net::Amazon::Property::DigitalMusicTrack;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Property);

__PACKAGE__->make_accessor($_) for qw(
	binding 
	genre 
	label 
	manufacturer 
	publisher 
	release_date 
	studio 
	title 
	track_sequence 
	running_time);

__PACKAGE__->make_array_accessor($_) for qw(artists);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = $class->SUPER::new(%options);
    bless $self, $class; # Bless into this class

    if(exists $options{xmlref}) {
        $self->init_via_xmlref($options{xmlref});
    }

    return $self;
}

##################################################
sub artist {
##################################################
    my($self, $nameref) = @_;

    # Only return the first artist
    return ($self->artists($nameref))[0];
}

##################################################
sub init_via_xmlref {
##################################################
    my($self, $xmlref) = @_;

    $self->SUPER::init_via_xmlref($xmlref);
    
    my $ref = $xmlref->{ItemAttributes};

    # It could either be a Creator (and?)/or an Artist
    my @artists;
    for my $artist (@{$ref->{Creator}}) {
        push @artists, $artist->{content};
    }

    for my $artist (@{$ref->{Artist}}) {
        push @artists, $artist;
    }
    $self->artists(\@artists);

    $self->binding($ref->{Binding});
    $self->genre($ref->{Genre});
    $self->label($ref->{Label});
    $self->manufacturer($ref->{Manufcaturer});
    $self->publisher($ref->{Publisher});
    $self->release_date($ref->{ReleaseDate});
    $self->running_time($ref->{RunningTime}->{content});
    $self->studio($ref->{Studio});
    $self->title($ref->{Title});
    $self->track_sequence($ref->{TrackSequence});

    my $year = 0;
    if (defined $ref->{ReleaseDate}) {
        $year =  (split(/\-/, $ref->{ReleaseDate}))[0];
    }
    $self->year($year);
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    return join('/', $self->artists) . ", " .
           '"' . $self->title. '"' . ", " .
           $self->year . ", " .
           $self->_best_effort_price() . ", " .
           $self->Asin;
}

1;

__END__

=head1 NAME

Net::Amazon::Property::DigitalMusicTrack- Class for MP3 downloads on amazon.com

=head1 SYNOPSIS

  use Net::Amazon;

  # ...

  if($resp->is_success()) {
      for my $prop ($resp->properties) {
          print join("/", $_->artists(), " ",
                $_->title(), " ",
                $_->year(), " ";
                $_->running_time(), " ";
   }

=head1 DESCRIPTION

C<Net::Amazon::Property::DigitalMusicTrack> is derived from 
C<Net::Amazon::Property> and on top of the all-purpose
methods the base class provides, it offers specialized accessors for
popular digital music track parameters.

=head2 METHODS

=over 4

=item artists()

Returns a list of the artists. There's also a C<artist()> method
which just returns the first artist.

=item binding()

Returns the binding of the digital music track, such as MP3 Download.

=item genre()

Returns the genre as a string.

=item label()

Returns the music label as a string.

=item manufacturer()

Returns the manufacturer as a string.

=item publisher()

Returns the publisher as a string.

=item release_date()

Returns the release date as a string formatted YYYY-MM-DD.

=item studio()

Returns the studio as a string.

=item title()

Returns the title as a string.

=item track_sequence()

Returns the track sequence number of this song from its released CD. 

=item running_time()

Running time of this track in seconds.

=item new(xmlref => $xmlref)

Initializes an object by passing a hash of hashes structure containing
the XML data returned from the service. Usually, this is just used by
C<Net::Amazon> internally to initialize objects for on backcoming
data.

=back

Check out L<Net::Amazon::Property> for all-purpose accessors, like
C<year>, C<OurPrice>, C<ListPrice>, etc.

=head1 AUTHOR

Christopher Boumenot, E<lt>boumenot+na@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Christopher Boumenot E<lt>boumenot+na@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

