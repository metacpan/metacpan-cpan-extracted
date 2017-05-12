<?xml version='1.0' encoding='iso-8859-1'?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

<!--  template "DELCHECK_MASTER_TEMPLATE" should be defined by the files that include this -->


<xsl:variable name="newline">
<xsl:text>
</xsl:text>
</xsl:variable>

<xsl:variable name="tab">
<xsl:text>	</xsl:text>
</xsl:variable>



<xsl:output method="xml"
	    doctype-system="testns.dtd" 
	    standalone="no"/>


<xsl:variable name="outform">simple</xsl:variable>    

<xsl:template match="testns">
  <xsl:comment> 
    
    This xml document has been generated using transform-conf.xsl 
    
    $Id: master2simple.xsl,v 1.1.2.1 2004/10/14 09:54:03 olaf Exp $
    
    tranform-conf.xsl is used to tranform the configuration files that
    came with version 1.06 of Net::DNS::TestNS to the version introduced
    with Net::DNS::TestNS 1.07
    
  </xsl:comment>
  
  <xsl:value-of select="$newline"/>     
  <xsl:element name="testns">
    <xsl:attribute name="version">1.0</xsl:attribute>
    <xsl:value-of select="$newline"/> 

    <xsl:apply-templates select="server"/>
  </xsl:element>
  
  
  
</xsl:template>


<xsl:template match="server">
  <xsl:element name="server">
    <xsl:attribute name="ip">
      <xsl:value-of select="@ip"/>
    </xsl:attribute>
    <xsl:attribute name="port">
      <xsl:value-of select="@port"/>
    </xsl:attribute>
      <xsl:value-of select="$newline"/>    
      <xsl:value-of select="$tab"/>    
    <xsl:apply-templates select="qname"/>
  </xsl:element>
  <xsl:value-of select="$newline"/>    <xsl:value-of select="$newline"/> 
</xsl:template>


<xsl:template match="qname">
  <xsl:element name="qname">
    <xsl:attribute name="name">
      <xsl:value-of select="@name"/>
    </xsl:attribute>
      <xsl:value-of select="$newline"/>    
      <xsl:value-of select="$tab"/>    
      <xsl:value-of select="$tab"/>    
    <xsl:apply-templates select="qtype"/>
      <xsl:value-of select="$newline"/>    
  </xsl:element>
  <xsl:value-of select="$newline"/>    <xsl:value-of select="$newline"/> 
</xsl:template>


<xsl:template match="qtype">
  <xsl:element name="qtype">
    <xsl:attribute name="type">
      <xsl:value-of select="@type"/>
    </xsl:attribute>

    <xsl:attribute name="delay">
      <xsl:value-of select="@delay"/>
    </xsl:attribute>
    <xsl:value-of select="$newline"/>    
    <xsl:value-of select="$tab"/>    
    <xsl:value-of select="$tab"/>    
    <xsl:element name="header">
      <xsl:value-of select="$newline"/>    
      <xsl:value-of select="$tab"/>    
      <xsl:value-of select="$tab"/>    
      <xsl:value-of select="$tab"/>    
      <xsl:element name="rcode">
	<xsl:attribute name="value">
	<xsl:value-of select="@rcode"/>
	</xsl:attribute>
      </xsl:element>
      <xsl:element name="aa">
	<xsl:attribute name="value">
	  <xsl:value-of select="@aa"/>
	</xsl:attribute>
      </xsl:element>
      <xsl:element name="ra">
	<xsl:attribute name="value">
	  <xsl:value-of select="@ra"/>
	</xsl:attribute>
      </xsl:element>
      <xsl:element name="ad">
	<xsl:attribute name="value">
	  <xsl:value-of select="@ad"/>
	</xsl:attribute>
      </xsl:element>
    <xsl:value-of select="$newline"/> 
    <xsl:value-of select="$tab"/> 
    <xsl:value-of select="$tab"/> 
    </xsl:element>
      <xsl:apply-templates select="* | text()"/>
    <xsl:value-of select="$newline"/>    
    <xsl:value-of select="$tab"/>    
    <xsl:value-of select="$tab"/>    
  </xsl:element>
</xsl:template>
    

  <xsl:template match="* | text()">
    <xsl:copy>
      <xsl:apply-templates select="* | text()"/>
    </xsl:copy>
  </xsl:template>



</xsl:stylesheet>
