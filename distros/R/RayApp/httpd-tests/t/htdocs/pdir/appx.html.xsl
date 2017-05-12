<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>
<xsl:import href="pdatax.xsl"/>

<xsl:output
	method="text"
	media-type="text/plain"
	omit-xml-declaration="yes"
	/>

<xsl:template match="/root">The id is <xsl:value-of select="id"/>,
<xsl:apply-templates select="data"/></xsl:template>
</xsl:stylesheet>

