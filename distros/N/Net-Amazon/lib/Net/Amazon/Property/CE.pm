######################################################################
package Net::Amazon::Property::CE;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Property);

__PACKAGE__->make_accessor($_) for qw(brand ean label manufacturer model mpn 
                                      publisher studio upc warranty);
__PACKAGE__->make_array_accessor($_) for qw(platforms features);


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
    $self->features($ref->{Feature});
    $self->label($ref->{Label});
    $self->manufacturer($ref->{Manufacturer});
    $self->model($ref->{Model});
    $self->mpn($ref->{MPN});
    $self->platforms($ref->{Platform} || 'UNKNOWN');
    $self->publisher($ref->{Publisher});
    $self->studio($ref->{Studio});
    $self->upc($ref->{UPC});
    $self->warranty($ref->{Warranty});

    $self->NumMedia($ref->{NumberOfItems});
}

##################################################
sub platform {
##################################################
    my($self, $nameref) = @_;

    # Only return the first platform
    return ($self->platforms($nameref))[0];
}

##################################################
sub feature {
##################################################
    my($self, $nameref) = @_;

    # Only return the first feature
    return ($self->features($nameref))[0];
}


##################################################
sub as_string {
##################################################
    my($self) = @_;

    return join('/', $self->platforms) . ", " .
      '"' . $self->title . '"' . ", " .
      $self->_best_effort_price() . ", " .
      $self->ASIN;
}

1;

__END__

=head1 NAME

Net::Amazon::Property::CE - Class for consumer electronics on amazon.com

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

C<Net::Amazon::Property::CE> is derived from C<Net::Amazon::Property> and on
top of the all-purpose methods the base class provides, it offers specialized
accessors for consumer electronic parameters.

=head2 METHODS

=over 4

=item platforms()

Returns a list of the consumer electronic's platforms. There's also a
C<platform()> method which just returns the I<first> platform.

=item features()

Returns a list of the consumer electronic's features. There's also a
C<feature()> method which just returns the I<first> feature.

=item publisher()

Returns the consumer electronic's publishing company as a string.

=item title()

Returns the consumer electronic's title as a string.

=item ean()

Returns the consumer electronic's EAN number.

=item label()

Returns the consumer electronic's label type as a string.

=item studio()

Returns the consumer electronic's studio type as a string.

=item brand()

Returns the consumer electronic's brand type as a string.

=item manufacturer()

Returns the consumer electronic's manufacturer type as a string.

=item mpn()

Returns the consumer electronic's mpn (manufacturer's part number) as a string.

=item model()

Returns the consumer electronic's model as a string.

=item warranty()

Returns the consumer electronic's warranty as a string.

=item new(xmlref => $xmlref)

Initializes an object by passing a hash of hashes structure containing the XML
data returned from the service. Usually, this is just used by C<Net::Amazon>
internally to initialize objects for on backcoming data.

=back

Check out L<Net::Amazon::Property> for all-purpose accessors, like
C<year>, C<OurPrice>, C<ListPrice>, etc.

=head1 AUTHOR

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free consumer electronic; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
