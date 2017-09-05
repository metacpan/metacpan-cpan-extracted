package Net::PMP::Profile;
use Moose;
use Data::Dump qw( dump );
use Data::Clean::JSON;
use Net::PMP::Profile::TypeConstraints;
use Net::PMP::CollectionDoc;
use Net::PMP::CollectionDoc::Link;

our $VERSION = '0.102';

# attributes
has 'title' => ( is => 'rw', isa => 'Str', required => 1, );
has 'hreflang' =>
    ( is => 'rw', isa => 'Net::PMP::Type::ISO6391', default => sub {'en'}, );
has 'published' =>
    ( is => 'rw', isa => 'Net::PMP::Type::DateTimeOrStr', coerce => 1, );
has 'valid' =>
    ( is => 'rw', isa => 'Net::PMP::Type::ValidDates', coerce => 1, );
has 'tags' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    handles => { add_tag => 'push', },
);
has 'itags' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    handles => { add_itag => 'push', },
);
has 'description' => ( is => 'rw', isa => 'Str', );
has 'byline'      => ( is => 'rw', isa => 'Str', );
has 'guid'        => ( is => 'rw', isa => 'Net::PMP::Type::GUID', );
has 'href' => ( is => 'rw', isa => 'Net::PMP::Type::Href', coerce => 1 );

# links
has 'author' => ( is => 'rw', isa => 'Net::PMP::Type::Links', coerce => 1, );
has 'copyright' =>
    ( is => 'rw', isa => 'Net::PMP::Type::Links', coerce => 1, );
has 'distributor' =>
    ( is => 'rw', isa => 'Net::PMP::Type::Links', coerce => 1, );
has 'profile' => ( is => 'rw', isa => 'Net::PMP::Type::Links', coerce => 1, );
has 'collection' =>
    ( is => 'rw', isa => 'Net::PMP::Type::Links', coerce => 1, );
has 'item' => ( is => 'rw', isa => 'Net::PMP::Type::Links', coerce => 1, );
has 'permission' =>
    ( is => 'rw', isa => 'Net::PMP::Type::Permissions', coerce => 1, );
has 'alternate' =>
    ( is => 'rw', isa => 'Net::PMP::Type::Links', coerce => 1, );

sub get_profile_url   {'https://api.pmp.io/profiles/base'}
sub get_profile_title { ref(shift) }

# singleton for class
my $cleaner = Data::Clean::JSON->new(
    DateTime                              => [ call_method => 'stringify' ],
    'Net::PMP::CollectionDoc::Link'       => [ call_method => 'as_hash' ],
    'Net::PMP::CollectionDoc::Permission' => [ call_method => 'as_hash' ],
    SCALAR                                => ['deref_scalar'],
    '-ref'                                => ['replace_with_ref'],
    '-circular' => 0,             #['detect_circular'],
    '-obj'      => ['unbless'],
);

sub as_doc {
    my $self = shift;

    # coerce into hash
    my %attrs = %{$self};

    # pull out those attributes which are really links
    my %links = (
        profile => [
            Net::PMP::CollectionDoc::Link->new(
                href  => $self->get_profile_url,
                title => $self->get_profile_title,
            )
        ]
    );

    my %class_attrs = map { $_->name => $_ } $self->meta->get_all_attributes;

    # not an attribute, a top-level key.
    my $href = delete $attrs{href};

    for my $k ( keys %attrs ) {
        if ( exists $class_attrs{$k} ) {
            my $attr = $class_attrs{$k};
            my $isa  = $attr->{isa};

            #warn "key $k => isa $isa";
            if ( $isa eq 'Net::PMP::Type::Links' ) {
                $links{$k} = delete $attrs{$k};
            }
            elsif ( $isa eq 'Net::PMP::Type::Link' ) {
                $links{$k} = [ delete $attrs{$k} ];
            }
            elsif ( $isa eq 'Net::PMP::Type::Permissions' ) {
                $links{$k} = delete $attrs{$k};
            }
            elsif ( $isa eq 'Net::PMP::Type::Permission' ) {
                $links{$k} = [ delete $attrs{$k} ];
            }
            elsif ( $isa eq 'Net::PMP::Type::MediaEnclosures' ) {
                $links{$k} = [ map { $_->as_hash } @{ delete $attrs{$k} } ];
            }
            elsif ( $isa eq 'Net::PMP::Type::MediaEnclosure' ) {
                $links{$k} = [ delete( $attrs{$k} )->as_hash ];
            }
        }
    }

    # CollectionDoc can only work with strings
    my %doc = ( attributes => \%attrs, links => \%links );

    # only pass href if it is set
    $doc{href} = $href if $href;

    # coerce everything into something CollectionDoc can handle.
    my $clean = $cleaner->clean_in_place( \%doc );

    return Net::PMP::CollectionDoc->new($clean);

}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::PMP::Profile - Base Content Profile for PMP CollectionDoc

=head1 SYNOPSIS

 use Net::PMP;
 use Net::PMP::Profile;

 # instantiate a client
 my $client = Net::PMP->client(
     host   => $host,
     id     => $client_id,
     secret => $client_secret,
 );

 # get explicit guid. otherwise one will be created for you on save.
 my $guid = Net::PMP::CollectionDoc->create_guid(); 
 my $profile_doc = Net::PMP::Profile->new(
     href      => $client->uri_for_doc($guid),
     guid      => $guid,
     title     => 'I am A Title',
     published => '2013-12-03T12:34:56.789Z',
     valid     => {
         from => "2013-04-11T13:21:31.598Z",
         to   => "3013-04-11T13:21:31.598Z",
     },
     byline    => 'By: John Writer and Nancy Author',
     description => 'This is a summary of the document.',
     tags      => [qw( foo bar baz )],
     itags     => [qw( abc123 )],
     hreflang  => 'en',  # ISO639-1 code
     author      => [qw( http://api.pmp.io/user/some-guid )],
     copyright   => [qw( http://americanpublicmedia.org/ )],
     distributor => [qw( http://api.pmp.io/organization/different-guid )],
 );

 # save doc
 $client->save($profile_doc);
 
=cut

=head1 DESCRIPTION

Net::PMP::Profile implements the CollectionDoc fields for the PMP Base Content Profile
L<https://github.com/publicmediaplatform/pmpdocs/wiki/Base-Content-Profile>.

This class B<does not> inherit from L<Net::PMP::CollectionDoc>. Net::PMP::Profile-based
classes are intended to ease data synchronization between PMP and other systems, by
providing client-based attribute validation and syntactic sugar. A CollectionDoc-based
object has no inherent validation for its attributes; it simply reflects what is on 
the PMP server. A Profile-based object can be used to validate attribute values before
they are sent to the PMP server. The B<as_doc> method converts the Profile-based object
to a CollectionDoc-based object.

=head1 METHODS

=head2 title

=head2 hreflang

=head2 valid

=head2 published

Optional ISO 8601 datetime string. You may pass in a DateTime object and as_doc()
will render it correctly.

=head2 byline

Optional attribution string.

=head2 description

Optional summary string.

=head2 tags

Optional keyword array of strings.

=head2 itags

Optional array of strings for "internal" tags.

=head2 add_tag( I<tagname> )

Push I<tagname> onto the array.

=head2 add_itag( I<tagname> )

Push I<tagname> onto the array.

=head2 as_doc

Returns a L<Net::PMP::CollectionDoc> object suitable for L<Net::PMP::Client> interaction.

=head2 get_profile_url

Returns a string for the PMP profile's URL.

=head2 get_profile_title

Returns a string for the PMP profile's title. Default is the class name.

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
