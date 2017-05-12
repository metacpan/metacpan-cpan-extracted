package SWISH::Prog::Result;
use strict;
use warnings;
use base qw( SWISH::Prog::Class );
use Carp;

our $VERSION = '0.75';

__PACKAGE__->mk_accessors(qw( doc score ));

=head1 NAME

SWISH::Prog::Result - base result class

=head1 SYNOPSIS
                
 my $results = $searcher->search( 'foo bar' );
 while (my $result = $results->next) {
     printf("%4d %s\n", $result->score, $result->uri);
 }

=head1 DESCRIPTION

SWISH::Prog::Results is a base results class. It defines
the APIs that all SWISH::Prog storage backends adhere to in
returning results from a SWISH::Prog::InvIndex.

=head1 METHODS

The following methods are all accessors (getters) only.

=head2 doc

Returns a SWISH::Prog::Doc instance.

=head2 score

Returns the ranking score for the Result.

=head2 uri

=head2 mtime

=head2 title

=head2 summary

=head2 swishdocpath

Alias for uri().

=head2 swishlastmodified

Alias for mtime().

=head2 swishtitle

Alias for title().

=head2 swishdescription

Alias for summary().

=cut

sub uri     { croak "must implement uri" }
sub mtime   { croak "must implement mtime" }
sub title   { croak "must implement title" }
sub summary { croak "must implement summary" }

# version 2 names for the faithful
sub swishdocpath      { shift->uri }
sub swishlastmodified { shift->mtime }
sub swishtitle        { shift->title }
sub swishdescription  { shift->summary }

=head2 get_property( I<property> )

Returns the stored value for I<property> for this Result.

The default behavior is to simply call a method called I<property>
on the internal doc() object. Subclasses should implement per-engine
behavior.

=cut

sub get_property {
    my $self = shift;
    my $propname = shift or croak "propname required";
    return $self->doc->property($propname);
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
