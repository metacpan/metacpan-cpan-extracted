#============================================================= -*-perl-*-
#
# t/xml.t
#
# Test the XML plugin.
#
# Written by Andy Wardley <abw@cpan.org>
#
# Copyright (C) 1996-2006 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: dom.t,v 2.8 2002/08/12 11:07:14 abw Exp $
# 
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template;
use Template::Test;
use Cwd qw( abs_path );

my $dir  = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
my $file = 'example.xml';

my $libxml = eval { require XML::LibXML };
my $vars = { 
    dir            => $dir,
    file           => $file, 
    libxml         => $libxml,
    debug_on       => sub { $Template::Plugin::XML::DEBUG = 1 },
    debug_off      => sub { $Template::Plugin::XML::DEBUG = 0 },
    libxml_on      => sub { $Template::Plugin::XML::LIBXML = 1 },
    libxml_off     => sub { $Template::Plugin::XML::LIBXML = 0 },
    libxml_save    => sub { $libxml = $Template::Plugin::XML::LIBXML },
    libxml_restore => sub { $Template::Plugin::XML::LIBXML = $libxml },
}; 
test_expect(\*DATA, undef, $vars);

__END__

#------------------------------------------------------------------------
# test the $DEBUG package variable sets debugging on/off by default
# unless overridden by a debug named parameter
#------------------------------------------------------------------------

-- test --
[% CALL debug_on; 
   USE XML;
   'debugging is '; XML.debug ? 'on' : 'off'
-%]
-- expect --
debugging is on


-- test --
[% CALL debug_off; 
   USE XML;
   'debugging is '; XML.debug ? 'on' : 'off'
-%]
-- expect --
debugging is off


-- test --
[% USE XML(debug=1);
   'debugging is '; XML.debug ? 'on' : 'off'
%]
-- expect --
debugging is on


-- test --
[% CALL debug_on;
   USE XML(debug=0);
   'debugging is '; XML.debug ? 'on' : 'off'
%]
-- expect --
debugging is off


#------------------------------------------------------------------------
# test to see if $LIBXML is defined (if XML::LibXML is available).  It
# should match whatever the libxml is set to.  Also check that we can 
# disable with a parameter and also that we get an error if we try to 
# enable it when it's not available.
#------------------------------------------------------------------------

-- test --
[% USE XML;
   'libxml is '; XML.libxml ? 'enabled' : 'disabled'
-%]
-- expect --
-- process --
libxml is [% libxml ? 'enabled' : 'disabled' %]


-- test --
[% CALL libxml_off; 
   USE XML;
  'libxml is '; XML.libxml ? 'enabled' : 'disabled';
-%]
-- expect --
libxml is disabled


-- test --
[% USE XML(libxml = 0);
   'libxml is '; XML.libxml ? 'enabled' : 'disabled'
-%]
-- expect --
libxml is disabled


-- test --
[% CALL libxml_off; 
   TRY;
     USE XML(libxml=1);
     "should have got 'XML::LibXML not available' error but didn't";
   CATCH;
     "good, we got an error: $error";
   END
-%]
-- expect --
good, we got an error: XML error - XML::LibXML is not available


# if libxml is available then check we can set and get various options
# such as expand_entities
-- test --
[% IF libxml;
     CALL libxml_restore; 
     USE XML(expand_entities=1);
     "expanding: $XML.libxml.expand_entities\n";
     CALL XML.libxml.expand_entities(0);
     "expanding: $XML.libxml.expand_entities\n";
   ELSE;
     "no libxml";
   END
-%]
-- expect --
-- process --
[% IF libxml -%]
expanding: 1
expanding: 0
[% ELSE -%]
no libxml
[% END %]


-- stop --

-- test --
[% USE XML(file='xmlfile.xml') -%]
[% XML.type %]: [% XML.source %]
-- expect --
file: xmlfile.xml

-- test --
[% USE XML %]
got libxml? [% XML.libxml ? 'yes' : 'no' %]
-- expect --
-- process --
Hmmm: [% libxml ? 'yes' : 'no' %]

-- stop --

# load a file via the file() method
-- test --
[% USE XML;
   xfile = XML.file(file);
   xfile.name               # a Template::Plugin::XML::File object
-%]
-- expect --
-- process --
[% file %]

-- stop --


-- test --
[% USE XML;
   XML.type or 'No type';
%]
-- expect --
No type


# specify directory as constructor parameter
-- test --
[% USE XML( dir => dir );
   xfile = XML.file(file);
-%]
name: [% xfile.name %]
dir: [% xfile.dir %]
-- expect --
-- process --
name: [% file %]
dir: [% dir %]


# specify directory via dir() method
-- test --
[% USE XML;
   xdir  = XML.dir(dir);   # Template::Plugin::XML::Directory
   xfile = XML.file(file);
-%]
path: [% xdir.path %]
name: [% xfile.name %]
dir: [% xfile.dir %]
-- expect --
-- process --
path: [% dir %]
name: [% file %]
dir: [% dir %]


# specify file via single argument to constructor method
-- test --
[% USE xfile = XML(file) -%]
name: [% xfile.name %]
-- expect --
-- process --
name: [% file %]


# specify file via named parameter to constructor method
-- test --
[% USE xfile = XML( file = file ) -%]
name: [% xfile.name %]
-- expect --
-- process --
name: [% file %]


# specify file and dir via named params to constructor method
-- test --
[% USE xfile = XML( dir=dir, file=file ) -%]
name: [% xfile.name %]
dir: [% xfile.dir %]
-- expect --
-- process --
name: [% file %]
dir: [% dir %]

-- stop --

# TODO: more tests...
-- test --
[% XML.dom(file) %] and [% XML.dom(file=file) %]

-- test --
[% xdir.dom(file) %] and [% xdir.dom(file=file) %] 

-- test --
[% xfile.dom %] => T::P::XML::DOM

# repeat above tests for xpath, simple and rss




# these tests below are copied from dom.t for reference

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(filename => xmlfile) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% global.xmltext = BLOCK %]
<website id="webzone1">
  <section name="alpha" title="The Alpha Zone">
    <page href="/foo/bar" title="The Foo Page"><msg>Hello World!</msg></page>
    <page href="/bar/baz" title="The Bar Page"/>
    <page href="/baz/qux" title="The Baz Page"/>
  </section>
</website>
[% END -%]
[% USE dom = XML.DOM -%]
[% doc = dom.parse(global.xmltext) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(text => global.xmltext) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(xml => global.xmltext) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE parser = XML.DOM -%]
[% doc = parser.parse(global.xmltext) -%]
[% FOREACH node = doc.getElementsByTagName('section') -%]
[% node.toTemplate %]
[% END %]

[% BLOCK section -%]
Section name: [% node.name %]  title: [% node.title %]
[% node.childrenToTemplate -%]
[% END %]

[% BLOCK page -%]
<a href="[% node.href %]">[% node.title %]</a>
[% node.childrenToTemplate -%]
[% END %]

[% BLOCK msg -%]
<b>[% node.childrenToTemplate(verbose=1) %]</b>
[% END %]

-- expect --
Section name: alpha  title: The Alpha Zone
<a href="/foo/bar">The Foo Page</a>
<b>Hello World!</b>
<a href="/bar/baz">The Bar Page</a>
<a href="/baz/qux">The Baz Page</a>

-- test --
[% xmltext = BLOCK %]
<xml>
<section id="a" title="First Section">>
  <page id="a1" title="page 1">
    <head><author>Andy Wardley</author></head>
    <body>
    This is the first page
    </body>
  </page>
  <page id="a2" title="page 2">
    This is the second page
  </page>
</section>
<section id="b" title="Second Section">
  <page id="b1" title="page 1">
    This is the first page in section b
  </page>
  <page id="b2" title="page 2">
    This is the second page in section b
  </page>
</section>
</xml>
[% END -%]
[% USE parser = XML.DOM -%]
[% doc = parser.parse(xmltext) -%]
[% node.allChildrenToTemplate(default='anynode') 
     FOREACH node = doc.getChildNodes %]

[% BLOCK section -%]
SECTION [% node.id %]: [% node.title %]
[% children -%]
END OF SECTION [% node.id %]
[% END %]

[% BLOCK page -%]
PAGE: [% node.title %]
[% node.children -%]
END OF PAGE
[% END %]

[% BLOCK head -%]
HEADER: [% node.toString; prune %]END_HEADER
[% END %]

[% BLOCK anynode -%]
<any>[% node.toString; node.prune %]</any>
[% END %]
-- expect --
SECTION a: First Section
PAGE: page 1
HEADER: <head><author>Andy Wardley</author></head>END_HEADER
<any><body>
    This is the first page
    </body></any>
END OF PAGE
PAGE: page 2
END OF PAGE
END OF SECTION a
SECTION b: Second Section
PAGE: page 1
END OF PAGE
PAGE: page 2
END OF PAGE
END OF SECTION b
