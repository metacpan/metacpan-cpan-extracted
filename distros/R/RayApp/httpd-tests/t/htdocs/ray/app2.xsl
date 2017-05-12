<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:template match="/root">

<html>
<body>
<p>The id is <span id="id"><xsl:value-of select="id"/></span>,
	the data is <span id="data"><xsl:value-of select="data"/></span>.
</p>
</body>
</html>

</xsl:template>
</xsl:stylesheet>

