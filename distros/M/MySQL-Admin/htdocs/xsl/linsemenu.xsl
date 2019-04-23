<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:template match="/">
<div id="menuContent" style="display:none" class="menupoint">
<table>
<xsl:for-each select="actions/action">
<xsl:if test="@output = 'loadPage'">
<tr><td><a class="menupoint" id="m{id}" href="javascript:loadPage('{xml}','{xsl}','{out}','{id}','{title}');" title="{title}"><xsl:value-of select="text"/></a>
</td></tr></xsl:if>
<xsl:if test="@output = 'requestURI'">
<tr><td><a class="menupoint" id="m{id}" href="javascript:requestURI('{xml}','{id}','{title}');" title="{title}"><xsl:value-of select="text"/></a>
</td></tr></xsl:if>
<xsl:if test="@output = 'javascript'">
<tr><td><a class="menupoint" id="m{id}" href="javascript:{javascript}" title="{title}"><xsl:value-of select="text"/></a>
</td></tr></xsl:if>
</xsl:for-each>
</table>
</div>
</xsl:template>
</xsl:stylesheet>

