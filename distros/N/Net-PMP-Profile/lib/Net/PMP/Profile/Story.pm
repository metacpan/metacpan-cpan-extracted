package Net::PMP::Profile::Story;
use Moose;
extends 'Net::PMP::Profile';

our $VERSION = '0.102';

has 'teaser'           => ( is => 'rw', isa => 'Str', );
has 'contentencoded'   => ( is => 'rw', isa => 'Str', );
has 'contenttemplated' => ( is => 'rw', isa => 'Str', );

sub get_profile_url {'https://api.pmp.io/profiles/story'}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::PMP::Profile::Story - Story Profile for PMP CollectionDoc

=head1 SYNOPSIS

 use Net::PMP;
 use Net::PMP::Profile::Story;
 
 my $story = Net::PMP::Profile::Story->new(
     title     => 'I am A Title',
     published => '2013-12-03T12:34:56.789Z',
     valid     => {
         from => "2013-04-11T13:21:31.598Z",
         to   => "3013-04-11T13:21:31.598Z",
     },
     byline    => 'By: John Writer and Nancy Author',
     description => 'This is a summary of the document.',
     tags      => [qw( foo bar baz )],
     teaser    => 'important story to read here!',
     contentencoded => $html,
     contenttemplated => $templated_html,
 );

 # instantiate a client
 my $client = Net::PMP->client(
     host   => $host,
     id     => $client_id,
     secret => $client_secret,
 ); 

 # save doc
 $client->save($story);
 
=cut

=head1 DESCRIPTION

Net::PMP::Profile::Story implements the CollectionDoc fields for the PMP Story Profile
L<https://github.com/publicmediaplatform/pmpdocs/wiki/Story-Profile>.

=head1 METHODS

This class extends L<Net::PMP::Profile>. Only new or overridden methods are documented here.

=head2 teaser

Optional brief summary.

=head2 contentencoded

Optional full HTML-encoded string.

=head2 contenttemplated

Optional content with placeholders for rich media assets.

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
