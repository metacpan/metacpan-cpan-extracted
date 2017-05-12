<?xml version="1.0" encoding="UTF-8"?>
<!-- ....................................................................... -->
<!-- XFrames Qname Module  ................................................. -->
<!-- URI: http://www.w3.org/MarkUp/DTD/xframes-qname-1.mod

     This is XFrames - an XML application for composing documents together.

     Copyright ©2002-2005 W3C (MIT, ERCIM, Keio), All Rights Reserved.

     Revision: $Id: xframes-qname-1.mod,v 1.5 2005/09/21 18:03:25 mimasa Exp $

     This DTD module is identified by the PUBLIC and SYSTEM identifiers:

       PUBLIC "-//W3C//ENTITIES XFrames Qualified Names 1.0//EN"
       SYSTEM "http://www.w3.org/MarkUp/DTD/xframes-qname-1.mod"

     Revisions:
     (none)
     ....................................................................... -->

<!-- XFrames Qname (Qualified Name) Module

     This module is contained in two parts, labeled Section 'A' and 'B':

       Section A declares parameter entities to support namespace-
       qualified names, namespace declarations, and name prefixing
       for XFrames and extensions.

       Section B declares parameter entities used to provide
       namespace-qualified names for all XFrames element types:

         %XFRAMES.frames.qname;   the xmlns-qualified name for <frames>
         ...

     XFrames extensions would create a module similar to this one.
     Included in the XML distribution is a template module
     ('template-qname-1.mod') suitable for this purpose.
-->

<!-- Section A: XFrames XML Namespace Framework :::::::::::::::::::: -->

<!-- 1. Declare a %XFRAMES.prefixed; conditional section keyword, used
        to activate namespace prefixing. The default value should
        inherit '%XFRAMES.NS.prefixed;' from the DTD driver, so that unless
        overridden, the default behaviour follows the overall DTD
        prefixing scheme.
-->
<!ENTITY % XFRAMES.NS.prefixed "IGNORE" >
<!ENTITY % XFRAMES.prefixed "%XFRAMES.NS.prefixed;" >

<!-- 2. Declare a parameter entity (eg., %XFRAMES.xmlns;) containing
        the URI reference used to identify the XFrames namespace
-->
<!ENTITY % XFRAMES.xmlns  "http://www.w3.org/2002/06/xframes/" >

<!-- 3. Declare parameter entities (eg., %MODULE.prefix;) containing
        the default namespace prefix string(s) to use when prefixing
        is enabled. This may be overridden in the DTD driver or the
        internal subset of an document instance. If no default prefix
        is desired, this may be declared as an empty string.

     NOTE: As specified in [XMLNAMES], the namespace prefix serves
     as a proxy for the URI reference, and is not in itself significant.
-->
<!ENTITY % XFRAMES.prefix  "x" >

<!-- 4. Declare parameter entities (eg., %XFRAMES.pfx;) containing the
        colonized prefix(es) (eg., '%XFRAMES.prefix;:') used when
        prefixing is active, an empty string when it is not.
-->
<![%XFRAMES.prefixed;[
<!ENTITY % XFRAMES.pfx  "%XFRAMES.prefix;:" >
]]>
<!ENTITY % XFRAMES.pfx  "" >

<!-- declare qualified name extensions here ............ -->
<!ENTITY % xframes-qname-extra.mod "" >
%xframes-qname-extra.mod;

<!-- 5. The parameter entity %XFRAMES.xmlns.extra.attrib; may be
        redeclared to contain any non-XFrames namespace declaration
        attributes for namespaces embedded in XML. The default
        is an empty string.  XLink should be included here if used
        in the DTD.
-->
<!ENTITY % XFRAMES.xmlns.extra.attrib "" >

<![%XFRAMES.prefixed;[
<!ENTITY % XFRAMES.NS.decl.attrib
     "xmlns:%XFRAMES.prefix;  %URI.datatype;  #FIXED '%XFRAMES.xmlns;'
      %XFRAMES.xmlns.extra.attrib;"
>
]]>
<!ENTITY % XFRAMES.NS.decl.attrib
     "%XFRAMES.xmlns.extra.attrib;"
>

<!-- Declare a parameter entity %XFRAMES.NS.decl.attrib; containing all
     XML namespace declaration attributes used by XFrames, including
     a default xmlns declaration when prefixing is inactive.
-->
<![%XFRAMES.prefixed;[
<!ENTITY % XFRAMES.xmlns.attrib
     "%XFRAMES.NS.decl.attrib;"
>
]]>
<!ENTITY % XFRAMES.xmlns.attrib
     "xmlns                   %URI.datatype;  #FIXED '%XFRAMES.xmlns;'
      %XFRAMES.xmlns.extra.attrib;"
>

<!-- Section B: XML Qualified Names ::::::::::::::::::::::::::::: -->

<!-- 6. This section declares parameter entities used to provide
        namespace-qualified names for all XFrames element types.
-->

<!ENTITY % XFRAMES.frames.qname "%XFRAMES.pfx;frames" >
<!ENTITY % XFRAMES.head.qname   "%XFRAMES.pfx;head" >
<!ENTITY % XFRAMES.title.qname  "%XFRAMES.pfx;title" >
<!ENTITY % XFRAMES.style.qname  "%XFRAMES.pfx;style" >
<!ENTITY % XFRAMES.group.qname  "%XFRAMES.pfx;group" >
<!ENTITY % XFRAMES.frame.qname  "%XFRAMES.pfx;frame" >

<!-- end of xfames-qname-1.mod -->
