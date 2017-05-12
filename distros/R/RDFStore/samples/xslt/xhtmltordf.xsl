<stylesheet 
    xmlns="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
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
   <attribute name="dc:title">
    Semantic Extraction of metadata
   </attribute>
 <apply-templates/>
  </rdf:Description>
 </rdf:RDF>
</template>

<!-- Extract normal meta-data stuff -->

<template match="h:html/h:head">

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
 <for-each select=".//h:address">
  <dc:author>
   <value-of select="(.)" /> 
  </dc:author>
 </for-each>
 <for-each select=".//h:meta[@name='DC.author']">
  <dc:author>
   <value-of select="(@content)" /> 
  </dc:author>
 </for-each>

 <for-each select=".//h:meta[@name='description']">
  <dc:description>
   <value-of select="(@content)" /> 
  </dc:description>
 </for-each>
 <for-each select=".//h:meta[@name='DC.description']">
  <dc:description>
   <value-of select="(@content)" /> 
  </dc:description>
 </for-each>

 <for-each select=".//h:link[@rel]">
  <rdfs:seeAlso rdfs:label="{@rel}" rdf:resource="{@href}" /> 
 </for-each>
 <for-each select=".//h:link[@rev]">
  <dc:description rdfs:label="{@rev}" rdf:resource="{@href}" /> 
 </for-each>
</template>

<!-- Extract body stuff -->
<template match="h:html/h:body">

<!-- Headings -->
 <choose>
  <when test=".//h:h1/h:img">
   <for-each select=".//h:h1/h:img">
    <dc:description dc:title="HTML Heading" 
     rdf:resource="http://www.w3.org/1999/xhtml#h1" 
     rdf:value="{@alt}" foaf:img="{@src}" /> 
   </for-each>
  </when>
  <otherwise>
   <for-each select=".//h:h1">
    <dc:description dc:title="HTML Heading" 
     rdf:resource="http://www.w3.org/1999/xhtml#h1" rdf:value="{.}" /> 
   </for-each>
  </otherwise>
 </choose>
 <for-each select=".//h:h2">
  <dc:description dc:title="HTML Heading" 
   rdf:resource="http://www.w3.org/1999/xhtml#h2" rdf:value="{.}" />
 </for-each>
 <for-each select=".//h:h3">
  <dc:description dc:title="HTML Heading" 
   rdf:resource="http://www.w3.org/1999/xhtml#h3" rdf:value="{.}" />
 </for-each>
 <for-each select=".//h:h4">
  <dc:description dc:title="HTML Heading" 
   rdf:resource="http://www.w3.org/1999/xhtml#h4" rdf:value="{.}" />
 </for-each>
 <for-each select=".//h:h5">
  <dc:description dc:title="HTML Heading" 
   rdf:resource="http://www.w3.org/1999/xhtml#h5" rdf:value="{.}" />
 </for-each>
 <for-each select=".//h:h6">
  <dc:description dc:title="HTML Heading" 
   rdf:resource="http://www.w3.org/1999/xhtml#h6" rdf:value="{.}" />
 </for-each>

<!-- Table summaries -->
 <for-each select=".//h:table[@summary]">
  <dc:description dc:title="Table Summary" rdf:value="{@summary}" /> 
 </for-each>

<!-- Links (anchors) -->
 <for-each select=".//h:a[@href]">
  <rss:link rdfs:label="{.}" rdf:resource="{@href}" dc:title="{@title}" /> 
 </for-each>
 <for-each select=".//h:a[@name]">
  <rss:link rdfs:label="{.}" rdf:resource="{@name}" /> 
 </for-each>

<!-- Images -->
 <for-each select=".//h:img">
  <foaf:img rdfs:label="{@alt}" rdf:resource="{@src}" /> 
 </for-each>

</template>

<!-- Dan Connolly trick: don't pass text through -->
<template match="text()|@*">
</template>
</stylesheet>
