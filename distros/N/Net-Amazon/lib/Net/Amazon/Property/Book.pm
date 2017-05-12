###################################################################### 
package Net::Amazon::Property::Book;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Property);

__PACKAGE__->make_accessor($_) for qw(publisher binding isbn 
    dewey_decimal numpages edition ean publication_date);
__PACKAGE__->make_array_accessor($_) for qw(authors);

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

    $self->authors($ref->{Author});
    $self->binding($ref->{Binding});
    $self->dewey_decimal($ref->{DeweyDecimalNumber});
    $self->numpages($ref->{NumberOfPages});
    $self->publisher($ref->{Publisher});
    $self->isbn($ref->{ISBN});
    $self->edition($ref->{Edition});
    $self->ean($ref->{EAN});

    my $year = 0;
    if (defined $ref->{PublicationDate}) {
        $year =  (split(/\-/, $ref->{PublicationDate}))[0];
    }
    $self->year($year);

    $self->publication_date($ref->{PublicationDate});
}

##################################################
sub author {
##################################################
    my($self, $nameref) = @_;

    # Only return the first author
    return ($self->authors($nameref))[0];
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    my @a = (defined $self->authors) ? $self->authors : qw();

    return join('/', @a) . ", " .
      '"' . $self->title . '"' . ", " .
      $self->year . ", " .
      $self->_best_effort_price() . ", " .
      $self->ASIN;
}

1;

__END__

=head1 NAME

Net::Amazon::Property::Book - Class for books on amazon.com

=head1 SYNOPSIS

  use Net::Amazon;

  # ...

  if($resp->is_success()) {
      for my $prop ($resp->properties) {
          print join("/", $prop->authors()), " ",
                $prop->title(), " ",
                $prop->publisher(), " ",
                $prop->year(), "\n";
  }

=head1 DESCRIPTION

C<Net::Amazon::Property::Book> is derived from 
C<Net::Amazon::Property> and on top of the all-purpose
methods the base class provides, it offers specialized accessors for
book parameters.

=head2 METHODS

=over 4

=item authors()

Returns a list of the book's authors. There's also a C<author()> method
which just returns the I<first> author.

=item publisher()

Returns the book's publishing company as a string.

=item title()

Returns the book's title as a string.

=item isbn()

Returns the book's ISBN number.

=item edition()

Returns the book's edition.

=item ean()

Returns the book's EAN number.

=item numpages()

Returns the number of pages.

=item dewey_decimal()

Returns the Dewey decimal number, this is for non-fiction only.

This method is deprecated (2011-10-28) as it does not appear to be returned by
Amazon any more.

=item publication_date()

Returns the publication date.

=item ReleaseDate()

Returns the release date.

For historical reasons, this method used to return the publication date. 
However, as of version Net::Amazon 0.44 the release date is returned, and 
a separate L</publication_date()> method is available. 

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

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
