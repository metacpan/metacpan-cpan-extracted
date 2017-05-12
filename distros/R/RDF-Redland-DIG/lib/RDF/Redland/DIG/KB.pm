package RDF::Redland::DIG::KB;

use strict;
use warnings;

use constant CREATE_KB => q|<?xml version="1.0"?>
<newKB xmlns="http://dl.kr.org/dig/2003/02/lang"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
|;

# Primitive Concept Retrieval

use constant ASK_ALLCONCEPTNAMES => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<allConceptNames id="acn"/>
	</asks>
</xsl:template>
</xsl:stylesheet>
|;

use constant ASK_ALLROLENAMES => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<allRoleNames id="arn"/>
	</asks>
</xsl:template>
</xsl:stylesheet>
|;

use constant ASK_ALLINDIVIDUALS => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<allIndividuals id="ai"/>
	</asks>
</xsl:template>
</xsl:stylesheet>
|;

# Satisfiability

use constant ASK_SATISFIABLE => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#Class')]" />
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="classname" select="../@rdf:about"/>
	<satisfiable><xsl:attribute name="id"><xsl:value-of select="$classname"/></xsl:attribute>
	<catom><xsl:attribute name="name"><xsl:value-of select="$classname" /></xsl:attribute>
	</catom>
	</satisfiable>
</xsl:template>

</xsl:stylesheet>
|;


# Concept Hierarchy

use constant ASK_PARENTS => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#Class')]"/>
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="classname" select="../@rdf:about"/>
	<parents><xsl:attribute name="id"><xsl:value-of select="$classname"/></xsl:attribute>
	<catom><xsl:attribute name="name"><xsl:value-of select="$classname" /></xsl:attribute>
	</catom>
	</parents>
</xsl:template>

</xsl:stylesheet>
|;

use constant ASK_CHILDREN => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#Class')]"/>
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="classname" select="../@rdf:about"/>
	<children><xsl:attribute name="id"><xsl:value-of select="$classname"/></xsl:attribute>
	<catom><xsl:attribute name="name"><xsl:value-of select="$classname" /></xsl:attribute>
	</catom>
	</children>
</xsl:template>

</xsl:stylesheet>
|;

use constant ASK_DESCENDANTS => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#Class')]"/>
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="classname" select="../@rdf:about"/>
	<descendants><xsl:attribute name="id"><xsl:value-of select="$classname"/></xsl:attribute>
	<catom><xsl:attribute name="name"><xsl:value-of select="$classname" /></xsl:attribute>
	</catom>
	</descendants>
</xsl:template>

</xsl:stylesheet>
|;

use constant ASK_ANCESTORS => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#Class')]"/>
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="classname" select="../@rdf:about"/>
	<ancestors><xsl:attribute name="id"><xsl:value-of select="$classname"/></xsl:attribute>
	<catom><xsl:attribute name="name"><xsl:value-of select="$classname" /></xsl:attribute>
	</catom>
	</ancestors>
</xsl:template>

</xsl:stylesheet>
|;

use constant ASK_EQUIVALENTS => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#Class')]" />
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="classname" select="../@rdf:about"/>
	<equivalents><xsl:attribute name="id"><xsl:value-of select="$classname"/></xsl:attribute>
	<catom><xsl:attribute name="name"><xsl:value-of select="$classname" /></xsl:attribute>
	</catom>
	</equivalents>
</xsl:template>

</xsl:stylesheet>
|;

use constant ASK_RPARENTS => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#ObjectProperty')]" />
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="rolename" select="../@rdf:about"/>
	<rparents><xsl:attribute name="id"><xsl:value-of select="$rolename"/></xsl:attribute>
	<ratom><xsl:attribute name="name"><xsl:value-of select="$rolename" /></xsl:attribute>
	</ratom>
	</rparents>
</xsl:template>

</xsl:stylesheet>
|;

use constant ASK_RCHILDREN => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#ObjectProperty')]" />
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="rolename" select="../@rdf:about"/>
	<rchildren><xsl:attribute name="id"><xsl:value-of select="$rolename"/></xsl:attribute>
	<ratom><xsl:attribute name="name"><xsl:value-of select="$rolename" /></xsl:attribute>
	</ratom>
	</rchildren>
</xsl:template>

</xsl:stylesheet>
|;


use constant ASK_RANCESTORS => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#ObjectProperty')]" />
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="rolename" select="../@rdf:about"/>
	<rancestors><xsl:attribute name="id"><xsl:value-of select="$rolename"/></xsl:attribute>
	<ratom><xsl:attribute name="name"><xsl:value-of select="$rolename" /></xsl:attribute>
	</ratom>
	</rancestors>
</xsl:template>

</xsl:stylesheet>
|;


use constant ASK_RDESCENDANTS => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#ObjectProperty')]" />
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="rolename" select="../@rdf:about"/>
	<rdescendants><xsl:attribute name="id"><xsl:value-of select="$rolename"/></xsl:attribute>
	<ratom><xsl:attribute name="name"><xsl:value-of select="$rolename" /></xsl:attribute>
	</ratom>
	</rdescendants>
</xsl:template>

</xsl:stylesheet>
|;

use constant ASK_INSTANCES => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type[contains(@rdf:resource,'#Class')]" />
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="classname" select="../@rdf:about"/>
	<instances><xsl:attribute name="id"><xsl:value-of select="$classname"/></xsl:attribute>
	<catom><xsl:attribute name="name"><xsl:value-of select="$classname" /></xsl:attribute>
	</catom>
	</instances>
</xsl:template>

</xsl:stylesheet>
|;

use constant ASK_TYPES => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<asks uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type" />
	</asks>
</xsl:template>

<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="instancename" select="../@rdf:about"/>
	
	
	<xsl:choose>
	<!-- Class definition -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#Class")'/>
	<!-- Property definition -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#ObjectProperty")'/>
	<!-- property is transitive -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#TransitiveProperty")'/>
	<!-- property is functional -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#InverseFunctionalProperty")'/>
	<!-- property is functional -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#FunctionalProperty")'/>
	<!-- Restrictions: existence quantor -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#Restriction")'/>
	<xsl:when test='@rdf:resource=""'/>
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#Ontology")'/>
	
	<!-- INDIVIDUAL -->
	<xsl:otherwise>
		<types>  <xsl:attribute name="id"><xsl:value-of select="$instancename"/></xsl:attribute>
		<individual> <xsl:attribute name="name"><xsl:value-of select="$instancename"/></xsl:attribute>
		</individual>
		</types>
	</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
|;

use constant TELLS => q|<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:fo="http://www.w3.org/1999/XSL/Format"
 	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:ns0="http://www.owl-ontologies.com/Ontology1206537648.owl#"
    xmlns="http://dl.kr.org/dig/2003/03/lang">
<xsl:output method="xml" encoding="UTF-8" version="1.0" />

<xsl:template match="/">
	<tells uri="{$param}">
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdf:type"/>
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdfs:subClassOf"/>
	<xsl:apply-templates select="rdf:RDF/rdf:Description/owl:disjointWith"/>
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdfs:subPropertyOf"/>
	<xsl:apply-templates select="rdf:RDF/rdf:Description/owl:inverseOf"/>
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdfs:domain"/>
	<xsl:apply-templates select="rdf:RDF/rdf:Description/rdfs:range"/>
	</tells>
</xsl:template>

<!-- class and property defintion -->
<xsl:template match="rdf:Description/rdf:type">
	<xsl:variable name="itemname" select="../@rdf:about"/>
	
	<xsl:choose>
	<!-- Class definition -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#Class")'>
		<defconcept><xsl:attribute name="name"><xsl:value-of select="$itemname" /></xsl:attribute>
		</defconcept>
	</xsl:when>
	<!-- Property definition -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#ObjectProperty")'>
		<defrole><xsl:attribute name="name"><xsl:value-of select="$itemname" /></xsl:attribute>
		</defrole>
	</xsl:when>
	<!-- property is transitive -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#TransitiveProperty")'>
		<transitive>
			<ratom><xsl:attribute name="name"><xsl:value-of select="$itemname"/></xsl:attribute>
			</ratom>
		</transitive>
	</xsl:when>
	<!-- property is functional -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#InverseFunctionalProperty")'>
		<functional>
			<ratom><xsl:attribute name="name"><xsl:value-of select="$itemname"/></xsl:attribute>
			</ratom>
		</functional>
	</xsl:when>
	<!-- property is functional -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#FunctionalProperty")'>
		<functional>
			<ratom><xsl:attribute name="name"><xsl:value-of select="$itemname"/></xsl:attribute>
			</ratom>
		</functional>
	</xsl:when>
	<!-- Restrictions: existence quantor -->
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#Restriction")'>
		<xsl:variable name="node" select="../@rdf:nodeID"/>
		
		<xsl:if test='/rdf:RDF/rdf:Description/rdfs:subClassOf/@rdf:nodeID=$node'>
		<!-- NECESSARY CONDITION -->
			<impliesc>
			<xsl:for-each select='/rdf:RDF/rdf:Description/rdfs:subClassOf[@rdf:nodeID=$node]'>
				<catom><xsl:attribute name="name"><xsl:value-of select="@rdf:about"/></xsl:attribute>
				</catom>
			</xsl:for-each>
			<some>
				<xsl:if test='/rdf:RDF/rdf:Description[@rdf:nodeID=$node]/owl:onProperty/@rdf:resource!=""'>
					<ratom><xsl:attribute name="name"><xsl:value-of select="/rdf:RDF/rdf:Description[@rdf:nodeID=$node]/owl:onProperty/@rdf:resource"/></xsl:attribute>
					</ratom>
				</xsl:if>

				<xsl:if test='/rdf:RDF/rdf:Description[@rdf:nodeID=$node]/owl:someValuesFrom/@rdf:resource!=""'>
					<catom><xsl:attribute name="name"><xsl:value-of select="/rdf:RDF/rdf:Description[@rdf:nodeID=$node]/owl:someValuesFrom/@rdf:resource"/></xsl:attribute>
					</catom>
				</xsl:if>
			</some>
			</impliesc>
		</xsl:if>
		
		<xsl:if test='/rdf:RDF/rdf:Description/owl:equivalentClass/@rdf:nodeID=$node'>
		<!-- NECESSARY & SUFFICIENT CONDITION -->
			<equalc>
			<xsl:for-each select='/rdf:RDF/rdf:Description/owl:equivalentClass[@rdf:nodeID=$node]'>
				<catom><xsl:attribute name="name"><xsl:value-of select="../@rdf:about"/></xsl:attribute>
				</catom>
			</xsl:for-each>
			<and><some>
				<xsl:if test='/rdf:RDF/rdf:Description[@rdf:nodeID=$node]/owl:onProperty/@rdf:resource!=""'>
					<ratom><xsl:attribute name="name"><xsl:value-of select="/rdf:RDF/rdf:Description[@rdf:nodeID=$node]/owl:onProperty/@rdf:resource"/></xsl:attribute>
					</ratom>
				</xsl:if>

				<xsl:if test='/rdf:RDF/rdf:Description[@rdf:nodeID=$node]/owl:someValuesFrom/@rdf:resource!=""'>
					<catom><xsl:attribute name="name"><xsl:value-of select="/rdf:RDF/rdf:Description[@rdf:nodeID=$node]/owl:someValuesFrom/@rdf:resource"/></xsl:attribute>
					</catom>
				</xsl:if>
			</some> </and>
			</equalc>
		</xsl:if>
	</xsl:when>
	
	<xsl:when test='@rdf:resource=""'/>
	<xsl:when test='@rdf:resource!="" and contains(@rdf:resource,"#Ontology")'/>
	
	<!-- INDIVIDUAL -->
	<xsl:otherwise>
		<defindividual> <xsl:attribute name="name"><xsl:value-of select="$itemname"/></xsl:attribute>
		</defindividual>
		<instanceof> 
			<individual> <xsl:attribute name="name"><xsl:value-of select="$itemname"/></xsl:attribute>
			</individual>
			<catom><xsl:attribute name="name"><xsl:value-of select="@rdf:resource"/></xsl:attribute>
			</catom>
		</instanceof>
		
		<xsl:for-each select='/rdf:RDF/rdf:Description[contains(@rdf:about, $itemname)]/ns0:*'>
		
		<related>
			<individual> <xsl:attribute name="name"><xsl:value-of select="$itemname"/></xsl:attribute>
			</individual>
			<ratom> <xsl:attribute name="name"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></xsl:attribute>
			</ratom>
			<individual> <xsl:attribute name="name"><xsl:value-of select="@rdf:resource"/></xsl:attribute>
			</individual>
		</related>		
		</xsl:for-each>
	</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- definition: class1 is subclass of class2: necessary condition -->
<xsl:template match="rdf:Description/rdfs:subClassOf">
	<xsl:variable name="class1" select="../@rdf:about"/>
	<xsl:variable name="class2" select="@rdf:resource"/>
	
	<xsl:if test='$class2!=""'>
		<impliesc>
			<catom><xsl:attribute name="name"><xsl:value-of select="$class1"/></xsl:attribute>
			</catom>
			<catom><xsl:attribute name="name"><xsl:value-of select="$class2"/></xsl:attribute>
			</catom>
		</impliesc>
	</xsl:if>
</xsl:template>

<!-- definition: disjoint item1 and item2 -->
<xsl:template match="rdf:Description/owl:disjointWith">
	<xsl:variable name="item1" select="../@rdf:about"/>
	<xsl:variable name="item2" select="@rdf:resource"/>
	<disjoint>
		<catom><xsl:attribute name="name"><xsl:value-of select="$item1"/></xsl:attribute>
		</catom>
		<catom><xsl:attribute name="name"><xsl:value-of select="$item2"/></xsl:attribute>
		</catom>
	</disjoint>
</xsl:template>

<!-- definition: property1 is subproperty of property2 -->
<xsl:template match="rdf:Description/rdfs:subPropertyOf">
	<xsl:variable name="property1" select="../@rdf:about"/>
	<xsl:variable name="property2" select="@rdf:resource"/>
	<impliesr>
		<ratom><xsl:attribute name="name"><xsl:value-of select="$property1"/></xsl:attribute>
		</ratom>
		<ratom><xsl:attribute name="name"><xsl:value-of select="$property2"/></xsl:attribute>
		</ratom>
	</impliesr>
</xsl:template>

<!-- definition: property1 is inverseOf property2 -->
<xsl:template match="rdf:Description/owl:inverseOf">
	<xsl:variable name="property1" select="../@rdf:about"/>
	<xsl:variable name="property2" select="@rdf:resource"/>
	<equalr>
		<ratom><xsl:attribute name="name"><xsl:value-of select="$property1"/></xsl:attribute>
		</ratom>
		<inverse><ratom><xsl:attribute name="name"><xsl:value-of select="$property2"/></xsl:attribute>
		</ratom></inverse>
	</equalr>
</xsl:template>

<!-- definition: property is in domain of class -->
<xsl:template match="rdf:Description/rdfs:domain">
	<xsl:variable name="property" select="../@rdf:about"/>
	<xsl:variable name="class" select="@rdf:resource"/>
	<domain>
		<ratom><xsl:attribute name="name"><xsl:value-of select="$property"/></xsl:attribute>
		</ratom>
		<catom><xsl:attribute name="name"><xsl:value-of select="$class"/></xsl:attribute>
		</catom>
	</domain>
</xsl:template>

<!-- definition: class is in range of property -->
<xsl:template match="rdf:Description/rdfs:range">
	<xsl:variable name="property" select="../@rdf:about"/>
	<xsl:variable name="class" select="@rdf:resource"/>
	<range>
		<ratom><xsl:attribute name="name"><xsl:value-of select="$property"/></xsl:attribute>
		</ratom>
		<or><catom><xsl:attribute name="name"><xsl:value-of select="$class"/></xsl:attribute>
		</catom></or>
	</range>
</xsl:template>

</xsl:stylesheet>
|;

=pod

=head1 NAME

RDF::Redland::DIG::KB - DIG extension for Redland RDF (Knowledge Base)

=head1 SYNOPSIS

   my $model = new RDF::Redland::Model ....

   use RDF::Redland::DIG;
   my $r = new RDF::Redland::DIG (url => http://localhost:8081/);

   use RDF::Redland::DIG::KB;
   my $kb = $r->kb;   # create an empty knowledge base there

   eval {
      $kb->tell ($model);
   }; die $@ if $@;

   my %children = $kb->children ('urn:pizza', 'urn:topping');

   my %all_children = $kb->children ();

   my %parents     = $kb->parents ....
   my %descendants = $kb->descendants ...

   my @equivs      = $kb->equivalents ('urn:pizza');


   my @unsatisfiable = $kb->unsatisfiable;  # returns all

   my %relatedIndividuals = $kb->relatedIndividuals ...

=head1 DESCRIPTION

Objects of this class represent knowledge bases in the sense of DIG. Any DIG reasoner can host a
number of such knowledge bases.

=cut

use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::LibXSLT;
my $xpc = XML::LibXML::XPathContext->new;
$xpc->registerNs('x','http://dl.kr.org/dig/2003/02/lang');

=pod 

=head1 INTERFACE

=head2 Constructor

You will create knowledge bases by using an existing reasoner object (see L<RDF::Redland::DIG>).
Alternatively, this constructor clones one knowledge base. The only mandatory parameter is the
reasoner.

   my $kb = new RDF::Redland::DIG::KB ($r);

You can have any number of knowledge bases for one reasoner.

=cut

sub new {
    my $class = shift;
    my $reasoner = shift;
    
    my $dig_answer = _get_response(CREATE_KB, $reasoner);
  	my $uri = $xpc->findvalue('/x:response/x:kb/@uri',$dig_answer);
    
    return bless { reasoner => $reasoner, uri => $uri }, $class;
}

sub DESTROY{
	my $self = shift;
	my $release = qq|<?xml version="1.0"?>
	<releaseKB xmlns="http://dl.kr.org/dig/2003/02/lang"
				xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
				uri="$self->{uri}" />|;
	
	my $dig_answer = _get_response ($release, $self->{reasoner});	
}

=pod

=head2 Methods

=over

=item B<tell>

This method stores data from the given model in the knowledge base.  The only mandatory parameter is
an L<RDF::Redland::Model>. The last provided model is the actual model.

=cut

sub tell {
    my $self = shift;
    my $model = shift;
    $self->{last_model} = $model or die 'no model provided';
        
    # create RDF/XML-scheme from $model
    my $dig_question = $self->_create_digxml (TELLS);
    my $dig_answer = _get_response ($dig_question, $self->{reasoner});
    
    # find all error codes -> <error code="xx" message=""/>
	my @error_nodes;
	
	foreach my $node ( $xpc->findnodes('x:error', $dig_answer) ) {
  		push(@error_nodes, $node->findvalue('@code'));
	}
	
	#use Data::Dumper;
	#warn Dumper \@error_nodes;
	
	die "errors occurred during tell" unless (! @error_nodes);
}

=pod

=item B<allConceptNames>

Returns an array that contains all concepts from the knowledge base based on the actual model.

=cut

sub allConceptNames {
	my $self = shift;
	
	# create RDF/XML-scheme from $model
  	my $dig_question = $self->_create_digxml (ASK_ALLCONCEPTNAMES);
    my $dig_answer = _get_response($dig_question, $self->{reasoner});
   
	# find all classes -> 
	#<conceptSet id=""><synonyms><catom name="Class"/></synonyms></conceptSet>
	my @result;
	
	foreach my $node ( $xpc->findnodes('x:conceptSet', $dig_answer) ) {
  		foreach my $conceptnode( $xpc->findnodes('x:synonyms/x:catom', $node) ){
  			push(@result, $conceptnode->findvalue('@name'));
  		}
	}

	return @result;
}

=pod

=item B<allRoleNames>

Returns an array that contains all roles from the knowledge base based on the actual model.

=cut

sub allRoleNames {
	my $self = shift;
	
	# create RDF/XML-scheme from $model
  	my $dig_question = $self->_create_digxml (ASK_ALLROLENAMES);
    my $dig_answer = _get_response($dig_question, $self->{reasoner});

	
	# find all classes -> 
	#<roleSet id=""><synonyms><ratom name="Role"/></synonyms></roleSet>
	my @result;
	
	foreach my $node ( $xpc->findnodes('x:roleSet', $dig_answer) ) {
  		foreach my $rolenode($xpc->findnodes('x:synonyms/x:ratom', $node)){
  			push(@result, $rolenode->findvalue('@name'));
  		}
	}

	return @result;
}

=pod

=item B<allIndividuals>

Returns an array that contains all individuals from the knowledge base based on the actual model.

=cut

sub allIndividuals {
	my $self = shift;
	
	# create RDF/XML-scheme from $model
  	my $dig_question = $self->_create_digxml (ASK_ALLINDIVIDUALS);
	my $dig_answer = _get_response ($dig_question, $self->{reasoner});
	# find all classes -> 
	#<individualSet id=""><individual name="Individual"/></individualSet>
	my @result;
	
	foreach my $node ( $xpc->findnodes('x:individualSet', $dig_answer) ) {
		foreach my $individualnode($xpc->findnodes('x:individual', $node)){
  			push(@result, $individualnode->findvalue('@name'));
  		}
	}

	return @result;
}

=pod

=item B<unsatisfiable>

Returns an array that contains all unsatisfied concept-elements from the knowledge base based on the
actual model.

=cut

sub unsatisfiable {
	my $self = shift;
	
	# create RDF/XML-scheme from $model
    my $dig_question = $self->_create_digxml (ASK_SATISFIABLE);
  	my $dig_answer = _get_response ($dig_question, $self->{reasoner});
	# find all classes that are unsatisfied -> <false id="UnsatisfiedClass"/>
	my @result;
	
	foreach my $node ( $xpc->findnodes('x:false', $dig_answer) ) {
  		push(@result, $node->findvalue('@id'));
	}
	
	return @result;
}

=pod

=item B<subsumes>

This method checks whether or not one concept subsumes another. The only mandatory parameter is a
hash that contains the main concept as a key and the questioned concepts as an array reference as
value. Returns the hash without the concepts that do not subsume the main concept.

=cut

sub subsumes {
	my $self = shift;
	my $dref = shift or die 'no data provided';
	my %data = %{ ($dref) };
	
	my $dig_question = $self->_create_digxml2("subsumes", "catom", "catom", \%data);
	my $dig_answer = _get_response($dig_question, $self->{reasoner});

	foreach my $key ( keys( %data ) ){
		my $i = 0;
		
		foreach my $node ( $xpc->findnodes("x:*[\@id='$key']", $dig_answer) ){
			if ( $node->nodeName eq "false" ) {
				splice( @{ $data { $key } } , $i, 1);
			} else {
				$i++;
			}
		}
	}
	return %data;
}

=pod

=item B<disjoint>

This method checks whether or not once concept is disjoint with another.  The only mandatory
parameter is a hash that contains the main concept as a key and the questioned concepts as an array
reference as value. Returns the hash without the concepts that are not disjoint with the main
concept.

=cut

sub disjoint {
	my $self = shift;
	my $dref = shift or die 'no data provided';
	my %data = %{ ($dref) };
	
	
	my $dig_question = $self->_create_digxml2("disjoint", "catom", "catom", \%data);
	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	foreach my $key ( keys( %data ) ){
	
		my $i = 0;
		
		foreach my $node ( $xpc->findnodes("x:*[\@id='$key']", $dig_answer) ){
			if ( $node->nodeName eq "false" ) {
				splice( @{ $data { $key } } , $i, 1);
			} else {
				$i++;
			}
		}
	}
	
	return %data;
}

=pod

=item B<parents>

This method returns a hash with concepts as key and their parents as value. You can either provide
an array as parameter (if you want the parents from specific concepts) or otherwise all parents from
all concepts will be returned.

=cut

sub parents {
	my $self = shift;
	my @classes = @_;
	
	my $dig_question;
	if (@classes) {
		$dig_question = $self->_create_digxml3("parents", "catom", \ @classes);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_PARENTS);	
	}
	
	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	
	# find parents of all classes -> 
	#<conceptSet id="Child"><synonyms><catom name="Parent"/></synonyms></conceptSet>
	
	# stores child and the list of parents
	my %result = ();
	
	foreach my $node ( $xpc->findnodes('x:conceptSet', $dig_answer) ) {
  		my @parentnodes;
  		
  		foreach my $parentnode( $xpc->findnodes('x:synonyms/x:catom', $node) ){
  			push(@parentnodes, $parentnode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @parentnodes;
	}

	return %result;
}

=pod

=item B<children>
  
This method returns a hash with concepts as key and their children as value. You can either provide
an array as parameter (if you want the children from specific concepts) or otherwise all children
from all concepts will be returned.

=cut

sub children {
	my $self = shift;
	my @classes = @_;
	
	my $dig_question;
	if (@classes) {
		$dig_question = $self->_create_digxml3("children", "catom", \ @classes);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_CHILDREN);	
	}

	# create RDF/XML-scheme from $model
	my $dig_answer = _get_response ($dig_question, $self->{reasoner} );
    
	# find parents of all classes -> 
	#<conceptSet id="Parent"><synonyms><catom name="Child"/></synonyms></conceptSet>
	
	# stores parent and the list of children
	my %result = ();
	
	foreach my $node ( $xpc->findnodes('x:conceptSet', $dig_answer) ) {
		my @childnodes;
  		
  		foreach my $childnode( $xpc->findnodes('x:synonyms/x:catom', $node) ){
  			push(@childnodes, $childnode->findvalue('@name') );
  		}
  	
  		$result { $node->findvalue('@id') } = \ @childnodes;
	}
	return %result;
}

=pod

=item B<descendants>
  
This method returns a hash with concepts as key and their descendants as value. You can either
provide an array as parameter (if you want the descendants from specific concepts) or otherwise all
descendants from all concepts will be returned.

=cut

sub descendants {
	my $self = shift;
	my @classes = @_;
	
	# create RDF/XML-scheme from $model
	
	my $dig_question;
	if (@classes) {
		$dig_question = $self->_create_digxml3("descendants", "catom", \ @classes);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_DESCENDANTS);	
	}

    my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	
	# find descendants for all classes -> 
	#<conceptSet id="Class><synonyms><catom name="Descendants"/></synonyms></conceptSet>
	
	# stores class and the list of descendants
	my %result = ();
	
	foreach my $node ( $xpc->findnodes('x:conceptSet', $dig_answer) ) {
		my @descendantnodes;
  		
  		foreach my $descendantnode( $xpc->findnodes('x:synonyms/x:catom', $node) ){
  			push(@descendantnodes, $descendantnode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @descendantnodes;
	}

	return %result;
}

=pod

=item B<ancestors>
  
This method returns a hash with concepts as key and their ancestors as value. You can either provide
an array as parameter (if you want the ancestors from specific concepts) or otherwise all ancestors
from all concepts will be returned.

=cut

sub ancestors {
	my $self = shift;
	my @classes = @_;
	
	my $dig_question;
	if (@classes) {
		$dig_question = $self->_create_digxml3("ancestors", "catom", \ @classes);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_ANCESTORS);	
	}

	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	# find ancestors for all classes -> 
	#<conceptSet id="Class"><synonyms><catom name="Ancestor"/></synonyms></conceptSet>
	
	# stores node and the list of ancestors
	my %result = ();
	
	foreach my $node ( $xpc->findnodes('x:conceptSet', $dig_answer) ) {
  		my @ancestornodes;
  		
  		foreach my $ancestornode( $xpc->findnodes('x:synonyms/x:catom', $node) ){
  			push(@ancestornodes, $ancestornode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @ancestornodes;
	}

	return %result;
}

=pod

=item B<equivalents>
  
This method returns a hash with concepts as key and their equivalents as value. You can either
provide an array as parameter (if you want the equivalents from specific concepts) or otherwise all
equivalents from all concepts will be returned.

=cut

sub equivalents {
	my $self = shift;
	my @classes = @_;
	
	my $dig_question;
	if (@classes) {
		$dig_question = $self->_create_digxml3("equivalents", "catom", \ @classes);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_EQUIVALENTS);	
	}

    my $dig_answer = _get_response ($dig_question, $self->{reasoner});	

	# find equivalents of all classes -> 
	#<conceptSet id="Class"><synonyms><catom name="Eq1"/><catom name="Eq2"/></synonyms></conceptSet>
	
	# stores class and equivalents in hash
	my %result = ();
	
	foreach my $node ( $xpc->findnodes('x:conceptSet', $dig_answer) ) {
  		my @equivalentnodes;
  		foreach my $equivalentnode( $xpc->findnodes('x:synonyms/x:catom', $node) ){
  			push(@equivalentnodes, $equivalentnode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @equivalentnodes;
	}

	return %result;
}

=pod

=item B<rparents>
  
This method returns a hash with roles as key and their parents as value. You can either provide an
array as parameter (if you want the parents from specific roles) or otherwise all parents from all
roles will be returned.

=cut

sub rparents {
	my $self = shift;
	my @roles = @_;
	
	# create RDF/XML-scheme from $model
   
	my $dig_question;
	if (@roles) {
		$dig_question = $self->_create_digxml3("rparents", "ratom", \ @roles);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_RPARENTS);	
	}

	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	
	# find parents of all classes -> 
	#<roleSet id="Child"><synonyms><ratom name="Parent"/></synonyms></roleSet>
	
	# a child can have one or more parents
	my @parents;
	
	# stores child and the list of parents
	my %result = ();
	foreach my $node ( $xpc->findnodes('x:roleSet', $dig_answer) ) {
		my @parentnodes;
  		foreach my $parentnode( $xpc->findnodes('x:synonyms/x:ratom', $node) ){
  			push(@parentnodes, $parentnode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @parentnodes;
	}
	return %result;
}

=pod

=item B<rchildren>
  
This method returns a hash with roles as key and their children as value. You can either provide an
array as parameter (if you want the children from specific roles) or otherwise all children from all
roles will be returned.

=cut

sub rchildren {
	my $self = shift;
	my @roles = @_;
	
	# create RDF/XML-scheme from $model
   
	my $dig_question;
	if (@roles) {
		$dig_question = $self->_create_digxml3("rchildren", "ratom", \ @roles);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_RCHILDREN);	
	}
	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	
	# find parents for all roles -> 
	#<roleSet id="Parent"><synonyms><ratom name="Child"/></synonyms></roleSet>
	
	# stores parent and the list of children
	my %result = ();
	foreach my $node ( $xpc->findnodes('x:roleSet', $dig_answer) ) {
		my @childnodes;
		
  		foreach my $childnode( $xpc->findnodes('x:synonyms/x:ratom', $node) ){
  			push(@childnodes, $childnode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @childnodes;
	}
	return %result;
}

=pod

=item B<rdescendants>
  
This method returns a hash with roles as key and their descendants as value. You can either provide
an array as parameter (if you want the descendants from specific roles) or otherwise all descendants
from all roles will be returned.

=cut

sub rdescendants {
	my $self = shift;
	my @roles = @_;
	
	# create RDF/XML-scheme from $model
   
	my $dig_question;
	if (@roles) {
		$dig_question = $self->_create_digxml3("rdescendants", "ratom", \ @roles);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_RDESCENDANTS);	
	}
	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	
	# find descendants for all roles -> 
	#<roleSet id="Role><synonyms><ratom name="Descendants"/></synonyms></roleSet>
	
	# stores class and the list of descendants
	my %result = ();
	foreach my $node ( $xpc->findnodes('x:roleSet', $dig_answer) ) {
		my @descendantnodes;
  		
  		foreach my $descendantnode( $xpc->findnodes('x:synonyms/x:ratom', $node) ){
  			push(@descendantnodes, $descendantnode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @descendantnodes;
	}
	return %result;
}

=pod

=item B<rancestors>
  
This method returns a hash with roles as key and their ancestors as value. You can either provide an
array as parameter (if you want the ancestors from specific roles) or otherwise all ancestors from
all roles will be returned.

=cut

sub rancestors {
	my $self = shift;
	my @roles = @_;
	
	# create RDF/XML-scheme from $model
   
	my $dig_question;
	if (@roles) {
		$dig_question = $self->_create_digxml3("rancestors", "ratom", \ @roles);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_RANCESTORS);	
	}
	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	

	# find ancestors for all roles -> 
	#<roleSet id="Role"><synonyms><ratom name="Ancestor"/></synonyms></roleSet>
	
	# stores node and the list of ancestors
	my %result = ();
	foreach my $node ( $xpc->findnodes('x:roleSet', $dig_answer) ) {
  		my @ancestornodes;
  		
  		foreach my $ancestornode( $xpc->findnodes('x:synonyms/x:ratom', $node) ){
  			push(@ancestornodes, $ancestornode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @ancestornodes;
	}
	return %result;
}

=pod

=item B<instances>
  
This method returns a hash with concepts as key and their instances as value. You can either provide
an array as parameter (if you want the instances from specific concepts) or otherwise all instances
from all concepts will be returned.

=cut

sub instances {
	my $self = shift;
	my @classes = @_;
	
	my $dig_question;
	if (@classes) {
		$dig_question = $self->_create_digxml3("instances", "catom", \ @classes);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_INSTANCES);	
	}

    my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	
	# find instances for all classes -> 
	#<individualSet id="Class"><individual name="Instance"/></individualSet>
	
	# stores node and the list of instances
	my %result = ();
	
	foreach my $node ( $xpc->findnodes('x:individualSet', $dig_answer) ) {
		my @instances;
  		
  		foreach my $instancenode( $xpc->findnodes('x:individual', $node) ){
  			push(@instances, $instancenode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @instances;
	}

	return %result;
}

=pod

=item B<types>
  
This method returns a hash with individuals as key and their concepts as value. You can either
provide an array as parameter (if you want the concepts from specific individuals) or otherwise all
concepts from all individuals will be returned.

=cut

sub types {
	my $self = shift;
	my @individuals = @_;
	
	my $dig_question;
	if (@individuals) {
		$dig_question = $self->_create_digxml3("types", "individual", \ @individuals);
	} else {
		# look for all classes
		$dig_question = $self->_create_digxml (ASK_TYPES);	
	}

	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
 
 	# find classes for all instances -> 
	#<conceptSet id="Instance"><synonyms><catom name="Class"/></synonyms></conceptSet>
	
	# stores node and the list of classes
	my %result = ();
	foreach my $node ( $xpc->findnodes('x:conceptSet', $dig_answer) ) {
		my @types;
  		
  		foreach my $typenode( $xpc->findnodes('x:synonyms/x:catom', $node) ){
  			push(@types, $typenode->findvalue('@name'));
  		}
  	
  		$result { $node->findvalue('@id') } = \ @types;
	}
	return %result;
}

=pod

=item B<instance>

This method checks whether or not an individual is an instance from a specified concept. The only
mandatory parameter is a hash that contains the individual as a key and the questioned concepts as
an array reference as value.  Returns the hash without the concepts that are not disjoint with the
main concept.

=cut

sub instance {
	my $self = shift;
	my $dref = shift or die 'no data provided';
	my %data = %{ ($dref) };
	
	
	my $dig_question = $self->_create_digxml2("instance", "individual", "catom", \%data);
	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	
	
	foreach my $key ( keys( %data ) ){
	
		my $i = 0;
		
		foreach my $node ( $xpc->findnodes("x:*[\@id='$key']", $dig_answer) ){
			if ( $node->nodeName eq "false" ) {
				splice( @{ $data { $key } } , $i, 1);
			} else {
				$i++;
			}
		}
	}
	
	return %data;
}

=pod

=item B<roleFillers>

This method checks which individuals are asserted to a specified (individual,role)-pair. The
mandatory parameters are the name of the main individual and the name of the role. Returns the
asserted individuals to this pair as an array.

=cut

sub roleFillers {
	my $self = shift;
	my $individual = shift or die 'no data provided';
	my $role = shift or die 'no data provided';
	
	my $dig_question = $self->_create_digxml4("roleFillers", "individual", "ratom", $individual, $role);
	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	
	# find roleFillers for individuals -> 
	#<individualSet id="Individual"><individual name="Individual1"/>
	#<individual name="individual2"/></individualSet>
	
	# stores node and the list of ancestors
	my @result;
	foreach my $node ( $xpc->findnodes('x:individualSet', $dig_answer) ) {
		foreach my $relatednode( $xpc->findnodes('x:individual', $node) ){
  			push(@result, $relatednode->findvalue('@name'));
  		}
  	}
	return @result;
}

=pod

=item B<relatedIndividuals>

This method returns an array with pairs of individuals that are asserted to a specified role. The
only mandatory parameter is the role.

=cut

sub relatedIndividuals {
	my $self = shift;
	my $role = shift or die 'no data provided';
	
	my $dig_question = $self->_create_digxml5("relatedIndividuals", "ratom", $role);
	my $dig_answer = _get_response ($dig_question, $self->{reasoner});	
	
	# find related individuals for all individuals -> 
	#<individualPairSet id="role"><individualPair><individual name="Individual1"/>
	#<individual name="individual2"/></individualPair></individualPairSet>

	# stores relatedIndividuals
	my @result;
	foreach my $node ( $xpc->findnodes('x:individualPairSet/x:individualPair', $dig_answer) ) {
		my @relatednodes;
  		
  		foreach my $relatednode( $xpc->findnodes('x:individual', $node) ){
  			push(@relatednodes, $relatednode->findvalue('@name'));
  		}
  		push(@result,  \ @relatednodes);
	}
	return @result;
}

=pod

=back

=cut

#-- aux functions ---------------------------------------------------------------
sub _create_digxml {
	my $self = shift;
	my $stylesheet = shift;
	
	# create RDF/XML-File from model	
	use RDF::Redland;
	my $serializer = new RDF::Redland::Serializer("rdfxml")
    or die "Failed to find serializer";

	my $uri = new RDF::Redland::URI($self->{uri});
	# serialize model to string
	my $ser_model = $serializer->serialize_model_to_string ($uri, $self->{last_model});
	
	$serializer = undef;
	
	my $parser = XML::LibXML->new();
	my $xslt = XML::LibXSLT->new();
	
	# parse rdf/xml-string
	my $source = $parser->parse_string($ser_model);
	
	# define xslt-stylesheet
	my $style_doc = $parser->parse_string($stylesheet);
	my $xml = $xslt->parse_stylesheet($style_doc);
	
	# define uri in $tell_result
	my $result = $xml->transform($source, XML::LibXSLT::xpath_to_string(
        param => "$self->{uri}"
        ));
	
	#my $out = "OUTPUT_TELL.xml";
  	#open OUT, ">$out" or die "Cannot open $out for write";
  	#print OUT $xml->output_string($result);
  	
  	return ($xml->output_string($result));
}

sub _create_digxml2 {
	my $self = shift;
	my $tag = shift;
	my $attribute1 = shift;
	my $attribute2 = shift;
	my $dataref = shift;
	
	my %data = % {$dataref};
	
	
	# create XML-File
	my $xml = XML::LibXML::Document->new("1.0","UTF-8");
	my $rootnode = XML::LibXML::Element->new("asks");
	$rootnode->setAttribute("xmlns","http://dl.kr.org/dig/2003/03/lang");
	$rootnode->setAttribute("xmlns:fo", "http://www.w3.org/1999/XSL/Format");
	$rootnode->setAttribute("xmlns:rdfs", "http://www.w3.org/2000/01/rdf-schema#");
	$rootnode->setAttribute("xmlns:rdf","http://www.w3.org/1999/02/22-rdf-syntax-ns#");
	$rootnode->setAttribute("xmlns:owl","http://www.w3.org/2002/07/owl#");
	$rootnode->setAttribute("uri","$self->{uri}");
	
	while ( my ($key, $value) = each(%data) ) {
	
		my @listvalues = @{($value)};
		
		foreach my $lvalue ( @listvalues ) {
		
			my $node = XML::LibXML::Element->new($tag);
			$node->setAttribute("id", "$key");
			
			my $childnode1 = XML::LibXML::Element->new($attribute1);
			$childnode1->setAttribute("name","$key");
			
			$node->appendChild($childnode1);
			
			my $childnode2 = XML::LibXML::Element->new($attribute2);
			$childnode2->setAttribute("name","$lvalue");
			$node->appendChild($childnode2);
			
			$rootnode->appendChild($node);
		
		}
	}
	$xml->setDocumentElement($rootnode);
	
	return $xml->toString();
}

sub _create_digxml3 {
	my $self = shift;
	my $tag = shift;
	my $attribute = shift;
	my $dataref = shift;
	
	my @data = @{$dataref};
	
	# create XML-File
	my $xml = XML::LibXML::Document->new("1.0","UTF-8");
	my $rootnode = XML::LibXML::Element->new("asks");
	$rootnode->setAttribute("xmlns","http://dl.kr.org/dig/2003/03/lang");
	$rootnode->setAttribute("xmlns:fo", "http://www.w3.org/1999/XSL/Format");
	$rootnode->setAttribute("xmlns:rdfs", "http://www.w3.org/2000/01/rdf-schema#");
	$rootnode->setAttribute("xmlns:rdf","http://www.w3.org/1999/02/22-rdf-syntax-ns#");
	$rootnode->setAttribute("xmlns:owl","http://www.w3.org/2002/07/owl#");
	$rootnode->setAttribute("uri","$self->{uri}");
	
	my $element;
	foreach $element ( @data ) {
		my $node = XML::LibXML::Element->new($tag);
		$node->setAttribute("id", "$element");
			
		my $childnode = XML::LibXML::Element->new($attribute);
		$childnode->setAttribute("name","$element");
			
		$node->appendChild($childnode);
		$rootnode->appendChild($node);
	}
	$xml->setDocumentElement($rootnode);
	
	return $xml->toString();
}

sub _create_digxml4 {
	my $self = shift;
	my $tag = shift;
	my $attribute1 = shift;
	my $attribute2 = shift;
	my $data1 = shift;
	my $data2 = shift;
	
	# create XML-File
	my $xml = XML::LibXML::Document->new("1.0","UTF-8");
	my $rootnode = XML::LibXML::Element->new("asks");
	$rootnode->setAttribute("xmlns","http://dl.kr.org/dig/2003/03/lang");
	$rootnode->setAttribute("xmlns:fo", "http://www.w3.org/1999/XSL/Format");
	$rootnode->setAttribute("xmlns:rdfs", "http://www.w3.org/2000/01/rdf-schema#");
	$rootnode->setAttribute("xmlns:rdf","http://www.w3.org/1999/02/22-rdf-syntax-ns#");
	$rootnode->setAttribute("xmlns:owl","http://www.w3.org/2002/07/owl#");
	$rootnode->setAttribute("uri","$self->{uri}");
	
	my $node = XML::LibXML::Element->new($tag);
	$node->setAttribute("id", "$data1");
			
	my $childnode1 = XML::LibXML::Element->new($attribute1);
	$childnode1->setAttribute("name","$data1");
	$node->appendChild($childnode1);
			
	my $childnode2 = XML::LibXML::Element->new($attribute2);
	$childnode2->setAttribute("name","$data2");
	$node->appendChild($childnode2);
			
	$rootnode->appendChild($node);
	$xml->setDocumentElement($rootnode);
	
	return $xml->toString();
}

sub _create_digxml5 {
	my $self = shift;
	my $tag = shift;
	my $attribute = shift;
	my $data = shift;
	
	# create XML-File
	my $xml = XML::LibXML::Document->new("1.0","UTF-8");
	my $rootnode = XML::LibXML::Element->new("asks");
	$rootnode->setAttribute("xmlns","http://dl.kr.org/dig/2003/03/lang");
	$rootnode->setAttribute("xmlns:fo", "http://www.w3.org/1999/XSL/Format");
	$rootnode->setAttribute("xmlns:rdfs", "http://www.w3.org/2000/01/rdf-schema#");
	$rootnode->setAttribute("xmlns:rdf","http://www.w3.org/1999/02/22-rdf-syntax-ns#");
	$rootnode->setAttribute("xmlns:owl","http://www.w3.org/2002/07/owl#");
	$rootnode->setAttribute("uri","$self->{uri}");
	
	my $node = XML::LibXML::Element->new($tag);
	$node->setAttribute("id", "$data");
			
	my $childnode = XML::LibXML::Element->new($attribute);
	$childnode->setAttribute("name","$data");
			
	$node->appendChild($childnode);
	$rootnode->appendChild($node);
	$xml->setDocumentElement($rootnode);
	
	return $xml->toString();
}

sub _get_response {
	my $dig_question = shift;
	my $reasoner = shift;    
    
    my $req = HTTP::Request->new(POST => $reasoner->{url});
    $req->content_type('text/xml');
    use Encode;
    $req->content(encode("iso-8859-1", $dig_question));
    
    # Pass request to the user agent and get a response back
    my $res = $reasoner->{ua}->request ($req);
    
    # Check the outcome of the response
    die "reasoner could not be contacted at $reasoner->{url}" unless $res->is_success;

	my $parser = XML::LibXML->new();
	# parse content	
	my $tree = $parser->parse_string($res->content);
	my $root = $tree->getDocumentElement;

	return $root;
}

=pod

=head1 COPYRIGHT AND LICENCE

Copyright 2008 by Lara Spendier and Robert Barta

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

Work supported by the Austrian Research Centers Seibersdorf (Smart Systems).

=cut

our $VERSION = 0.02;

1;
