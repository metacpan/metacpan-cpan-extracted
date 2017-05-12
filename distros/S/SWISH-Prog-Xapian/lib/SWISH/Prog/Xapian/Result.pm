package SWISH::Prog::Xapian::Result;
use strict;
use warnings;
use base qw( SWISH::Prog::Result );
use SWISH::3 ':constants';
use Carp;

__PACKAGE__->mk_ro_accessors(qw( prop_id_map ));

our $VERSION = '0.09';

my $field_map = SWISH_DOC_FIELDS_MAP();

=head1 NAME

SWISH::Prog::Xapian::Result - search result for Swish3 Xapian backend

=head1 SYNOPSIS

 # see SWISH::Prog::Result
 
=cut

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Result> documentation.

=cut

=head2 prop_id_map 

Get the read-only internal map for PropertyNames to id values.

=head2 uri

Returns the uri (unique term) for the result document.

=cut

sub uri { $_[0]->{doc}->get_value( $field_map->{uri} ) }

=head2 title

Returns the title of the result document.

=cut

sub title { $_[0]->{doc}->get_value( $field_map->{title} ) }

=head2 mtime

Returns the last modified time of the result document.

=cut

sub mtime {
    $_[0]->{doc}->get_value( $field_map->{mtime} );
}

=head2 summary

Returns body of the result document.

=cut

sub summary {
    $_[0]->{doc}->get_value( $field_map->{description} );
}

=head2 get_property(I<name>)

Returns value for PropertyName I<name>.

=cut

sub get_property {
    my $self = shift;
    my $name = shift;
    if ( !defined $name ) {
        croak "name required";
    }
    if ( !exists $self->{prop_id_map}->{$name} ) {
        warn "prop_id_map: " . Data::Dump::dump( $self->{prop_id_map} );
        croak "unrecognized PropertyName: $name";
    }
    return $self->{doc}->get_value( $self->{prop_id_map}->{$name} );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-swish-prog-xapian at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-Xapian>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::Xapian

You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-Xapian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-Xapian>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-Xapian>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-Xapian>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
