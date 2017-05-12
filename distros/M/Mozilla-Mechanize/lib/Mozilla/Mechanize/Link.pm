package Mozilla::Mechanize::Link;
use strict;
use warnings;

# $Id: Link.pm,v 1.3 2005/10/06 18:25:18 slanning Exp $

=head1 NAME Mozilla::Mechanize::Link

Mozilla::Mechanize::Link - Mimic WWW::Mechanize::Link

=head1 SYNOPSIS

sorry, read the source for now

=head1 DESCRIPTION

The C<Mozilla::Mechanize::Link> object is a thin wrapper around
HTML link elements.

=head1 METHODS

=head2 Mozilla::Mechanize::Link->new($link_node, $moz)

Initialize a new object. $link_node is a
L<Mozilla::DOM::HTMLElement|Mozilla::DOM::HTMLElement>
(or a node that can be QueryInterfaced to one); specifically,
it must be an HTMLAnchorElement, an HTMLFrameElement, an HTMLIFrameElement,
or an HTMLAreaElement.
$moz is a L<Mozilla::Mechanize|Mozilla::Mechanize> object.
(This latter is a hack for `click', so that new pages can load
in the browser. The GUI has to be able to enter its main loop.
If you don't plan to use that method, you don't have to pass it in.)

B<Note>: Although it supports the same methods as
L<WWW::Mechanize::Link|WWW::Mechanize::Link>, it is a
completely different implementation.

=cut

sub new {
    my $class = shift;
    my $node = shift;
    my $moz = shift;

    my $iid = 0;

    # turn the Node into the appropriate HTMLElement
    if (lc $node->GetNodeName eq 'a') {
        $iid = Mozilla::DOM::HTMLAnchorElement->GetIID;
    } elsif (lc $node->GetNodeName eq 'frame') {
        $iid = Mozilla::DOM::HTMLFrameElement->GetIID;
    } elsif (lc $node->GetNodeName eq 'iframe') {
        $iid = Mozilla::DOM::HTMLIFrameElement->GetIID;
    } elsif (lc $node->GetNodeName eq 'area') {
        $iid = Mozilla::DOM::HTMLAreaElement->GetIID;
    } else {
        my $errstr = "Invalid Link node";
        defined($moz) ? $moz->die($errstr) : die($errstr);
    }
    my $link = $node->QueryInterface($iid);

    my $self = { link => $link };
    $self->{moz} = $moz if defined $moz;
    bless($self, $class);
}

=head2 $link->url

Returns the url from the link.

=cut

sub url {
    my $self = shift;
    my $link = $self->{link};

    if ($link->GetTagName =~ /^i?frame$/i) {
        return $link->GetSrc;
    } else {
        return $link->GetHref;
    }
}

=head2 $link->text

Text of the link (innerHTML, so includes any HTML markup).

=cut

sub text {
    my $self = shift;
    my $link = $self->{link};

    my $iid = Mozilla::DOM::NSHTMLElement->GetIID;
    my $nshtmlelem = $link->QueryInterface($iid);

    return $nshtmlelem->GetInnerHTML;
}

=head2 $link->name

NAME attribute from the source tag, if any.

=cut

sub name {
    my $self = shift;
    my $link = $self->{link};

    return $link->HasAttribute('name') ? $link->GetAttribute('name') : '';
}

=head2 $link->tag

Tag name ("A", "AREA", "FRAME" or "IFRAME").

=cut

sub tag {
    my $self = shift;
    my $link = $self->{link};

    return $link->GetTagName;
}

=head2 $link->click

Click the link (does this fire onClick?).

=cut

sub click {
    my $self = shift;
    my $link = $self->{link};

    # XXX: maybe this could be done better

    # Create a click event
    my $doc = $link->GetOwnerDocument;
    my $deiid = Mozilla::DOM::DocumentEvent->GetIID();
    my $docevent = $doc->QueryInterface($deiid);
    my $event = $docevent->CreateEvent('MouseEvents');
    $event->InitEvent('click', 1, 1);

    # Dispatch the click event
    my $etiid = Mozilla::DOM::EventTarget->GetIID();
    my $target = $link->QueryInterface($etiid);
    $target->DispatchEvent($event);

    # XXX: if they didn't pass $moz to `new', they're stuck..
    my $moz = $self->{moz} || return;
    $moz->_wait_while_busy();
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
