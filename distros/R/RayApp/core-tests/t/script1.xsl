<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

<xsl:output method="html" encoding="UTF-8"/>

<xsl:template match="/list">
<html>
<head><title></title></head>
<body>
<h1>A list of students</h1>
  <xsl:apply-templates select="program"/>
  <xsl:apply-templates select="students"/>
</body>
</html>
</xsl:template>

<xsl:template match="/list/program">
<p>
Study program:
<b><xsl:value-of select="name"/></b>
(<tt><xsl:value-of select="code"/></tt>)
</p>
</xsl:template>

<xsl:template match="/list/students">
<ul>
  <xsl:apply-templates />
</ul>
</xsl:template>

<xsl:template match="/list/students/student">
<li>
<xsl:value-of select="firstname"/>
<xsl:text> </xsl:text>
<xsl:value-of select="lastname"/>
</li>
</xsl:template>

</xsl:stylesheet>

