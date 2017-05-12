package SWISH::Prog::KSx::Result;
use strict;
use warnings;

our $VERSION = '0.21';

use base qw( SWISH::Prog::Result );
use SWISH::3 ':constants';
use Carp;

=head1 NAME

SWISH::Prog::KSx::Result - search result for Swish3 KinoSearch backend

=head1 SYNOPSIS

 # see SWISH::Prog::Result

=head1 DESCRIPTION

SWISH::Prog::KSx::Result is a KinoSearch-based Result
class for Swish3.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Result> documentation.

=cut

=head2 uri

Returns the uri (unique term) for the result document.

=cut

sub uri { $_[0]->{doc}->{swishdocpath} }

=head2 title

Returns the title of the result document.

=cut

sub title { $_[0]->{doc}->{swishtitle} }

=head2 mtime

Returns the last modified time of the result document.

=cut

sub mtime { $_[0]->{doc}->{swishlastmodified} }

=head2 summary

Returns the swishdescription of the result document.

=cut

sub summary { $_[0]->{doc}->{swishdescription} }

=head2 get_property( I<PropertyName> )

Returns the value for I<PropertyName>.

=cut

sub get_property {
    my $self = shift;
    my $propname = shift or croak "PropertyName required";
    if ( !exists $self->{doc}->{$propname} ) {
        croak "no such PropertyName: $propname";
    }
    return $self->{doc}->{$propname};
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog-ksx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-KSx>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::KSx


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-KSx>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-KSx>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-KSx>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-KSx/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

