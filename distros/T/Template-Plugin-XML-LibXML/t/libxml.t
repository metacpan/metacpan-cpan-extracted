#============================================================= -*-perl-*-
#
# t/libxml.t
#
# Test the XML::LibXML plugin.
#
# Written by Mark Fowler <mark@twoshortplanks.com>
#
# Copyright (C) 2002 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: xpath.t,v 2.8 2002/03/12 15:58:23 abw Exp $
# 
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use Template;
use Template::Test;
use Cwd qw( abs_path );
use IO::File;
$^W = 1;

# I hate having to do this
my $shut_up_warnings = $XML::XPath::VERSION;

eval "use XML::LibXML";

# account for script being run in distribution root or 't' directory
# (note, does this work on Win32?  Shouldn't we be using catfile?
# the XML::XPath plugin does it like this...)
my $xmlfile = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$xmlfile .= '/testfile.xml';
my $xmlfile2 = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$xmlfile2 .= '/example.rdf';
my $htmlfile = abs_path( -d 't' ? 't/test/html' : 'test/html' );
$htmlfile .= '/basic.html';

# okay read in the entire test data into memory
my ($xmldata, $xmldata2, $htmldata);
{
    local $/ = undef;

    my $fh = IO::File->new($xmlfile)
	or die "Can't slurp file '$xmlfile': $!";
    $xmldata = <$fh>;

    $fh = IO::File->new($xmlfile2)
	or die "Can't slurp file '$xmlfile2': $!";
    $xmldata2 = <$fh>;

    $fh = IO::File->new($htmlfile)
	or die "Can't slurp file '$htmlfile': $!";
    $htmldata = <$fh>;
}

test_expect(\*DATA, { EVAL_PERL => 1 },
	   { xmldata    => $xmldata,
	     xmlfile    => $xmlfile,

	     # two file handles as run two tests
	     xmlhandle  => IO::File->new($xmlfile),
	     xmlhandle2 => IO::File->new($xmlfile),

	     xmldata2   => $xmldata2,

	     htmldata    => $htmldata,
	     htmlfile    => $htmlfile,
	     htmlhandle  => IO::File->new($htmlfile),

	   });

__END__
#################################################################################
# postional parameter tests
#################################################################################
-- test --
# try finding it by name
[% USE xml = XML.LibXML(xmlfile); 
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# try finding it by filehandle
[% USE xml = XML.LibXML(xmlhandle);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# xml string with declaration
[% str = BLOCK -%]
<?xml version="1.0"?>
[% xmldata %]
[% END; USE xml = XML.LibXML(str);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# and without that declaration
[% str = BLOCK -%]
[% xmldata %]
[% END; USE xml = XML.LibXML(str);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# okay, try passing in a document with html in it
[% USE xml = XML.LibXML(htmldata);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<html><body><p>hello</p><p>world<br/><br/><img src="foo.gif"/></p></body></html>
-- test --
# finally, a xml document with html in it that's got an xml declaration
[% str = BLOCK -%]
<?xml version="1.0"?>
<html><body>hello</body></html>
[% END; USE xml = XML.LibXML(str);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<html><body>hello</body></html>
-- test --
#################################################################################
# named parameter tests - normal attributes
################################################################################
# testing filehandles
[% USE xml = XML.LibXML(fh => xmlhandle2);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# testing string
[% USE xml = XML.LibXML(string => xmldata);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# testing filename
[% USE xml = XML.LibXML(file => xmlfile);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# testing filehandles for html files
[% USE xml = XML.LibXML(html_fh => htmlhandle);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<html><body><p>hello</p><p>world<br/><br/><img src="foo.gif"/></p></body></html>
-- test --
# testing string for html strings
[% USE xml = XML.LibXML(html_string => htmldata);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<html><body><p>hello</p><p>world<br/><br/><img src="foo.gif"/></p></body></html>
-- test --
# testing filename for html files
[% USE xml = XML.LibXML(html_file => htmlfile);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<html><body><p>hello</p><p>world<br/><br/><img src="foo.gif"/></p></body></html>
#################################################################################
# named parameter tests - XML.XPath emulation
################################################################################
-- test --
# testing "xml" string emulation
[% USE xml = XML.LibXML(xml => xmldata);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# testing "text" string emulation
[% USE xml = XML.LibXML(text => xmldata);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# testing "filename" file emulation
[% USE xml = XML.LibXML(filename => xmlfile);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
-- process --
[% xmldata %]
-- test --
# testing "html" html_string emulation
[% USE xml = XML.LibXML(html => htmldata);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<html><body><p>hello</p><p>world<br/><br/><img src="foo.gif"/></p></body></html>
-- test --
# testing "html_text" string emulation
[% USE xml = XML.LibXML(html_text => htmldata);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<html><body><p>hello</p><p>world<br/><br/><img src="foo.gif"/></p></body></html>
-- test --
# testing "html_filename" file emulation
[% USE xml = XML.LibXML(html_filename => htmlfile);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<html><body><p>hello</p><p>world<br/><br/><img src="foo.gif"/></p></body></html>
-- test --
# testing "html_file" file emulation
[% USE xml = XML.LibXML(html_file => htmlfile);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<html><body><p>hello</p><p>world<br/><br/><img src="foo.gif"/></p></body></html>
######################################################################
# Views and all that
######################################################################
-- test --
# test a view
[% VIEW myview %]

 [% BLOCK website %]<html><body>[% item.content(view) %]</body></html>[% END %]
 [% BLOCK section %]<h1><a name="[% item.getAttribute("name") %]">[% item.getAttribute("title") %]</h1><ul>[% item.content(view) %]</ul>[% END %]
 [% BLOCK page %]<li><a href="[% item.getAttribute("href") %]">[% item.getAttribute("title") %]</a></li>[% END %]
 [% BLOCK text; item ; END %]

[% END ;
   USE xml = XML.LibXML(xml => xmldata);
   xml.present(myview);
%]
-- expect --
<html><body>
  <h1><a name="alpha">The Alpha Zone</h1><ul>
    <li><a href="/foo/bar">The Foo Page</a></li>
    <li><a href="/bar/baz">The Bar Page</a></li>
    <li><a href="/baz/qux">The Baz Page</a></li>
  </ul>
</body></html>
-- test --
# test xpath selection
[% USE xml = XML.LibXML(xml => xmldata);
   xml.findvalue("/website/section/page[1]/@title"); %]
-- expect --
The Foo Page
-- test --
# test rendering of text and unknown elements
[% VIEW myview 
  notfound = "default" %]

 [% BLOCK item %]<thingy>[% item.content(view) %]</thingy>[% END %]

 [% BLOCK text ; item ; END %]
 [% BLOCK default; item.starttag; item.content(view); item.endtag; END %]

[% END;
   USE xml = XML.LibXML(xml => xmldata2); -%]
<document>
[% myview.print(xml.findnodes("//*[local-name()='item'][1]")) %]
</document>
-- expect --
<document>
<thingy>
    <title>I Read the News Today</title>
    <link>http://oh.boy.com/</link>
  </thingy>
</document>
-- test --
# test viewing a NodeList.  This might happen if we're passed one
# from outside the template via a plugin or something
[% VIEW myview 
  notfound = "default" %]

 [% BLOCK item %]<thingy>[% item.content(view) %]</thingy>[% END %]

 [% BLOCK text ; item ; END %]
 [% BLOCK default; item.starttag; item.content(view); item.endtag; END %]

[% END ; PERL %]
my $parser = XML::LibXML->new();
my $xml = $parser->parse_string($stash->get("xmldata2"));
$stash->set("bob", scalar($xml->findnodes("//*[local-name()='item'][1]")))
[% END -%]
<document>
[% myview.print(bob) %]
</document>
-- expect --
<document>
<thingy>
    <title>I Read the News Today</title>
    <link>http://oh.boy.com/</link>
  </thingy>
</document>
-- test --
# test viewing something that has no alpha numeric tag names
[% VIEW myview %]
  [% BLOCK foo_bar %]Wibble[% END %]
[% END;
 USE xml = XML.LibXML("<foo-bar/>");
 myview.print(xml) %]
-- expect --
Wibble
######################################################################
# extra arguments
######################################################################
-- test --
[%
   USE xml = XML.LibXML(xml         => xmldata,
		        keep_blanks => 0);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<website id="webzone1"><section name="alpha" title="The Alpha Zone"><page href="/foo/bar" title="The Foo Page"/><page href="/bar/baz" title="The Bar Page"/><page href="/baz/qux" title="The Baz Page"/></section></website>
-- test --
[%
   USE xml = XML.LibXML(xmldata, keep_blanks => 0);
   string = xml.toString;
   string = string.replace('<\?.*\n','');
   string = string.replace('<!DOC.*\n','');
   string
%]
-- expect --
<website id="webzone1"><section name="alpha" title="The Alpha Zone"><page href="/foo/bar" title="The Foo Page"/><page href="/bar/baz" title="The Bar Page"/><page href="/baz/qux" title="The Baz Page"/></section></website>
-- test --
[% TRY -%]
[%  USE xml = XML.LibXML(xmldata, blame_muttley => 0);
     xml.toString  %]
[%- CATCH -%]
type: [% error.type %]
info: [% error.info %]
[%- END %]
-- expect --
type: XML.LibXML
info: option 'blame_muttley' not supported
