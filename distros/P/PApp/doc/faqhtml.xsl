<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xhtml" omit-xml-declaration='yes' media-type="text/html" encoding="utf-8"/>

<xsl:template match="faq">
   <html><head>
      <title><xsl:apply-templates select="@title"/></title>
   </head><body bgcolor="#ffffff" text="#000000" link="#0000cc" vlink="#551a8b" alink="#ff0000">
      <h1><xsl:apply-templates select="@title"/></h1>
      <xsl:apply-templates select="abstract"/>
      <hr/>
      <ul>
      <xsl:for-each select="section">
         <li><h2><a href="#{generate-id(.)}"><xsl:value-of select="@title"/></a></h2>
            <ul>
               <xsl:for-each select="qa">
                  <li><a href="#{generate-id(.)}">
                     <xsl:choose>
                        <xsl:when test="@q">
                           <xsl:value-of select="@q"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:apply-templates select="q"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </a></li>
               </xsl:for-each>
            </ul>
         </li>
      </xsl:for-each>
      </ul>
      <xsl:apply-templates select="section"/>
   </body></html>
</xsl:template>

<xsl:template match="abstract">
   <blockquote><xsl:apply-templates/></blockquote>
</xsl:template>

<xsl:template match="section">
   <hr/>
   <a name="{generate-id(.)}">
      <h2><xsl:value-of select="@title"/></h2>
      <blockquote> <!-- microsoft-trick :( -->
         <xsl:apply-templates/>
      </blockquote>
   </a>
</xsl:template>

<xsl:template match="qa">
   <a name="{generate-id(.)}"/>
   <xsl:if test="@id">
      <a name="{@id}"/>
   </xsl:if>
   <h3><xsl:value-of select="@q"/></h3>
   <p><xsl:apply-templates/></p>
</xsl:template>

<xsl:template match="xlink">
   <a href="{string(.)}"><xsl:value-of select="string(.)"/></a>
</xsl:template>

<xsl:template match="mailto">
   <a href="mailto:{string(.)}"><xsl:value-of select="string(.)"/></a>
</xsl:template>

<xsl:template match="text">
</xsl:template>

<xsl:template match="html">
   <xsl:apply-templates select="node()" mode="copy"/>
</xsl:template>

<xsl:template match="c">
   <tt>
      <xsl:apply-templates select="node()"/>
   </tt>
</xsl:template>

<xsl:template match="code">
   <pre>
      <xsl:apply-templates select="node()"/>
   </pre>
</xsl:template>

<xsl:template match="p|em|tt|strong">
   <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
   </xsl:copy>
</xsl:template>

<xsl:template match="@*|node()" mode="copy">
   <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="copy"/>
   </xsl:copy>
</xsl:template>

</xsl:stylesheet>

