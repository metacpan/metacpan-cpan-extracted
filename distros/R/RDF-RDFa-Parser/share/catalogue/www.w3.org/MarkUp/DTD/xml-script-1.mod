<!-- ................................................................... -->
<!-- XML Scripting Module .............................................. -->
<!-- file: xml-script-1.mod

     This is XML Scripting - the Scripting Module for XML.

     Copyright 2008 W3C (MIT, ERCIM, Keio), All Rights Reserved.

     This DTD module is identified by the PUBLIC and SYSTEM identifiers:

       PUBLIC "-//W3C//ENTITIES XML Scripting 1.0//EN"
       SYSTEM "http://www.w3.org/MarkUp/DTD/xml-script-1.mod"

     Revisions:
     (none)
     ....................................................................... -->


<!-- XML Scripting defines the following element -->

<!ENTITY % xml-script.script.content "( #PCDATA )" >
<!ELEMENT %xml-script.script.qname; %xml-handlers.script.content; >
<!ENTITY % xml-script.script.attlist  "INCLUDE" >
<![%xml-script.script.attlist;[
<!ATTLIST %xml-script.script.qname;
      %XML-EVENTS.xmlns.attrib;
      xml:id       ID                       #IMPLIED
      encoding     %Charset.datatype;       #IMPLIED
      type         %ContentType.datatype;   #REQUIRED
      src          %URI.datatype;           #IMPLIED
      implements   %URIorSafeCURIEs.datatype;  #IMPLIED
>
<!-- end of xml-script.script.attlist -->]]>

<!-- end of xml-script-1.mod -->
