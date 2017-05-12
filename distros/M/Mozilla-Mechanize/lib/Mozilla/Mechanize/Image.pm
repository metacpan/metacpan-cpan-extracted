package Mozilla::Mechanize::Image;
use strict;
use warnings;

# $Id: Image.pm,v 1.3 2005/10/07 12:17:24 slanning Exp $

=head1 NAME Mozilla::Mechanize::Image

Mozilla::Mechanize::Image - Mimic L<WWW::Mechanize::Image>

=head1 SYNOPSIS

sorry, read the code for now

=head1 DESCRIPTION

The C<Mozilla::Mechanize::Image> object is a thin wrapper around
an image element.

=head1 METHODS

=head2 Mozilla::Mechanize::Image->new($image_node, $moz)

Initialize a new object. $image_node is a
L<Mozilla::DOM::HTMLElement|Mozilla::DOM::HTMLElement>
(or a node that can be QueryInterfaced to one); specifically,
it must be an HTMLImageElement or an HTMLInputElement
whose type="image".

$moz is a L<Mozilla::Mechanize|Mozilla::Mechanize> object.
This is optional and currently unused.

=cut

sub new {
    my $class = shift;
    my $node = shift;
    my $moz = shift;

    my $iid = 0;
    if (lc $node->GetNodeName eq 'img') {
        $iid = Mozilla::DOM::HTMLImageElement->GetIID;
    } elsif (lc $node->GetNodeName eq 'input') {
        $iid = Mozilla::DOM::HTMLInputElement->GetIID;  # type="image"
    } else {
        my $errstr = "Invalid Image node";
        defined($moz) ? $moz->die($errstr) : die($errstr);
    }
    my $image = $node->QueryInterface($iid);

    my $self = { image => $image };
    $self->{moz} = $moz if defined $moz;
    bless($self, $class);
}

=head2 $image->url

Return the SRC attribute from the IMG tag.

=cut

sub url {
    my $self = shift;
    my $img = $self->{image};
    return $img->GetSrc;
}

=head2 $image->tag

Return 'IMG' for images.

=cut

sub tag {
    my $self = shift;
    my $img = $self->{image};
    return $img->GetTagName;
}

=head2 $image->width

Return the value of the C<width> attribute. Only works for <img>.

=cut

sub width {
    my $self = shift;
    my $img = $self->{image};

    if (lc($self->tag) eq 'img') {
        # xxx: no!
        #return $img->GetWidth;

        return $img->GetAttribute('width');
    }
    else {
        return '';
    }
}

=head2 $image->height

Return the value of the C<height> attribute. Only works for <img>.

=cut

sub height {
    my $self = shift;
    my $img = $self->{image};
    if (lc($self->tag) eq 'img') {
        # xxx: no!
        #return $img->GetHeight;

        return $img->GetAttribute('height');
    }
    else {
        return '';
    }
}

=head2 $image->alt

Return the value C<alt> attrubite.

=cut

sub alt {
    my $self = shift;
    my $img = $self->{image};
    return $img->GetAlt;
}


1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright 2005,2009 Scott Lanning <slanning@cpan.org>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
