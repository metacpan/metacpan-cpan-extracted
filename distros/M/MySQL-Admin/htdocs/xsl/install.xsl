<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:template match="/">
<table class="tabwidget" id="tabwidget" style="padding-top:5px;width:100%;" width="100%" border="0">
<tr>
<td width="5" class="headerItemUnderline"></td>
<xsl:for-each select="actions/action">
<xsl:if test="@position = 'top'">
<xsl:if test="@output = 'requestURI'">
<td width="100" class="headerItem" id="{id}">
<a title="{title}" class="menupoint" onclick="requestURI('{xml}','{id}','{title}');">
<xsl:value-of select="text"/>
</a>
</td>
<td width="1" class="headerItemUnderline"></td>
</xsl:if>
</xsl:if>
<xsl:if test="@position = 'top'">
<xsl:if test="@output = 'link'">
<td width="100" class="headerItem" id="{id}">
<a title="{title}" class="menupoint" href="{href}">
<xsl:value-of select="text"/>
</a>
</td>
<td width="1" class="headerItemUnderline"></td>
</xsl:if>
</xsl:if>
</xsl:for-each>
<td width="100" class="headerItem" id="dynamicTab" style="display:none;"></td>
<td width="*" class="headerItemUnderline"></td>
</tr>
</table>
</xsl:template>
</xsl:stylesheet>
