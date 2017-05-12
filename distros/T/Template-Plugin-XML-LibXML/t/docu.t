#!/usr/bin/perl

# The documentation contains several examples of how to do things.
# Wouldn't I just look like the biggest idiot if these didn't
# actually work?  Well yes, so let's check that functions...

use strict;
use lib qw( ./lib ../lib );
use Template;
use Template::Test;
use Cwd qw( abs_path );
$^W = 1;

# I hate having to do this
#my $shut_up_warnings = $XML::XPath::VERSION;

use XML::LibXML;

# account for script being run in distribution root or 't' directory
# (note, does this work on Win32?  Shouldn't we be using catfile?
# the XML::XPath plugin does it like this...)
my $xmlfile = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$xmlfile .= '/testfile.xml';
my $document = abs_path( -d 't' ? 't/test/xml' : 'test/xml' );
$document .= '/document.xml';
my $xhtml = abs_path( -d 't' ? 't/test/html' : 'test/html' );
$xhtml .= '/xhtml.html';

test_expect(\*DATA, { EVAL_PERL => 1 },
	   { xmlfile    => $xmlfile,
	     document   => $document,
	     xhtml      => $xhtml});

__END__
#################################################################################
# Obtaining Parts with XPath
#################################################################################
-- test --
[% USE docroot = XML.LibXML(xmlfile);
   docroot.findvalue("/website/section/page[1]/@title"); %]
-- expect --
The Foo Page
-- test --
[% USE docroot = XML.LibXML(xmlfile);
   pages = docroot.findnodes("/website/section/page");
   pages.size() %]
-- expect --
3
-- test --
[% USE htmlroot = XML.LibXML(xhtml);
   htmlroot.findvalue("/html/body/h1/text()") %]
-- expect --
Buffy The Vampire Slayer
-- test --
[% USE docroot = XML.LibXML(xmlfile);
   pages = docroot.findnodes("/website/section/page[1]");
   pages.findvalue("@title") %]
-- expect --
The Foo Page
#################################################################################
# Obtaining Parts with Method Calls
#################################################################################
-- test --
[% USE htmlroot = XML.LibXML(xhtml);
   htmlroot.documentElement
           .getElementsByLocalName("body").first
           .getElementsByLocalName("h1").first
           .textContent %]
-- expect --
Buffy The Vampire Slayer
-- test --
[% USE docroot = XML.LibXML(xmlfile);
   docroot.documentElement
          .getElementsByLocalName("section").first
          .getElementsByLocalName("page").first
          .getAttribute("title") %]
-- expect --
The Foo Page
#################################################################################
# Rendering
#################################################################################
-- test --
[% USE docroot = XML.LibXML(xmlfile) -%]
The title of the first page is '[% docroot.findvalue("/website/section/page[1]/@title") %]'
-- expect --
The title of the first page is 'The Foo Page'
-- test --
[% USE docroot = XML.LibXML(xmlfile) -%]
The title of the first page is '[% docroot.documentElement
            .getElementsByLocalName("section").first
            .getElementsByLocalName("page").first
            .getAttribute("title") %]'
-- expect --
The title of the first page is 'The Foo Page'
-- test --
[% USE htmlroot = XML.LibXML(xhtml) -%]
<p>[% htmlroot.findvalue("normalize-space(
                              /html/body/p[1]/text()
                           )") %]</p>
-- expect --
<p>Buffy Summers knows this tale by heart, and no matter how hard she tries to be just a "normal girl", she can not escape from her destiny.</p>
-- test --
[% # note this is slightly different from the documentation.  This is to cope with
   # the fact that the html filter has changed on different versionso of TT
   # and no longer quotes '"'
   USE htmlroot = XML.LibXML(xhtml);
   string = htmlroot.findnodes("/html/body/p[2]").toString;
   string.replace('"', '&quot;');
%]
-- expect --
<p>
   Thankfully, she is not alone in her quest to save the world, as she
   has the help of her friends, the hilarious (and surprisingly quite
   effective) evil-fighting team called &quot;<i>The Scooby
   Gang</i>&quot;. Together, Buffy &amp; co. will slay their demons,
   survive one apocalypse after another, attend high school and
   college... and above all, understand that growing up can truly be
   Hell sometimes... literally.
  </p>
#################################################################################
# The Big Huge View Example
#################################################################################
-- test --
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

    [% BLOCK text; item | html; END %]

  [% END %]

  # use it to render the paragraphs
  [% USE doc = XML.LibXML(document) %]
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
-- expect --
  # create the view
  

  # use it to render the paragraphs
  
  <html>
   <head>
    <title>Template</title>
   </head>
   <body>
    
    <!-- next section -->
    
    <h2>DESCRIPTION</h2>
    <p>
    This documentation describes the Template module which is the
    direct Perl interface into the <em>Template Toolkit</em>.  It
    covers the use of the module &amp; gives a brief summary of
    configuration options and template directives.  Please see
    
    <b>Template::Manual</b>
     for the complete reference manual
    which goes into much greater depth about the features and use of
    the Template Toolkit.  The 
    <b>Template::Tutorial</b>
     is also
    available as an introductory guide to using the Template Toolkit.
  </p>
    
    <!-- next section -->
    
    <h2>AUTHOR</h2>
    <p>
   Andy Wardly 
    <a href="mailto:abw@andwardly.com">abw@andwardly.com</a>
    
   
    <a href="http://www.andywardley.com/">http://www.andywardley.com/</a>
    
  </p>
    
   </body>
  </html>
