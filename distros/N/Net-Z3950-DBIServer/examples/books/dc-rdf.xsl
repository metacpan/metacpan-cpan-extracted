<?xml version="1.0"?>
<!-- $Id: dc-rdf.xsl,v 1.2 2005-04-22 11:41:29 mike Exp $ -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"
	doctype-public="-//DUBLIN CORE//DCMES DTD 2002/07/31//EN"
	doctype-system="http://dublincore.org/documents/2002/07/31/dcmes-xml/dcmes-xml-dtd.dtd"/>
  <xsl:template match="/book">
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	     xmlns:dc="http://purl.org/dc/elements/1.1/">
      <rdf:Description>
	<dc:title><xsl:value-of select="bookName"/></dc:title>
	<dc:creator><xsl:value-of select="authorName"/></dc:creator>
      </rdf:Description>
    </rdf:RDF>
  </xsl:template>
</xsl:stylesheet>
