#============================================================= -*-perl-*-
#
# t/file.t
#
# Test the XML::File plugin.
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

local *FP;
my $dir  = abs_path( -d 't' ? 't/xml' : 'xml' );
my $file = 'example.xml';
my $path = File::Spec->catfile($dir, $file);

open(FP, $path) || die "cannot open $path: $!";

my $vars = { 
    dir       => $dir,
    file      => $file,
    path      => $path,
    debug_on  => sub { $Template::Plugin::XML::File::DEBUG = 1 },
    debug_off => sub { $Template::Plugin::XML::File::DEBUG = 0 },
    handle    => \*FP,   
}; 
test_expect(\*DATA, undef, $vars);

close(FP);

__END__


#------------------------------------------------------------------------
# test the $DEBUG package variable sets debugging on/off by default
# unless overridden by a debug named parameter
#------------------------------------------------------------------------

-- test --
[% CALL debug_on; 
   USE xf = XML.File('foo');
   'debugging is '; xf.debug ? 'on' : 'off'
-%]
-- expect --
debugging is on


-- test --
[% CALL debug_off; 
   USE xf = XML.File('foo');
   'debugging is '; xf.debug ? 'on' : 'off'
-%]
-- expect --
debugging is off


-- test --
[% USE xf = XML.File('foo', debug=1);
   'debugging is '; xf.debug ? 'on' : 'off'
%]
-- expect --
debugging is on


-- test --
[% CALL debug_on;
   USE xf=XML('foo', debug=0);
   'debugging is '; xf.debug ? 'on' : 'off'
%]
-- expect --
debugging is off


#------------------------------------------------------------------------
# test the use of the positional argument to specify file name or handle
#------------------------------------------------------------------------

-- test --
[% USE xf = XML.File(file) -%]
  type: [% xf.type   or 'no type'   %]
  name: [% xf.name   or 'no name'   %]
handle: [% xf.handle or 'no handle' %]
-- expect --
-- process -- 
  type: name
  name: [% file %]
handle: no handle


-- test --
[% USE xf = XML.File(handle) -%]
  type: [% xf.type   or 'no type'   %]
  name: [% xf.name   or 'no name'   %]
handle: [% xf.handle or 'no handle' %]
-- expect --
-- process -- 
  type: handle
  name: no name
handle: [% handle %]


#------------------------------------------------------------------------
# test the use of named parameters for file name
#------------------------------------------------------------------------

-- test --
[% USE xf = XML.File(file=file) -%]
[% xf.type %]: [% xf.name %]
-- expect --
-- process -- 
name: [% file %]

-- test --
[% USE xf = XML.File(name=file) -%]
[% xf.type %]: [% xf.name %]
-- expect --
-- process -- 
name: [% file %]

-- test --
[% USE xf = XML.File(xml_file=file) -%]
[% xf.type %]: [% xf.name %]
-- expect --
-- process -- 
name: [% file %]


#------------------------------------------------------------------------
# test the use of named parameters for file handle
#------------------------------------------------------------------------

-- test --
[% USE xf = XML.File(fh=handle) -%]
[% xf.type %]: [% xf.handle %]
-- expect --
-- process -- 
handle: [% handle %]

-- test --
[% USE xf = XML.File(handle=handle) -%]
[% xf.type %]: [% xf.handle %]
-- expect --
-- process -- 
handle: [% handle %]


-- test --
[% USE xf = XML.File(xml_fh=handle) -%]
[% xf.type %]: [% xf.handle %]
-- expect --
-- process -- 
handle: [% handle %]



#------------------------------------------------------------------------
# test file() method
#------------------------------------------------------------------------

-- test --
[% USE XML;
   file = XML.file(file) 
-%]
file: [% file.name %]
-- expect --
-- process --
file: [% file %]


#------------------------------------------------------------------------
# TODO: dom(), xpath() and other methods.
#------------------------------------------------------------------------

