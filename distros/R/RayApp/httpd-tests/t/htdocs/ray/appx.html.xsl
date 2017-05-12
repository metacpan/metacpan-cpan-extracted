<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:import href="datax.xsl"/>

<xsl:template match="/root">

<html>
<body>
<p>The id is <span id="id"><xsl:value-of select="id"/></span>,
<xsl:apply-templates select="data"/>
</p>
</body>
</html>

</xsl:template>
</xsl:stylesheet>

