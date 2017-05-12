<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:template match="data">	the data is <span id="data"><xsl:value-of select="."/></span>.
</xsl:template>

</xsl:stylesheet>

