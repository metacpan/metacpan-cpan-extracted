<!--

   this stylesheet fragment can be used to "embed" html into
   other html pages, i.e. you can open a new <html> element
   anywhere and expect that your title/javascript/head etc..
   element are moved to their correct position.

   additionally, everything inside the <javascript> elements
   will be correctly quoted (i.e. incorrectly quoted so browsers
   can understand it ;)

   this must only be used at the top-level, since this fragment does
   not output valid xml.

-->

<xsl:output method="xhtml" omit-xml-declaration='yes' media-type="text/html" encoding="utf-8"/>

<xsl:template match="/">
   <html>
      <head>
         <title>
            <xsl:variable name="title" select="descendant::title"/>
            <xsl:choose>
               <xsl:when test="$title">
                  <xsl:value-of select="$title"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="concat(descendant::*@package, '/', descendant::*@module)"/>
               </xsl:otherwise>
            </xsl:choose>
         </title>
         <xsl:apply-templates select="descendant::head/node()[name() != 'title']"/>
      </head>
      <body text="black" link="#1010C0" vlink="#101080" alink="red" bgcolor="#e0e0e0">
         <xsl:apply-templates select="descendant::body@*"/>
         <xsl:apply-templates/>
      </body>
   </html>
</xsl:template>

<xsl:template match="head|title">
</xsl:template>

<xsl:template match="html|body">
   <xsl:apply-templates/>
</xsl:template>

<xsl:template xmlns:papp="http://www.plan9.de/xmlns/papp" match="papp:module">
   <xsl:apply-templates/>
</xsl:template>

<xsl:template match="javascript">
   <script type="text/javascript" language="javascript">
      <xsl:comment>
         <xsl:text>&#10;</xsl:text>
         <xsl:value-of disable-output-escaping="yes"/>
         <xsl:text>//</xsl:text>
      </xsl:comment>
   </script>
</xsl:template>

