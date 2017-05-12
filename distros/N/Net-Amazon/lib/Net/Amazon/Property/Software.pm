######################################################################
package Net::Amazon::Property::Software;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Property);
use Log::Log4perl qw(:easy get_logger);

__PACKAGE__->make_accessor($_) for qw(brand ean esrb_rating label media
                                      manufacturer nummedia publisher studio);
__PACKAGE__->make_array_accessor($_) for qw(platforms);


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
sub init_via_xmlref {
##################################################
    my($self, $xmlref) = @_;

    $self->SUPER::init_via_xmlref($xmlref);

    my $ref = $xmlref->{ItemAttributes};

    $self->brand($ref->{Brand});
    $self->ean($ref->{EAN});
    $self->esrb_rating($ref->{ESRBAgeRating});
    $self->label($ref->{Label});
    $self->manufacturer($ref->{Manufacturer});
    $self->platforms($ref->{Platform});
    $self->publisher($ref->{Publisher});
    $self->studio($ref->{Studio});

    $self->media($ref->{Binding});

    $self->NumMedia($ref->{NumberOfItems});
    $self->nummedia($ref->{NumberOfItems});
}

##################################################
sub platform {
##################################################
    my($self, $nameref) = @_;

    # Only return the first platform
    return ($self->platforms($nameref))[0];
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    my @a = (defined $self->platforms) ? $self->platforms : qw();

    return join('/', @a) . ", " .
      '"' . $self->title . '"' . ", " .
      $self->_best_effort_price() . ", " .
      $self->ASIN;
}

1;

__END__

=head1 NAME

Net::Amazon::Property::Software - Class for software on amazon.com

=head1 SYNOPSIS

  use Net::Amazon;

  # ...

  if($resp->is_success()) {
      for my $prop ($resp->properties) {
          print join("/", $prop->platforms()), " ",
                $prop->title(), " ",
                $prop->publisher(), "\n";
  }

=head1 DESCRIPTION

C<Net::Amazon::Property::Software> is derived from 
C<Net::Amazon::Property> and on top of the all-purpose
methods the base class provides, it offers specialized accessors for
software parameters.

=head2 METHODS

=over 4

=item platforms()

Returns a list of the software's platforms. There's also a C<platform()> method
which just returns the I<first> platform.

=item publisher()

Returns the software's publishing company as a string.

=item title()

Returns the software's title as a string.

=item ean()

Returns the software's EAN number.

=item media()

Returns the software's media type as a string.

=item label()

Returns the software's label type as a string.

=item studio()

Returns the software's studio type as a string.

=item brand()

Returns the software's brand type as a string.

=item manufacturer()

Returns the software's manufacturer type as a string.

=item esrb_rating()

Returns the software's ESRB age rating type as a string.

=item media()

Returns the software's media type as a string.

=item nummedia()

Returns the software's number of media (number of discs) as a string.

=item new(xmlref => $xmlref)

Initializes an object by passing a hash of hashes structure containing
the XML data returned from the service. Usually, this is just used by
C<Net::Amazon> internally to initialize objects for on backcoming
data.

=back

Check out L<Net::Amazon::Property> for all-purpose accessors, like
C<year>, C<OurPrice>, C<ListPrice>, etc.

=head1 AUTHOR

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Christopher Bomenot E<lt>boumenot@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
