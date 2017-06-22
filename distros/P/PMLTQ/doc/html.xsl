<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
		xmlns:str="http://exslt.org/strings"
                version='1.0'>
  <!-- Import docbook stylesheet. Or import slides/fo/plain.xsl, or ... -->
  <xsl:import href="http://docbook.sourceforge.net/release/xsl/current/html/docbook.xsl"/>

  <xsl:template match="text()[ancestor::phrase[@role='math']]">
    <xsl:for-each select="str:tokenize(string(.), '')">
      <xsl:choose>
	<xsl:when test="starts-with(translate(.,'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
			                        'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),'x')">
	  <i>
	    <xsl:value-of select="."/>
	  </i>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="."/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>