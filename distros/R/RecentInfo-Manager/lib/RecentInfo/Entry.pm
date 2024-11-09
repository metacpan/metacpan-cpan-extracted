package RecentInfo::Entry 0.04;
use 5.020;
use Moo 2;
use XML::LibXML;
use experimental 'signatures', 'postderef';
use Carp 'croak';
use URI;

=head1 NAME

RecentInfo::Entry - recent files XBEL entry

=cut

has ['href'] => (
    is => 'ro',
    required => 1,
);

has ['added', 'visited'] => (
    is => 'rw',
);
has ['modified'] => (
    is => 'lazy',
    default => sub($self) {
        (stat($self->to_native))[9]
    }
);

has ['mime_type'] => (
    is => 'ro',
    required => 1,
);

has ['applications', 'groups'] => (
    is => 'ro',
    default => sub { [] },
);

# XML fragments as strings
has 'othermeta' => (
    is => 'ro',
    default => sub { [] },
);

sub to_native( $self ) {
    my $href = $self->href;
    return $href =~ m!^file:!
        ? URI->new( $href )->file
        : $href
}

state $xpc = XML::LibXML::XPathContext->new();
$xpc->registerNs( bookmark => "http://www.freedesktop.org/standards/desktop-bookmarks");
$xpc->registerNs( mime     => "http://www.freedesktop.org/standards/shared-mime-info" );

sub as_XML_fragment($self, $doc) {
    my $bookmark = $doc->createElement('bookmark');
    $bookmark->setAttribute( 'href' => $self->href );
    # Validate that $modified, $visited etc. are proper DateTime strings
    # We enforce here a Z timezone

    for my $attr (qw(added modified visited )) {
        my $at = $self->$attr;

        # Sanity check that we add an UTC timestamp to the XBEL structure
        if( $at !~ /\A\d\d\d\d-[012]\d-[0123]\dT[012]\d:[0-5]\d:[0-6]\d(?:\.\d+)?Z\z/ ) {
            croak "Invalid time format in '$attr': $at";
        };

        $bookmark->setAttribute( $attr => $self->$attr );
    };
    my $info = $bookmark->addNewChild( undef, 'info' );
    my $metadata = $info->addNewChild( undef, 'metadata' );
    #my $mime = $metadata->addNewChild( 'mime', 'mime-type' );
    my $mime = $metadata->addNewChild( undef,'mime:mime-type' );
    $mime->setAttribute( type => $self->mime_type );
    #$mime->appendText( $self->mime_type );
    $metadata->setAttribute('owner' => 'http://freedesktop.org' );
    # Should we allow this to be empty, or should we leave it out completely then?!

    if ($self->othermeta->@* ) {
        my $parser = XML::LibXML->new();
        for my $other ($self->othermeta->@* ) {
            $info->addChild( $parser->parse_balanced_chunk( $other, 'UTF-8' )->firstChild);
        }
    };

    if( $self->groups->@* ) {
        my $groups = $metadata->addNewChild( undef, "bookmark:groups" );
        for my $group ($self->groups->@* ) {
            $groups->addChild( $group->as_XML_fragment( $doc ));
        };
    }

    my $applications = $metadata->addNewChild( undef, "bookmark:applications" );
    for my $application ($self->applications->@* ) {
        $applications->addChild( $application->as_XML_fragment( $doc ));
    };

    return $bookmark;
}

sub from_XML_fragment( $class, $frag ) {
    my $meta = $xpc->findnodes('./info[1]/metadata[@owner="http://freedesktop.org"]', $frag)->[0];
    if(! $meta) {
        warn $frag->toString;
        croak "Invalid xml?! No <info>/<metadata> element found"
    };

    my $othermeta = $xpc->findnodes('./info[1]/metadata[@owner!="http://freedesktop.org"]', $frag);
    my @othermeta = map { $_->toString } $othermeta->@*;

    my %meta = (
        mime_type => $xpc->find('./mime:mime-type/@type', $meta)->[0]->nodeValue,
    );

    my @applications = $xpc->find('./bookmark:applications/bookmark:application', $meta)->@*;
    if( !@applications ) {
        warn $meta->toString;
        die "No applications found";
    };

    $class->new(
        href      => $frag->getAttribute('href'),
        added     => $frag->getAttribute('added'),
        modified  => $frag->getAttribute('modified'),
        visited   => $frag->getAttribute('visited'),
        # info/metadata/mime-type
        mime_type => $meta{ mime_type },
        applications => [map {
             RecentInfo::Application->from_XML_fragment($_)
        } $xpc->find('./bookmark:applications/bookmark:application', $meta)->@*],
        groups => [map {
            RecentInfo::GroupEntry->from_XML_fragment($_)
        } $xpc->find('./bookmark:groups/bookmark:group', $meta)->@*],
        othermeta => \@othermeta,
        #...
    )
}

1;
=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/RecentInfo-Manager>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via Github
at L<https://github.com/Corion/RecentInfo-Manager/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2024-2024 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

