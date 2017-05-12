<?xml version="1.0" encoding="ISO-8859-1"?>

<!-- $Id: names.xsl 1847 2011-06-06 12:38:58Z erick.antezana $

# Module  : names.xsl
# Purpose : Get the term names from APO (in XML) into HTML
# Usage: xsltproc names.xsl apo.xml > apo-names.html
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
           This program is free software; you can redistribute it and/or
           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>

-->

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
  <html>
  <body>
    <h2>Application Ontology term names list</h2>
    
    <xsl:for-each select="apo/term">
      <xsl:sort select="name"/>
      "<xsl:value-of select="name"/>", <br/>
	</xsl:for-each>
    
  </body>
  </html>
</xsl:template>

</xsl:stylesheet>