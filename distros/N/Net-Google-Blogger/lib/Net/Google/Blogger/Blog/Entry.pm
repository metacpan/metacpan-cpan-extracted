package Net::Google::Blogger::Blog::Entry;

use warnings;
use strict;

use Any::Moose;
use XML::Simple ();


our $VERSION = '0.09';

has id              => ( is => 'rw', isa => 'Str' );
has title           => ( is => 'rw', isa => 'Str' );
has content         => ( is => 'rw', isa => 'Str' );
has author          => ( is => 'rw', isa => 'Str' );
has published       => ( is => 'rw', isa => 'Str' );
has updated         => ( is => 'rw', isa => 'Str' );
has edit_url        => ( is => 'rw', isa => 'Str' );
has id_url          => ( is => 'rw', isa => 'Str' );
has public_url      => ( is => 'rw', isa => 'Str' );
has source_xml_tree => ( is => 'rw', isa => 'HashRef', default => sub { {} }, required => 1 );
has categories      => ( is => 'rw', isa => 'ArrayRef[Str]', auto_deref => 1 );
has blog            => ( is => 'rw', isa => 'Net::Google::Blogger::Blog', required => 1 );

__PACKAGE__->meta->make_immutable;


sub BUILDARGS {
    ## Populates object attributes from parsed XML source.
    my $class = shift;
    my %params = @_;

    my $attrs = $class->source_xml_tree_to_attrs($params{source_xml_tree})
        if $params{source_xml_tree};

    $attrs->{$_} = $params{$_} foreach keys %params;
    return $attrs;
}


sub source_xml_tree_to_attrs {
    ## Returns hash of attributes extracted from XML tree.
    my $class = shift;
    my ($tree) = @_;

    my $get_link_by_rel = sub {
        ## Returns value for 'href' attribute for link with given 'ref' attribute, if it's present.
        my ($rel_value) = @_;

        my ($link) = grep $_->{rel} eq $rel_value, @{ $tree->{link} };
        return $link->{href} if $link;
     };

    return {
        id         => $tree->{id}[0],
        author     => $tree->{author}[0]{name}[0],
        published  => $tree->{published}[0],
        updated    => $tree->{updated}[0],
        title      => $tree->{title}[0]{content},
        content    => $tree->{content}{content},
        public_url => $get_link_by_rel->('alternate'),
        id_url     => $get_link_by_rel->('self'),
        edit_url   => $get_link_by_rel->('edit'),
        categories => [ map $_->{term}, @{ $tree->{category} || [] } ],
    };
}


sub update_from_http_response {
    ## Updates entry internal structures from given HTTP
    ## response. Used to update entry after it's been created on the
    ## server.
    my $self = shift;
    my ($response) = @_;

    my $xml_tree = XML::Simple::XMLin($response->content, ForceArray => 1);
    $self->source_xml_tree($xml_tree);

    my $new_attrs = $self->source_xml_tree_to_attrs($xml_tree);
    $self->$_($new_attrs->{$_}) foreach keys %$new_attrs;
}


sub as_xml {
    ## Returns XML string representing the entry.
    my $self = shift;

    # Add namespace specifiers to the root element, which appears to be undocumented requirement.
    $self->source_xml_tree->{xmlns} = 'http://www.w3.org/2005/Atom';
    $self->source_xml_tree->{'xmlns:thr'} = 'http://purl.org/rss/1.0/modules/threading/' if $self->id;

    # Place attribute values into original data tree. Don't generate an Atom entry anew as
    # Blogger wants us to preserve all original data when updating posts.
    $self->source_xml_tree->{title}[0] = {
        content => $self->title,
        type    => 'text',
    };
    $self->source_xml_tree->{content} = {
        content => $self->content,
        type    => 'html',
    };
    $self->source_xml_tree->{category} = [
        map {
                scheme => 'http://www.blogger.com/atom/ns#',
                term   => $_,
            },
            $self->categories
    ];

    # Convert data tree to XML.
    return XML::Simple::XMLout($self->source_xml_tree, RootName => 'entry');
}


sub save {
    ## Saves the entry to blogger.
    my $self = shift;

    if ($self->id) {
        # Update the entry.
        my $response = $self->blog->blogger->http_put($self->edit_url => $self->as_xml);
        die 'Unable to save entry: ' . $response->status_line unless $response->is_success;
    }
    else {
        # Create new entry.
        $self->blog->add_entry($self);
    }
}


sub delete {
    ## Deletes the entry from server.
    my $self = shift;

    $self->blog->delete_entry($self);
}


1;

__END__

=head1 NAME

Net::Google::Blogger::Entry - (** DEPRECATED **) represents blog entry in Net::Google::Blogger package.

=head1 SYNOPSIS

This module is deprecated. Please use L<WebService::Blogger>.

=head1 ATTRIBUTES

=head3 C<id>

=over

Unique numeric ID of the entry.

=back

=head3 C<title>

=over

Title of the entry.

=back


=head3 C<content>

=over

Content of the entry. Currently entries are always submitted with
content type set to "html".

=back


=head3 C<author>

=over

Author of the entry, as name only. Editing of this field is currently
not supported by Blogger API.

=back

=head3 C<published>

=over

Time when entry was published, in ISO format.

=back

=head3 C<updated>

=over

Time when entry was last updated, in ISO format.

=back

=head3 C<public_url>

=over

The human-readable, SEO-friendly URL of the entry.

=back

=head3 C<id_url>

=over

The never-changing URL of the entry, based on its numeric ID.

=back

=head3 C<categories>

=over

Categories (tags) of the entry, as array of strings.

=back

=head3 C<blog>

=over

The blog in which entry is published, as instance of Net::Google::Blogger::Blog

=back

=cut

=head1 METHODS

=over 1

=item new()

Creates new entry. Requires C<blog>, C<content> and C<title> attributes.

=item save()

Saves changes to the entry.

=item delete()

Deltes the entry from server and parent blog object.

=cut

=back

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-google-api-blogger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Google-Blogger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Google::Blogger


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Google-Blogger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Google-Blogger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Google-Blogger>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Google-Blogger/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Egor Shipovalov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
