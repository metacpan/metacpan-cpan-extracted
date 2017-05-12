package Net::PMP::CollectionDoc::Item;
use Moose;
use Carp;
use Data::Dump qw( dump );
extends 'Net::PMP::CollectionDoc';

our $VERSION = '0.006';

# do NOT make immutable. somehow this breaks subclassing of CollectionDoc
#__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::PMP::CollectionDoc::Item - item from a Net::PMP::CollectionDoc::Items object

=head1 SYNOPSIS

 # see Net::PMP::CollectionDoc

=head1 METHODS

L<Net::PMP::CollectionDoc::Item> is a subclass of L<Net::PMP::CollectionDoc>. It currently does not implement
any new methods or functionality. It may disappear in a future release.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::CollectionDoc::Item


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PMP/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut
