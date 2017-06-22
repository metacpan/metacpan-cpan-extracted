<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
		xmlns:str="http://exslt.org/strings"
                version='1.0'>
  <!-- Import docbook stylesheet. Or import slides/fo/plain.xsl, or ... -->
  <xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl"/>

  <xsl:param name="xep.extensions" select="1"></xsl:param>
  <!-- Essential templates to prevent PassiveTeX from choking: -->
  <xsl:param name="section.autolabel" select="1"/>
  <xsl:param name="section.label.includes.component.label" select="1"/>
  <xsl:param name="body.start.indent" select="'0pt'"/>
  <xsl:param name="variablelist.as.blocks" select="1"/>
  <!-- Header causes problems, just get rid of it: -->
<!--  <xsl:template name="header.content"/> -->

  <!-- Precompute attribute values; PassiveTex is too stupid: -->
  <xsl:attribute-set name="component.title.properties">
    <xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>
    <xsl:attribute name="space-before.optimum">
      <xsl:value-of select="concat($body.font.master, 'pt')"/>
    </xsl:attribute>
    <xsl:attribute name="space-before.minimum">
      <xsl:value-of select="$body.font.master * 0.8"/>
      <xsl:text>pt</xsl:text>
    </xsl:attribute>
    <xsl:attribute name="space-before.maximum">
      <xsl:value-of select="$body.font.master * 1.2"/>
      <xsl:text>pt</xsl:text>
    </xsl:attribute>
    <xsl:attribute name="hyphenate">false</xsl:attribute>
  </xsl:attribute-set>


  <!-- Don't put in extra fo:block; PassiveTeX gets confused by nested
       fo:blocks: -->
  <xsl:template match="listitem/*[1][local-name()='para' or
                local-name()='simpara']
                |glossdef/*[1][local-name()='para' or
                local-name()='simpara' or
                local-name()='formalpara']
                |step/*[1][local-name()='para' or
                local-name()='simpara' or
                local-name()='formalpara']
                |callout/*[1][local-name()='para' or
                local-name()='simpara' or
                local-name()='formalpara']"
                priority="2">
    <xsl:call-template name="anchor"/>
    <xsl:apply-templates/>
  </xsl:template>


  <!-- Here are some adjustments that I find useful; your mileage may vary: -->


  <!-- Adjust to work around PassiveTeX spacing bug: -->
  <xsl:attribute-set name="list.block.spacing">
    <xsl:attribute name="space-before.optimum">0em</xsl:attribute>
    <xsl:attribute name="space-before.minimum">0em</xsl:attribute>
    <xsl:attribute name="space-before.maximum">0em</xsl:attribute>
    <xsl:attribute name="space-after.optimum">1em</xsl:attribute>
    <xsl:attribute name="space-after.minimum">0.8em</xsl:attribute>
    <xsl:attribute name="space-after.maximum">1.2em</xsl:attribute>
  </xsl:attribute-set>


  <!-- Remove spurious space preceding equations -->
  <!-- informalequation.properties maps directly to
       informalobject.properties -->
  <xsl:attribute-set name="informal.object.properties">
    <xsl:attribute name="space-before.minimum">0em</xsl:attribute>
    <xsl:attribute name="space-before.optimum">0em</xsl:attribute>
    <xsl:attribute name="space-before.maximum">0em</xsl:attribute>
    <xsl:attribute name="space-after.minimum">0em</xsl:attribute>
    <xsl:attribute name="space-after.optimum">0em</xsl:attribute>
    <xsl:attribute name="space-after.maximum">0em</xsl:attribute>
  </xsl:attribute-set>

  <xsl:template match="text()[ancestor::phrase[@role='math']]">
    <xsl:for-each select="str:tokenize(string(.), '')">
      <xsl:choose>
	<xsl:when test="starts-with(translate(.,'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
			                        'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),'x')">
	  <fo:inline font-style="italic">
	    <xsl:value-of select="."/>
	  </fo:inline>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="."/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>