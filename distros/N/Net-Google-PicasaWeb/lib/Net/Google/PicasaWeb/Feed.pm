package Net::Google::PicasaWeb::Feed;
{
  $Net::Google::PicasaWeb::Feed::VERSION = '0.12';
}
use Moose;

# ABSTRACT: base class for feed entries

extends 'Net::Google::PicasaWeb::Base';


has url => (
    is          => 'rw',
    isa         => 'Str',
);


has title => (
    is          => 'rw',
    isa         => 'Str',
);


has summary => (
    is          => 'rw',
    isa         => 'Str',
);


has author_name => (
    is          => 'rw',
    isa         => 'Str',
);


has author_uri => (
    is          => 'rw',
    isa         => 'Str',
);


has entry_id => (
    is          => 'rw',
    isa         => 'Str',
);


has user_id => (
    is          => 'rw',
    isa         => 'Str',
);


has latitude => (
    is          => 'rw',
    isa         => 'Num',
);


has longitude => (
    is          => 'rw',
    isa         => 'Num',
);


sub from_feed {
    my ($class, $service, $entry) = @_;

    my $url = $entry->field('id');
    $url =~ s/^\s+//; $url =~ s/\s+$//;
    $url =~ s{/data/entry/}{/data/feed/};

    my %params = (
        service  => $service,
        twig     => $entry,
        url      => $url,
        title    => $entry->field('title'),
        summary  => $entry->field('summary'),
        entry_id => $entry->field('gphoto:id'),
        user_id  => $entry->field('gphoto:user'),
    );

    if (my $author = $entry->first_child('author')) {
        $params{author_name} = $author->field('name')
            if $author->has_child('name');
        $params{author_uri}  = $author->field('uri')
            if $author->has_child('uri');
        $params{user_id}   ||= $author->field('gphoto:user')
            if $author->has_child('gphoto:user');
    }

    if (my $georss = $entry->first_child('georss:where')) {
        if (my $point = $georss->first_child('gml:Point')) {      
            if (my $pos = $point->field('gml:pos') ) {
                
                $pos =~ s/^\s+//;
                my ($lat, $lon) = split /\s+/, $pos, 2;

                $params{latitude}  = $lat;
                $params{longitude} = $lon;
            }
        }
    } 

    return $class->new(\%params);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Net::Google::PicasaWeb::Feed - base class for feed entries

=head1 VERSION

version 0.12

=head1 DESCRIPTION

Provides some common functions for feed-based objects. This class extends L<Net::Google::PicasaWeb::Base>.

=head1 ATTRIBUTES

All feed-based objects have these attributes. However, they may not all be used.

=head2 url

The URL used to get information about the object.

=head2 title

The title of the object.

=head2 summary

The summary of the object. This is the long description of the album or caption of the photo.

=head2 author_name

This is the author/owner of the object.

=head2 author_uri

This is the URL to get the author's public albums on Picasa Web.

=head2 entry_id

This is the ID that may be used with the object type to uniquely identify (and lookup) this object.

=head2 user_id

This is the account ID of the user.

=head2 latitude

This is the geo-coded latitude of the object.

=head2 longitude

This is the geo-coded longitude of the object.

=head1 METHODS

=head2 from_feed

  my $feed = $class->from_feed($service, $entry);

This method creates the feed object from the service object and an L<XML::Twig::Elt> representing the element returned descring that object.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Sterling Hanenkamp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
