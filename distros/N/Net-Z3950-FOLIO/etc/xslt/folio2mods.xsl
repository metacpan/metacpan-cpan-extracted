<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mods="http://www.loc.gov/mods/v3"
    xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-8.xsd"
    version="1.0">
    <xsl:output encoding="UTF-8" method="xml" indent="yes"/>

    <!-- Mapping from FOLIO raw format to mods for the FOLIO Z39.50 server 
         Marko Knepper, UB Mainz 2025, Apache 2.0 -->

    <xsl:template match="opt"> <!-- expecting an opt element for the record -->
        <mods:mods>
            <xsl:apply-templates mode="instance"/>
            <mods:location>
                <mods:physicalLocation><xsl:value-of select="holdingsRecords2[1]/permanentLocation/institution/name"/></mods:physicalLocation>
                <mods:holdingSimple>
                    <xsl:apply-templates select="//bareHoldingsItems" mode="holdings"/>
                </mods:holdingSimple>
            </mods:location>
            <mods:recordInfo>
                <mods:recordIdentifier source="hrid"><xsl:value-of select="hrid"/></mods:recordIdentifier>
                <mods:recordIdentifier source="uuid"><xsl:value-of select="id"/></mods:recordIdentifier>
            </mods:recordInfo>
        </mods:mods>
    </xsl:template>

    <xsl:template match="title" mode="instance">
        <mods:titleInfo>
            <mods:title><xsl:value-of select="."/></mods:title>
        </mods:titleInfo>
    </xsl:template>
    
    <xsl:template match="contributors" mode="instance">
        <mods:name>
            <mods:displayForm><xsl:value-of select="name"/></mods:displayForm>
        </mods:name>
    </xsl:template>
    
    <xsl:template match="publication" mode="instance">
        <mods:originInfo>
            <mods:publisher><xsl:value-of select="publisher"/></mods:publisher>
            <mods:dateIssued encoding="w3cdtf" keyDate="yes"><xsl:value-of select="dateOfPublication"/></mods:dateIssued>
        </mods:originInfo>
    </xsl:template>
    
    <xsl:template match="bareHoldingsItems" mode="holdings"> <!-- mapping each item of all holdings on mods:copyInformation -->
        <mods:copyInformation>
            <xsl:apply-templates select="materialType" mode="item"/>
            <xsl:choose>         <!-- permanentLocation is inherited here -->
                <xsl:when test="permanentLocation/name/text()">
                    <xsl:apply-templates select="permanentLocation" mode="item"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="../permanentLocation" mode="item"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="effectiveCallNumberComponents" mode="item"/>
            <xsl:apply-templates select="../notes" mode="item"/>
            <xsl:apply-templates select="chronology|copyNumber" mode="item"/>
            <xsl:apply-templates select="barcode|hrid" mode="item"/>
        </mods:copyInformation>
    </xsl:template>
    
    <xsl:template match="effectiveCallNumberComponents" mode="item">
        <mods:shelfLocator>
            <xsl:if test="prefix/text()"><xsl:value-of select="prefix"/><xsl:text> </xsl:text></xsl:if>
            <xsl:value-of select="callNumber"/>
            <xsl:if test="suffix/text()"><xsl:text> </xsl:text><xsl:value-of select="suffix"/></xsl:if>
        </mods:shelfLocator>
    </xsl:template>
    
    <xsl:template match="permanentLocation" mode="item">
        <mods:subLocation><xsl:value-of select="name"/></mods:subLocation>
    </xsl:template>
    
    <xsl:template match="barcode" mode="item">
        <mods:itemIdentifier type="barcode"><xsl:value-of select="."/></mods:itemIdentifier>
    </xsl:template>
    
    <xsl:template match="hrid" mode= "item">
        <mods:itemIdentifier type="hrid"><xsl:value-of select="."/></mods:itemIdentifier>
    </xsl:template>
    
    <xsl:template match="materialType" mode="item">
        <mods:form><xsl:value-of select="name"/></mods:form>
    </xsl:template>
    
    <xsl:template match="notes" mode="item">
        <mods:note type="{holdingsNoteType/name}"><xsl:value-of select="note"/></mods:note>
    </xsl:template>

    <xsl:template match="chronology[text()]|copyNumber[text()]" mode="item">
        <mods:enumerationAndChronology unitType="1"><xsl:value-of select="."/></mods:enumerationAndChronology>
    </xsl:template>

    <xsl:template match="text()" mode="instance"/>
</xsl:stylesheet>
