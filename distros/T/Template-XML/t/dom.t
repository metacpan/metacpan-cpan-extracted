#============================================================= -*-perl-*-
#
# t/dom.t
#
# Test the XML::DOM plugin.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
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
use Template::Plugin::XML;
use Cwd qw( abs_path );

#$Template::Test::DEBUG = 1;
$Template::Test::PRESERVE = 1;

# I hate having to do this
my $shut_up_warnings = $XML::DOM::VERSION;

# make sure we've got XML::DOM installed
eval "use XML::DOM";
skip_all("XML::DOM v1.27 or later not installed")
    if $@ || $XML::DOM::VERSION < 1.27;

# disable LibXML
$Template::Plugin::XML::LIBXML = 0;

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$file .= '/testfile.xml';   

test_expect(\*DATA, undef, { 'xmlfile' => $file });

__END__

-- test --
-- name: libxml disabled --
[% USE XML;
   XML.libxml ? 'error: libxml should be disabled' : 'libxml disabled'
%]
-- expect --
libxml disabled


#------------------------------------------------------------------------
# get XML::DOM via XML plugin
#------------------------------------------------------------------------

-- test --
[% USE XML;
   TRY;
     file = XML.file(name = 'no_such_file.xml');
     dom  = file.dom;
   CATCH;
     error.as_string.replace('(?s::.*)', '');
   END
-%]
-- expect --
XML.File error - failed to parse no_such_file.xml

-- test --
[% USE XML;
   TRY;
     dom = XML.file('no_such_file.xml').dom;
   CATCH;
     error.as_string.replace('(?s::.*)', '');
   END;  
-%]
-- expect --
XML.File error - failed to parse no_such_file.xml

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(file => xmlfile) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page


#------------------------------------------------------------------------
# get XML::DOM direct via XML.DOM plugin
#------------------------------------------------------------------------

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(xmlfile) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE XML;
   dom = XML.dom;
   doc = dom.parse(xmlfile)
-%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

-- test --
[% USE dom = XML.DOM -%]
[% doc = dom.parse(file => xmlfile) -%]
[% FOREACH tag = doc.getElementsByTagName('page') -%]
   * [% tag.href %] [% tag.title %]
[% END %]
-- expect --
   * /foo/bar The Foo Page
   * /bar/baz The Bar Page
   * /baz/qux The Baz Page

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


#------------------------------------------------------------------------
# TODO: test views
#------------------------------------------------------------------------
