package Net::PMP::Schema;
use Moose;
use Carp;
use Data::Dump qw( dump );

our $VERSION = '0.006';

has 'definitions' => ( is => 'ro', isa => 'HashRef', required => 1, );
has 'description' => ( is => 'ro', isa => 'Str',     required => 1, );
has 'id'          => ( is => 'ro', isa => 'Str',     required => 1, );
has 'properties'  => ( is => 'ro', isa => 'HashRef', required => 1, );
has 'type'        => ( is => 'ro', isa => 'Str',     required => 1, );

=head1 NAME

Net::PMP::Schema - PMP schema object

=head1 SYNOPSIS

 my $schema = $pmp_client->get_doc($pmp_client->host . '/schemas/user');

=head1 DESCRIPTION

Net::PMP::Schema represents a PMP API schema object.

=head1 METHODS

=head2 definitions

=head2 description

=head2 id

=head2 properties

=head2 type

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::CollectionDoc


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
