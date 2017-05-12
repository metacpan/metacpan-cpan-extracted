<?xml version="1.0" encoding="iso-8859-1"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!-- Import the identity transformation. -->
<xsl:import href="identity.xsl"/>
<xsl:output method="xml" omit-xml-declaration="no" />

<xsl:template match="host">
  <xsl:if test="./status[@state='up']">
      <xsl:copy-of select="."/>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
