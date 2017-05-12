<!-- ................................................................... -->
<!-- XML Handlers Module ............................................... -->
<!-- file: xml-handlers-1.mod

     This is XML Handlers - the Handlers Module for XML.
     a redefinition of support for handlers of the DOM event model.

     Copyright 2007-2008 W3C (MIT, ERCIM, Keio), All Rights Reserved.

     This DTD module is identified by the PUBLIC and SYSTEM identifiers:

       PUBLIC "-//W3C//ENTITIES XML Handlers 1.0//EN"
       SYSTEM "http://www.w3.org/MarkUp/DTD/xml-handlers-1.mod"

     Revisions:
     (none)
     ....................................................................... -->


<!-- XML Handlers defines the various element and attributes -->

<!ENTITY % xml-handlers.action.content 
    "( %xml-handlers.action.qname; |
       %xml-handlers.dispatchevent.qname; |
       %xml-handlers.addEventListener.qname; |
       %xml-handlers.removeEventListener.qname; |
       %xml-handlers.stopPropagation.qname; |
       %xml-handlers.preventDefault.qname; |
       %xml-handlers.action.extras; )+ "
>

<!ELEMENT %xml-handlers.action.qname; %xml-handlers.action.content;>
<!ATTLIST %xml-handlers.action.qname;
    xml:id           ID                   #IMPLIED
    event            %QName.datatype;     #IMPLIED
    targetid         IDREF                #IMPLIED
    declare          ( declare )          #IMPLIED
    if               CDATA                #IMPLIED
    while            CDATA                #IMPLIED
>

<!ENTITY % xml-handlers.dispatchEvent.content "NONE" >
<!ELEMENT %xml-handlers.dispatchEvent.qname; 
          %xml-handlers.dispatchEvent.content >

<ENTITY % xml-handlers.dispatchEvent.attlist "INCLUDE" >
<![%xml-handlers.dispatchEvent.attlist;[
<!ATTLIST %xml-handlers.dispatchEvent.qname;
      %XML-EVENTS.xmlns.attrib;
      xml:id       ID                       #IMPLIED
      to           IDREF                    #IMPLIED
      raise        %QName.datatype;         #IMPLIED
      bubbles      ( bubbles )              #IMPLIED
      cancelable   ( cancelable )           #IMPLIED
>
<!-- end of xml-handlers.dispatchEvent.attlist -->]]>

<!ENTITY % xml-handlers.addEventListener.content "NONE" >
<!ELEMENT %xml-handlers.addEventListener.qname; 
          %xml-handlers.addEventListener.content >

<ENTITY % xml-handlers.addEventListener.attlist "INCLUDE" >
<![%xml-handlers.addEventListener.attlist;[
<!ATTLIST %xml-handlers.addEventListener.qname;
      %XML-EVENTS.xmlns.attrib;
      xml:id       ID                       #IMPLIED
      event        %QName.datatype;         #REQUIRED
      handler      IDREF                    #REQUIRED
      phase        (capture|default)        #IMPLIED
>
<!-- end of xml-handlers.addEventListener.attlist -->]]>

<!ENTITY % xml-handlers.removeEventListener.content "NONE" >
<!ELEMENT %xml-handlers.removeEventListener.qname; 
          %xml-handlers.removeEventListener.content >

<ENTITY % xml-handlers.removeEventListener.attlist "INCLUDE" >
<![%xml-handlers.removeEventListener.attlist;[
<!ATTLIST %xml-handlers.removeEventListener.qname;
      %XML-EVENTS.xmlns.attrib;
      xml:id       ID                       #IMPLIED
      event        %QName.datatype;         #REQUIRED
      handler      IDREF                    #REQUIRED
      phase        (capture|default)        #IMPLIED
>
<!-- end of xml-handlers.addEventListener.attlist -->]]>

<!ENTITY % xml-handlers.stopPropagation.content "NONE" >
<!ELEMENT %xml-handlers.stopPropagation.qname; 
          %xml-handlers.stopPropagation.content >

<ENTITY % xml-handlers.stopPropagation.attlist "INCLUDE" >
<![%xml-handlers.stopPropagation.attlist;[
<!ATTLIST %xml-handlers.stopPropagation.qname;
      %XML-EVENTS.xmlns.attrib;
      xml:id       ID                       #IMPLIED
      event        %QName.datatype;         #REQUIRED
>
<!-- end of xml-handlers.stopPropagation.attlist -->]]>

<!ENTITY % xml-handlers.preventDefault.content "NONE" >
<!ELEMENT %xml-handlers.preventDefault.qname; 
          %xml-handlers.preventDefault.content >

<ENTITY % xml-handlers.preventDefault.attlist "INCLUDE" >
<![%xml-handlers.preventDefault.attlist;[
<!ATTLIST %xml-handlers.preventDefault.qname;
      %XML-EVENTS.xmlns.attrib;
      xml:id       ID                       #IMPLIED
      event        %QName.datatype;         #REQUIRED
>
<!-- end of xml-handlers.preventDefault.attlist -->]]>

<!-- end of xml-handlers-1.mod -->
