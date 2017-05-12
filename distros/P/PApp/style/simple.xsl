<xsl:stylesheet version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:papp="http://www.plan9.de/xmlns/papp"
>

<xsl:output method="xhtml" omit-xml-declaration='yes' media-type="text/html" encoding="utf-8"/>

<xsl:template match="papp:module">
   <html>
      <head>
         <title><xsl:value-of select="@module"/></title>
      </head>
      <body text="black" link="#1010C0" vlink="#101080" alink="red" bgcolor="#e0e0e0">
         <xsl:apply-templates/>
         <hr/>
      </body>
   </html>
</xsl:template>

</xsl:stylesheet>
