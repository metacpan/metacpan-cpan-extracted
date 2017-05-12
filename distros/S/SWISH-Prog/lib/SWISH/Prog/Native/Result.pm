package SWISH::Prog::Native::Result;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( SWISH::Prog::Class );

__PACKAGE__->mk_accessors(
    qw(
        swishdocpath
        swishlastmodified
        swishtitle
        swishdescription
        swishrank
        swishdbfile
        swishdocsize
        swishreccount
        swishfilenum
        swish_result
        )
);

our $VERSION = '0.75';

=head1 NAME

SWISH::Prog::Native::Result - result class for SWISH::API::Object

=head1 SYNOPSIS

 # see SWISH::Prog::Result

=head1 DESCRIPTION

The Native Result implements the SWISH::Prog::Result API for 
SWISH::API::Object results.

=head1 METHODS

=head2 swish_result

Returns the internal SWISH::API::More::Result object.

=head2 uri

Alias for swishdocpath().

=head2 mtime

Alias for swishlastmodified().

=head2 title

Alias for swishtitle().

=head2 summary

Alias for swishdescription().

=head2 score

Alias for swishrank().

=head2 swishdocpath 

=head2 swishlastmodified 

=head2 swishtitle 

=head2 swishdescription 

=head2 swishrank

=head2 swishdbfile

=head2 swishdocsize

=head2 swishreccount

=head2 swishfilenum

=cut

sub uri     { shift->swishdocpath }
sub mtime   { shift->swishlastmodified }
sub title   { shift->swishtitle }
sub summary { shift->swishdescription }
sub score   { shift->swishrank }

=head2 get_property( I<property> )

Returns the stored value for I<property> for this Result.

Same as calling property().

=cut

sub get_property {
    my $self = shift;
    my $propname = shift or croak "propname required";
    if ( $self->can($propname) ) {
        return $self->$propname;
    }
    return $self->swish_result->property($propname);
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
