package Net::PMP::Profile::Audio;
use Moose;
extends 'Net::PMP::Profile::Media';

our $VERSION = '0.102';

sub get_profile_url {'https://api.pmp.io/profiles/audio'}

1;

__END__

=head1 NAME

Net::PMP::Profile::Audio - Rich Media Audio Profile for PMP CollectionDoc

=head1 SYNOPSIS

 # see Net::PMP::Profile::Media
 
=cut

=head1 DESCRIPTION

Net::PMP::Profile::Audio implements the CollectionDoc fields for the PMP Rich Media Profile
L<https://github.com/publicmediaplatform/pmpdocs/wiki/Rich-Media-Profiles>.

=head1 METHODS

This class extends L<Net::PMP::Profile>. Only new or overridden methods are documented here.

=head2 get_profile_url

Returns a string for the PMP profile's URL.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP-Profile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP


You can also look for information at:

=over 4

=item IRC

Join #pmp on L<http://freenode.net>.

=item RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP-Profile>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP-Profile>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP-Profile>

=item Search CPAN

L<http://search.cpan.org/dist/Net-PMP-Profile/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut
