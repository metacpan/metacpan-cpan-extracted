<!-- remove superfluous text, this is dangerous for <pre>-elements -->

<xsl:template match="text()">
   <xsl:if test="not (normalize-space() = '')">
      <xsl:value-of select="."/>
   </xsl:if>
</xsl:template>

