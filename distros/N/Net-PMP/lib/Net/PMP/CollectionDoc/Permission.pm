package Net::PMP::CollectionDoc::Permission;
use Moose;
use Carp;
use Data::Dump qw( dump );
use Net::PMP::TypeConstraints;

our $VERSION = '0.006';

has 'href' => ( is => 'rw', isa => 'Net::PMP::Type::Href', required => 1, );
has 'operation' => (
    is       => 'rw',
    isa      => Moose::Util::TypeConstraints::enum( [qw( read write )] ),
    default  => 'read',
    required => 1,
);
has 'blacklist' => ( is => 'rw', isa => 'Bool' );

sub as_hash {
    my $self = shift;
    my $hash = { %{$self} };
    if ( exists $hash->{blacklist} ) {
        $hash->{blacklist} = $hash->{blacklist} ? \1 : \0;
    }
    return $hash;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::PMP::CollectionDoc::Permission - permission link type from a Net::PMP::CollectionDoc::Links object

=head1 SYNOPSIS

 my $permission = Net::PMP::CollectionDoc::Permission->new(
     href      => 'https://api.pmp.io/docs/some-guid-for-some-group',
     operation => 'read',
     blacklist => 1,
 );
 $doc->links->{permission} = [ $permission ];

=head1 DESCRIPTION

Net::PMP::CollectionDoc::Permission represents a special link in a Collection.doc+JSON PMP API response.
See L<https://github.com/publicmediaplatform/pmpdocs/wiki/Permissions-Design>.

=head1 METHODS

=head2 href

=head2 operation

Either C<write> or C<read>.

=head2 blacklist

Boolean (true or false). 

=head2 as_hash

Returns object as Perl hashref. The blacklist() value, if set, will be output as a scalar
reference to an integer, so that passing to encode_json() will create a proper JSON boolean.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::CollectionDoc::Link


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
