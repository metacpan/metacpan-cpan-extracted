<!-- ....................................................................... -->
<!-- XML Events Qname Module  ............................................ -->
<!-- file: xml-events-qname-2.mod

     This is XML Events - the Events Module for XML,
     a definition of access to the DOM events model.

     Copyright 2000-2007 W3C (MIT, ERCIM, Keio), All Rights Reserved.

     This DTD module is identified by the PUBLIC and SYSTEM identifiers:

       PUBLIC "-//W3C//ENTITIES XML Events Qnames 2.0//EN"
       SYSTEM "http://www.w3.org/MarkUp/DTD/xml-events-qname-2.mod"

     Revisions:
     (none)
     ....................................................................... -->

<!-- XML Events Qname (Qualified Name) Module

     This module is contained in two parts, labeled Section 'A' and 'B':

       Section A declares parameter entities to support namespace-
       qualified names, namespace declarations, and name prefixing
       for XML Events and extensions.

       Section B declares parameter entities used to provide
       namespace-qualified names for all XML Events element types:

         %listener.qname;   the xmlns-qualified name for <listener>
         ...

     XML Events extensions would create a module similar to this one.
     Included in the XML distribution is a template module
     ('template-qname-2.mod') suitable for this purpose.
-->

<!-- Section A: XML Events XML Namespace Framework :::::::::::::::::::: -->

<!-- 1. Declare a %XML-EVENTS.prefixed; conditional section keyword, used
        to activate namespace prefixing. The default value should
        inherit '%NS.prefixed;' from the DTD driver, so that unless
        overridden, the default behavior follows the overall DTD
        prefixing scheme.
-->
<!ENTITY % NS.prefixed "IGNORE" >
<!ENTITY % XML-EVENTS.prefixed "%NS.prefixed;" >

<!-- 2. Declare a parameter entity (eg., %XML-EVENTS.xmlns;) containing
        the URI reference used to identify the XML Events namespace
-->
<!ENTITY % XML-EVENTS.xmlns  "http://www.w3.org/2001/xml-events" >

<!-- 3. Declare parameter entities (eg., %XML.prefix;) containing
        the default namespace prefix string(s) to use when prefixing
        is enabled. This may be overridden in the DTD driver or the
        internal subset of an document instance. If no default prefix
        is desired, this may be declared as an empty string.

     NOTE: As specified in [XMLNAMES], the namespace prefix serves
     as a proxy for the URI reference, and is not in itself significant.
-->
<!ENTITY % XML-EVENTS.prefix  "" >

<!-- 4. Declare parameter entities (eg., %XML-EVENTS.pfx;) containing the
        colonized prefix(es) (eg., '%XML-EVENTS.prefix;:') used when
        prefixing is active, an empty string when it is not.
-->
<![%XML-EVENTS.prefixed;[
<!ENTITY % XML-EVENTS.pfx  "%XML-EVENTS.prefix;:" >
]]>
<!ENTITY % XML-EVENTS.pfx  "" >

<!-- declare qualified name extensions here ............ -->
<!ENTITY % xml-events-qname-extra.mod "" >
%xml-events-qname-extra.mod;

<!-- 5. The parameter entity %XML-EVENTS.xmlns.extra.attrib; may be
        redeclared to contain any non-XML Events namespace declaration
        attributes for namespaces embedded in XML. The default
        is an empty string.  XLink should be included here if used
        in the DTD.
-->
<!ENTITY % XML-EVENTS.xmlns.extra.attrib "" >


<!-- Section B: XML Qualified Names ::::::::::::::::::::::::::::: -->

<!-- 6. This section declares parameter entities used to provide
        namespace-qualified names for all XML Events element types.
-->

<!ENTITY % xml-events.listener.qname  "%XML-EVENTS.pfx;listener" >


<!ENTITY % xml-handlers.action.qname  "%XML-EVENTS.pfx;action" >
<!ENTITY % xml-script.script.qname  "%XML-EVENTS.pfx;script" >
<!ENTITY % xml-handlers.dispatchEvent.qname  "%XML-EVENTS.pfx;dispatchEvent" >
<!ENTITY % xml-handlers.addEventListener.qname  "%XML-EVENTS.pfx;addEventListener" >
<!ENTITY % xml-handlers.removeEventListener.qname  "%XML-EVENTS.pfx;removeEventListener" >
<!ENTITY % xml-handlers.stopPropagation.qname  "%XML-EVENTS.pfx;stopPropagation" >
<!ENTITY % xml-handlers.preventDefault.qname  "%XML-EVENTS.pfx;preventDefault" >


<!-- The following defines a PE for use in the attribute sets of elements in
     other namespaces that want to incorporate the XML Event attributes. Note
     that in this case the XML-EVENTS.pfx should always be defined. -->

<!ENTITY % xml-events.attrs.qname
   "%XML-EVENTS.pfx;event            NMTOKEN      #IMPLIED
    %XML-EVENTS.pfx;observer         IDREF        #IMPLIED
    %XML-EVENTS.pfx;target           IDREF        #IMPLIED
    %XML-EVENTS.pfx;handler          %URI.datatype;        #IMPLIED
    %XML-EVENTS.pfx;phase            (capture|default) #IMPLIED
    %XML-EVENTS.pfx;propagate        (stop|continue) #IMPLIED
    %XML-EVENTS.pfx;defaultAction    (cancel|perform) #IMPLIED
    %XML-EVENTS.pfx;condition        CDATA        #IMPLIED"
    >

<!-- end of xml-events-qname-2.mod -->
