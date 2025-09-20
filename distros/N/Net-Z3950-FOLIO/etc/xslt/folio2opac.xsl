<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.loc.gov/MARC21/slim">
  <xsl:include href="http://www.loc.gov/standards/marcxml/xslt/MARC21slimUtils.xsl"/>
  <xsl:output indent="yes"/>

  <xsl:template match="/">
    <record xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
      <xsl:apply-templates select="opt"/>
    </record>
  </xsl:template>

  <xsl:template match="opt">
    <leader>
      <xsl:value-of select="'     '"/>  <!-- length -->
      <xsl:value-of select="' '"/>      <!-- status -->
      <xsl:value-of select="'a'"/>      <!-- decode type -->
      <xsl:value-of select="'m'"/>      <!-- decode type -->
      <xsl:value-of select="' '"/>      <!-- type of control -->
      <xsl:value-of select="'a'"/>      <!-- unicode -->
      <xsl:value-of select="'2'"/>      <!-- #ind -->
      <xsl:value-of select="'1'"/>      <!-- #subf chars -->
      <xsl:value-of select="'     '"/>  <!-- base address -->
      <xsl:value-of select="'3'"/>      <!-- encoding level (3=minimal) -->
      <xsl:value-of select="'#'"/>      <!-- cataloging form, #=non-ISBD -->
      <xsl:value-of select="'#'"/>      <!-- multipart level #=N/A -->
      <xsl:value-of select="'4'"/>      <!-- length of length always 4 -->
      <xsl:value-of select="'5'"/>      <!-- length of start char always 5 -->
      <xsl:value-of select="'0'"/>      <!-- always 0 -->
      <xsl:value-of select="'0'"/>      <!-- always 0 -->
    </leader>
    <xsl:apply-templates select="title"/>
  </xsl:template>

  <xsl:template match="title">
    <datafield tag="245" ind1="0" ind2="0">
      <subfield code="a">
        XXX This stylesheet has not yet been written
      </subfield>
    </datafield>
  </xsl:template>
</xsl:stylesheet>
