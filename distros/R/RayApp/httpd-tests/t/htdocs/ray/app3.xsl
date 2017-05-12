<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:param name="style_data"/>
<xsl:param name="style_env_data"/>

<xsl:template match="/root">

<html>
<body>
<p>The id is <span id="id"><xsl:value-of select="id"/></span>,
	the data is <span id="data"><xsl:value-of select="data"/></span>.
</p>
<p>
<a href="{$my_relative_url}">Style data is <xsl:value-of select="$style_data"/>
	and style env data is <xsl:value-of select="$style_env_data"/></a>
</p>
<ul>
	<li><a href="{$my_base_url}">base url</a></li>
	<li><a href="{$my_url}">url</a> is the same as <a href="{$my_absolute_url}">absolute url</a></li>
	<li><a href="{$my_relative_url}">relative url</a></li>
	<li><a href="{$my_relative_url_query}">relative url with query</a></li>
</ul>
</body>
</html>

</xsl:template>
</xsl:stylesheet>

