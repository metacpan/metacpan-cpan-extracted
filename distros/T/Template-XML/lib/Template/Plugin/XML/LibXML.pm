#============================================================= -*-Perl-*-
#
# Template::Plugin::XML::LibXML
#
# DESCRIPTION
#   Template Toolkit plugin interfacing to the XML::LibXML.pm module.
#
# AUTHORS
#   Mark Fowler   <mark@twoshortplanks.com>
#   Andy Wardley  <abw@cpan.org>
#
# COPYRIGHT
#   Copyright (C) 2002-3 Mark Fowler, 2006 Andy Wardley. 
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::XML::LibXML;

require 5.004;

use strict;
use warnings;
use base 'Template::Plugin';
use Template::Plugin::XML;
use XML::LibXML;

# load the recommended (but not manditory) openhandle routine
# for filehandle detection.
BEGIN { eval "use Scalar::Util qw(openhandle)" }

our $VERSION = 2.00;

# these are a list of combatibilty mappings from names that were used
# (or logical extensions of those names for html) in the XML::XPath
# plugin.  Though we're using existing names, I want you to be able
# to still use the old names.  Very DWIM
use constant TYPE  => { 
    'xml'           => 'string',
    'text'          => 'string',
    'filename'      => 'file',
    'html'          => 'html_string',
    'html_text'     => 'html_string',
    'html_file'     => 'html_file',
    'html_filename' => 'html_file',
};


#------------------------------------------------------------------------
# new($context, \%config)
#
# Constructor method for XML::LibXML plugin.  Creates an XML::LibXML
# object and initialises plugin configuration.
#------------------------------------------------------------------------

sub new {
    my $class   = shift;
    my $context = shift;
    my $args    = ref $_[-1] eq 'HASH' ? pop(@_) : { };
    my $type;    # how we're going to get out data
    my $content; # a ref to the data

    local $_;

    # work out what data we should process
    if (@_) {
        # ah, we got positional data.
        $content = \$_[0];            # remember where it is
        $type = _guess_type($_[0]);   # guess what type we're doing
    }
    else {
        # okay, the data must be in the named parameters
        
        # first up we'll just try the method names.  You really should
        # supply the arguments like this you know.
        foreach (qw(string file fh html_string html_file html_fh)) {
            if ($args->{ $_ }) {
                $content = \$args->{ $_ }; # remember where it is
                delete $args->{ $_ };      # don't pass on parameter though
                $type = $_;                # remember what type we're doing
                last;                      # skip to the end
            }
        }
        
        unless ($type) {
            # last ditch effort.  In this case we'll try some of the names
            # that the XML::XPath plugin uses.  We might strike lucky
            foreach (keys %{ &TYPE }) {
                if ($args->{ $_ }) {
                    $content = \$args->{ $_ }; # remember where it is
                    delete $args->{ $_ };      # don't pass on parameter though
                    $type = &TYPE->{ $_ };     # remember what type we're doing
                    last;                      # skip to the end
                }
            }
        }
    }

    # return an error if we didn't get a response back
    return $class->_throw('no filename, handle or text specified')
        unless $type;

    # create a parser
    my $parser =  XML::LibXML->new();
    
    # set the options
    foreach my $method (keys %$args) {
        # try setting the method
        eval { $parser->$method($args->{$method}) };
        
        # if there's a problem throw a Tempalte::Exception
        $self->throw("option '$method' not supported") if $@;
    }
    
    # parse
    my $method = "parse_$type";
    return $parser->$method($$content);
}


#------------------------------------------------------------------------
# _guess_type($string)
#
# Guesses what type of data this is
#------------------------------------------------------------------------

sub _guess_type
{
    # look for a filehandle
    return "fh" if _openhandle($_[0]);

    # okay, look for the xml declaration at the start
    return "string" if $_[0] =~ m/^\<\?xml/;

    # okay, look for the html declaration anywhere in the doc
    return "html_string" if $_[0] =~ m/<html>/i;

    # okay, does this contain a "<" symbol, and declare it to be
    # xml if it's got one, though they should use "<?xml"
    return "string" if $_[0] =~ m{\<};

    # okay, we've tried everything else, return a filename
    return "file";
}

#------------------------------------------------------------------------
# _throw($errmsg)
#
# Raise a Template::Exception of type XML.XPath via die().
#------------------------------------------------------------------------

sub throw {
    my $self = shift;
    die $Template::Plugin::XML::EXCEPTION->new( 'XML.LibXML' => join('', @_) );
}


#------------------------------------------------------------------------
# _openhandle($scalar)
#
# Determines if this is probably an open filehandle or not.
#
# uses openhandle from Scalar::Util if we have it.
#------------------------------------------------------------------------

sub _openhandle ($)
{
   return openhandle($_[0]) if defined(&openhandle);

   # poor man's openhandle
   return defined(fileno $_[0]);
}

#========================================================================
package XML::LibXML::Node;
#========================================================================

#-----------------------------------------------------------------------
# present($view)
#
# Method to present an node via a view, using the block that has the
# same localname.
#-----------------------------------------------------------------------

# note, should this worry about namespaces?  Probably.  Hmm.

sub present {
  my ($self, $view) = @_;
  my $localname = $self->localname();

  # convert anything that isn't A-Za-z1-9 to _.  All those years
  # of working on i18n and this throws it all away.  I suck.
  $localname =~ s/[^A-Za-z0-9]/_/g;

  # render out with the block matching the hacked version of localname
  $view->view($localname, $self);
}

#-----------------------------------------------------------------------
# content($view)
#
# Method present the node's children via a view
#-----------------------------------------------------------------------

sub content {
    my ($self, $view) = @_;
    my $output = '';
    foreach my $node ($self->childNodes ) {
	$output .= $node->present($view);
    }
    return $output;
}

#----------------------------------------------------------------------
# starttag(), endtag()
#
# Methods to output the start & end tag, e.g. <bar:foo buzz="baz">
# and </bar:foo>
#----------------------------------------------------------------------

sub starttag {
    my ($self) = @_;
    my $output =  "<". $self->nodeName();
    foreach my $attr ($self->attributes)
    {
	$output .= $attr->toString();
    }
    $output .= ">";
    return $output;
}

sub endtag {
    my ($self) = @_;
    return "</". $self->nodeName() . ">";
}

#========================================================================
package XML::LibXML::Document;
#========================================================================

#------------------------------------------------------------------------
# present($view)
#
# Method to present a document node via a view.
#------------------------------------------------------------------------

sub present {
    my ($self, $view) = @_;
    # okay, just start rendering from the first element, ignore the pi
    # and all that
    $self->documentElement->present($view);
}

#========================================================================
package XML::LibXML::Text;
#========================================================================

#------------------------------------------------------------------------
# present($view)
#
# Method to present a text node via a view.
#------------------------------------------------------------------------

sub present {
    my ($self, $view) = @_;
    $view->view('text', $self->data);  # same as $self->nodeData
}

#========================================================================
package XML::LibXML::NodeList;
#========================================================================

#------------------------------------------------------------------------
# present($view)
#
# Method to present a node list via a view.  This is only normally useful
# when you call outside of TT as findnodes will be called in list context
# normally
#------------------------------------------------------------------------

sub present {
    my ($self, $view) = @_;
    my $output = '';
    foreach my $node ($self->get_nodelist ) {
	$output .= $node->present($view);
    }
    return $output;
}

#package debug;

#sub debug
#{
#  local $^W;
#  my $nodename;
#  eval { $nodename = $_[0]->nodeName(); };
#  my $methodname = (caller(1))[3];
#  $methodname =~ s/.*:://;
#
#  print STDERR "${nodename}'s $methodname: ".
#               (join ",", (map { ref } @_)) .
#	       "\n";
#}

1;

__END__

=head1 NAME

Template::Plugin::XML::LibXML - XML::LibXML Template Toolkit Plugin

=head1 SYNOPSIS

   [% USE docroot = XML.LibXML("helloworld.xml") %]

   The message is: [% docroot.find("/greeting/text") %]

=head1 DESCRIPTION

This module provides a plugin for the XML::LibXML module.  It can be
utilised the same as any other Template Toolkit plugin, by using a USE
statement from within a Template.  The use statment will return a
reference to root node of the parsed document

=head2 Specifying a Data Source

The plugin is capable of using either a string, a filename or a
filehandle as a source for either XML data, or HTML data which will be
converted to XHTML internally.

The USE statement can take one or more arguments to specify what XML
should be processed.  If only one argument is passed then the plugin
will attempt to guess how what it has been passed should be
interpreted.

When it is forced to guess what type of data it is used the routine
will first look for an open filehandle, which if it finds it will
assume it's a filehandle to a file containing XML.  Failing this (in
decreasing order) it will look for the chars "<?xml" at the start of
what it was passed (and assume it's an XML string,) look for a
"<html>" tag (and assume it's HTML string,) look for a "<" (and assume
it's XML string without a header,) or assume what it's been passed is
the filename to a file containing XML.

In the interests of being explicit, you may specify the type of
data you are loading using the same names as in the B<XML::LibXML>
documentation:

   # value contains the xml string
   [% USE docroot = XML.LibXML(string => value) %]

   # value contains the filename of the xml
   [% USE docroot = XML.LibXML(file => value) %]

   # value contains an open filehandle to some xml
   [% USE docroot = XML.LibXML(fh => value) %]

   # value contains the html string
   [% USE docroot = XML.LibXML(html_string => value) %]

   # value contains the filename of the html
   [% USE docroot = XML.LibXML(html_file => value) %]

   # value contains an open filehandle to some html
   [% USE docroot = XML.LibXML(html_fh => value) %]

Or, if you want you can use similar names to that the XML.XPath
plugin uses:

   # value contains the xml string
   [% USE docroot = XML.LibXML(xml => value) %] or
   [% USE docroot = XML.LibXML(text => value) %]

   # value contains the filename of the xml
   [% USE docroot = XML.LibXML(filename => value) %]

   # value contains the html string
   [% USE docroot = XML.LibXML(html => value) %] or
   [% USE docroot = XML.LibXML(html_text => value) %]

   # value contains the filename of the html
   [% USE docroot = XML.LibXML(html_file => value) %]
   [% USE docroot = XML.LibXML(html_filename => value) %]

You can provide extra arguments which will be used to set parser
options.  See L<XML::LibXML> for details on these.  I will repeat the
following warning however: "LibXML options are global (unfortunately
this is a limitation of the underlying implementation, not this
interface)...Note that even two forked processes will share some of
the same options, so be careful out there!"

   # turn off expanding entities
   [% USE docroot = XML.LibXML("file.xml",
                               expand_entities => 0);

=head2 Obtaining Parts of an XML Document

XML::LibXML provides two simple mechanisms for obtaining sections
of the XML document, both of which can be used from within
the Template Toolkit

The first of these is to use a XPath statement.  Simple values
can be found with the C<findvalue> routine:

  # get the title attribute of the first page node
  # (note xpath starts counting from one not zero)
  [% docroot.findvalue("/website/section/page[1]/@title"); %]

  # get the text contained within a node
  [% htmldoc.findvalue("/html/body/h1[1]/text()") %]

Nodes of the xml document can be found with the C<findnodes>

  # get all the pages ('pages' is a list of nodes)
  [% pages = docroot.findnodes("/website/section/page") %]

  # get the first page (as TT folds single elements arrays
  # to scalars, 'page1' is the one node that matched)
  [% page1 = docroot.findnodes("/website/section/page[1]") %]

Then further xpath commands can then be applied to those
nodes in turn:

  # get the title attribute of the first page
  [% page1.findvalue("@title") %]

An alternative approach is to use individual method calls to move
around the tree.  So the above could be written:

  # get the text of the h1 node
   [% htmlroot.documentElement
              .getElementsByLocalName("body").first
              .getElementsByLocalName("h1").first
              .textContent %]

  # get the title of the first page
  [% docroot.documentElement
            .getElementsByLocalName("section").first
            .getElementsByLocalName("page").first
            .getAttribute("title") %]

You should use the technique that makes the most since in the
particular situation.  These approaches can even be mixed:

  # get the first page title
  [% page1 = htmlroot.findnodes("/website/section/page[1]");
     page1.getAttribute("title") %]

Much more information can be found in L<XML::LibXML::Node>.

=head2 Rendering XML

The simplest way to use this plugin is simply to extract each value
you want to print by hand

   The title of the first page is '[%
    docroot.findvalue("/website/section/page[1]/@title") %]'

or

   The title of the first page is '[%
     docroot.documentElement
            .getElementsByLocalName("section").first
            .getElementsByLocalName("page").first
            .getAttribute("title") %]'

You might want to discard whitespace from text areas.  XPath
can remove all leading and following whitespace, and condense
all multiple spaces in the text to single spaces.

   <p>[% htmlroot.findvalue("normalize-space(
                              /html/body/p[1]/text()
                           )" | html %]</p>

Note that, as above, when we're inserting the values extracted into a
XML or HTML document we have to be careful to re-encode the attributes
we need to escape with something like the html filter.  A slightly
more advanced technique is to extract a whole node and use the
toString method call on it to convert it to a string of XML.  This is
most useful when you are extracting an existing chunk of XML en mass,
as things like E<lt>bE<gt> and E<lt>iE<gt> tags will be passed thought
correctly and entities will be encoded suitably (for example '"' will
be turned into '&quot;')

  # get the second paragraph and insert it here as XML
  [% htmlroot.findnodes("/html/body/p[2]").toString %]

The most powerful technique is to use a view (as defined by the VIEW
keyword) to recursively render out the XML.  By loading this plugin
C<present> methods will be created in the B<XML::LibXML::Node> classes
and subclasses.  Calling C<present> on a node with a VIEW will cause
it to be rendered by the view block matching the local name of that
node (with any non alphanumeric charecters turned to underscores.  So
a E<lt>authorE<gt> tag will be rendered by the 'author' block.  Text
nodes will call the 'text' block with the text of the node.

As the blocks can refer back to both the node it was called with and
the view they can choose to recursively render out it's children using
the view again.  To better facilitate this technique the extra methods
C<starttag> (recreate a string of the starting tag, including
attributes,) C<endtag> (recreate a string of the ending tag) and
C<content> (when called with a view, will render by calling all the
children of that node in turn with that view) have been added.

This is probably best shown with a well commented example:

  # create the view
  [% VIEW myview notfound => 'passthru' %]

    # default tag that will recreate the tag 'as is' meaning
    # that unknown tags will 'passed though' by the view
    [% BLOCK passthru; item.starttag;
                       item.content(view);
                       item.endtag;
    END %]

    # convert all sections to headed paragraphs
    [% BLOCK section %]
    <h2>[% item.getAttribute("title") %]</h2>
    <p>[% item.content(view) %]</p>
    [% END %]

    # urls link to themselves
    [% BLOCK url %]
    <a href="[% item.content(view) %]">[% item.content(view) %]</a>
    [% END %]

    # email link to themselves with mailtos
    [% BLOCK email %]
    <a href="mailto:[% item.content(view) %]">[% item.content(view) %]</a>
    [% END %]

    # make pod links bold
    [% BLOCK pod %]
    <b>[% item.content(view) %]</b>
    [% END %]

    # render text, re-encoding the attributes as we go
    [% BLOCK text; item | html; END %]

    # render arrays out
    [% BLOCK list; FOREACH i = item; view.print(i); END ; END %]

  [% END %]

  # use it to render the paragraphs
  [% USE doc = XML.LibXML("mydoc.xml") %]
  <html>
   <head>
    <title>[% doc.findvalue("/doc/page[1]/@title") %]</title>
   </head>
   <body>
    [% sections = doc.findnodes("/doc/page[1]/section");
       FOREACH section = sections %]
    <!-- next section -->
    [% section.present(myview);
       END %]
   </body>
  </html>

=head1 BUGS

In order to detect if a scalar is an open filehandle (which is used if
the USE isn't explicit about it's data source) this plugin uses the
C<openhandle> routine from B<Scalar::Util>.  If you do not have
B<Scalar::Util> installed, or the version of B<Scalar::Util> is
sufficiently old that it does not support the C<openhandle> routine
then a much cruder C<defined(fileno $scalar)> check will be employed.

Bugs may be reported either via the CPAN RT at
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-XML-LibXML
or via the Template Toolkit mailing list:
http://www.template-toolkit.org/mailman/listinfo/templates or direct
to the author

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

Copyright Mark Fowler 2002-3, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This module wouldn't have been possible without the wonderful work
that has been put into the libxml library by the gnome team or the
equally wonderful work put in by Matt Sergeant and Christian Glahn in
creating XML::LibXML.

=head1 SEE ALSO

L<Template>, L<Template::Plugin>, L<XML::LibXML>, L<XML::LibXML::Node>.

On a similar note, you may want to see L<Template::Plugin::XML::XPath>.

The t/test directory in the Template-Plugin-XML-LibXML distribution
contains all the example XML files discussed in this documentation.

=cut
