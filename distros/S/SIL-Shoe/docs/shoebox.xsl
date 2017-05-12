<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:math="http://www.w3.org/1998/Math/MathML"
    xmlns="http://www.w3.org/1999/xhtml">

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:param name="css">shoebox.css</xsl:param>

<xsl:key name="pars" match="/shoebox/shoebox-format/marker[@style='par' and not(interlinear)]" use="@name"/>
<xsl:key name="chars" match="/shoebox/shoebox-format/marker[@style='char' and not(interlinear)]" use="@name"/>


<xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <META http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
            <xsl:if test="$css!=''">
                <xsl:element name="link">
                    <xsl:attribute name="rel">stylesheet</xsl:attribute>
                    <xsl:attribute name="href"><xsl:value-of select="$css"/></xsl:attribute>
                    <xsl:attribute name="type">text/css</xsl:attribute>
                    <xsl:attribute name="media">all</xsl:attribute>
                </xsl:element>
            </xsl:if>
        </head>
        <body>
            <xsl:choose>
                <xsl:when test="local-name(/shoebox/*[1])='shoebox-format'">
                    <xsl:apply-templates select="shoebox/*[boolean(key('pars', local-name()))]" mode="formatted"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </body>
    </html>
</xsl:template>

<!--
<xsl:template match="interlinear-block">
    <math:math>
        <xsl:apply-templates mode="interlinear"/>
    </math:math>
</xsl:template>

<xsl:template match="interlinear-block" mode="formatted">
    <math:math>
        <xsl:apply-templates mode="interlinear"/>
    </math:math>
</xsl:template>

<xsl:template match="*[count(child::*)=0]" mode="interlinear">
    <math:mtr><math:mtd><math:mtext><xsl:value-of select="."/></math:mtext></math:mtd></math:mtr>
</xsl:template>

<xsl:template match="*" mode="interlinear">
    <math:mtable columnalign="left" rowspacing="3pt">
        <math:mtr><math:mtd><math:mtext><xsl:value-of select="@value"/></math:mtext></math:mtd></math:mtr>
        <xsl:apply-templates mode="interlinear"/>
    </math:mtable>
</xsl:template>
-->

<xsl:template match="interlinear-block">
<!--    <table style="border-style: none"> -->
    <div style="clear:both">
        <xsl:for-each select="*">
            <div style="float:left; margin-top=6pt"><xsl:apply-templates select="." mode="interlinear"/></div>
        </xsl:for-each>
    </div>
    <div style="clear:both"><p/></div>
</xsl:template>

<xsl:template match="interlinear-block" mode="formatted">
    <div style="clear:both">
        <xsl:for-each select="*">
            <div style="float:left"><xsl:apply-templates select="." mode="interlinear"/></div>
        </xsl:for-each>
    </div>
</xsl:template>

<xsl:template match="*" mode="interlinear">
    <p style="margin=0; margin-right=3pt">
        <xsl:choose>
            <xsl:when test="@value"><xsl:value-of select="@value"/></xsl:when>
            <xsl:when test="not(*) and normalize-space(.)"><xsl:value-of select="."/></xsl:when>
            <xsl:otherwise>&#x00A0;</xsl:otherwise>
        </xsl:choose>
    </p>
<!--    
    <xsl:variable name="all" select="*"/>
    <xsl:for-each select="*">
        <xsl:if test="not(preceding-sibling::*[name()=name(current())])">
            <div style="float: left">
                <xsl:for-each select="$all[name()=name(current())]">
                    <xsl:apply-templates select="." mode="interlinear"/>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:for-each>
-->
    <xsl:for-each select="*">
        <xsl:variable name="style">
            <xsl:choose>
                <xsl:when test="following-sibling::*[1][name()!=name(current())]">
                    <xsl:text>clear: right</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>float: left</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <div style="{$style}">
            <xsl:apply-templates select="." mode="interlinear"/>
        </div>
    </xsl:for-each>
</xsl:template>

<xsl:template match="*[boolean(key('chars', local-name(.)))]" mode="formatted">
    <span class="{local-name()}">
        <xsl:choose>
            <xsl:when test="@value != ''">
                <xsl:value-of select="@value"/>
             </xsl:when>
             <xsl:otherwise>
                <xsl:value-of select="text()"/>
             </xsl:otherwise>
         </xsl:choose>
    </span>
    <xsl:apply-templates select="*[boolean(key('chars', local-name(.)))]" mode="formatted"/>
</xsl:template>

<xsl:template match="*[key('pars', local-name(.))]" mode="formatted">
    <p class="{local-name()}">
        <xsl:choose>
            <xsl:when test="@value != ''">
                <xsl:value-of select="@value"/>
             </xsl:when>
             <xsl:otherwise>
                <xsl:value-of select="text()"/>
             </xsl:otherwise>
         </xsl:choose>
         <xsl:apply-templates select="*[boolean(key('chars', local-name(.)))]" mode="formatted"/>
         <xsl:apply-templates select="following-sibling::*[boolean(key('chars', local-name(.)))]" mode="formatted"/>
    </p>
    <xsl:apply-templates select="descendant::*[boolean(key('pars', local-name(.))) or local-name(.)='interlinear-block']" mode="formatted"/>
</xsl:template>

<xsl:template match="*">
    <p class="{local-name()}">
        <xsl:choose>
            <xsl:when test="@value != ''">
                <xsl:value-of select="@value"/>
             </xsl:when>
             <xsl:otherwise>
                <xsl:value-of select="text()"/>
             </xsl:otherwise>
         </xsl:choose>
    </p>
    <xsl:apply-templates/>
</xsl:template>

</xsl:stylesheet>
