package Net::PMP::Credentials;
use Moose;
use Carp;
use Data::Dump qw( dump );

has 'token_expires_in' => ( is => 'ro', isa => 'Int', required => 1, );
has 'client_id'        => ( is => 'ro', isa => 'Str', required => 1, );
has 'client_secret'    => ( is => 'ro', isa => 'Str', required => 1, );
has 'label'            => ( is => 'ro', isa => 'Str', required => 1, );
has 'scope'            => ( is => 'ro', isa => 'Str', required => 1, );

=head1 NAME

Net::PMP::Credentials - PMP credentials object

=head1 SYNOPSIS

 my $credentials = $pmp_client->create_credentials(
    username => 'i-am-a-user',
    password => 'secret-phrase-here',
    scope    => 'read', 
    expires  => 86400,
    label    => 'pmp ftw!',
 );

=head1 DESCRIPTION

Net::PMP::Credentials represents a PMP API credentials object.
See L<https://github.com/publicmediaplatform/pmpdocs/wiki/Authentication-Model#client-credentials-management>.

=head1 METHODS

=head2 token_expires_in

=head2 client_id

=head2 client_secret

=head2 label

=head2 scope

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
