package TM::Serializable::CTM;

use Class::Trait 'base';
use Class::Trait 'TM::Serializable';

use Data::Dumper;

=pod

=head1 NAME

TM::Serializable::CTM - Topic Maps, trait for parsing of CTM instances.

=head1 SYNOPSIS

  # this is not an end-user package
  # see the source of TM::Materialized::CTM

=head1 DESCRIPTION

This package provides parsing functionality for CTM instances with the exceptions listed
below.

   http://www.isotopicmaps.org/ctm/ctm.html

=begin html

<BLOCKQUOTE>
<A HREF="http://www.isotopicmaps.org/ctm/ctm.html">http://www.isotopicmaps.org/ctm/ctm.html</A>
</BLOCKQUOTE>

=end html

=begin man

   http://www.isotopicmaps.org/ctm/ctm.html

=end man

=head2 Deviations from the CTM Specification

=over

=back

=head1 INTERFACE

=head2 Methods

=over

=item B<deserialize>

This method tries to parse the passed in text stream as CTM instance. It will raise an exception on
the first parse error. On success, it will return the map object.

=cut

sub deserialize {
    my $self    = shift;
    my $content = shift;

    use TM::CTM::Parser;
    my $ap = new TM::CTM::Parser (store => $self);
    $ap->parse ($content);                                                 # we parse content into the ap object component 'store'
    return $self;
}

=pod

=item B<serialize>

This is not implemented.

=cut

sub serialize {
  $TM::log->logdie ( scalar __PACKAGE__ .": not implemented" );
}

=pod

=back

=head1 SEE ALSO

L<TM>

=head1 AUTHOR INFORMATION

Copyright 200[8], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.2';
our $REVISION = '$Id$';

1;

__END__
