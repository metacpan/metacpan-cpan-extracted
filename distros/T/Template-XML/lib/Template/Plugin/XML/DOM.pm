#============================================================= -*-Perl-*-
#
# Template::Plugin::XML::DOM
#
# DESCRIPTION
#   Simple Template Toolkit plugin interfacing to the XML::DOM.pm module.
#
# AUTHORS
#   Andy Wardley   <abw@cpan.org>
#   Simon Matthews <sam@knowledgepool.com>
#
# COPYRIGHT
#   Copyright (C) 2000-2006 Andy Wardley, Simon Matthews. 
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::XML::DOM;

use strict;
use warnings;
use base 'Template::Plugin';
use Template::Plugin::XML;
use XML::DOM;

our $VERSION = 2.70;
our $DEBUG   = 0 unless defined $DEBUG;


#------------------------------------------------------------------------
# new($context, \%config)
#
# Constructor method for XML::DOM plugin.  Creates an XML::DOM::Parser
# object and initialise plugin configuration.
#------------------------------------------------------------------------

sub new {
    my $class   = shift;
    my $context = shift;
    my $args    = ref $_[-1] eq 'HASH' ? pop(@_) : { };
    
    my $parser ||= XML::DOM::Parser->new(%$args)
        || return $class->throw("failed to create XML::DOM::Parser\n");

    bless { 
        PARSER  => $parser,
        DOCS    => [ ],
        CONTEXT => $context,
    }, $class;
}


#------------------------------------------------------------------------
# parse($content, \%named_params)
#
# Parses an XML stream, provided as the first positional argument (assumed
# to be a filename unless it contains a '<' character) or specified in 
# the named parameter hash as one of 'text', 'xml' (same as text), 'file'
# or 'filename'.
#------------------------------------------------------------------------

sub parse {
    my $self   = shift;
    my $args   = ref $_[-1] eq 'HASH' ? pop(@_) : { };
    my $parser = $self->{ PARSER };
    my ($content, $about, $method, $doc);

    # determine the input source from a positional parameter (may be a 
    # filename or XML text if it contains a '<' character) or by using
    # named parameters which may specify one of 'file', 'filename', 'text'
    # or 'xml'

    if ($content = shift) {
        if ($content =~ /\</) {
            $about  = 'xml text';
            $method = 'parse';
        }
        else {
            $about = "xml file $content";
            $method = 'parsefile';
        }
    }
    elsif ($content = $args->{ text } || $args->{ xml }) {
        $about = 'xml text';
        $method = 'parse';
    }
    elsif ($content = $args->{ file } || $args->{ filename }) {
        $about = "xml file $content";
        $method = 'parsefile';
    }
    else {
        return $self->throw('no filename or xml text specified');
    }
    
    # parse the input source using the appropriate method determined above
    eval { $doc = $parser->$method($content) } and not $@
        or return $self->throw("failed to parse $about: $@");
    
    # update XML::DOM::Document _UserData to contain config details
    $doc->[ XML::DOM::Node::_UserData ] = {
        map { ( $_ => $self->{ $_ } ) } 
        qw( _CONTEXT ),
    };
    
    push(@{ $self->{ _DOCS } }, $doc);

    return $doc;
}


#------------------------------------------------------------------------
# throw($errmsg)
#
# Raised a Template::Exception of type XML.DOM via die().
#------------------------------------------------------------------------

sub throw {
    my $self = shift;
    die $Template::Plugin::XML::EXCEPTION->new( 'XML.DOM' => join('', @_) );
}

#------------------------------------------------------------------------
# DESTROY
#
# Cleanup method which calls dispose() on any and all DOM documents 
# created by this object.  Also breaks any circular references that
# may exist with the context object.
#------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;

    # call dispose() on each document produced by this parser
    foreach my $doc (@{ $self->{ DOCS } }) {
        if (ref $doc) {
            undef $doc->[ XML::DOM::Node::_UserData ]->{ CONTEXT };
            $doc->dispose();
        }
    }
    delete $self->{ CONTEXT };
    delete $self->{ PARSER };
}



#========================================================================
package XML::DOM::Node;
#========================================================================


#------------------------------------------------------------------------
# present($view)
#
# Method to present node via a view (supercedes all that messy toTemplate
# stuff below).
#------------------------------------------------------------------------

sub present {
    my ($self, $view) = @_;

    if ($self->getNodeType() == XML::DOM::ELEMENT_NODE) {
        # it's an element
        $view->view($self->getTagName(), $self);
    }
    else {
        my $text = $self->toString();
        $view->view('text', $text);
    }
}

sub content {
    my ($self, $view) = @_;
    my $output = '';
    foreach my $node (@{ $self->getChildNodes }) {
        $output .= $node->present($view);        
    }
    return $output;
}



#========================================================================
package XML::DOM::Element;
#========================================================================

use vars qw( $AUTOLOAD );

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    my $attrib;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    my $doc  = $self->getOwnerDocument() || $self;
    my $data = $doc->[ XML::DOM::Node::_UserData ];

    # call 'content' or 'prune' callbacks, if defined (see _template_node())
    return &$attrib()
        if ($method =~ /^children|prune$/)
        && defined($attrib = $data->{ "_TT_\U$method" })
        && ref $attrib eq 'CODE';
    
    return $attrib
        if defined ($attrib = $self->getAttribute($method));
    
    return '';
}


1;

__END__

=head1 NAME

Template::Plugin::XML::DOM - Plugin interface to XML::DOM

=head1 SYNOPSIS

    # load plugin
    [% USE dom = XML.DOM %]

    # also provide XML::Parser options
    [% USE dom = XML.DOM(ProtocolEncoding = 'ISO-8859-1') %]

    # parse an XML file
    [% doc = dom.parse(filename) %]
    [% doc = dom.parse(file = filename) %]

    # parse XML text
    [% doc = dom.parse(xmltext) %]
    [% doc = dom.parse(text = xmltext) %]

    # call any XML::DOM methods on document/element nodes
    [% FOREACH node = doc.getElementsByTagName('report') %]
       * [% node.getAttribute('title') %]   # or [% node.title %]
    [% END %]

    # define VIEW to present node(s)
    [% VIEW report notfound='xmlstring' %]
       # handler block for a <report>...</report> element
       [% BLOCK report %]
          [% item.content(view) %]
       [% END %]

       # handler block for a <section title="...">...</section> element
       [% BLOCK section %]
       <h1>[% item.title %]</h1>
       [% item.content(view) %]
       [% END %]

       # default template block converts item to string
       [% BLOCK xmlstring; item.toString; END %]
       
       # block to generate simple text
       [% BLOCK text; item; END %]
    [% END %]

    # now present node (and children) via view
    [% report.print(node) %]

    # or print node content via view
    [% node.content(report) %]

    # following methods are soon to be deprecated in favour of views
    [% node.toTemplate %]
    [% node.childrenToTemplate %]
    [% node.allChildrenToTemplate %]

=head1 DESCRIPTION

This is a Template Toolkit plugin interfacing to the XML::DOM module.
The plugin loads the XML::DOM module and creates an XML::DOM::Parser
object which is stored internally.  The parse() method can then be
called on the plugin to parse an XML stream into a DOM document.

    [% USE dom = XML.DOM %]
    [% doc = dom.parse('/tmp/myxmlfile') %]

The XML::DOM plugin object (i.e. 'dom' in these examples) acts as a
sentinel for the documents it creates ('doc' and any others).  When
the plugin object goes out of scope at the end of the current
template, it will automatically call dispose() on any documents that
it has created.  Note that if you dispose of the the plugin object
before the end of the block (i.e.  by assigning a new value to the
'dom' variable) then the documents will also be disposed at that point
and should not be used thereafter.

    [% USE dom = XML.DOM %]
    [% doc = dom.parse('/tmp/myfile') %]
    [% dom = 'new value' %]     # releases XML.DOM plugin and calls
                                # dispose() on 'doc', so don't use it!

The plugin constructor will also accept configuration options destined
for the XML::Parser object:

    [% USE dom = XML.DOM(ProtocolEncoding = 'ISO-8859-1') %]

=head1 METHODS

=head2 parse()

The parse() method accepts a positional parameter which contains a filename
or XML string.  It is assumed to be a filename unless it contains a E<lt>
character.

    [% xmlfile = '/tmp/foo.xml' %]
    [% doc = dom.parse(xmlfile) %]

    [% xmltext = BLOCK %]
    <xml>
      <blah><etc/></blah>
      ...
    </xml>
    [% END %]
    [% doc = dom.parse(xmltext) %]

The named parameters 'file' (or 'filename') and 'text' (or 'xml') can also
be used:

    [% doc = dom.parse(file = xmlfile) %]
    [% doc = dom.parse(text = xmltext) %]

The parse() method returns an instance of the XML::DOM::Document object 
representing the parsed document in DOM form.  You can then call any 
XML::DOM methods on the document node and other nodes that its methods
may return.  See L<XML::DOM> for full details.

    [% FOREACH node = doc.getElementsByTagName('CODEBASE') %]
       * [% node.getAttribute('href') %]
    [% END %]

This plugin also provides an AUTOLOAD method for XML::DOM::Node which 
calls getAttribute() for any undefined methods.  Thus, you can use the 
short form of 

    [% node.attrib %]

in place of

    [% node.getAttribute('attrib') %]

=head1 PRESENTING DOM NODES USING VIEWS

You can define a VIEW to present all or part of a DOM tree by automatically
mapping elements onto templates.  Consider a source document like the
following:

    <report>
      <section title="Introduction">
        <p>
        Blah blah.
        <ul>
          <li>Item 1</li>
          <li>item 2</li>
        </ul>
        </p>
      </section>
      <section title="The Gory Details">
        ...
      </section>
    </report>

We can load it up via the XML::DOM plugin and fetch the node for the 
E<lt>reportE<gt> element.

    [% USE dom = XML.DOM;
       doc = dom.parse(file = filename);
       report = doc.getElementsByTagName('report')
    %]

We can then define a VIEW as follows to present this document fragment in 
a particular way.  The L<Template::Manual::Views> documentation
contains further details on the VIEW directive and various configuration
options it supports.

    [% VIEW report_view notfound='xmlstring' %]
       # handler block for a <report>...</report> element
       [% BLOCK report %]
          [% item.content(view) %]
       [% END %]

       # handler block for a <section title="...">...</section> element
       [% BLOCK section %]
       <h1>[% item.title %]</h1>
       [% item.content(view) %]
       [% END %]

       # default template block converts item to string representation
       [% BLOCK xmlstring; item.toString; END %]
       
       # block to generate simple text
       [% BLOCK text; item; END %]
    [% END %]

Each BLOCK defined within the VIEW represents a presentation style for 
a particular element or elements.  The current node is available via the
'item' variable.  Elements that contain other content can generate it
according to the current view by calling [% item.content(view) %].
Elements that don't have a specific template defined are mapped to the
'xmlstring' template via the 'notfound' parameter specified in the VIEW
header.  This replicates the node as an XML string, effectively allowing
general XML/XHTML markup to be passed through unmodified.

To present the report node via the view, we simply call:

    [% report_view.print(report) %]

The output from the above example would look something like this:

    <h1>Introduction</h1>
    <p>
    Blah blah.
    <ul>
      <li>Item 1</li>
      <li>item 2</li>
    </ul>
    </p>
  
    <h1>The Gory Details</h1>
    ...

To print just the content of the report node (i.e. don't process the
'report' template for the report node), you can call:

    [% report.content(report_view) %]

=head1 AUTHORS

This plugin module was written by Andy Wardley and Simon Matthews.

The XML::DOM module is by Enno Derksen and Clark Cooper.  It extends
the the XML::Parser module, also by Clark Cooper which itself is built
on James Clark's expat library.

=head1 COPYRIGHT

Copyright (C) 2000-2006 Andy Wardley, Simon Matthews. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin>, L<XML::DOM>, L<XML::Parser>

