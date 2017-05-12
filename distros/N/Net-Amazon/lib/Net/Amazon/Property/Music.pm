######################################################################
package Net::Amazon::Property::Music;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Property);

__PACKAGE__->make_accessor($_) for qw(album label media nummedia upc
  ean studio publisher release_date binding);
__PACKAGE__->make_array_accessor($_) for qw(artists tracks);

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
        push @artists, $artist->{content} if $artist->{Role} eq 'Performer';
    }

    for my $artist (@{$ref->{Artist}}) {
        push @artists, $artist;
    }
    $self->artists(\@artists);

    $self->album($ref->{Title});
    $self->ean($ref->{EAN});
    $self->label($ref->{Label});
    $self->media($ref->{Binding});
    $self->binding($ref->{Binding});
    $self->nummedia($ref->{NumberOfDiscs});
    $self->publisher($ref->{Publisher});
    $self->release_date($ref->{ReleaseDate});
    $self->studio($ref->{Studio});
    $self->upc($ref->{UPC});

    $self->NumMedia($ref->{NumberOfDiscs});

    my @tracks;
    for my $disc (@{$xmlref->{Tracks}->{Disc}}) {
        for my $track (@{$disc->{Track}}) {
            push @tracks, $track->{content};
        }
    }
    $self->tracks(\@tracks);

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
           '"' . $self->album . '"' . ", " .
           $self->year . ", " .
           $self->_best_effort_price() . ", " .
           $self->Asin;
}

1;

__END__

=head1 NAME

Net::Amazon::Property::Music - Class for pop CDs on amazon.com

=head1 SYNOPSIS

  use Net::Amazon;

  # ...

  if($resp->is_success()) {
      for my $prop ($resp->properties) {
          print join("/", $_->artists(), " ",
                $_->album(), " ",
                $_->label(), " ",
                $_->year(), " ";
                $_->upc(), " ";
                $_->media(), " ";
                $_->nummedia(), "\n";
  }

=head1 DESCRIPTION

C<Net::Amazon::Property::Music> is derived from 
C<Net::Amazon::Property> and on top of the all-purpose
methods the base class provides, it offers specialized accessors for
popular music CD parameters.

=head2 METHODS

=over 4

=item artists()

Returns a list of the CD's artists. There's also a C<artist()> method
which just returns the first artist.

=item tracks()

Returns a list of the CD's track titles.  Tracks are ordered as they appear on
the media.  Track one is at offset zero in the tracks() list.  If there are
multiple media then tracks are appended to the same list.  There is currently
no way to determine which track belongs to which media.  (Amazon returns these
data, but it is not used by Net::Amazon.)

=item label()

Returns the music label as a string.

=item album()

Returns the CD's title as a string.

=item upc()

Returns the CD's UPC as a string.

=item media()

Returns the CD's media type as a string.

=item nummedia()

Returns the CD's number of media (number of discs) as a string.
Amazon doesn't always send this back, so if you get undef assume it
is 1.

=item new(xmlref => $xmlref)

Initializes an object by passing a hash of hashes structure containing
the XML data returned from the service. Usually, this is just used by
C<Net::Amazon> internally to initialize objects for on backcoming
data.

=back

Check out L<Net::Amazon::Property> for all-purpose accessors, like
C<year>, C<OurPrice>, C<ListPrice>, etc.

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 THANKS

Thanks to Padraic Renaghan E<lt>padraic@renaghan.com<gt> for adding
the upc/media/nummedia fields.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

