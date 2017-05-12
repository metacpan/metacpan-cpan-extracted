<?xml version="1.0" ?>
<!--
	http://www.openhealth.org/RDF/extract/rdfExtractity.xsl
	Copyright (c) 2000 Jonathan Borden, The Open Healthcare Group and GroveLogic, LLC. all rights reserved
	licensed under the Open Health Community License http://www.openhealth.org/license
	
	Version 2000-09-20
	
	* Implements RDF 'extraction' from RDF into <rdf:Statement>s
		- default rdf:parseType = 'Resource'
	* When this is run on its output, implements reification
	* Implements XLink2RDF conversion - this version includes extended links
	
	This version incorporates (xsl:include-s) Jason Diamond's <jason@injektilo.org> rdf.xsl parser 
		- (excellent code!!)
		- modified to implement 'alternative' RDF serialization syntax
		- outputs rdf:Statement's
		- handles bagID
		- allows arbitrary elements as children of containers
	Includes also from Dan Connolly's rdfp.xsl
		
	link2rdf.xsl includes XLink - > RDF implementation
	
	Parameters:
		trace - when present inserts trace info into output stream
		explicitPathIndices = 'ChildSeq' (default) when null, attribute values id generated xpointer()
		defaultParseType = 'Resource' alternative 'Literal' any other gives M&S1.0 behavior
		
-->
<!-- jonathan@openhealth.org -->
<!DOCTYPE xsl:stylesheet [
<!ENTITY alt-minimum-one-member "Alts need at least one member">
<!ENTITY container-member-attributes-vs-elements "containers with member attributes cannot have elements">
]>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfx="http://www.openhealth.org/RDF/extract#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:saxon="http://icl.com/saxon"
>
	<!--
	exclude-result-prefixes='xsl rdfx xlink saxon'
	-->
	<!--exclude-result-prefixes='xsl rdf rdfs rdfx xlink saxon' by AR 2000/09/25 -->

<xsl:output method="xml" indent="yes"/>
  <xsl:variable name='rdfNS' select='"http://www.w3.org/1999/02/22-rdf-syntax-ns#"'/>
  <xsl:variable name='rdfsNS' select='"http://www.w3.org/2000/01/rdf-schema#"'/>  
  <xsl:variable name='xlinkNS' select='"http://www.w3.org/1999/xlink"'/>
  <xsl:variable name='uriReferenceType' select='"http://www.w3.org/1999/XMLSchema#datatype_uriReference"'/>
  <xsl:variable name='stringType' select='"http://www.w3.org/1999/XMLSchema#datatype_string"'/>
  <xsl:variable name="rdfsLiteralType" select='concat($rdfsNS,"Literal")'/>
  <xsl:variable name="rdfsResourceType" select='concat($rdfsNS,"Resource")'/>
  <xsl:variable name="xmlNS" select="'http://www.w3.org/XML/1998/namespace'" />
  <xsl:variable name="rdfType" select="concat($rdfNS,'type')"/>
  <xsl:variable name="rdfValue" select="concat($rdfNS,'value')"/>
  <xsl:variable name="rdfsClass" select="concat($rdfsNS,'Class')"/>
  <xsl:variable name="xlinkBase" select="'http://www.w3.org/1999/xlink/properties/linkbase'"/>

<xsl:param name="explicitPathIndices" select="'ChildSeq'"/>
<xsl:param name="trace" /><!--	select="'true'"-->
<xsl:param name="QNameTrace" /><!--	 select="'true'"	-->
<xsl:param name="defaultParseType" select="'Resource'"/><!--  -->
<xsl:include href="rdf.xsl"/>
<!--<xsl:include href="link2rdf.xsl"/>-->
<!--                                                                         -->

<xsl:template match="/rdf:RDF">
<rdf:RDF>
<xsl:if test="$trace">[TRACE /rdf:RDF]</xsl:if>
  <xsl:apply-templates select="*" mode="objects"/>
</rdf:RDF>
</xsl:template>

<!--                                                                         -->

<xsl:template match="rdf:RDF">
<rdf:RDF>
<xsl:if test="$trace">[TRACE rdf:RDF]</xsl:if>
  <xsl:apply-templates select="*" mode="objects"/>
</rdf:RDF>
</xsl:template>

<!--                                                                         -->
<!--                                                                         -->

<xsl:template match="/*">
<rdf:RDF>
<xsl:if test="$trace">[TRACE /* (<xsl:value-of select="name()" />)]</xsl:if>
  <xsl:apply-templates select="." mode="objects"/>
</rdf:RDF>
</xsl:template>

<!--                                                                         -->
<xsl:template match="rdf:Description" mode="objects">
<xsl:if test="$trace">[TRACE rdf:Description]</xsl:if>
	<xsl:call-template name="generate-description-statements"/>
</xsl:template>

<!--                                                                         -->

<xsl:template match="rdf:Description[@about or @rdf:about]" mode="objects">
<xsl:if test="$trace">[TRACE rdf:Description[@about] ]</xsl:if>
	<xsl:call-template name="generate-description-statements"/>
</xsl:template>

<!--                                                                         -->

<xsl:template match="*[@rdf:about]" mode="objects">
<xsl:if test="$trace">[TRACE *[@rdf:about] (<xsl:value-of select="name()" />) ]</xsl:if>
	<xsl:call-template name="generate-type-statement">
  		<xsl:with-param name="subject" select="@rdf:about"/>
  		<xsl:with-param name="type"><xsl:call-template name="QNameToURI" /></xsl:with-param><!-- select="concat(namespace-uri(), local-name())"/>-->
	</xsl:call-template>
	<xsl:call-template name="generate-statements"/>
	
</xsl:template>

<!--                                                                         -->

<xsl:template match="*" mode="objects">
	<xsl:param name="parse-type" select="$defaultParseType"/>
<xsl:if test="$trace">[TRACE * (<xsl:value-of select="name()" />) ]</xsl:if>
	<xsl:if test="$parse-type='Resource'">
		<xsl:call-template name="generate-type-statement">
  			<xsl:with-param name="subject"><xsl:call-template name="nodeIdentifier"/></xsl:with-param>
  			<xsl:with-param name="type"><xsl:call-template name="QNameToURI" /></xsl:with-param><!-- select="concat(namespace-uri(), local-name())"/>-->
		</xsl:call-template>
	</xsl:if>
	<xsl:call-template name="generate-statements"/>

</xsl:template>
<!--                                                                         -->

<xsl:template match="rdf:Description[@rdf:aboutEach]" mode="objects">
<xsl:if test="$trace">[TRACE rdf:Description[@rdf:aboutEach] ]</xsl:if>
<xsl:call-template name="generate-statements-about-each">
  <xsl:with-param name="node" select="."/>
  <xsl:with-param name="about-each" select="@rdf:aboutEach"/>
</xsl:call-template>

</xsl:template>

<!--                                                                         -->

<xsl:template match="*[@rdf:aboutEach]" mode="objects">
<xsl:if test="$trace">[TRACE *[@rdf:aboutEach] <xsl:value-of select="name()" />]</xsl:if>
<xsl:call-template name="generate-statements-about-each">
  <xsl:with-param name="node" select="."/>
  <xsl:with-param name="about-each" select="@rdf:aboutEach"/>
  <xsl:with-param name="type"><xsl:call-template name="QNameToURI" /></xsl:with-param><!-- select="concat(namespace-uri(), local-name())"/> -->
</xsl:call-template>

</xsl:template>


<!--                                                                         -->

<xsl:template match="rdf:Bag | rdf:Seq | rdf:Alt" mode="objects">
<xsl:if test="$trace">[TRACE container <xsl:value-of select="name()" /> ]</xsl:if>
<xsl:variable name="subject">
  <xsl:call-template name="container-uri">
    <xsl:with-param name="node" select="."/>
  </xsl:call-template>
</xsl:variable>

<xsl:call-template name="generate-type-statement">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="type"><xsl:call-template name="QNameToURI" /></xsl:with-param>
</xsl:call-template>

<!-- make sure Alts have at least one member -->
<!--<xsl:if test="local-name() = 'Alt' and count(rdf:li) = 0">
  <xsl:message terminate="yes">&alt-minimum-one-member;</xsl:message>
</xsl:if>-->
<!-- jab rdf syntax -->
<xsl:if test="local-name() = 'Alt' and count(*) = 0">
  <xsl:message terminate="yes">&alt-minimum-one-member;</xsl:message>
</xsl:if>


<!-- make sure there are not both member attributes and elements -->
<xsl:choose>
  <xsl:when test="@rdf:*[starts-with(local-name(), '_')]">
    <xsl:choose>
      <xsl:when test="*">
        <xsl:message terminate="yes">&container-member-attributes-vs-elements;</xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="@rdf:*" mode="member-attributes">
          <xsl:with-param name="subject" select="$subject"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:otherwise>
    <!-- jab rdf syntax <xsl:apply-templates select="rdf:li" mode="members">-->
	<xsl:apply-templates select="*" mode="members">
      <xsl:with-param name="container" select="$subject"/>
    </xsl:apply-templates>
  </xsl:otherwise>
</xsl:choose>

</xsl:template>

<!--                                                                         -->

<xsl:template match="@*" mode="property-attributes">
  	<xsl:param name="subject"/>
	<!-- by AR 2000/24/10 -->
	<xsl:variable name="attribute-container" select=".."/>
	<xsl:variable name="attribute-namespace-uri" select="namespace-uri($attribute-container)"/>

	<!-- by AR 2000/24/10 by with NS does not work :-( -->
	<xsl:variable name="attribute-name" ><xsl:value-of select="$subject" />[@<xsl:value-of select="name()" />]</xsl:variable>
<xsl:if test="$trace">[TRACE @* <xsl:value-of select="name()" /> <xsl:value-of select="$attribute-name" /> property-attributes]</xsl:if>
	<xsl:if test="($attribute-namespace-uri != $rdfNS) and ($attribute-namespace-uri != $xmlNS) and ($attribute-namespace-uri != $xlinkNS)">
  		<xsl:if test="($attribute-namespace-uri != '') or ((local-name() != 'about') and (local-name() != 'ID') and (local-name() != 'bagID') and (local-name() != 'aboutEach'))">
    		<xsl:call-template name="generate-statement-string">
      			<xsl:with-param name="subject" select="$subject"/>
      			<xsl:with-param name="predicate-namespace-uri" select="$attribute-namespace-uri"/>
			<!--
      			<xsl:with-param name="predicate-local-name" select="local-name()"/>
			-->
      			<xsl:with-param name="predicate-local-name" select="$attribute-name"/>
      			<xsl:with-param name="object-type" select="'literal'"/>
      			<xsl:with-param name="object" select="."/>
    		</xsl:call-template>
  		</xsl:if>
	</xsl:if>
</xsl:template>
<!-- ************************************************************************** -->
<!--																			-->
<xsl:template match="*" mode="property-elements">
	<xsl:param name="subject"><xsl:call-template name="nodeIdentifier"/></xsl:param>
<xsl:if test="$trace">[TRACE * name=<xsl:value-of select="name()" /> property-elements]</xsl:if>
	<xsl:call-template name="generate-for-default-parse-type">
		<xsl:with-param name="subject" select="$subject"/>
	</xsl:call-template>
</xsl:template>
<!-- ************************************************************************** -->
<!--																		-->
<xsl:template match="*[@rdf:*]" mode="property-elements">
<xsl:if test="$trace">[TRACE *[@rdf:*] name=<xsl:value-of select="name()" />]</xsl:if>
</xsl:template>
<!--                                                                         -->
<xsl:template match="*[@*]" mode="property-elements">
	<xsl:param name="subject"><xsl:call-template name="nodeIdentifier"/></xsl:param>
<xsl:if test="$trace">[TRACE *[@*] name=<xsl:value-of select="name()" /> property-elements]</xsl:if>
	<xsl:call-template name="generate-for-default-parse-type">
		<xsl:with-param name="subject" select="$subject"/>
	</xsl:call-template>
</xsl:template>
<!-- ************************************************************************** -->
<xsl:template match="rdf:*[@rdf:*]" mode="property-elements">
<xsl:if test="$trace">
[TRACE rdf:*[@rdf:*] name=<xsl:value-of select="name()" />]
(<xsl:for-each select="attribute::rdf:*"><xsl:value-of select="name()" />=<xsl:value-of select="." />,</xsl:for-each>)
</xsl:if>
</xsl:template>
<!--                                                                         -->
<xsl:template match="rdf:*[@*]" mode="property-elements">
	<xsl:param name="subject"><xsl:call-template name="nodeIdentifier"/></xsl:param>
<xsl:if test="$trace">[TRACE rdf:*[@*] name=<xsl:value-of select="name()" /> property-elements]</xsl:if>
	<xsl:call-template name="generate-for-default-parse-type">
		<xsl:with-param name="subject" select="$subject"/>
	</xsl:call-template>
</xsl:template>
<!--																		-->
<!-- jab set parse-type for children -->
<xsl:template match="rdf:*[@resource]" mode="property-elements">
  <xsl:param name="subject"/>
<xsl:if test="$trace">[TRACE rdf:*[@resource] name=<xsl:value-of select="name()" /> property-elements]</xsl:if>
<xsl:call-template name="generate-statement-string">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate-namespace-uri" select="namespace-uri()"/>
  <xsl:with-param name="predicate-local-name" select="local-name()"/>
  <xsl:with-param name="object-type" select="'resource'"/>
  <xsl:with-param name="object" select="@resource"/>
</xsl:call-template>

<xsl:apply-templates select="." mode="objects">
	<xsl:with-param name="parse-type" select="'RDF1.0-base'"/>
</xsl:apply-templates>

</xsl:template>

<!--                                                                         -->

<xsl:template match="rdf:*[@rdf:resource]" mode="property-elements">
  <xsl:param name="subject"/>
<xsl:if test="$trace">[TRACE rdf:*[@rdf:resource] property-elements]</xsl:if>
<xsl:call-template name="generate-statement-string">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate-namespace-uri" select="namespace-uri()"/>
  <xsl:with-param name="predicate-local-name" select="local-name()"/>
  <xsl:with-param name="object-type" select="'resource'"/>
  <xsl:with-param name="object" select="@rdf:resource"/>
</xsl:call-template>

<xsl:apply-templates select="." mode="objects">
	<xsl:with-param name="parse-type" select="'RDF1.0-base'"/>
</xsl:apply-templates>

</xsl:template>

<!-- jab -->
<xsl:template match="*[@rdf:type]" mode="property-elements">
	<xsl:param name="subject"><xsl:call-template name="nodeIdentifier"/></xsl:param>
<xsl:if test="$trace">[TRACE *[@rdf:type] name=<xsl:value-of select="name()" /> property-elements]</xsl:if>
	<xsl:call-template name="generate-for-default-parse-type">
		<xsl:with-param name="subject" select="$subject"/>
	</xsl:call-template>
</xsl:template>
<!-- ************************************************************************** -->
<xsl:template name="generate-for-default-parse-type">
  <xsl:param name="subject"><xsl:call-template name="nodeIdentifier" /></xsl:param>
  <xsl:param name="parse-type" select="$defaultParseType"/>
  	<xsl:param name="type">
		<xsl:choose>
			<xsl:when test="@rdf:type"><xsl:value-of select="@rdf:type" /></xsl:when>
			<xsl:when test="rdf:type[@rdf:resource]"><xsl:value-of select="rdf:type/@rdf:resource" /></xsl:when>
			<xsl:when test="rdf:type"><xsl:value-of select="rdf:type" /></xsl:when>
			<xsl:otherwise><xsl:call-template name="QNameToURI" /></xsl:otherwise>
		</xsl:choose>
	</xsl:param>


<xsl:choose>
 <xsl:when test="$parse-type='Resource'">
<xsl:variable name="object">
  <xsl:choose>
  	<xsl:when test="@rdf:resource"><xsl:value-of select="@rdf:resource" /></xsl:when>
  	<xsl:otherwise>
	 <xsl:call-template name="resource-uri">
    	<xsl:with-param name="node" select="."/>
     </xsl:call-template>
  	</xsl:otherwise>
 </xsl:choose>
</xsl:variable>

<xsl:call-template name="generate-statement-string">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate-namespace-uri" select="namespace-uri()"/>
  <xsl:with-param name="predicate-local-name" select="local-name()"/>
  <xsl:with-param name="object-type" select="'resource'"/>
  <xsl:with-param name="object" select="$object"/>
</xsl:call-template>
<xsl:call-template name="generate-type-statement">
  <xsl:with-param name="subject"><xsl:call-template name="nodeIdentifier"/></xsl:with-param>
  <xsl:with-param name="type" select="$type" /><!-- select="concat(namespace-uri(), local-name())"/>-->
</xsl:call-template>
<xsl:call-template name="generate-statements">
  <xsl:with-param name="node" select="."/>
  <xsl:with-param name="subject" select="$object"/>
</xsl:call-template>

 </xsl:when>
 <xsl:when test="$parse-type='Literal'">
<xsl:call-template name="statement">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate" select="$type" />
  <xsl:with-param name="object-type" select="'literal'"/>
  <xsl:with-param name="object" select="*|text()"/>
</xsl:call-template>

 </xsl:when>
 <xsl:otherwise>
	<xsl:call-template name="generate-statement-string">
  		<xsl:with-param name="subject" select="$subject"/>
  		<xsl:with-param name="predicate-namespace-uri" select="namespace-uri()"/>
  		<xsl:with-param name="predicate-local-name" select="local-name()"/>
  		<xsl:with-param name="object-type" select="'literal'"/>
  		<xsl:with-param name="object" select="."/>
	</xsl:call-template>
 </xsl:otherwise>
</xsl:choose>	
</xsl:template>

<!--                                                                         -->

<xsl:template match="*[@rdf:parseType='Literal']" mode="property-elements">
	<xsl:param name="subject" />
	<xsl:param name="type">
		<xsl:choose>
			<xsl:when test="@rdf:type"><xsl:value-of select="@rdf:type" /></xsl:when>
			<xsl:when test="rdf:type[@rdf:resource]"><xsl:value-of select="rdf:type/@rdf:resource" /></xsl:when>
			<xsl:when test="rdf:type"><xsl:value-of select="rdf:type" /></xsl:when>
			<xsl:otherwise><xsl:call-template name="QNameToURI" /></xsl:otherwise>
		</xsl:choose>
	</xsl:param>

<xsl:call-template name="statement">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate"><xsl:call-template name="QNameToURI"/></xsl:with-param>
  <xsl:with-param name="object-type" select="'literal'"/>
  <xsl:with-param name="object" select="*|text()"/>
</xsl:call-template>

<xsl:call-template name="generate-type-statement">
  <xsl:with-param name="subject"><xsl:call-template name="nodeIdentifier"/></xsl:with-param>
  <xsl:with-param name="type" select="$type"/><!-- select="concat(namespace-uri(), local-name())"/>-->
</xsl:call-template>
</xsl:template>

<!--                                                                         -->

<xsl:template match="*[@rdf:parseType='Resource']" mode="property-elements">
	<xsl:param name="subject" />
	<xsl:param name="type">
		<xsl:choose>
			<xsl:when test="@rdf:type"><xsl:value-of select="@rdf:type" /></xsl:when>
			<xsl:when test="rdf:type[@rdf:resource]"><xsl:value-of select="rdf:type/@rdf:resource" /></xsl:when>
			<xsl:when test="rdf:type"><xsl:value-of select="rdf:type" /></xsl:when>
			<xsl:otherwise><xsl:call-template name="QNameToURI" /></xsl:otherwise>
		</xsl:choose>
	</xsl:param>

<xsl:if test="$trace">[TRACE *[@rdf:parseType='Resource'] name=<xsl:value-of select="name()" />]</xsl:if>
<xsl:variable name="object">
  <xsl:choose>
  <!-- jab -->
  	<xsl:when test="@rdf:resource"><xsl:value-of select="@rdf:resource" /></xsl:when>
  	<xsl:otherwise>
	 <xsl:call-template name="resource-uri">
    	<xsl:with-param name="node" select="."/>
     </xsl:call-template>
  	</xsl:otherwise>
 </xsl:choose>
</xsl:variable>

<xsl:call-template name="generate-statement-string">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate-namespace-uri" select="namespace-uri()"/>
  <xsl:with-param name="predicate-local-name" select="local-name()"/>
  <xsl:with-param name="object-type" select="'resource'"/>
  <xsl:with-param name="object" select="$object"/>
</xsl:call-template>
<xsl:call-template name="generate-type-statement">
  <xsl:with-param name="subject"><xsl:call-template name="nodeIdentifier"/></xsl:with-param>
  <xsl:with-param name="type" select="$type" /><!-- select="concat(namespace-uri(), local-name())"/>-->
</xsl:call-template>
<xsl:call-template name="generate-statements">
  <xsl:with-param name="node" select="."/>
  <xsl:with-param name="subject" select="$object"/>
</xsl:call-template>

</xsl:template>

<!-- 																		-->

<xsl:template match="*[@xlink:arcrole='http://www.w3.org/1999/xlink/properties/linkbase']" mode="property-elements">
	<xsl:apply-templates select="document(@xlink:href)/*[@xlink:type]" mode="property-elements"/>
</xsl:template>

<xsl:template match="*[@xlink:type='simple']" mode="property-elements">
	<xsl:call-template name="xlink-simple"/>
</xsl:template>

<xsl:template match="*[@xlink:type='extended']" mode="property-elements">
    <xsl:apply-templates select="*" mode="xlink-extended"/>
</xsl:template>

<!--																		-->  
<!-- jab this is an optimization for special elements which don't need to be a node -->
<!-- not needed for XML2RDF ? is skipping leaf nodes #type
<xsl:template match="*[not(*) and not(@*)]" mode="property-elements">
	<xsl:param name="subject" />
<xsl:if test="$trace">[TRACE *[not(*) and not(@*)] name=<xsl:value-of select="name()" />]</xsl:if>
	<xsl:call-template name="statement">
		<xsl:with-param name="predicate"><xsl:call-template name="QNameToURI"/></xsl:with-param>
		<xsl:with-param name="subject" select="$subject"/>
		<xsl:with-param name="object" select="text()"/>
		<xsl:with-param name="object-type" select="'literal'"/>
	</xsl:call-template>
</xsl:template>
-->
<!--                                                                         -->
<xsl:template match="*[@rdf:value and not(*) and (count(@*)=1) and text()[string-length(normalize-space())=0]]" mode="property-elements">
	<xsl:param name="subject" />
<xsl:if test="$trace">[TRACE *[@rdf:value and not(*) and count(@*)=1] name=<xsl:value-of select="name()" />]</xsl:if>
	<xsl:call-template name="statement">
		<xsl:with-param name="predicate"><xsl:call-template name="QNameToURI"/></xsl:with-param>
		<xsl:with-param name="subject" select="$subject"/>
		<xsl:with-param name="object" select="@rdf:value"/>
		<xsl:with-param name="object-type" select="'literal'"/>
	</xsl:call-template>
</xsl:template>
<!-- *********************************************************************** -->
<!-- jab alt syntax -->
<!--                                                                         -->

<xsl:template match="*[@resource]" mode="members">
  <xsl:param name="container"/>
<xsl:if test="$trace">[TRACE *[@resource] <xsl:value-of select="name()" /> members]</xsl:if>
<xsl:call-template name="generate-statement-string">
  <xsl:with-param name="subject" select="$container"/>
  <xsl:with-param name="predicate-namespace-uri" select="$rdf"/>
  <xsl:with-param name="predicate-local-name" select="concat('_', position())"/>
  <xsl:with-param name="object-type" select="'resource'"/>
  <xsl:with-param name="object" select="@resource"/>
</xsl:call-template>

</xsl:template>

<!--                                                                         -->

<!-- this is mostly a copy of the previous template with the resource
attribute explicitly in the rdf namespace. this isn't legal according to the
spec but it probably should be. -->

<xsl:template match="*[@rdf:resource]" mode="members">
  <xsl:param name="container"/>
<xsl:if test="$trace">[TRACE *[@rdf:resource] <xsl:value-of select="name()" /> members]</xsl:if>
<xsl:call-template name="generate-statement-string">
  <xsl:with-param name="subject" select="$container"/>
  <xsl:with-param name="predicate-namespace-uri" select="$rdf"/>
  <xsl:with-param name="predicate-local-name" select="concat('_', position())"/>
  <xsl:with-param name="object-type" select="'resource'"/>
  <xsl:with-param name="object" select="@rdf:resource"/>
</xsl:call-template>

</xsl:template>

<!--                                                                         -->

<xsl:template match="*" mode="members">
  <xsl:param name="container"/>
<xsl:if test="$trace">[TRACE * <xsl:value-of select="name()" /> members]</xsl:if>
<xsl:call-template name="generate-statement-string">
  <xsl:with-param name="subject" select="$container"/>
  <xsl:with-param name="predicate-namespace-uri" select="$rdf"/>
  <xsl:with-param name="predicate-local-name" select="concat('_', position())"/>
  <xsl:with-param name="object-type" select="'literal'"/>
  <xsl:with-param name="object" select="."/>
</xsl:call-template>

</xsl:template>
<!--                                                                         -->

<xsl:template match="*[*]" mode="members">
  <xsl:param name="container"/>
<xsl:if test="$trace">[TRACE *[*] <xsl:value-of select="name()" /> members]</xsl:if>
	<xsl:variable name="object"><xsl:call-template name="nodeIdentifier"/></xsl:variable>
	<xsl:call-template name="generate-statement-string">
  		<xsl:with-param name="subject" select="$container"/>
  		<xsl:with-param name="predicate-namespace-uri" select="$rdf"/>
  		<xsl:with-param name="predicate-local-name" select="concat('_', position())"/>
  		<xsl:with-param name="object-type" select="'resource'"/>
  		<xsl:with-param name="object" select="$object"/>
	</xsl:call-template>
	<xsl:call-template name="generate-type-statement">
		<xsl:with-param name="subject" select="$object" />
		<xsl:with-param name="type"><xsl:call-template name="QNameToURI" /></xsl:with-param>
	</xsl:call-template>
	<xsl:apply-templates select="*" mode="property-elements">
		<xsl:with-param name="subject" select="$object"/>
	</xsl:apply-templates>
</xsl:template>
<!--                                                                         -->

<xsl:template match="*[@*]" mode="members">
  <xsl:param name="container"/>
<xsl:if test="$trace">[TRACE *[@*] <xsl:value-of select="name()" /> members]</xsl:if>
	<xsl:variable name="object"><xsl:call-template name="nodeIdentifier"/></xsl:variable>
	<xsl:call-template name="generate-statement-string">
  		<xsl:with-param name="subject" select="$container"/>
  		<xsl:with-param name="predicate-namespace-uri" select="$rdf"/>
  		<xsl:with-param name="predicate-local-name" select="concat('_', position())"/>
  		<xsl:with-param name="object-type" select="'resource'"/>
  		<xsl:with-param name="object" select="$object"/>
	</xsl:call-template>
	<xsl:call-template name="generate-type-statement">
		<xsl:with-param name="subject" select="$object" />
		<xsl:with-param name="type"><xsl:call-template name="QNameToURI" /></xsl:with-param>
	</xsl:call-template>
	<xsl:apply-templates select="@*" mode="property-attributes">
		<xsl:with-param name="subject" select="$object"/>
	</xsl:apply-templates>
</xsl:template>

<!--                                                                         -->

<xsl:template match="rdf:li" mode="members">
  <xsl:param name="container"/>
<xsl:if test="$trace">[TRACE rdf:li members]</xsl:if>
<xsl:call-template name="generate-statement-string">
  <xsl:with-param name="subject" select="$container"/>
  <xsl:with-param name="predicate-namespace-uri" select="$rdf"/>
  <xsl:with-param name="predicate-local-name" select="concat('_', position())"/>
  <xsl:with-param name="object-type" select="'literal'"/>
  <xsl:with-param name="object" select="."/>
</xsl:call-template>
</xsl:template>
<!--                                                                         -->

<xsl:template match="rdf:li[@*]" mode="members">
  <xsl:param name="container"/>
<xsl:if test="$trace">[TRACE rdf:li[@*] <xsl:value-of select="name()" /> members]</xsl:if>
	<xsl:variable name="object"><xsl:call-template name="nodeIdentifier"/></xsl:variable>
	<xsl:call-template name="generate-statement-string">
  		<xsl:with-param name="subject" select="$container"/>
  		<xsl:with-param name="predicate-namespace-uri" select="$rdf"/>
  		<xsl:with-param name="predicate-local-name" select="concat('_', position())"/>
  		<xsl:with-param name="object-type" select="'resource'"/>
  		<xsl:with-param name="object" select="$object"/>
	</xsl:call-template>
	<xsl:apply-templates select="@*" mode="property-attributes">
		<xsl:with-param name="subject" select="$object"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="." mode="property-elements">
		<xsl:with-param name="subject" select="$container"/>
	</xsl:apply-templates>

</xsl:template>

<!--                                                                         -->

<xsl:template name="resource-uri">
  <xsl:param name="node" select="."/>

<xsl:choose>
  <xsl:when test="namespace-uri($node) = $rdf and $node/@about">
    <xsl:value-of select="$node/@about"/>
  </xsl:when>
  <xsl:when test="$node/@rdf:about">
    <xsl:value-of select="$node/@rdf:about"/>
  </xsl:when>
  <xsl:when test="namespace-uri($node) = $rdf and $node/@resource">
    <xsl:value-of select="$node/@resource"/>
  </xsl:when>
  <xsl:when test="namespace-uri($node) != $rdf and $node/@rdf:resource">
    <xsl:value-of select="$node/@rdf:resource"/>
  </xsl:when>
  <!--<xsl:when test="namespace-uri($node) != $rdf and $node/@rdf:about">
    <xsl:value-of select="$node/@rdf:about"/>
  </xsl:when>-->
  <xsl:when test="$node/@ID">
    <xsl:value-of select="concat('#', $node/@ID)"/>
  </xsl:when>
  <xsl:when test="$node/@rdf:ID">
    <xsl:value-of select="concat('#', $node/@rdf:ID)"/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="nodeIdentifier">
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>
    <!--<xsl:call-template name="anonymous-uri">
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>-->
  </xsl:otherwise>
</xsl:choose>

</xsl:template>

<!--                                                                         -->

<xsl:template name="container-uri">
  <xsl:param name="node" select="."/>

<xsl:choose>
  <xsl:when test="namespace-uri($node) = $rdf and $node/@ID">
    <xsl:value-of select="concat('#', $node/@ID)"/>
  </xsl:when>
  <xsl:when test="namespace-uri($node) != $rdf and $node/@rdf:ID">
    <xsl:value-of select="concat('#', $node/@rdf:ID)"/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="nodeIdentifier">
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>
    <!--<xsl:call-template name="anonymous-uri">
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>-->
  </xsl:otherwise>
</xsl:choose>

</xsl:template>


<!--                                                                         -->

<xsl:template name="generate-statement-string">
  <xsl:param name="subject"/>
  <xsl:param name="predicate-namespace-uri"/>
  <xsl:param name="predicate-local-name"/>
  <xsl:param name="object-type"/>
  <xsl:param name="object"/>
  <!--<xsl:variable name="otype">
  	<xsl:choose>
		<xsl:when test="$object-type='literal'"><xsl:value-of select="$rdfsLiteralType" /></xsl:when>
		<xsl:when test="$object-type='resource'"><xsl:value-of select="$rdfsResourceType" /></xsl:when>
		<xsl:otherwise><xsl:value-of select="$object-type" /></xsl:otherwise>
	</xsl:choose>
 </xsl:variable>-->
<xsl:if test="$trace">
[TRACE gen-stat-string
	pred(ns,loc)=<xsl:value-of select="$predicate-namespace-uri" />:<xsl:value-of select="$predicate-local-name" />
]
</xsl:if>
<xsl:call-template name="statement">
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate"><xsl:call-template name="QNameToURI"><xsl:with-param name="namespace-name" select="$predicate-namespace-uri"/><xsl:with-param name="local-name" select="$predicate-local-name"/></xsl:call-template></xsl:with-param>
  <xsl:with-param name="object-type" select="$object-type"/>
  <xsl:with-param name="object" select="string($object)"/>
</xsl:call-template>

</xsl:template>

<!--                                                                         -->

<xsl:template name="generate-statement">
  <xsl:param name="subject"/>
  <xsl:param name="predicate-namespace-uri"/>
  <xsl:param name="predicate-local-name"/>
  <xsl:param name="object-type"/>
  <xsl:param name="object"/>
<xsl:if test="$trace">[TRACE gen-statement
	name=<xsl:value-of select="name()" />
	predicate=<xsl:value-of select="$predicate-namespace-uri" />:<xsl:value-of select="$predicate-local-name" />
	subject=<xsl:value-of select="$subject" />
	object=<xsl:value-of select="$object" />
]</xsl:if>

<xsl:call-template name="statement">
  <xsl:with-param name="predicate"><xsl:call-template name="QNameToURI"><xsl:with-param name="namespace-name" select="$predicate-namespace-uri"/><xsl:with-param name="local-name" select="$predicate-local-name"/></xsl:call-template></xsl:with-param><!--<xsl:value-of select="concat($predicate-namespace-uri, $predicate-local-name)"/>-->
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="object" select="$object"/>
  <xsl:with-param name="object-type" select="$object-type"/>
 </xsl:call-template>
</xsl:template>
<!-- ******************************************************************* -->
<xsl:template name="statement">
  <xsl:param name="subject"/>
  <xsl:param name="predicate"/>
  <xsl:param name="object-type"/>
  <xsl:param name="object"/>

<rdf:Statement>
  <rdf:predicate rdf:resource="{$predicate}" />
  <rdf:subject rdf:resource="{$subject}"/>
  <xsl:choose>
		<xsl:when test="$object-type='literal'">
  			<rdf:object><xsl:copy-of select="$object"/></rdf:object>
		</xsl:when>
		<xsl:when test="$object-type='resource'">
  			<rdf:object rdf:resource="{$object}" />
		</xsl:when>
	</xsl:choose>
</rdf:Statement>

</xsl:template>

<!--                                                                         -->

<xsl:template name="generate-description-statements">

  <xsl:param name="node" select="."/>
  <xsl:param name="subject">
    <xsl:call-template name="resource-uri">
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>
  </xsl:param>
<xsl:if test="$trace">[TRACE gen-description-statements
	node=<xsl:value-of select="name($node)" />
	subject=<xsl:value-of select="$subject" />
]</xsl:if>
  <xsl:variable name="reified-statement"><xsl:value-of select="$node/@bagID"/></xsl:variable>

  <xsl:apply-templates select="$node/@*" mode="property-attributes">
  	<xsl:with-param name="subject" select="$subject"/>
  </xsl:apply-templates>

  <xsl:choose>
  	<xsl:when test="string-length(normalize-space($reified-statement))&gt;0">
	  <rdf:Bag ID="{$reified-statement}">
		<xsl:apply-templates select="$node/*" mode="property-elements">
  			<xsl:with-param name="subject" select="$subject"/>
  			<xsl:with-param name="reified-statement" select="$reified-statement"/>
			<xsl:with-param name="parse-type" select="'RDF1.0-base'"/>
  		</xsl:apply-templates>
	  </rdf:Bag>
	</xsl:when>
	<xsl:otherwise>  
		<xsl:apply-templates select="$node/*" mode="property-elements">
  			<xsl:with-param name="subject" select="$subject"/>
  			<xsl:with-param name="reified-statement" select="$reified-statement"/>
			<xsl:with-param name="parse-type" select="'RDF1.0-base'"/>
  		</xsl:apply-templates>
	</xsl:otherwise>
  </xsl:choose>
<xsl:if test="$trace">[-- gen-description-statments]</xsl:if>
</xsl:template>
<!--                                                                         -->

<xsl:template name="generate-statements-about-each">
  <xsl:param name="node"/>
  <xsl:param name="about-each"/>
  <xsl:param name="type"/>
<xsl:variable name="id">
  <xsl:choose>
    <xsl:when test="starts-with($about-each, '#')">
      <xsl:value-of select="substring-after($about-each, '#')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$about-each"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!--<xsl:for-each select="//rdf:*[@ID=$id]/rdf:li">-->
<!-- jab - alt syntax -->
<xsl:for-each select="//rdf:*[@ID=$id]/*">
	<xsl:variable name="res">
		<xsl:choose>
			<xsl:when test="@rdf:resource"><xsl:value-of select="@rdf:resource" /></xsl:when>
			<xsl:when test="(namespace-uri()=$rdfNS) and (@resource)"><xsl:value-of select="@resource" /></xsl:when>
			<xsl:otherwise><xsl:call-template name="nodeIdentifier"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
  <xsl:if test="$type">
    <xsl:call-template name="generate-type-statement">
      <xsl:with-param name="subject" select="$res"/>
      <xsl:with-param name="type" select="$type"/>
    </xsl:call-template>
  </xsl:if>

  <xsl:call-template name="generate-statements">
    <xsl:with-param name="node" select="$node"/>
    <xsl:with-param name="subject" select="$res"/>
  </xsl:call-template>

</xsl:for-each>

</xsl:template>

<!--                                                                         -->

<xsl:template name="generate-statements">

  <xsl:param name="node" select="."/>
  <xsl:param name="subject">
    <xsl:call-template name="resource-uri">
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>
  </xsl:param>
<xsl:if test="$trace">
[TRACE gen-statements
	node=<xsl:value-of select="name($node)" />
	subject=<xsl:value-of select="$subject" />
]
</xsl:if>
<xsl:variable name="reified-statement">
  <xsl:value-of select="$node/@bagID"/>
</xsl:variable>

<xsl:apply-templates select="$node/@*" mode="property-attributes">
  <xsl:with-param name="subject" select="$subject"/>
</xsl:apply-templates>

  <xsl:choose>
  	<xsl:when test="string-length(normalize-space($reified-statement))&gt;0">
	  <rdf:Bag ID="{$reified-statement}">
		<xsl:apply-templates select="$node/*" mode="property-elements">
  			<xsl:with-param name="subject" select="$subject"/>
  			<xsl:with-param name="reified-statement" select="$reified-statement"/>
			<xsl:with-param name="parse-type" select="'RDF1.0-base'"/>
  		</xsl:apply-templates>
	  </rdf:Bag>
	</xsl:when>
	<xsl:otherwise>  
		<xsl:apply-templates select="$node/*" mode="property-elements">
  			<xsl:with-param name="subject" select="$subject"/>
  			<xsl:with-param name="reified-statement" select="$reified-statement"/>
			<xsl:with-param name="parse-type" select="$defaultParseType"/>
  		</xsl:apply-templates>
	</xsl:otherwise>
  </xsl:choose>

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
<xsl:if test="$trace">
[-- gen-statements]
</xsl:if>
</xsl:template>
<!-- *************************************************************************	
			XLink templates
     *************************************************************************	-->
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

<!-- *************************************************************************	
			Function templates
     *************************************************************************	-->
<xsl:template name="childSeq">
	<xsl:param name="node" select="."/>
	<xsl:for-each select="$node/ancestor-or-self::*">/<xsl:value-of select="1 + count(preceding-sibling::*)"/></xsl:for-each>
</xsl:template>
<!-- 																	-->
<xsl:template name="nodeIdentifier">
	<xsl:param name="node" select="."/>
	<xsl:choose>
		<!--<xsl:when test="@rdf:instance"><xsl:value-of select="@rdf:instance" /></xsl:when>-->
		<xsl:when test="$node/@rdf:resource"><xsl:value-of select="$node/@rdf:resource" /></xsl:when>
		<xsl:when test="$node/@ID">#<xsl:value-of select="$node/@ID" /></xsl:when>
		<xsl:when test="$node/@rdf:ID">#<xsl:value-of select="$node/@rdf:ID" /></xsl:when>
		<xsl:when test="$explicitPathIndices='ChildSeq'">#<xsl:call-template name="childSeq" ><xsl:with-param name="node" select="$node"/></xsl:call-template></xsl:when>
		<xsl:otherwise>#xpointer(<xsl:call-template name="pathName" ><xsl:with-param name="node" select="$node"/></xsl:call-template>)</xsl:otherwise>
	</xsl:choose>
</xsl:template>
<!-- 																	-->
<xsl:template name="QNameToURI">
	<xsl:param name="sep" select="'#'"/>
	<xsl:param name="node" select="."/>
	<xsl:param name="namespace-name" select="namespace-uri($node)"/>
	<xsl:param name="local-name" select="local-name($node)"/>
	<xsl:param name="local-name-len" select="string-length($local-name)"/>
	<xsl:variable name="nslen" select="string-length($namespace-name)"/>
	<xsl:variable name="base">
		<xsl:choose>
			<xsl:when test="$nslen > 0"></xsl:when>
			<xsl:when test="$node/ancestor-or-self::*/@xml:base"><xsl:value-of select="$node/ancestor-or-self::*/@xml:base" /></xsl:when>
<!--
			<xsl:when test="function-available('saxon:system-id')"><xsl:value-of select="saxon:system-id()" /></xsl:when>
-->
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="firstLNChar" select="substring($local-name,1,1)"/>
	<xsl:variable name="lastNSChar" select="substring($namespace-name,$nslen)"/>
<xsl:if test="$QNameTrace">[TRACE qnuri
	node=<xsl:value-of select="name($node)" />
	nsn=<xsl:value-of select="$namespace-name" />
	ln=<xsl:value-of select="$local-name" />
	first='<xsl:value-of select="$firstLNChar" />'
]</xsl:if>
	<xsl:choose>
		<!--<xsl:when test="$node/@ID">#<xsl:value-of select="$node/@ID" /></xsl:when>
		<xsl:when test="$node/@rdf:ID">#<xsl:value-of select="$node/@rdf:ID" /></xsl:when>-->
		<xsl:when test="($nslen = 0) and ($firstLNChar='#')"><xsl:value-of select="concat($base,$local-name)" /></xsl:when>
		<xsl:when test="$nslen = 0"><xsl:value-of select="concat($base,$sep,$local-name)" /></xsl:when>
		<xsl:when test="($firstLNChar='#') or ($lastNSChar='#') or ($lastNSChar='/') or ($lastNSChar='\')"><xsl:value-of select="concat($namespace-name,$local-name)" /></xsl:when>
		<xsl:otherwise><xsl:value-of select="concat($namespace-name,$sep,$local-name)" /></xsl:otherwise>
	</xsl:choose>
</xsl:template>
<!-- 																	-->
<xsl:template name="pathName">
  <xsl:param name="node" select="."/>
  <xsl:for-each select="$node/ancestor-or-self::*">
    <xsl:variable name="nodename" select="name()" />
    <xsl:text>/</xsl:text>
    <xsl:value-of select="$nodename" />
	<xsl:choose>
	  <xsl:when test="$explicitPathIndices">
		<xsl:text>[</xsl:text>
    	<xsl:value-of select="1 + count(preceding-sibling::*[name() = $nodename])"/>
    	<xsl:text>]</xsl:text>
	  </xsl:when>
	  <xsl:when test="@*[not(namespace-uri()=$rdfNS) and not(namespace-uri() = $xlinkNS)]">    
		<xsl:text>[</xsl:text>
		<xsl:for-each select="@*[not(namespace-uri()=$rdfNS) and not(namespace-uri() = $xlinkNS)]">@<xsl:value-of select="name()" />='<xsl:value-of select="." />'<xsl:if test="not(position() = last())"> and </xsl:if></xsl:for-each>
    	<xsl:text>]</xsl:text>
	  </xsl:when>  
	</xsl:choose>  
 </xsl:for-each>
</xsl:template>
</xsl:stylesheet>
