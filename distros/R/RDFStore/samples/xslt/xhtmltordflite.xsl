<stylesheet 
    xmlns="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:dc="http://purl.org/DC"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:rss="http://purl.org/rss/1.0/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">

<!-- A neat little XSLT file for scraping RDF Semantics from XHTML files -->

<param name="xmlfile" />

<output method="xml" indent="yes"/>

<template match="h:html">
 <rdf:RDF>
  <rdf:Description>
   <attribute name="rdf:about">
    <value-of select="$xmlfile"/>
   </attribute>
 <apply-templates/>
  </rdf:Description>
 </rdf:RDF>
</template>

<!-- Extract normal meta-data stuff -->

<template match="h:html/h:head">
 <element name="rdf:bag">

  <attribute name="dc:title">Description of h:head contents</attribute>

 <for-each select="/h:html/h:head/h:title">
  <dc:title>
   <value-of select="(.)" /> 
  </dc:title>
 </for-each>

 <for-each select=".//h:meta[@name='author']">
  <dc:author>
   <value-of select="(@content)" /> 
  </dc:author>
 </for-each>
 <for-each select=".//h:link[@rev='made']">
  <dc:author>
   <value-of select="(@href)" /> 
  </dc:author>
 </for-each>

 <for-each select=".//h:meta[@name='description']">
  <dc:description>
   <value-of select="(@content)" /> 
  </dc:description>
 </for-each>

 <for-each select=".//h:link[@rel]">
  <rdfs:seeAlso rdfs:label="{@rel}" rdf:resource="{@href}" /> 
 </for-each>
 <for-each select=".//h:link[@rev]">
  <rdfs:seeAlso rdfs:label="{@rev}" rdf:resource="{@href}" /> 
 </for-each>
</element>
</template>

<!-- Extract body stuff -->
<template match="h:html/h:body">
 <element name="rdf:bag">
  <attribute name="dc:title">Description of h:body contents</attribute>
 <for-each select=".//h:a[@href]">
  <rss:resource rdfs:label="{.}" rdf:resource="{@href}" /> 
 </for-each>

 <for-each select=".//h:img">
  <foaf:img rdfs:label="{@alt}" rdf:resource="{@src}" /> 
 </for-each>
</element>
</template>

<!-- Dan Connolly trick: don't pass text through -->
<template match="text()|@*">
</template>
</stylesheet>
