<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:dc="http://purl.org/dc/elements/1.1/" 
xmlns:atom="http://www.w3.org/2005/Atom" 
version="2.0">
<xsl:template match="/">
<xsl:for-each select="rss/channel/item">
<article>
<header>
<h1><a class="link" href="{link}"> <xsl:value-of select="title"/></a></h1>
<p><xsl:value-of select="pubDate"/></p>
</header>
<p>
<xsl:value-of select="description" disable-output-escaping="yes"/>
</p>
<footer><xsl:value-of select="author"/></footer>
</article>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
