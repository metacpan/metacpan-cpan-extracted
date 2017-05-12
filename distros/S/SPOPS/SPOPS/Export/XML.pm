package SPOPS::Export::XML;

# $Id: XML.pm,v 3.3 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base qw( SPOPS::Export );

$SPOPS::Export::XML::VERSION  = sprintf("%d.%02d", q$Revision: 3.3 $ =~ /(\d+)\.(\d+)/);

use constant DEFAULT_DOC_TAG    => 'spops';
use constant DEFAULT_OBJECT_TAG => 'spops-object';

my @FIELDS = qw( document_tag object_tag );
SPOPS::Export::XML->mk_accessors( @FIELDS );

sub initialize {
    my ( $self, $params ) = @_;
    $self->document_tag || $self->document_tag( DEFAULT_DOC_TAG );
    $self->object_tag   || $self->object_tag( DEFAULT_OBJECT_TAG );
    return $self;
}

sub get_fields           { return ( $_[0]->SUPER::get_fields, @FIELDS ) }

sub create_header        { return '<' . $_[0]->document_tag . ">\n" }
sub create_footer        { return '</' . $_[0]->document_tag . ">\n" }

sub create_record {
    my ( $self, $object, $fields ) = @_;
    my @output = ( '  <' . $_[0]->object_tag . '>' );
    foreach my $field ( @{ $fields } ) {
        push @output, join( '', "      <$field>",
                                $self->serialize_field_data( $object->{ $field } ),
                                "</$field>" );
    }
    push @output, '  </' . $_[0]->object_tag . '>', '';
    return join( "\n", @output );
}


sub serialize_field_data {
    my ( $self, $data ) = @_;
    $data =~ s/&/&amp;/g;
    $data =~ s/</&lt;/g;
    $data =~ s/>/&gt;/g;
    return $data;
}
1;

__END__

=head1 NAME

SPOPS::Export::XML - Export SPOPS objects in XML format

=head1 SYNOPSIS

 # See SPOPS::Export

=head1 DESCRIPTION

Implement XML output for L<SPOPS::Export|SPOPS::Export>.

=head1 PROPERTIES

B<document_tag>

Define the document tag. Default is: 'spops', so the resulting document is:

 <spops>
  ...
 </spops>

B<object_tag>

Define the surrounding tag for each object. Default is 'spops-object',
so if you use the default C<document_tag> as well the resulting
document will look like:

 <spops>
    <spops-object>
       <field1>bar</field1>
       <field2>foo</field2>
    </spops-object>
    <spops-object>
       <field1>foo</field1>
       <field2>bar</field2>
    </spops-object>
    ...
 </spops>

=head1 METHODS

B<create_header>

Output the opening document tag.

B<create_footer>

Output the closing document tag.

B<create_record( $object, $fields )>

Output the individual object.

B<serialize_field_data( $data )>

Escape relevant values in C<$data>. For right now, we just escape the
'&', 'E<lt>' and 'E<gt>' characters.

=head1 BUGS

B<Minimal escaping>

We currently do fairly minimal escaping. Will probably use
L<HTML::Entities|HTML::Entities> or some other module to deal with
this.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Export|SPOPS::Export>

L<SPOPS::Manual::ImportExport|SPOPS::Manual::ImportExport>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
