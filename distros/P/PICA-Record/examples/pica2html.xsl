<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:pica="info:srw/schema/5/picaXML-v1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--
    pica2html.xsl

    date: 2009-05-18
    description: Display PicaXML in HTML
    author: Jakob Voss

    Changelog:
      2008-02-25: First public draft
      2009-05-18: Modified layout
    TODO:
      * toggle display with JavaScript
      ** hide/show level 1 and 2
      ** display blanks as (&#x2423;)
      ** change subfield indicator ($)
      * add information about known/unknown fields/subfields
  -->

  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!-- CSS file -->
  <xsl:param name="css"/>

<xsl:param name="defaultcss">
  html { font-family: sans-serif; }

  .record {
    background-color:#F0F0F0;
    border:1px dotted gray;
    margin:0.5em 0 0.5em 0;
    border-spacing:0px;
    padding: 0;
    border-collapse: collapse;
  }
  .record caption { 
    font-weight: bold;
    text-align: left;
  }

  /* uncomment this to use monospaced font */
  /* .record td { font-family: monospace; } */

  /* row of a field */
  .field {  }
  .localfield {  }
  .firstlocalfield td { border-top: 1px solid gray; }

  /* the tag of a field */
  .tag {
    font-weight: bold; 
    vertical-align: top;
  }
  .tagcode { color:#000066; }
  .occurrence { color:#0000BB; }

  /* subfield indicator and code */
  .sfcode { 
    font-weight: bold; 
    color:#BB00BB; 
  }
  .sfindicator { 
    font-weight: bold; 
    color:#000; 
  }

  /* other styles */
  .ppn, .epn { 
    color:#00bb00;
  }
  .error { 
    font-weight: bold;
    color:#FF0000;
   }
/*
  a.link { text-style:italic; text-weight:default; text-decoration:underline; }
*/
</xsl:param>

  <!-- HTML -->
  <xsl:template match="/">
    <html>
      <head>
        <title>PicaXML in HTML</title>
        <xsl:choose>
          <xsl:when test="$css">
            <link rel="stylesheet" type="text/css" href="{$css}"/>
          </xsl:when>
          <xsl:otherwise>
            <style type="text/css">
              <xsl:value-of select="$defaultcss"/>
            </style>
          </xsl:otherwise>
        </xsl:choose>
      </head>
      <body>
        <a name="top"/>
        <h1>PicaXML in HTML</h1>
        <xsl:apply-templates select="pica:collection|pica:record"/>
      </body>
    </html>
  </xsl:template>


  <!-- Multiple records in one file -->
  <xsl:template match="pica:collection">
    <!-- TODO: show number of records -->
    <xsl:apply-templates select="pica:record"/>
  </xsl:template>


  <!-- Content of a record -->
  <xsl:template match="pica:record">
    <!--div class="record"-->
      <xsl:choose>
        <xsl:when test="pica:datafield">
          <table class="record">
            <xsl:apply-templates select="." mode="caption"/>
            <xsl:apply-templates select="pica:datafield"/>
          </table>
        </xsl:when>  
        <xsl:otherwise>
          <p class="error">record contains no datafields!</p>
        </xsl:otherwise>
      </xsl:choose>
    <!--/div-->
  </xsl:template>

  <xsl:template match="pica:record" mode="caption">
    <xsl:variable name="ppn" select="pica:datafield[@tag='003@']/pica:subfield[@code='0']"/>
    <caption>
      <xsl:if test="$ppn">
        <xsl:attribute name="id">
          <xsl:text>ppn</xsl:text>
          <xsl:value-of select="$ppn"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="$ppn">
        <span class="ppn"><xsl:value-of select="$ppn"/></span>
      </xsl:if>
      <xsl:text> #</xsl:text>
      <xsl:value-of select="count(preceding-sibling::pica:record)+1"/>
    </caption>
  </xsl:template>

  <!-- Content of a field -->
  <xsl:template match="pica:datafield">
    <xsl:variable name="tag" select="@tag"/>
    <!-- TODO: check whether a tag matches [0-9][0-9][0-9][A-Z@] -->

    <xsl:variable name="tagValid" select="true()"/>
    <xsl:variable name="local" select="substring(@tag,1,1)!='0'"/>
    <xsl:variable name="prevtag" select="preceding-sibling::pica:datafield[1]/@tag" />

    <tr>
      <xsl:attribute name="class">
        <xsl:if test="$local">
          <xsl:if test="substring(@tag,1,1)='1' and substring($prevtag,1,1)!='1'">first</xsl:if>
          <xsl:text>local</xsl:text>
        </xsl:if>
        <xsl:text>field</xsl:text>
      </xsl:attribute>
      <td class="tag">
        <!--xsl:attribute name="title">
            TODO: add semantics/help with title attribute
          </xsl:attribute>
          <xsl:if test="not($tagValid)"> invalid</xsl:if>
        -->
        <span class="tagcode">
          <xsl:value-of select="@tag"/>
        </span>
        <xsl:if test="@occurrence">
          <xsl:text>/</xsl:text> <!-- TODO: how to show this? -->
          <span class="occurrence">
            <xsl:value-of select="@occurrence"/>
          </span>  
        </xsl:if>
      </td>
      <td>
        <xsl:if test="not(pica:subfield)">
          <xsl:attribute name="class">error</xsl:attribute>
          <xsl:text>missing subfields in field!</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="pica:subfield"/>
      </td>
    </tr>
  </xsl:template>

  <!-- Content of a subfield -->
  <xsl:template match="pica:subfield">
    <!-- TODO: validate @code and show semantics -->
    <span class='sfindicator'>$</span>
    <span class="sfcode">
      <xsl:value-of select="@code"/>
    </span>
    <span class="value">
      <xsl:choose>
        <xsl:when test="@code='0' and parent::pica:datafield/@tag='003@'">
          <span class="ppn"><xsl:value-of select="."/></span>
        </xsl:when>
        <xsl:when test="@code='0' and parent::pica:datafield/@tag='203@'">
          <span class="epn"><xsl:value-of select="."/></span>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </span>
  </xsl:template>

</xsl:stylesheet>
