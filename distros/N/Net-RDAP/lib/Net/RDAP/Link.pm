package Net::RDAP::Link;
use URI;
use MIME::Type;
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::Link> - a module representing an RDAP link.

=head1 DESCRIPTION

Links are used throughout RDAP; the following objects may contain zero
or more links:

=over

=item * objects (see L<Net::RDAP::Object>)

=item * remarks (see L<Net::RDAP::Remark>)

=item * notices (see L<Net::RDAP::Notice>)

=item * events (see L<Net::RDAP::Event>)

=back

In all cases, the modules representing these types of object inherit
from L<Net::RDAP::Base> and therefore provide a C<links()> method
which will return a (potentially empty) array of L<Net::RDAP::Link>
objects.

=cut

sub new {
    my ($package, $args, $document_url, $parent) = @_;
    my %self = %{$args};

    $self{_document_url} = $document_url if ($document_url);
    $self{_document_url} = $document_url if ($document_url);

    return bless(\%self, $package);
}

#
# returns a URI corresponding to the context URI for this object.
#
sub document_url {
    my $self = shift;

    my $url = $self->{_document_url};

    return ($url->isa('URI') ? $url : URI->new($url)) if ($url);
}

=pod

=head1 METHODS

=head2 Value

    $value = $link->value;

Returns a string containing the value of the C<value> property of the link
object, if any.

=cut

sub value { $_[0]->{'value'} }

=pod

=head2 Context URI

    $uri = $link->context;

Returns a L<URI> object representing the context URI of the link, as described
in L<Section 3.2 of RFC 8288|https://datatracker.ietf.org/doc/html/rfc8288#autoid-13>.

This URI object is constructed from the value of the C<value> property
(described above). If the value of this property is a relative URL, then an
absolute URL will be computed using the URI of the RDAP response that contains
the link object.

=cut

sub context {
    my $self = shift;
    if ($self->value) {
        return URI->new_abs($self->value, $self->document_url);

    } else {
        return $self->document_url;

    }
}

=head2 Relationship

    $rel = $link->rel;

Returns the "relationship" attribute. The possible values are defined by
an IANA registry; see:

=over

=item * L<https://www.iana.org/assignments/link-relations/link-relations.xhtml>

=back

=cut

sub rel { $_[0]->{'rel'} }

=pod

=head2 URL

    $url = $link->href;

Returns a L<URI> object corresponding to the target of the link.

=cut

sub href {
    my $self = shift;
    return URI->new_abs($self->{href}, $self->context);
}

=pod

=head2 Language

    @languages = $link->hreflang;

Returns a (potentially empty) array containing the ISO-639-2 codes which
describe the language that the target is available in.

=cut

sub hreflang { exists($_[0]->{'hreflang'}) ? @{$_[0]->{'hreflang'}} : undef }

=pod

=head2 Title

    $title = $link->title;

Returns the "title" attribute of the link. This labels the destination of a link
such that it can be used as a human-readable identifier in the language of the
context in which the link appears.

=cut

sub title { $_[0]->{'title'} }

=pod

=head2 Media

    $media = $link->media;

Returns the "media" attribute of the link. This corresponds to the media/device
the target resource is optimized for.

=cut

sub media { $_[0]->{'media'} }

=pod

=head2 Media Type

    $type = $link->type;

Returns a L<MIME::Type> object corresponding to the media type of the target
resource.

=cut

sub type { exists($_[0]->{'type'}) && $_[0]->{'type'} ? MIME::Type->new('type' => $_[0]->{'type'}) : undef }

=pod

    $is = $link->is_rdap;

Returns true if the media type of the target resource suggests that it is in an
RDAP resource.

=cut

sub is_rdap { exists($_[0]->{'type'}) && $_[0]->{'type'} =~ /^application\/rdap/i }

sub TO_JSON {
    my $self = shift;
    my %hash = %{$self};

    delete($hash{_document_url});
    delete($hash{_parent});

    return \%hash;
}

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
