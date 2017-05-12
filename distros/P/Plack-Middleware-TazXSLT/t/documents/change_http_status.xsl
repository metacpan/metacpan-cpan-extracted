<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:response="http://taz.de/xmlns/tazxslt/http_response"
>
<xsl:template match="/"><xsl:value-of select="foo"/>
<xsl:variable name="old_code" select="response:code(204)"/>
</xsl:template>

</xsl:stylesheet> 
