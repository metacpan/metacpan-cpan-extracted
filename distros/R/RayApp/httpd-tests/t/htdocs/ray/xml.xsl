<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:template match="/data">

<html>
<body>
<xsl:apply-templates />
</body>
</html>

</xsl:template>

<xsl:template match="text()"/>

<xsl:template match="_param">
<p>
We have _param element here.
</p>
</xsl:template>

<xsl:template match="id[not(*)]">
<p>
We have the empty id element here.
</p>
</xsl:template>

</xsl:stylesheet>

