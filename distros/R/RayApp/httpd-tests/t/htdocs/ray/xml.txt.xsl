<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:output method="text"/>

<xsl:template match="/data">

Output:

<xsl:apply-templates select="_param|id"/>
</xsl:template>

<xsl:template match="_param">
We have _param element here.
</xsl:template>

<xsl:template match="id[not(*)]">
We have the empty id element here.
</xsl:template>

</xsl:stylesheet>

