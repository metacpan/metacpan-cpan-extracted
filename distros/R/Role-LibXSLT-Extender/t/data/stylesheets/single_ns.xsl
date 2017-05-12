<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:test="http://test/a/good/uri#v1"
>

<xsl:template match="/">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="test_cases">
    <result>
        <xsl:apply-templates />
    </result>
</xsl:template>

<xsl:template match="test_case[@name='foo']">
    <foo><xsl:value-of select="test:foo(.)"/></foo>
</xsl:template>

<xsl:template match="test_case[@name='bar']">
    <bar><xsl:value-of select="test:bar(.)"/></bar>
</xsl:template>

<xsl:template match="test_case[@name='quux']">
    <quux><xsl:copy-of select="test:quux(.)"/></quux>
</xsl:template>

</xsl:stylesheet>
