<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:template match="/">
<div id="menuContent" style="display:none">
  <xsl:for-each select="actions/action">
    <xsl:if test="@output = 'loadPage'">
    <a class="menupoint"  href="javascript:loadPage('{xml}','{xsl}','{out}','{id}','{title}');" title="{title}"><xsl:value-of select="text"/></a><br/>
    </xsl:if>
    <xsl:if test="@output = 'requestURI'">
    <a class="menupoint"  href="javascript:requestURI('{xml}','{id}','{title}');" title="{title}"><xsl:value-of select="text"/></a><br/>
    </xsl:if>
    <xsl:if test="@output = 'javascript'">
    <a class="menupoint"  href="javascript:{javascript}" title="{title}"><xsl:value-of select="text"/></a><br/>
    </xsl:if>
  </xsl:for-each>
</div>
</xsl:template>
</xsl:stylesheet>