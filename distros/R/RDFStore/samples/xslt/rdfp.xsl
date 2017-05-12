<?xml version='1.0'?>
<!-- 
	extended and modified by Jonathan Borden at http://www.openhealth.org/RDF/rdfp.xsl	
	original by Dan Connolly at http://www.w3.org/XML/2000/04rdf-parse/rdfp.xsl

	- handles strawman RDF syntax for colloquial XML 
	- see http://www.openhealth.org/RDF/rdf_Syntax_and_Names.htm
	- uses XPointer fragments for 'anonymous' node URIs
	- creates XPaths from either position() or attribute values
	- support for XLink - RDF
	
	Version 9/12/2000
-->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfp="http://www.w3.org/XML/2000/04/rdf-parse/#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	exclude-result-prefixes='xsl rdf rdfs rdfp xlink'>
<!-- an RDF parser in XSLTfor now, just the basic RDF syntax per2.2.1. Basic Serialization Syntaxofhttp://www.w3.org/TR/1999/REC-rdf-syntax-19990222$Id: rdfp.xsl,v 1.1.1.1 2002/06/17 09:30:52 areggiori Exp $-->
  <xsl:output method='xml' version="1.0" indent='yes'/>
  <xsl:variable name='rdfNS' select='"http://www.w3.org/1999/02/22-rdf-syntax-ns#"'/>
  <xsl:variable name='rdfsNS' select='"http://www.w3.org/2000/01/rdf-schema#"'/>  
  <xsl:variable name='xlinkNS' select='"http://www.w3.org/1999/xlink"'/>
  <xsl:variable name='uriReferenceType' select='"http://www.w3.org/1999/XMLSchema#datatype_uriReference"'/>
  <xsl:variable name='stringType' select='"http://www.w3.org/1999/XMLSchema#datatype_string"'/>
<xsl:param name="explicitPathIndices" />
<xsl:param name="trace" />
<xsl:template match="/">
    <webdata>
		<xsl:apply-templates />
    </webdata>
</xsl:template>
<xsl:template match="*">
<!-- 
	jb: handle colloquial XML + strawman RDF
	just call propertyElt_s
-->
    <xsl:call-template name='rdfp:propertyElt_s'>
        <xsl:with-param name='node' select='.'/>
        <xsl:with-param name='subject'><xsl:call-template name="rdfp:nodeIdentifier"/></xsl:with-param>
     </xsl:call-template>
     <xsl:call-template name='rdfp:propAttr_s'>
        <xsl:with-param name='subject'><xsl:call-template name="rdfp:nodeIdentifier"/></xsl:with-param>
     </xsl:call-template>
</xsl:template>
<!-- @@argh! how do I refer to XML Schema datatypes?  PLEASE can I have a canonical URI, in the appinfo, along with the has-facet stuff? -->
  <xsl:template match='rdf:RDF'>
<!-- [1] RDF -->
<!-- the syntax for the results per http://www.ilrt.bris.ac.uk/discovery/rdf-dev/rudolf/js-rdf/ -->
      <xsl:for-each select='text()[string-length(normalize-space())&gt;0]'>
        <xsl:call-template name='rdfp:badStuff'>
          <xsl:with-param name='expected' select='"description"'/>
        </xsl:call-template>
      </xsl:for-each>
      <xsl:call-template name='rdfp:description_s'/>
  </xsl:template>

  <xsl:template name='rdfp:description_s'>
    <xsl:param name='parentSubject'/>
    <xsl:param name='parentPredicate'/>
<xsl:if test="$trace">[TRACE description_s
	parentSubject=<xsl:value-of select="$parentSubject" />
	parentPredicate=<xsl:value-of select="$parentPredicate" />
	name=<xsl:value-of select="name()" />
]</xsl:if>
    <xsl:for-each select='*'>
<xsl:if test="$trace">[TRACE description_s name=<xsl:value-of select="name()" />]</xsl:if>
<!-- [2] description -->
      <xsl:variable name='node' select='.'/>
      <xsl:choose>
<!-- REVIEW: about vs. rdf:about?
reported Wed, 26 Apr 2000 05:12:05 -0500
http://lists.w3.org/Archives/Public/www-rdf-comments/2000AprJun/0019.html
 -->
        <xsl:when test='(@rdf:ID and @rdf:about) or (namespace-uri() = $rdfNS and @ID and @about)'>

          <xsl:call-template name='rdfp:badElement'>
            <xsl:with-param name='problem' select='"ID and about attribute"'/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when test='@rdf:ID'>
          <xsl:call-template name='rdfp:propertyElt_s'>
            <xsl:with-param name='node' select='$node'/>
            <xsl:with-param name='subject' select='concat("#", @rdf:ID)'/>
            <xsl:with-param name='parentSubject' select='$parentSubject'/>
            <xsl:with-param name='parentPredicate' select='$parentPredicate'/>
          </xsl:call-template>

          <xsl:call-template name='rdfp:propAttr_s'>
            <xsl:with-param name='subject' select='concat("#", @rdf:ID)'/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when test='(namespace-uri() = $rdfNS) and @ID'>
          <xsl:call-template name='rdfp:propertyElt_s'>
            <xsl:with-param name='node' select='$node'/>
            <xsl:with-param name='subject' select='concat("#", @ID)'/>
            <xsl:with-param name='parentSubject' select='$parentSubject'/>
            <xsl:with-param name='parentPredicate' select='$parentPredicate'/>
          </xsl:call-template>

          <xsl:call-template name='rdfp:propAttr_s'>
            <xsl:with-param name='subject' select='concat("#", @ID)'/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when test="@rdf:about">
          <xsl:call-template name='rdfp:propertyElt_s'>
            <xsl:with-param name='node' select='$node'/>
            <xsl:with-param name='subject' select='@rdf:about'/>
            <xsl:with-param name='parentSubject' select='$parentSubject'/>
            <xsl:with-param name='parentPredicate' select='$parentPredicate'/>
          </xsl:call-template>

          <xsl:call-template name='rdfp:propAttr_s'>
            <xsl:with-param name='subject' select='@rdf:about'/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when test='(namespace-uri() = $rdfNS) and @about'>
          <xsl:call-template name='rdfp:propertyElt_s'>
            <xsl:with-param name='node' select='$node'/>
            <xsl:with-param name='subject' select='@about'/>
            <xsl:with-param name='parentSubject' select='$parentSubject'/>
            <xsl:with-param name='parentPredicate' select='$parentPredicate'/>
          </xsl:call-template>

          <xsl:call-template name='rdfp:propAttr_s'>
            <xsl:with-param name='subject' select='@about'/>
          </xsl:call-template>
        </xsl:when>
		<xsl:when test='@xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase"'>
			<xsl:apply-templates select="document(@xlink:href)"/>
		</xsl:when>
		<!-- per http://www.w3.org/XML/2000/09/xlink2rdf.htm -->
		<xsl:when test="@xlink:simple">
      		<xsl:call-template name='rdfp:statement'>
        		<xsl:with-param name='subject'>
					<xsl:call-template name="rdfp:nodeIdentifier"/>
				</xsl:with-param>
        		<xsl:with-param name='predicate'>
					<xsl:choose>
						<xsl:when test="@xlink:arcrole"><xsl:value-of select="@xlink:arcrole" /></xsl:when>
						<xsl:otherwise><xsl:value-of select="concat(namespace-uri(.),local-name(.))" /></xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
        		<xsl:with-param name='object' select='@xlink:href'/>
        		<xsl:with-param name='objectType' select='$uriReferenceType'/>
      		</xsl:call-template>
			<xsl:if test="@xlink:role">
      		<xsl:call-template name='rdfp:statement'>
        		<xsl:with-param name='subject'><xsl:value-of select="@xlink:role" /></xsl:with-param>
        		<xsl:with-param name='predicate'><xsl:value-of select='concat($rdfNS,"type")' /></xsl:with-param>
        		<xsl:with-param name='object' select='@xlink:href'/>
        		<xsl:with-param name='objectType' select='$uriReferenceType'/>
      		</xsl:call-template>
      		<xsl:call-template name='rdfp:statement'>
        		<xsl:with-param name='subject'><xsl:value-of select='concat($rdfsNS,"Class")' /></xsl:with-param>
        		<xsl:with-param name='predicate'><xsl:value-of select='concat($rdfNS,"type")' /></xsl:with-param>
        		<xsl:with-param name='object' select='@xlink:href'/>
        		<xsl:with-param name='objectType' select='$uriReferenceType'/>
      		</xsl:call-template>
			</xsl:if>
		</xsl:when>
		<xsl:when test="@xlink:type='extended'">
			... TODO ...
		</xsl:when>
        <xsl:otherwise>
          <!--<xsl:variable name='genid' select='concat("#,", generate-id())'/>-->
		  <xsl:variable name="genid"><xsl:call-template name="rdfp:nodeIdentifier" /></xsl:variable>

<!-- @@hmm... what subject to use for an anonymous node?TimBL mentioned that RDF syntax for nodes denotes an existentialquantifier... it didn't make sense to me at first, but yesterday(21 apr 2000) I realized that anonymous nodes are like skolemfunctions, and skolem functions are used to represent existentialquantifiers in horn clauses (cf discussion with Boyer in Austin).... which reminds me: the skolem function needs to varyw.r.t. all the universally quantified variables at this point inthe expression. So... @@when we add variables/forall,don't forget to tweak this. We probably need a "free variables"parameter to most of the templates here.Hmm... why should only anonymous nodes get "skolemized"?I wonder if IDentified nodes also represent existentials.I suppose about='..' should be treated as a constant,not an existential.-->
          <xsl:call-template name='rdfp:propertyElt_s'>
            <xsl:with-param name='node' select='$node'/>
            <xsl:with-param name='subject' select='$genid'/>
            <xsl:with-param name='parentSubject' select='$parentSubject'/>
            <xsl:with-param name='parentPredicate' select='$parentPredicate'/>
          </xsl:call-template>

          <xsl:call-template name='rdfp:propAttr_s'>
            <xsl:with-param name='subject' select='$genid'/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="rdfp:propertyElt_s">

    <xsl:param name='subject'/>
<!-- @@expand w.r.t. base? -->
    <xsl:param name='parentSubject'/>
    <xsl:param name='parentPredicate'/>
    <xsl:param name='node'/>
<xsl:if test="$trace">
[TRACE propertyElt_s
		subject=<xsl:value-of select="$subject" />
		parentSubject=<xsl:value-of select="$parentSubject" />
		parentPredicate=<xsl:value-of select="$parentPredicate" />
		name=<xsl:value-of select="name()" />
]</xsl:if>

    <xsl:if test='$parentPredicate'>
      <xsl:call-template name='rdfp:statement'>
        <xsl:with-param name='subject' select='$parentSubject'/>
        <xsl:with-param name='predicate' select='$parentPredicate'/>
        <xsl:with-param name='object' select='$subject'/>
        <xsl:with-param name='objectType' select='$uriReferenceType'/>
      </xsl:call-template>
    </xsl:if>

<!-- [17] typedNode -->
    <xsl:if test='$node and (namespace-uri($node) != $rdfNS or local-name($node) != "Description")'>
	  <xsl:variable name="obj">
	  	<xsl:choose>
			<xsl:when test="$node/@rdf:type"><xsl:value-of select="$node/@rdf:type" /></xsl:when>
			<xsl:when test="$node/@rdf:resource"><xsl:value-of select='concat($rdfNS,"Property")' /></xsl:when>
			<xsl:otherwise><xsl:value-of select='concat(namespace-uri($node), local-name($node))' /></xsl:otherwise>
		</xsl:choose>
	 </xsl:variable>
      <xsl:call-template name='rdfp:statement'>
        <xsl:with-param name='subject' select='$subject'/>
        <xsl:with-param name='predicate' select='concat($rdfNS, "type")'/>
        <xsl:with-param name='object' select='$obj'/>
        <xsl:with-param name='objectType' select='$uriReferenceType'/>
      </xsl:call-template>
    </xsl:if>
<!-- this becomes common child element handler -->
    <xsl:for-each select='*'>
		<xsl:call-template name="rdfp:typedElement_s">
			<xsl:with-param name='subject' select="$subject"/>
    		<xsl:with-param name='parentSubject' select="$parentSubject"/>
    		<xsl:with-param name='parentPredicate' select="$parentPredicate"/>
    		<xsl:with-param name='node' select="$node"/>
		</xsl:call-template>
    </xsl:for-each>

    <xsl:for-each select='text()[string-length(normalize-space())&gt;0]'>
   <!--  jb <xsl:call-template name='rdfp:badStuff'>
        <xsl:with-param name='expected' select='"description"'/>
      </xsl:call-template>-->
      <xsl:call-template name="rdfp:statement">
        <xsl:with-param name='subject' select="$subject"/>
        <xsl:with-param name='predicate' select='concat($rdfNS,"value")'/>
        <xsl:with-param name='object'>
          <xsl:value-of select='.'/>
        </xsl:with-param>
        <xsl:with-param name='objectType' select='$stringType'/>
      </xsl:call-template>
    </xsl:for-each>	
<xsl:if test="$trace">[-propertyElt_s]</xsl:if>  
</xsl:template>

  <xsl:template name="rdfp:propAttr_s">
    <xsl:param name='subject'/>

<!-- @@expand w.r.t. base? -->
    <xsl:for-each select='@*[(namespace-uri() != $xlinkNS) or not ((local-name() = "about" or local-name() = "resource" or local-name() = "ID" or local-name() = "bagID" or local-name() = "aboutEach" or local-name() = "aboutEachPrefix") and (namespace-uri() = $rdfNS or namespace-uri(current()) = $rdfNS) ) ]'>

      <xsl:call-template name='rdfp:statement'>
        <xsl:with-param name='subject' select='$subject'/>
        <xsl:with-param name='predicate' select='concat(namespace-uri(.), local-name(.))'/>
        <xsl:with-param name='object'>
          <xsl:value-of select='.'/>
        </xsl:with-param>
        <xsl:with-param name='objectType' select='$stringType'/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="rdfp:statement">
    <xsl:param name='subject'/>

<!-- @@expand w.r.t. base? -->
    <xsl:param name='predicate'/>
    <xsl:param name='object'/>
    <xsl:param name='objectType'/>

    <arc>
      <subject>
        <xsl:value-of select='$subject'/>
      </subject>

      <predicate>
        <xsl:value-of select='$predicate'/>
      </predicate>

      <xsl:choose>
        <xsl:when test='$objectType = $uriReferenceType'>
          <webobject>
            <xsl:value-of select='$object'/>
          </webobject>
        </xsl:when>

        <xsl:when test='$objectType = $stringType'>
          <object>
            <xsl:value-of select='$object'/>
          </object>
        </xsl:when>

<!-- @@parsetype literal will give us content here -->
        <xsl:otherwise>
          <xsl:message>unknown object type: 
          <xsl:value-of select='$objectType'/>
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </arc>
  </xsl:template>
  <!-- jb: break this out so it can be twiddled -->
<xsl:template name="rdfp:typedElement_s">
<!-- @@expand w.r.t. base? -->
    <xsl:param name='parentSubject'/>
    <xsl:param name='parentPredicate'/>
    <xsl:param name='node' select='.'/>
	<xsl:variable name="thissubj"><xsl:call-template name="rdfp:nodeIdentifier" /></xsl:variable>
	<xsl:param name="subject" select="$thissubj"/>
<xsl:if test="$trace">
[TRACE typedElement_s 
	parentSubj=<xsl:value-of select="$parentSubject" />
	parentPred=<xsl:value-of select="$parentPredicate" />
	subject=<xsl:value-of select="$subject" />
	name=<xsl:value-of select="name()" />]
</xsl:if>
<!-- [6] propertyElt -->
      <xsl:variable name='predicate' select='concat(namespace-uri(), local-name())'/>

      <xsl:choose>
<!-- [8] value -->
        <xsl:when test='text()[string-length(normalize-space())&gt;0] and *'>
          <xsl:call-template name='rdfp:badElement'>
            <xsl:with-param name='problem' select='"text and subelements mixed in property value"'/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when test='text()[string-length(normalize-space())&gt;0]'>
<!-- @@ barf if any attrs except ID -->
          <xsl:call-template name='rdfp:statement'>
<!-- @@parameterize the template to call for each statement? -->
            <xsl:with-param name='subject' select="$subject"/>
            <xsl:with-param name='predicate' select='$predicate'/>
            <xsl:with-param name='object'>
              <xsl:copy-of select='text()'/>
            </xsl:with-param>

            <xsl:with-param name='objectType' select='$stringType'/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when test='*'>
<!-- jb: insert this -->
		  <xsl:call-template name="rdfp:propertyElt_s">
		    <xsl:with-param name='subject'><xsl:call-template name="rdfp:nodeIdentifier"/></xsl:with-param>
    		<xsl:with-param name='parentSubject' select="$subject"/>
    		<xsl:with-param name='parentPredicate' select="$predicate"/>
    		<xsl:with-param name='node' select="."/>
		  </xsl:call-template>
<!-- jb: no: @@ barf if any attrs except ID -->
          <xsl:call-template name='rdfp:description_s' >
          </xsl:call-template>
		  <xsl:call-template name="rdfp:propAttr_s">
            	<xsl:with-param name='subject' select="$thissubj"/>
          </xsl:call-template>

        </xsl:when>

<!-- @@parseLiteral and parseResource -->
        <xsl:when test='@rdf:resource or (namespace-uri()=$rdfNS and @resource)'>
          <xsl:for-each select='text()[string-length(normalize-space())&gt;0]|*'>
            <xsl:call-template name='rdfp:badElement'>
              <xsl:with-param name='problem' select='"propertyElt with resource attribute should be empty"'/>
            </xsl:call-template>
          </xsl:for-each>

          <xsl:variable name='resAttr' select='@*[local-name()="resource" and namespace-uri()=$rdfNS or namespace-uri(current()) = $rdfNS]'/>

          <xsl:call-template name='rdfp:statement'>
            <xsl:with-param name='subject' select='$subject'/>
            <xsl:with-param name='predicate' select='$predicate'/>
            <xsl:with-param name='object' select='$resAttr'/>
            <xsl:with-param name='objectType' select='$uriReferenceType'/>
          </xsl:call-template>

<!-- [16] propAttr -->
          <xsl:call-template name='rdfp:propAttr_s'>
            <xsl:with-param name='subject' select='$resAttr'/>
          </xsl:call-template>
        </xsl:when>

        <xsl:otherwise>
<!-- [16] propAttr -->
<!--@@ idAttr, bagIdAttr -->
          <!--<xsl:variable name='genid' select='concat("#,", generate-id())'/>-->
		  <xsl:variable name="genid"><xsl:call-template name="rdfp:nodeIdentifier" /></xsl:variable>

          <xsl:call-template name='rdfp:propAttr_s'>
            <xsl:with-param name='subject' select='$genid'/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
<xsl:if test="$trace">[-typedElt]</xsl:if>
</xsl:template>
  <xsl:template name='rdfp:badStuff'>
    <xsl:param name='expected'/>

    <xsl:message>expected 
    <xsl:value-of select='$expected'/>

    but got: [[
    <xsl:copy-of select='.'/>

    ]]</xsl:message>
  </xsl:template>

  <xsl:template name='rdfp:badElement'>
    <xsl:param name='problem'/>

    <xsl:message>problem in &lt;<xsl:value-of select='name(.)'/>&gt;: 
    <xsl:value-of select='$problem'/>
    </xsl:message>
  </xsl:template>
<xsl:template name="rdfp:pathName">
  <xsl:for-each select="ancestor-or-self::*">
    <xsl:variable name="nodename" select="name()" />
    <xsl:text>/</xsl:text>
    <xsl:value-of select="$nodename" />
	<xsl:choose>
	  <xsl:when test="$explicitPathIndices">
		<xsl:text>[</xsl:text>
    	<xsl:value-of select="1 + count(preceding-sibling::*[name() = $nodename])"/>
    	<xsl:text>]</xsl:text>
	  </xsl:when>
	  <xsl:when test="@*[not(namespace-uri()=$rdfNS)]">    
		<xsl:text>[</xsl:text>
		<xsl:for-each select="@*[not(namespace-uri()=$rdfNS)]">@<xsl:value-of select="name()" />='<xsl:value-of select="." />'<xsl:if test="position() != last()"> and </xsl:if></xsl:for-each>
    	<xsl:text>]</xsl:text>
	  </xsl:when>  
	</xsl:choose>  
 </xsl:for-each>
</xsl:template>
<xsl:template name="rdfp:nodeIdentifier">
	<xsl:choose>
		<xsl:when test="@rdf:instance"><xsl:value-of select="@rdf:instance" /></xsl:when>
		<xsl:when test="@rdf:resource"><xsl:value-of select="@rdf:resource" /></xsl:when>
		<xsl:otherwise>#xpointer(<xsl:call-template name="rdfp:pathName" />)</xsl:otherwise>
	</xsl:choose>
</xsl:template>
</xsl:stylesheet>
