package Spreadsheet::WriteExcelXML::XMLwriter;

###############################################################################
#
# XMLwriter - A base class for Excel workbooks and worksheets.
#
#
# Used in conjunction with Spreadsheet::WriteExcelXML
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# Documentation after __END__
#

use Exporter;
use strict;








use vars qw($VERSION @ISA);
@ISA = qw(Exporter);

$VERSION = '0.14';

###############################################################################
#
# new()
#
# Constructor
#
sub new {

    my $class  = $_[0];

    my $self   = {
                    _filehandle  => $_[1],
                    _indentation => "    ",
                    _no_encoding => 0,
                 };

    bless  $self, $class;
    return $self;
}


###############################################################################
#
# _format_tag($level, $nl, $list, @attributes)
#
# This function formats an XML element tag for printing. Adds indentation and
# newlines as specified. Keeps attributes, if any, on one line or formats
# them one per line.
#
# Args:
#       $level      = The indentation level (int)
#       $nl         = Number of newlines after tag (int)
#       $list       = List attributes on separate lines (0, 1, 2)
#                       0 = No list
#                       1 = Automatic list
#                       2 = Explicit list
#       @attributes = Attribute/Value pairs
#
# The list option puts the attributes on separate lines if there is more
# than one attribute. List option 2 generates this effect even when there
# is only one attribute.
#
sub _format_tag {

    my $self    = shift;

    my $level   = shift;
    my $nl      = shift;
    my $list    = shift;

    my $element = $self->{_indentation} x $level. '<' . shift;

    # Autolist option. Only use list format if there is more than 1 attribute.
    $list = 0 if $list == 1 and @_ <= 2;


    # Special case. If _indentation is "" avoid all unnecessary whitespace
    $list = 0 if $self->{_indentation} eq "";
    $nl   = 0 if $self->{_indentation} eq "";


    while (@_) {
        my $attrib = shift;
        my $value  = $self->_encode_xml_escapes(shift);

        if ($list) {$element .= "\n" . $self->{_indentation} x ($level +1);}
        else       {$element .= ' ';                                       }

        $element .= $attrib;
        $element .= '="' . $value . '"';
    }

    $nl = $nl ? "\n" x $nl : "";

    return $element . '>'. $nl;
}


###############################################################################
#
# _encode_xml_escapes()
#
# Encode standard XML escapes, namely " & < > and \n. The apostrophe character
# isn't escaped since it will only occur in double quoted strings.
#
sub _encode_xml_escapes {

    my $self  = shift;
    my $value = $_[0];

    # Print un-encoded entities for debugging
    return $value if $self->{_no_encoding};

    for ($value) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g; # "
        #s/'/&pos;/g; # Not used
        s/\n/&#10;/g;
    }

    return $value;
}


###############################################################################
#
# _write_xml_start_tag()
#
# Creates a formatted XML opening tag. Prints to the current filehandle by
# default.
#
# Ex: <Worksheet ss:Name="Sheet1">
#
sub _write_xml_start_tag {

    my $self = shift;

    my $tag  = $self->_format_tag(@_);

    local $\; # Make print() ignore -l on the command line.
    print {$self->{_filehandle}} $tag if $self->{_filehandle};

    return $tag;
}


###############################################################################
#
# _write_xml_directive()
#
# Creates a formatted XML <? ?> directive. Prints to the current filehandle by
# default.
#
# Ex: <?xml version="1.0"?>
#
sub _write_xml_directive {

    my $self = shift;

    my $tag  =  $self->_format_tag(@_);
       $tag  =~ s[<][<?];
       $tag  =~ s[>][?>];

    local $\; # Make print() ignore -l on the command line.
    print {$self->{_filehandle}} $tag if $self->{_filehandle};

    return $tag;
}


###############################################################################
#
# _write_xml_end_tag()
#
# Creates the closing tag of an XML element. Prints to the current filehandle
# by default.
#
# Ex: </Worksheet>
#
sub _write_xml_end_tag {

    my $self = shift;

    my $tag  =  $self->_format_tag(@_);
       $tag  =~ s[<][</];

    local $\; # Make print() ignore -l on the command line.
    print {$self->{_filehandle}} $tag if $self->{_filehandle};

    return $tag;

}


###############################################################################
#
# _write_xml_element()
#
# Creates a single open and closed XML element. Prints to the current
# filehandle by default.
#
# Ex: <Alignment ss:Vertical="Bottom"/> or <Alignment/>
#
sub _write_xml_element {

    my $self = shift;

    my $tag  =  $self->_format_tag(@_);
       $tag  =~ s[>][/>];

    local $\; # Make print() ignore -l on the command line.
    print {$self->{_filehandle}} $tag if $self->{_filehandle};

    return $tag;
}


###############################################################################
#
# _write_xml_content()
#
# Creates an encoded XML element content. Prints to the current filehandle
# by default.
#
# Ex: Hello in <Data ss:Type="String">Hello</Data>
#
sub _write_xml_content {

    my $self = shift;

    my $tag  = $self->_encode_xml_escapes($_[0]);

    local $\; # Make print() ignore -l on the command line.
    print {$self->{_filehandle}} $tag if $self->{_filehandle};

    return $tag;

}


###############################################################################
#
# _write_xml_unencoded_content()
#
# Creates an un-encoded XML element content. Prints to the current filehandle
# by default. Used for numerical or other data that doesn't need to be
# encoded.
#
# Ex: 1.2345 in <Data ss:Type="Number">1.2345</Data>
#
sub _write_xml_unencoded_content {

    my $self = shift;

    my $tag  = $_[0];

    local $\; # Make print() ignore -l on the command line.
    print {$self->{_filehandle}} $tag if $self->{_filehandle};

    return $tag;
}


###############################################################################
#
# set_indentation()
#
# Set indentation string used to indent the output. The default is 4 spaces.
#
sub set_indentation {

    my $self = shift;
       $self->{_indentation} = defined $_[0] ? $_[0] : '    ';
}


1;


__END__


=head1 NAME

XMLwriter - A base class for Excel workbooks and worksheets.

=head1 SYNOPSIS

    #!/usr/bin/perl -w

    use strict;
    use Spreadsheet::WriteExcelXML::XMLwriter;

    my $writer  = Spreadsheet::WriteExcelXML::XMLwriter->new(*STDOUT);

    $writer->_write_xml_start_tag(0, 1, 0, 'Table', 'Rows', 4, 'Cols', 2);
    $writer->_write_xml_element  (1, 1, 0, 'Row', 'Index', '1');
    $writer->_write_xml_end_tag  (0, 1, 0, 'Table');

    __END__

    Prints:

    <Table Rows="4" Cols="2">
        <Row Index="1"/>
    </Table>




=head1 DESCRIPTION

This module is used in conjunction with Spreadsheet::WriteExcelXML. It is not intended to be a general purpose module.

As such this documentation is intended mainly for Spreadsheet::WriteExcelXML developers and maintainers.




=head1 METHODS

This section describes the methods of the C<Spreadsheet::WriteExcelXML::XMLwriter> module.




=head2 set_indentation()

The C<set_indentation()> method is used to define the style of indentation used in the output from C<Spreadsheet::WriteExcelXML::XMLwriter>. This is the only C<public> method of the module.

The default indentation style is four spaces. Calling C<set_indentation()> with C<undef> or no argument will set the indentation style back to the default.

A special case argument is the null string C<''>. In addition to not adding any indentation this also overrides any newline settings so that the output is as compact as possible and in the form of a single line. This is useful for saving space or when streaming the output.

The following example shows some of the options:

    #!/usr/bin/perl -w

    use strict;
    use Spreadsheet::WriteExcelXML::XMLwriter;

    my $writer  = Spreadsheet::WriteExcelXML::XMLwriter->new(*STDOUT);

    # One space indent.
    $writer->set_indentation(' ');
    $writer->_write_xml_start_tag(1, 1, 1, 'Table');
    $writer->_write_xml_start_tag(2, 1, 1, 'Row'  );
    $writer->_write_xml_start_tag(3, 1, 1, 'Cell' );
    print "\n";

    # Undef. Four space indent, the default.
    $writer->set_indentation();
    $writer->_write_xml_start_tag(1, 1, 1, 'Table');
    $writer->_write_xml_start_tag(2, 1, 1, 'Row'  );
    $writer->_write_xml_start_tag(3, 1, 1, 'Cell' );
    print "\n";

    # Empty string. No indentation or newlines.
    $writer->set_indentation('');
    $writer->_write_xml_start_tag(1, 1, 1, 'Table');
    $writer->_write_xml_start_tag(2, 1, 1, 'Row'  );
    $writer->_write_xml_start_tag(3, 1, 1, 'Cell' );
    print "\n";


The output is as follows. Spaces shown as C<.> for clarity.

    .<Table>
    ..<Row>
    ...<Cell>

    ....<Table>
    ........<Row>
    ............<Cell>

    <Table><Row><Cell>




=head2 _format_tag($level, $nl, $list, @attributes)

This function formats an XML element tag for printing. This is a C<private> method used by the C<_write_xml_xxx> methods. The C<_write_xml_xxx> methods can be considered as C<protected> and share the same parameters as C<_format_tag()>.

The parameters are as follows:


=over 4

=item C<$level>

The C<$level> parameter sets the indentation level. The type of indentation is defined using the set_indentation() method.

=item C<$nl>

The  C<$nl> parameter sets the number of newlines after the tag.

=item C<$list>

The  C<$list> parameter defines if element attributes are listed on more than one line. The value should be 0, 1 or 2 as follows:

=over 4

=item * 0

No list.

    $writer->_format_tag(1, 1, 0, 'Foo', 'Color', 'red', 'Height', 12);

    # Returns
    <Foo Color="red" Height="12">


=item * 1

Automatic list. This option puts the attributes on separate lines if there is more than one attribute.

    # Implicit list (more than one attribute)
    $writer->_format_tag(1, 1, 1, 'Foo', 'Color', 'red', 'Height', 12);

    # Returns
    <Foo
        Color="red"
        Height="12">


    # No implicit list (one attribute only)
    $writer->_format_tag(1, 1, 1, 'Foo', 'Color', 'red');

    # Returns
    <Foo Color="red">



=item * 2

Explicit list. This option generates a list effect even when there is only one attribute.

    $writer->_format_tag(1, 1, 2, 'Foo', 'Color', 'red');

    # Returns
    <Foo
        Color="red">

=back

=back

B<Note>: The C<$level>, C<$nl> and C<$list> parameters could be set as defaults in the C<_write_xml_xxx> methods. For example C<$level> could be incremented and decremented automatically, and C<$nl> and <$list> could be set to 1. The defaults could then be overridden on a per tag basis. However, we'll maintain the simpler direct approach for now.




=head2 _write_xml_start_tag()

Write an XML start tag with attributes if present. See the _format_tag() method for a list of the parameters.

    $writer->_write_xml_start_tag(0, 0, 0, 'Table', 'Rows', 4, 'Cols', 2);

    # Output
    <Table Rows="4" Cols="2">




=head2 _write_xml_end_tag()

Write an XML end tag with attributes if present. See the _format_tag() method for a list of the parameters.

    $writer->_write_xml_end_tag(0, 0, 0, 'Table');

    # Output
    </Table>




=head2 _write_xml_element()

Write a complete XML tag with attributes if present. See the _format_tag() method for a list of the parameters.


    $writer->_write_xml_element(0, 0, 0, 'Table', 'Rows', 4, 'Cols', 2);

    # Output
    <Table Rows="4" Cols="2"/>




=head2 _write_xml_directive()

Write an XML directive tag. See the _format_tag() method for a list of the parameters.

    $writer->_write_xml_directive(0, 0, 0, 'xml', 'version', '1.0');

    # Output
    <?xml version="1.0"?>




=head2 _write_xml_content()

Write the content section of a tag:

    <Tag>This is the content.</Tag>

It encodes any XML escapes that occur in the content. See the C<_encode_xml_escapes> method.




=head2 _write_xml_unencoded_content()

This method is the same as C<> except that it doesn't try to encode. This is used mainly to save a small amount of time when writing data types that doesn't need to be encoded such as E<lt>NumberE<gt>.




=head2 _encode_xml_escapes()

Write some standard XML escapes, namely C<">, C<&>, C<E<lt>>, C<E<gt>> and C<\n>.

The apostrophe character isn't escaped since C<Spreadsheet::WriteExcelXML::XMLwriter> always uses double quoted strings for attribute values.

    print $writer->_encode_xml_escapes('foo < 3');

    # Outputs
    foo &lt; 3




=head1 AUTHOR

John McNamara jmcnamara@cpan.org

=head1 COPYRIGHT

© MM-MMXI, John McNamara.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
