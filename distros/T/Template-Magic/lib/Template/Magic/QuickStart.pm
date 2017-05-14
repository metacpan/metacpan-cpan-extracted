package Template::Magic::QuickStart;
$VERSION = 1.39;
use strict ;

__END__

=pod

=head1 NAME

Template::Magic::QuickGuide - A quick start for Webmasters

=head1 Quick Start for Webmasters

=head2 Overview

If you are a webmaster you don't need to know perl in order to completely customize the output of any perl script that uses Template::Magic: you have just to edit the templates that the perl script uses, and you will have the full power on the script output. Well... the full power the perl programmer decided to give you ;-).

=head2 Templates

Templates are simple files used by the Template::Magic system in order to produce the output. Depending on the application, a template might be a text, html, xml, or any other type of file. Usually the template is composed by static text (i.e. the text that will never be changed by the application), and a few delimited zones (labels or blocks), that will be substituted by the application with dynamic data produced by the program. The merging of the static text and the program data will produce the output of the program.

This is a very simple template file:

    City: {city}
    Date and Time: {date_and_time}

where {city} and {date_and_time} are just zones (labels) that the application recognizes and replaces with some real runtime values. The remaining text is static text which will be included verbatim in the output.

The following may be an output:

    City: NEW YORK
    Date and Time: Sat Nov 16 21:03:31 2002

=head2 Zones: Labels and Blocks

A 'zone' is a special delimited place in the template, that the Template::Magic system recognizes as a zone. Depending on the implementation decided by the programmer, the zones of each application may be delimited by a different set of characters. Usually the default delimiters are C<{ }> or C<< <!--{ }--> >> (which are default delimiters included in HTML comments, very handy in HTML WYSIWYG editors).

A zone may have a content or not. A zone with no content is also a label, while a zone with content is also a block:

    a label: {identifier}
    a block: {identifier} content of the block {/identifier}

Identifiers are case sensitive and are defined by the programmer. He should provide a list of recognized labels and block, along with a description of each zone.

=head2 Repeating blocks

Oftenly an application is required to produce lists. It can do so by implementing a repeating block. The content of the repeating block will be parsed and the included labels and blocks will be substituted with the actual data as many time as necessary in order to produce the full list output:

    {visit_list}
      City: {city}
      Date and Time: {date_and_time}
    {/visit_list}

The following may be an output:

    City: NEW YORK
    Date and Time: Sat Nov 16 21:03:31 2002
    
    City: WASHINGTON
    Date and Time: Sun Nov 17 18:21:40 2002
    
    City: MIAMI
    Date and Time: Mon Nov 18 16:38:16 2002

=head2 the NOT_* block

For any label or block you can use a NOT_* zone (where '*' stands for the zone id) which  will automatically be printed if the zone is not printed, or wiped out if the zone is printed.

    {visit_list}
      City: {city}
      Date and Time: {date_and_time}{NOT_date_and_time}N/A{/NOT_date_and_time}
    {/visit_list}
    {NOT_visit_list}
      No visit to report
    {/NOT_visit_list}

The following may be an output:

    City: DENVER
    Date and Time: N/A
    
    City: WASHINGTON
    Date and Time: Sun Nov 17 18:21:40 2002
    
    City: MIAMI
    Date and Time: Mon Nov 18 16:38:16 2002

The following may be another output:

    No visit to report

=head2 INCLUDE_TEXT and INCLUDE_TEMPLATE

You can inlude a template or a static text file by using 2 special lables: INCLUDE_TEXT and INCLUDE_TEMPLATE. The include text will include verbatim the text found into the file, while INCLUDE_TEMPLATE will parse the file first, substituting labels and blocks with actual data.

    {INCLUDE_TEMPLATE /templates/temp_file.html}
    {INCLUDE_TEXT /templates/text_file.html}

Paths are relative to the current template.

=head2 Customizing a template

You can customize all the static text in any template, you can also omit or move any label or block inside any template. You can split a template into chunks and include each chunk with an INCLUDE_TEXT or an INCLUDE_TEMPLATE label, or you can join different included templates chunk into a single template.

In special cases, when the programmer implemented this possibility, you can also pass some custom parameters to some custom labels in order to further customize the output. Anyway, the label and block definition along with the production of the dynamic content is always controlled by the application.

=head1 SYNTAX GLOSSARY

=over

=item attributes string

The I<attributes string> contains every character between the end of the label I<identifier> and the I<end label> marker.

B<Note>: The attributes are a special implementation decided by the programmer for special resons.

=item block

A I<block> is a I<template zone> delimited by (and including) a I<label> and an I<end label>:

    +-------+-------------------+------------+
    | LABEL |      CONTENT      | END_LABEL  |
    +-------+-------------------+------------+

Example: B<{my_identifier} content of the block {/my_identifier}>

where C<'{my_identifier}'> is the LABEL, C<' content of the block '> is the CONTENT and C<'{/my_identifier}'> is the END_LABEL.

=item end label

An I<end label> is a string in the form of:

    +--------------+---------------+------------+------------+
    | START_MARKER | END_MARKER_ID | IDENTIFIER | END_MARKER |
    +--------------+---------------+------------+------------+

Example of end label : B<{/my_identifier}>

where C<'{'> is the START_MARKER, C<'/'> is the END_MARKER_ID, C<'my_identifier'> is the IDENTIFIER, and C<'}'> is the END_MARKER.

=item identifier

A I<label identifier> is a alpha-numeric case-sensitive name that must be implemented by the application.

=item illegal blocks

Each block in the template can contain arbitrary quantities of nested labels and/or blocks, but it cannot contain itself (a block with its same identifier), or cannot be cross-nested.

B<Legal  block>: {block1}...{block2}...{/block2}...{/block1}

B<Illegal auto-nested block>: {block1}...{block1}...{/block1}...{/block1}

B<Illegal cross-nested block>: {block1}...{block2}...{/block1}...{/block2}

If the template contains any illegal block, unpredictable behaviours may occur.

=item include label

An I<include label> is a I<label> used to include a I<template> or I<static text> file. The I<identifier> must be 'INCLUDE_TEMPLATE' of 'INCLUDE_TEXT' and the attributes string should be a valid path. Paths are relative to the current template.

Example: B<{INCLUDE_TEMPLATE /templates/temp_file.html}>
Example: B<{INCLUDE_TEXT /templates/text_file.html}>

=item label

A I<label> is a string in the form of:

    +--------------+------------+------------+------------+
    | START_MARKER | IDENTIFIER | ATTRIBUTES | END_MARKER |
    +--------------+------------+------------+------------+

Example: B<{my_identifier attribute1 attribute2}>

where C<'{'> is the START_MARKER, C<'my_identifier'> is the IDENTIFIER, C<'attribute1 attribute2'> are the ATTRIBUTES and C<'}'> is the END_MARKER.

B<Note>: The attributes are a special implementation decided by the programmer for special resons.

=item markers

The markers that defines a labels and blocks. These are the default values of the markers that define the label:

    START_MARKER:   {
    END_MARKER_ID:  /
    END_MARKER:     }

The default marker used in HTML environment (e.g. <!--{identifier}-->):

    START_MARKER:   <!--{
    END_MARKER_ID:  /
    END_MARKER:     }-->

Each application may define a different set of markers.

=item nested block

A I<nested block> is a I<block> contained in another I<block>:

    +----------------------+
    |   CONTAINER_BLOCK    |
    |  +----------------+  |
    |  |  NESTED_BLOCK  |  |
    |  +----------------+  |
    +----------------------+

Example:
    {my_container_identifier}
    B<{my_nested_identifier} content of the block {/my_nested_identifier}>
    {/my_container_identifier}

where all the above is the CONTAINER_BLOCK and C<'{my_nested_identifier} content of the block {/my_nested_identifier}'> is the NESTED_BLOCK.

=item output

The I<output> is the result of the merger of runtimes values with a template

=item template

A I<template> is a text content or a text file (i.e. plain, HTML, XML, etc.) containing some I<label> or I<block>.

=item zone

A I<zone> is an area in the template that must have an I<identifier>, may have an I<attributes string> and may have a I<content>. A zone without any content is also called I<label>, while a zone with content is also called I<block>.

=back

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
