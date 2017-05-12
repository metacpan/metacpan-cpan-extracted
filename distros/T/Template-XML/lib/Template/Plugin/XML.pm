package Template::Plugin::XML;

use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION    = 2.17;
our $DEBUG      = 0 unless defined $DEBUG;
our $EXCEPTION  = 'Template::Exception' unless defined $EXCEPTION;
our $LIBXML     = eval { require XML::LibXML } unless defined $LIBXML;
our $OPENHANDLE = eval "use Scalar::Util qw(openhandle)";
our @TYPES      = qw( file fh text 
                      xml xml_file xml_fh xml_text 
                      html html_file html_fh html_text );


sub new {
    my $class   = shift;
    my $context = shift;
    my $params  = @_ && ref $_[-1] eq 'HASH' ? pop(@_) : { };
    my ($source, $type);

    if (@_) {
        # first positional argument is file name or XML string
        $source = shift;
        $type   = $class->detect_type($source);
    }
    else {
        # look in named params for a known type
        foreach (@TYPES) {
            $type = $_, last 
                if defined ($source = delete $params->{ $_ });
        }
    }

    my $self = bless { 
        context => $context,
        debug   => delete $params->{ debug  },
        libxml  => delete $params->{ libxml },
    }, $class;

    # apply defaults for debug and libxml from package variable
    $self->{ debug  } = $DEBUG  unless defined $self->{ debug  };
    $self->{ libxml } = $LIBXML unless defined $self->{ libxml };

    # if libxml is enabled then we create an XML::LibXML parser
    $self->{ libxml } &&= do {
        # make sure they didn't try and force libxml=>1 when $LIBXML
        # says we haven't got XML::LibXML installed
        return $self->throw('XML::LibXML is not available')
            unless $LIBXML;

        my $parser = XML::LibXML->new();

        # iterate through remaining params trying to call the 
        # appropriate method on the XML::LibXML object, e.g.
        # expand_entities => 1 becomes $parse->expand_entities(1)

        my ($param, $value, $method);
        while (($param, $value) = each %$params) {
            # throw an error if the parser doesn't have the method
            $self->throw("invalid configuration parameter: $param")
                unless ($method = UNIVERSAL::can($parser, $param));

            # catch any errors thrown and re-throw as our exceptions
            eval { &$method($parser, $value) };
            $self->throw("configuration parameter '$param' failed: $@")
                if $@;
        }
        $parser;
    };

    return $self;
}


sub source {
    return $_[0]->{ source };
}


sub type {
    return $_[0]->{ type };
}


sub debug {
    my $self = shift;
    return $self->{ debug };
}


sub libxml {
    my $self = shift;
    return $self->{ libxml };
}


sub file {
    my $self   = shift;
    my $params = @_ && ref $_[-1] eq 'HASH' ? pop(@_) : { };
    my @args   = @_;
    push(@args, $params);

    $params->{ libxml } = $self->{ libxml } 
        unless defined $params->{ libxml };
    return $self->{ context }->plugin('XML.File', \@args);
}


sub dir {
    die "dir() not yet implemented";

    # pretty much as per file
}

sub dom {
    my $self = shift;

    # TODO: see if we've got a filename defined, create a DOM parser
    # (and cache it), and then call its parse() method

    # ...but for now, we'll just create a plugin
    $self->{ context }->plugin('XML.DOM', \@_);
}

sub xpath {
    my $self = shift;
    # as above
    $self->{ context }->plugin('XML.XPath', \@_);
}

sub rss {
    my $self = shift;
    # as above
    $self->{ context }->plugin('XML.RSS', \@_);
}

sub simple {
    my $self = shift;
    # as above
    $self->{ context }->plugin('XML.Simple', \@_ );
}


sub throw {
    my $self = shift;
    die $EXCEPTION->new( XML => join('', @_) );
}



sub detect_filehandle {
    my $self = shift;

    # look for a filehandle using Scalar::Utils openhandle if it's 
    # available or our poor-man's version if not.
    return $OPENHANDLE ? openhandle($_[0]) : defined(fileno $_[0]);
}


sub detect_type {
    my $self = shift;

    # look for a filehandle using Scalar::Utils openhandle if it's 
    # available or our poor-man's version if not.
    return 'fh' if $self->detect_filehandle($_[0]);

    # okay, look for the xml declaration at the start
    return 'xml_text' if $_[0] =~ m/^\<\?xml/;

    # okay, look for the html declaration anywhere in the doc
    return 'html_text' if $_[0] =~ m/<html>/i;

    # okay, does this contain a "<" symbol, and declare it to be
    # xml if it's got one, though they should use "<?xml"
    return 'text' if $_[0] =~ m{\<};

    # okay, we've tried everything else, return a filename
    return 'file';
}



1;

__END__

=head1 NAME

Template::Plugin::XML - XML plugin for the Template Toolkit

=head1 SYNOPSIS

    [% USE XML;
       dom    = XML.dom('foo.xml');
       xpath  = XML.xpath('bar.xml');
       simple = XML.simple('baz.xml');
       rss    = XML.simple('news.rdf');
    %]
    
    [% USE XML(file='foo.xml');
       dom    = XML.dom
       xpath  = XML.xpath
       # ...etc...
    %]

    [% USE XML(dir='/path/to/xml');
       file  = XML.file('foo.xml' );
       dom   = file.dom
       xpath = file.xpath
       # ...etc...
    %]

=head1 DESCRIPTION

The Template-XML distribution provides a number of Template Toolkit
plugin modules for working with XML.

The Template::Plugin::XML module is a front-end to the various other
XML plugin modules.  Through this you can access XML files and
directories of XML files via the Template::Plugin::XML::File and
Template::Plugin::XML::Directory modules (which subclass from the
Template::Plugin::File and Template::Plugin::Directory modules
respectively).  You can then create a Document Object Model (DOM) from
an XML file (Template::Plugin::XML::DOM), examine it using XPath
queries (Template::Plugin::XML::XPath), turn it into a Perl data
structure (Template::Plugin::XML::Simple) or parse it as an RSS (RDF
Site Summary) file.

The basic XML plugins were distributed as part of the Template Toolkit
until version 2.15 released in May 2006.  At this time they were
extracted into this separate Template-XML distribution and an alpha
version of this Template::Plugin::XML front-end module was added.

The Template::Plugin::XML module is still in development and not
guaranteed to work correctly yet.  However, all the other XML plugins
are more-or-less exactly as they were in TT version 2.14 and should
work as normal.

For general information on the Template Toolkit see the documentation
for the L<Template> module or L<http://template-toolkit.org>.  For
information on using plugins, see L<Template::Plugins> and
L<Template::Manual::Directives/"USE">.  For further information
on XML, see L<http://xml.com/>.

=head1 METHODS

The XML plugin module provides a number of methods to create various
other XML plugin objects.

=head2 file(name)

Creates a Template::Plugin::XML::File object.  This is a subclass
of Template::Plugin::File.

=head2 dir(path)

Creates a Template::Plugin::XML::Directory object.  This is a subclass
of Template::Plugin::Directory.

=head2 dom()

Generate a Document Object Module from an XML file.  This can be
called against a directory, file or an XML plugin object, as long as
the source XML filename is defined somewhere along the line.

    [% dom = XML.dom(filename) %]

    [% file = XML.file(filename);
       dom  = file.dom
    %]

    [% dir = XML.dir(dirname);
       dom = dir.dom(filename)
    %]

=head2 xpath()

Perform XPath queries on the file.  Like the dom() method, xpath() can
be called against a file, directory or an XML plugin object.

    [% xpath = XML.xpath(filename) %]

    [% file  = XML.file(filename);
       xpath = file.xpath
    %]

    [% dir   = XML.dir(dirname);
       xpath = dir.xpath(filename)
    %]

=head2 simple()

TODO: As per dom() and xpath() but for XML::Simple

=head2 rss()

TODO: As per dom(), xpath() and simple() but for XML::RSS

=head1 XML PLUGINS

These are the XML plugins provided in this distribution.  

=head2 Template::Plugin::XML

Front-end module to the XML plugin collection.

=head2 Template::Plugin::XML::File

This plugin module is used to represent individual XML files.  It is a
subclass of the Template::Plugin::File module, providing the
additional dom(), xpath(), simple() and other methods relevant to XML
files.

=head2 Template::Plugin::XML::Directory

This plugin module is used to represent directories of XML files.  It
is a subclass of the Template::Plugin::Directory module and provides
the same additional XML related methods as Template::Plugin::XML::File.

=head2 Template::Plugin::XML::DOM

Plugin interface providing access to the XML::DOM module.

    [% USE XD = XML.Dom %]
    [% dom = XD.parse_file('example.xml') %]
    [% pages = dom.getElementsByTagName('page') %]

=head2 Template::Plugin::XML::RSS

Plugin interface providing access to the XML::RSS module.

    [% USE news = XML.RSS('news.rdf') -%]
    [% FOREACH item IN news.items -%]
       * [% item.title %]
    [% END %]

=head2 Template::Plugin::XML::Simple

Plugin interface providing access to the XML::Simple module.

    [%  USE xml = XML.Simple('example.xml') %]

=head2 Template::Plugin::XML::XPath

Plugin interface providing access to the XML::XPath module.

    [% USE xpath = XML.XPath('example.xml');
       bar = xpath.find('/foo/bar');
    %]

=head1 AUTHORS

Andy Wardley wrote the Template Toolkit plugin modules, with
assistance from Simon Matthews in the case of the XML::DOM plugin.
Matt Sergeant wrote the XML::XPath module.  Enno Derksen and Clark
Cooper wrote the XML::DOM module.  Jonathan Eisenzopf wrote the
XML::RSS module.  Grant McLean wrote the XML::Simple module.  Clark
Cooper and Larry Wall wrote the XML::Parser module.  James Clark wrote
the expat library.

=head1 COPYRIGHT

Copyright (C) 1996-2007 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>, L<Template::Plugins>,
L<Template::Plugin::XML::DOM>, L<Template::Plugin::XML::RSS>,
L<Template::Plugin::XML::Simple>, L<Template::Plugin::XML::XPath>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
