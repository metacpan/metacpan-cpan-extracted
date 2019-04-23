<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="/">
    <table class="tabwidget" id="tabwidget" width="100%" border="0">
      <tr>
      <td width="5%" class="headerItemUnderline"></td>
      <xsl:for-each select="actions/action">
      <xsl:if test="@position = 'top'">
      <xsl:if test="@output = 'requestURI'">
      <td  class="headerItem" id="{id}" width="120"><a title="{title}" class="menupoint" onclick="requestURI('{xml}','{id}','{title}');"><xsl:value-of select="text"/></a></td>
      <td width="1" class="headerItemUnderline"></td>
      </xsl:if>
      <xsl:if test="@output = 'loadPage'">
      <td  class="headerItem" id="{id}" width="120">
      <a class="headerItem" id="{id}" href="javascript:loadPage('{xml}','{xsl}','{out}','{id}','{title}');" title="{title}"><xsl:value-of select="text"/></a></td>
      <td width="1" class="headerItemUnderline"></td>
      </xsl:if>
      <xsl:if test="@output = 'javascript'">
      <td  class="headerItem" id="{id}" width="120">
      <a class="headerItem" id="{id}" href="javascript:{javascript}" title="{title}"><xsl:value-of select="text"/></a></td>
      <td width="1" class="headerItemUnderline"></td>
      </xsl:if>
      </xsl:if>
      </xsl:for-each>
      <td class="headerItem" id="dynamicTab" style="display:none;" title="Menu" width="120"><a class="menupoint"></a></td>
      <td class="headerItem batch menuButton" style="cursor:pointer" width="100"><div id="menuButton">&#xe9bd;Menu</div></td>
      <td width="95%" class="headerItemUnderline"></td>
      </tr>
    </table>
  </xsl:template>
</xsl:stylesheet>
