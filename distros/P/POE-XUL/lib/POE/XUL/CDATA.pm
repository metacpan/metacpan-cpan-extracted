package POE::XUL::CDATA;
# $Id: CDATA.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.

use strict;
use warnings;
use Carp;

our $VERSION = '0.0601';


################################################################
sub new
{
    my( $package, $data ) = @_;
    my $self = bless { data=>'' }, $package;
    $self->nodeValue( $data );
    return $self;
}

################################################################
sub is_window { 0 }

################################################################
sub update_CM
{
    my( $self ) = @_;
    return unless $POE::XUL::Node::CM;
    $POE::XUL::Node::CM->after_cdata_change( $self );
}


################################################################
sub nodeValue
{
    my( $self, $value ) = @_;
    
    if( 2==@_ ) {
        $_[0]->{data} = $value;
        $self->update_CM;
    }
    return $_[0]->{data};
}

################################################################
sub substringData
{
    my( $self, $offset, $count ) = @_;
    return substr( $self->{data}, $offset, $count );
}

################################################################
sub appendData
{
    my( $self, $data ) = @_;
    $self->{data} .= $data;
    $self->update_CM;
}

################################################################
sub insertData
{
    my( $self, $offset, $data ) = @_;
    substr( $self->{data}, $offset, 0, $data );
    $self->update_CM;
}

################################################################
sub deleteData
{
    my( $self, $offset, $count ) = @_;
    substr( $self->{data}, $offset, $count, '');
    $self->update_CM;
}

################################################################
sub replaceData
{
    my( $self, $offset, $count, $data ) = @_;
    substr( $self->{data}, $offset, $count, $data );
    $self->update_CM;
}

################################################################
sub as_xml
{
    return qq(<![CDATA[$_[0]->{data}]]>);
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

POE::XUL::CDATA - XUL CDATA

=head1 SYNOPSIS

    use POE::XUL::Node;
    use POE::XUL::CDATA;

    my $cdata = POE::XUL::CDATA->new( $raw_data );
    $node->appendChild( $cdata );

    Script( <<JS );
        function something() {
            // JS code here
        }
    JS

=head1 DESCRIPTION

POE::XUL::CDATA instances is are DOM-like object for holding and
manipulating character data.  CDATA differs from a TextNode in that C<&> and
C<E<lt>> are ignored.  This is especially useful for Javascript; CDATA in a
Script node will be C<eval()>ed by the client javascript library.

=head1 METHODS

While POE::XUL::CDATA offers the full DOM interface, the ChangeManager will
transmit data at each update.  This means that if you modify the data more
then once during an event, the data will be sent multiple times in the
response and C<eval()>ed multiple times if it the child of a Script node. 
This may or may not be what you want.
 
=head2 nodeValue

    $cdata->nodeValue( $raw_data );
    $data = $cdata->nodeValue;

=head2 appendData

    $cdata->appendData( $more_js );

=head2 deleteData

    $cdata->deleteData( $offset, $count );

=head2 insertData

    $cdata->insertData( $offset, $more_data );

=head2 replaceData

    $cdata->insertData( $offset, $count, $more_data );

=head2 substringData

    my $data = $cdata->substringData( $offset, $count );

=head2 as_xml

    my $xml = $cdata->as_xml;

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

perl(1), L<POE::XUL>, L<POE::XUL::Node>, , L<POE::XUL::TextNode>.

=cut

