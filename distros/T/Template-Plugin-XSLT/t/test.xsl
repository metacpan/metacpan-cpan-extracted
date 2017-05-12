<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [
  <!ENTITY foo "fooooo!">
]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html"/>
  <xsl:param name="magicvariable">test</xsl:param>

  <xsl:template match="/">
    <html><body>&foo;<xsl:copy/><xsl:apply-templates/>
    <xsl:if test="($magicvariable = 'abracadabra')">
        <p> You knew the magic word! </p>
    </xsl:if>
    </body></html>
  </xsl:template>

</xsl:stylesheet>
