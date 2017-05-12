package POE::XUL::TextNode;
# $Id: TextNode.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.

use strict;
use warnings;
use Carp;
use HTML::Entities qw( encode_entities_numeric );

our $VERSION = '0.0601';


################################################################
sub new
{
    my( $package, $text ) = @_;
    return bless { attributes => { value=>$text } }, $package;
}

################################################################
sub is_window { 0 }


################################################################
sub nodeValue
{
    my( $self, $value ) = @_;
    
    if( 2==@_ ) {
        if( $POE::XUL::Node::CM ) {
            $POE::XUL::Node::CM->after_set_attribute( $self, 
                                                      'textnode',
                                                        $value );
        }
        $_[0]->{attributes}{value} = $value;
    }
    return $_[0]->{attributes}{value};
}
*value = \&nodeValue;

################################################################
sub as_xml
{
    encode_entities_numeric( $_[0]->{attributes}{value}, 
                             "\x00-\x1f<>&\'\x80-\xff" );
}

################################################################
sub children
{
    return;
}

################################################################
sub dispose
{
    return;
}

################################################################
sub DESTROY
{
    my( $self ) = @_;
    $POE::XUL::Node::CM->after_destroy( $self )
                    if $POE::XUL::Node::CM;
}

1;

__DATA__

=head1 NAME

POE::XUL::TextNode - XUL TextNode

=head1 SYNOPSIS

    use POE::XUL::Node;
    use POE::XUL::TextNode;

    # Explicitly create a TextNode
    my $node = POE::XUL::TextNode->new( "Just some text" );
    print $node->nodeValue;

    # Implicitly create a TextNode
    my $desc = Description( "This is my description node" );
    print $desc->firstChild->nodeValue;

=head1 DESCRIPTION

POE::XUL::TextNode instances is are objects for holding and manipulating
plain text.  This permits mixed-mode nodes, that is nodes that contain both
text and other nodes.

=head1 METHODS

=head2 new

    my $textnode = POE::XUL::TextNode->new( "Some Text" );

=head2 nodeValue

    my $text = $textnode->nodeValue;

Returns the text of a TextNode.  You may also set the text of the node.

    $textnode->nodeValue( $other_text );

Of course this isn't possible in the browser's DOM; it is simulated by
replacing the previous node with a new one.

=head2 value

Synonym for L</nodeValue>.

=head2 as_xml

    my $escaped_text = $textnode->as_xml;

=head2 children

Returns an empty array.

=head2 dispose

Does nothing.



=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on XUL::Node by Ran Eilam.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), L<POE::XUL>, L<POE::XUL::Node>, L<POE::XUL::CDATA>.

=cut

