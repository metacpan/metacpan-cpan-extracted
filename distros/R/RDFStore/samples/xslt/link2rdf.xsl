<?xml version='1.0'?>
<!--
	http://www.openhealth.org/RDF/extract/link2rdf.xsl
	Copyright (c) 2000 Jonathan Borden, The Open Healthcare Group and GroveLogic, LLC. all rights reserved
	licensed under the Open Health Community License http://www.openhealth.org/license
	
	Version 2000-09-20
	
	* Implements XLink2RDF conversion - this version includes extended links
		
-->
<!-- jonathan@openhealth.org -->

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:saxon="http://icl.com/saxon"
	exclude-result-prefixes='xsl rdf rdfs xlink saxon'
	>


<!--   XLink 2 RDF here                                                                      -->
<!-- per http://www.w3.org/XML/2000/09/xlink2rdf.htm -->
<!--  <xsl:param name="subject"/> -->


<xsl:template name="xlink-simple">

  	<xsl:param name="subject"><xsl:call-template name="nodeIdentifier"/></xsl:param>
	<xsl:variable name="object" select="@xlink:href"/>

	<xsl:call-template name="statement">
		<xsl:with-param name="predicate">
			<xsl:choose>
				<xsl:when test="@xlink:arcrole"><xsl:value-of select="@xlink:arcrole" /></xsl:when>
				<xsl:otherwise><xsl:call-template name="QNameToURI"/></xsl:otherwise>
			</xsl:choose>
		</xsl:with-param>
		<xsl:with-param name="subject" select="$subject"/>
		<xsl:with-param name="object" select="@xlink:href"/>
		<xsl:with-param name="object-type" select="'resource'"/>
	</xsl:call-template>
	<xsl:if test="@xlink:role">
 		<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="$rdfType"/>
		 <xsl:with-param name="subject" select="@xlink:href"/>
		 <xsl:with-param name="object" select="@xlink:role"/>
		 <xsl:with-param name="object-type" select="'resource'"/>
		</xsl:call-template>
     	<!--<rdf:Statement>
        		<rdf:predicate><xsl:value-of select="$rdfType" /></rdf:predicate>
				<rdf:subject><xsl:value-of select="@xlink:href"/></rdf:subject>
        		<rdf:object rdf:type="{$rdfsResourceType}"><xsl:value-of select="@xlink:role" /></rdf:object>
      	</rdf:Statement>-->
		<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="$rdfType"/>
		 <xsl:with-param name="subject" select="@xlink:role"/>
		 <xsl:with-param name="object" select="$rdfsClass"/>
		 <xsl:with-param name="object-type" select="'resource'"/>
		</xsl:call-template>
      	<!--<rdf:Statement>
        		<rdf:predicate><xsl:value-of select="$rdfType" /></rdf:predicate>
        		<rdf:subject><xsl:value-of select="@xlink:role" /></rdf:subject>
        		<rdf:object rdf:type="{$rdfsResourceType}"><xsl:value-of select='concat($rdfsNS,"Class")' /></rdf:object>
      	</rdf:Statement>-->
	</xsl:if>
<!--
<xsl:call-template name="generate-statement-string">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate-namespace-uri" select="namespace-uri()"/>
  <xsl:with-param name="predicate-local-name" select="local-name()"/>
  <xsl:with-param name="object-type" select="'resource'"/>
  <xsl:with-param name="object" select="$object"/>
</xsl:call-template>
-->

<xsl:call-template name="generate-statements">
  <xsl:with-param name="node" select="."/>
  <xsl:with-param name="subject" select="$object"/>
</xsl:call-template>

</xsl:template>
<!-- this is special for linkbase processing -->
<xsl:template match="*[(@xlink:type='simple') and not(../@xlink:type='extended')]" mode="xlink-extended">
	<xsl:apply-templates select="." mode="property-elements"/>
</xsl:template>
<xsl:template match="*[@xlink:type='arc']" mode="xlink-extended">
	<xsl:param name="predicate"><xsl:call-template name="get-predicate" /></xsl:param>
	<xsl:variable name="base" select=".."/>
	<xsl:variable name="from" select="@xlink:from"/>
	<xsl:variable name="to" select="@xlink:to" />
<xsl:if test="$trace">[TRACE xlink:type'arc' predicate=<xsl:value-of select="$predicate" />]</xsl:if>
	<xsl:for-each select="$base/*[((@xlink:type='resource') or (@xlink:type='locator')) and (not($from) or (@xlink:label=$from))]">
		<xsl:variable name="this-from" select="."/>
		<xsl:variable name="subject"><xsl:call-template name="get-subject-object" /></xsl:variable>
		<xsl:for-each select="$base/*[((@xlink:type='resource') or (@xlink:type='locator')) and (not($to) or (@xlink:label=$to))]">
			<xsl:variable name="this-to" select="."/>
			<xsl:variable name="object"><xsl:call-template name="get-subject-object"/></xsl:variable>
			<xsl:call-template name="statement">
		 		<xsl:with-param name="predicate" select="$predicate"/>
		 		<xsl:with-param name="subject" select="$subject"/>
		 		<xsl:with-param name="object" select="$object"/>
		 		<xsl:with-param name="object-type" select="'resource'"/>
			</xsl:call-template>

			<!--<rdf:Statement>
				<rdf:predicate><xsl:value-of select="$predicate" /></rdf:predicate>
				<rdf:subject><xsl:value-of select="$subject" /></rdf:subject>
				<rdf:object rdf:type="{$rdfsResourceType}"><xsl:value-of select="$object" /></rdf:object>
			</rdf:Statement>-->
		</xsl:for-each>
	</xsl:for-each>
</xsl:template>
<xsl:template match="*[(@xlink:type='arc') and (@xlink:arcrole='http://www.w3.org/1999/xlink/properties/linkbase')]" mode="xlink-extended">
<xsl:if test="$trace">[TRACE xlink arcrole=linkbase]</xsl:if>
	<xsl:apply-templates select="document(@xlink:href)" mode="xlink-extended"/>
</xsl:template>
<xsl:template match="*[@xlink:type='locator']" mode="xlink-extended">
	<xsl:variable name="subject" select="@xlink:href"/>
	<xsl:variable name="object">
		<xsl:choose>
			<xsl:when test="@xlink:role"><xsl:value-of select="@xlink:role" /></xsl:when>
			<xsl:otherwise><xsl:call-template name="QNameToURI" /></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:if test="@xlink:role">
	 	<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="$rdfType"/>
		 <xsl:with-param name="subject" select="$subject"/>
		 <xsl:with-param name="object" select="@xlink:role"/>
		 <xsl:with-param name="object-type" select="'resource'"/>
		</xsl:call-template>
		<!--<rdf:Statement>
			<rdf:predicate><xsl:value-of select="$rdfType" /></rdf:predicate>
			<rdf:subject><xsl:value-of select="$subject" /></rdf:subject>
			<rdf:object rdf:type="{$rdfsResourceType}"><xsl:value-of select="@xlink:role" /></rdf:object>
		</rdf:Statement>-->
	 	<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="$rdfType"/>
		 <xsl:with-param name="subject" select="@xlink:role"/>
		 <xsl:with-param name="object" select="$rdfsClass"/>
		 <xsl:with-param name="object-type" select="'resource'"/>
		</xsl:call-template>
		<!--<rdf:Statement>
			<rdf:predicate><xsl:value-of select="$rdfType" /></rdf:predicate>
			<rdf:subject><xsl:value-of select="@xlink:role" /></rdf:subject>
			<rdf:object rdf:type="{$rdfsResourceType}"><xsl:value-of select="$rdfsClass" /></rdf:object>
		</rdf:Statement>-->
	</xsl:if>
	<xsl:if test="@xlink:label">
		<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="concat($xlinkNS,'#','label')"/>
		 <xsl:with-param name="subject" select="$subject"/>
		 <xsl:with-param name="object" select="@xlink:label"/>
		 <xsl:with-param name="object-type" select="'literal'"/>
		</xsl:call-template>
		<!--<rdf:Statement>
			<rdf:predicate><xsl:value-of select="" /></rdf:predicate>
			<rdf:subject><xsl:value-of select="$subject" /></rdf:subject>
			<rdf:object rdf:type="{$rdfsLiteralType}"><xsl:value-of select="@xlink:label" /></rdf:object>
		</rdf:Statement>-->
	</xsl:if>
	<xsl:if test="@xlink:title">
	 	<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="concat($xlinkNS,'#','title')"/>
		 <xsl:with-param name="subject" select="$subject"/>
		 <xsl:with-param name="object" select="@xlink:title"/>
		 <xsl:with-param name="object-type" select="'literal'"/>
		</xsl:call-template>
		<!--<rdf:Statement>
			<rdf:predicate><xsl:value-of select="" /></rdf:predicate>
			<rdf:subject><xsl:value-of select="$subject" /></rdf:subject>
			<rdf:object rdf:type="{$rdfsLiteralType}"><xsl:value-of select="@xlink:title" /></rdf:object>
		</rdf:Statement>-->
	</xsl:if>
	<xsl:apply-templates select="*[@xlink:type='title']" mode="xlink-extended"/>
	<xsl:call-template name="generate-statements-noxlink">
  		<xsl:with-param name="node" select="."/>
  		<xsl:with-param name="subject" select="$object"/>
	</xsl:call-template>

</xsl:template>
<xsl:template match="*[@xlink:type='resource']" mode="xlink-extended">
	<xsl:variable name="subject"><xsl:call-template name="QNameToURI" /></xsl:variable>
	<xsl:variable name="object">
		<xsl:choose>
			<xsl:when test="@xlink:role"><xsl:value-of select="@xlink:role" /></xsl:when>
			<xsl:otherwise><xsl:call-template name="QNameToURI" /></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:if test="@xlink:role">
	 	<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="$rdfType"/>
		 <xsl:with-param name="subject" select="$subject"/>
		 <xsl:with-param name="object" select="@xlink:role"/>
		 <xsl:with-param name="object-type" select="'resource'"/>
		</xsl:call-template>
	 	<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="$rdfType"/>
		 <xsl:with-param name="subject" select="@xlink:role"/>
		 <xsl:with-param name="object" select="$rdfsClass"/>
		 <xsl:with-param name="object-type" select="'resource'"/>
		</xsl:call-template>
	</xsl:if>
	<xsl:if test="@xlink:label">
		<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="concat($xlinkNS,'#','label')"/>
		 <xsl:with-param name="subject" select="$subject"/>
		 <xsl:with-param name="object" select="@xlink:label"/>
		 <xsl:with-param name="object-type" select="'literal'"/>
		</xsl:call-template>
	</xsl:if>
	<xsl:if test="@xlink:title">
	 	<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="concat($xlinkNS,'#','title')"/>
		 <xsl:with-param name="subject" select="$subject"/>
		 <xsl:with-param name="object" select="@xlink:title"/>
		 <xsl:with-param name="object-type" select="'literal'"/>
		</xsl:call-template>
	</xsl:if>

	<!--<xsl:if test="@xlink:role">
		<rdf:Statement>
			<rdf:predicate><xsl:value-of select="$rdfType" /></rdf:predicate>
			<rdf:subject><xsl:value-of select="$subject" /></rdf:subject>
			<rdf:object rdf:type="{$rdfsResourceType}"><xsl:value-of select="@xlink:role" /></rdf:object>
		</rdf:Statement>
		<rdf:Statement>
			<rdf:predicate><xsl:value-of select="$rdfType" /></rdf:predicate>
			<rdf:subject><xsl:value-of select="@xlink:role" /></rdf:subject>
			<rdf:object rdf:type="{$rdfsResourceType}"><xsl:value-of select="$rdfsClass" /></rdf:object>
		</rdf:Statement>
	</xsl:if>
	<xsl:if test="@xlink:label">
		<rdf:Statement>
			<rdf:predicate><xsl:value-of select="concat($xlinkNS,'#','label')" /></rdf:predicate>
			<rdf:subject><xsl:value-of select="$subject" /></rdf:subject>
			<rdf:object rdf:type="{$rdfsLiteralType}"><xsl:value-of select="@xlink:label" /></rdf:object>
		</rdf:Statement>
	</xsl:if>
	<xsl:if test="@xlink:title">
		<rdf:Statement>
			<rdf:predicate><xsl:value-of select="concat($xlinkNS,'#','title')" /></rdf:predicate>
			<rdf:subject><xsl:value-of select="$subject" /></rdf:subject>
			<rdf:object rdf:type="{$rdfsLiteralType}"><xsl:value-of select="@xlink:title" /></rdf:object>
		</rdf:Statement>
	</xsl:if>-->
	<xsl:apply-templates select="*[@xlink:type='title']" mode="xlink-extended"/>

	<xsl:call-template name="generate-statements-noxlink">
  		<xsl:with-param name="node" select="."/>
  		<xsl:with-param name="subject" select="$object"/>
	</xsl:call-template>

</xsl:template>
<xsl:template match="*[@xlink:type='title']" mode="xlink-extended">
	<xsl:variable name="subject"><xsl:call-template name="QNameToURI"><xsl:with-param name="node" select=".." /></xsl:call-template></xsl:variable>
	<xsl:variable name="object"><xsl:call-template name="QNameToURI"/></xsl:variable>
<xsl:if test="$trace">[TRACE *[xlink:type='title']
	subject=<xsl:value-of select="$subject" />:<xsl:value-of select="name(..)" />
	object=<xsl:value-of select="$object" />
]</xsl:if>
	 	<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="concat($xlinkNS,'#','title')"/>
		 <xsl:with-param name="subject" select="$subject"/>
		 <xsl:with-param name="object" select="$object"/>
		 <xsl:with-param name="object-type" select="'resource'"/>
		</xsl:call-template>

	<!--<rdf:Statement>
		<rdf:predicate><xsl:value-of select="" /></rdf:predicate>
		<rdf:subject><xsl:value-of select="$subject" /></rdf:subject>
		<rdf:object rdf:type="{$rdfsResourceType}"><xsl:value-of select="$object" /></rdf:object>
	</rdf:Statement>-->
	<xsl:choose>
		<!-- if XML content then process -->
		<xsl:when test="*">
			<xsl:for-each select="*">
	<xsl:if test="$trace">[TRACE "*" name=<xsl:value-of select="name()" />]</xsl:if>
		<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="$rdfValue"/>
		 <xsl:with-param name="subject" select="$object"/>
		 <xsl:with-param name="object"><xsl:call-template name="nodeIdentifier" /></xsl:with-param>
		 <xsl:with-param name="object-type" select="'resource'"/>
		</xsl:call-template>

	<!--<rdf:Statement>
		<rdf:predicate><xsl:value-of select="$rdfValue" /></rdf:predicate>
		<rdf:subject><xsl:value-of select="$object" /></rdf:subject>
		<rdf:object rdf:type="{$rdfsResourceType}"></rdf:object>
	</rdf:Statement>-->
	<xsl:apply-templates select="." mode="objects"/>
			</xsl:for-each>
		</xsl:when>
		<!-- otherwise literal content set to rdf:value -->
		<xsl:when test="text()[string-length(normalize-space())&gt;0]">
			<xsl:for-each select="text()[string-length(normalize-space())&gt;0]">
	 	<xsl:call-template name="statement">
		 <xsl:with-param name="predicate" select="$rdfValue"/>
		 <xsl:with-param name="subject" select="$object"/>
		 <xsl:with-param name="object" select="."/>
		 <xsl:with-param name="object-type" select="'literal'"/>
		</xsl:call-template>

	<!--<rdf:Statement>
		<rdf:predicate><xsl:value-of select="$rdfValue" /></rdf:predicate>
		<rdf:subject><xsl:value-of select="$object" /></rdf:subject>
		<rdf:object rdf:type="{$rdfsLiteralType}"><xsl:value-of select="." /></rdf:object>
	</rdf:Statement>-->
			</xsl:for-each>
		</xsl:when>
	</xsl:choose>
</xsl:template>
<xsl:template name="get-predicate">
<xsl:if test="$trace">
[TRACE get-predicate
	node=<xsl:value-of select="name()" />
	arcrole=<xsl:value-of select="@xlink:arcrole" />
]
</xsl:if>
	<xsl:choose>
		<xsl:when test="@xlink:arcrole"><xsl:value-of select="@xlink:arcrole" /></xsl:when>
		<xsl:otherwise><xsl:call-template name="QNameToURI"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>
<xsl:template name="get-subject-object">
	<xsl:choose>
		<xsl:when test="@xlink:type='locator'"><xsl:value-of select="@xlink:href" /></xsl:when>
		<xsl:when test="@xlink:type='resource'"><xsl:call-template name="QNameToURI"/></xsl:when>
		<xsl:otherwise><error>Unknown xlink:type for subject or object</error></xsl:otherwise>
	</xsl:choose>
</xsl:template>
<!--                                                                         -->

<xsl:template name="generate-statements-noxlink">
  <xsl:param name="node" select="."/>
  <xsl:param name="subject">
    <xsl:call-template name="resource-uri">
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>
  </xsl:param>
<xsl:if test="$trace">[TRACE gen-stat-noxlink
	subject=<xsl:value-of select="$subject" />
]</xsl:if>
<xsl:variable name="reified-statement">
  <xsl:value-of select="$node/@bagID"/>
</xsl:variable>

<xsl:apply-templates select="$node/@*" mode="property-attributes">
  <xsl:with-param name="subject" select="$subject"/>
</xsl:apply-templates>

<xsl:apply-templates select="$node/*[not(@xlink:*)]" mode="property-elements">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="reified-statement" select="$reified-statement"/>
</xsl:apply-templates>
	<xsl:choose>
		<xsl:when test="$defaultParseType='Resource'">
			<xsl:for-each select='text()[string-length(normalize-space())&gt;0]'>
        		<xsl:call-template name="generate-statement-string">
  					<xsl:with-param name="subject" select="$subject"/>
  					<xsl:with-param name="predicate-namespace-uri" select="$rdf"/>
  					<xsl:with-param name="predicate-local-name" select="'value'"/>
  					<xsl:with-param name="object-type" select="'literal'"/>
  					<xsl:with-param name="object" select="."/>
				</xsl:call-template>
      		</xsl:for-each>
		</xsl:when>
	</xsl:choose>
</xsl:template>
</xsl:stylesheet>
