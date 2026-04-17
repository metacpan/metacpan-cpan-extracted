<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:mods="http://www.loc.gov/mods/v3"
    version="1.0">
    <xsl:output encoding="UTF-8" method="xml" indent="yes"/>

    <!-- Mapping from FOLIO raw format to mods for the FOLIO Z39.50/SRU server 
         Marko Knepper, UB Mainz 2025, Apache 2.0 -->

    <xsl:template match="opt|record">
        <mods:mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:mods="http://www.loc.gov/mods/v3" 
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-8.xsd">
            <xsl:apply-templates mode="instance"/>
            <mods:recordInfo>
                <mods:recordCreationDate encoding="iso8601"><xsl:value-of select="metadata/createdDate"/></mods:recordCreationDate>
                <mods:recordChangeDate encoding="iso8601"><xsl:value-of select="metadata/updatedDate"/></mods:recordChangeDate>
                <xsl:if test="source/text()"><mods:recordIdentifier source="{source}"><xsl:value-of select="hrid"/></mods:recordIdentifier></xsl:if>
                <mods:recordIdentifier source="uuid"><xsl:value-of select="id"/></mods:recordIdentifier>
                <mods:recordIdentifier source="hrid"><xsl:value-of select="hrid"/></mods:recordIdentifier>
            </mods:recordInfo>
        </mods:mods>
    </xsl:template>

    <xsl:template match="holdingsRecords2" mode="instance">
        <mods:location>
            <mods:physicalLocation>
                <xsl:value-of select="permanentLocation/institution/name"/><xsl:text>, </xsl:text>
                <xsl:value-of select="permanentLocation/library/name"/>
            </mods:physicalLocation>
            <xsl:choose>
                <xsl:when test="bareHoldingsItems">
                    <mods:holdingSimple>
                        <xsl:apply-templates select="bareHoldingsItems" mode="holdings"/>                    
                    </mods:holdingSimple>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="callNumber" mode="holdings"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="hrid/text()">
                <mods:holdingExternal>
                    <identifier type="hrid"><xsl:value-of select="hrid"/></identifier>
                </mods:holdingExternal>
            </xsl:if>
        </mods:location>
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
            <xsl:if test="place/text()">
                <mods:place>
                    <mods:placeTerm type="text"><xsl:value-of select="place"/></mods:placeTerm>
                </mods:place>
            </xsl:if>
            <mods:publisher><xsl:value-of select="publisher"/></mods:publisher>
            <mods:dateIssued keyDate="yes"><xsl:value-of select="dateOfPublication"/></mods:dateIssued>
            <xsl:choose>
                <xsl:when test="../modeOfIssuanceId='4fc0f4fe-06fd-490a-a078-c4da1754e03a'">
                    <mods:issuance>integrating resource</mods:issuance>
                </xsl:when>
                <xsl:when test="../modeOfIssuanceId='f5cc2ab6-bb92-4cab-b83f-5a3d09261a41'">
                    <mods:issuance>multipart monograph</mods:issuance>
                </xsl:when>
                <xsl:when test="../modeOfIssuanceId='068b5344-e2a6-40df-9186-1829e13cd344'">
                    <mods:issuance>serial</mods:issuance>
                </xsl:when>
                <xsl:when test="../modeOfIssuanceId='9d18a02f-5897-4c31-9106-c9abb5c7ae8b'">
                    <mods:issuance>single unit</mods:issuance>
                </xsl:when>
                <xsl:when test="../modeOfIssuanceId='612bbd3d-c16b-4bfb-8517-2afafc60204a'">
                    <mods:issuance>unspecified</mods:issuance>
                </xsl:when>
            </xsl:choose>
        </mods:originInfo>
    </xsl:template>
   
    <xsl:template match="classifications" mode="instance">
        <xsl:choose> <!-- covering some of the reference data -->
            <xsl:when test="classificationTypeId='ce176ace-a53e-4b4d-aa89-725ed7b2edac'">
                <mods:classification authority="ce176ace-a53e-4b4d-aa89-725ed7b2edac" displayLabel="LCC" authorityURI="http://id.loc.gov/vocabulary/classSchemes/lcc">
                    <xsl:value-of select="classificationNumber"/>
                </mods:classification>
            </xsl:when>
            <xsl:when test="classificationTypeId='42471af9-7d25-4f3a-bf78-60d29dcf463b'">
                <mods:classification authority="42471af9-7d25-4f3a-bf78-60d29dcf463b" displayLabel="DDC" authorityURI="http://id.loc.gov/vocabulary/classSchemes/ddc">
                    <xsl:value-of select="classificationNumber"/>
                </mods:classification>
            </xsl:when>
            <xsl:otherwise>
                <mods:classification authority="{classificationNumber}">
                    <xsl:value-of select="classificationNumber"/>
                </mods:classification>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="subjects" mode="instance">
        <mods:subject>
            <mods:topic><xsl:value-of select="value"/></mods:topic>
        </mods:subject>
    </xsl:template>
    
    <xsl:template match="instanceTypeId" mode="instance">
        <!-- Auto-generated by Python script -->
        <xsl:choose>
            <xsl:when test=".='3363cdb1-e644-446c-82a4-dc3a1d4395b9'">
                <mods:genre>cartographic dataset</mods:genre>
            </xsl:when>
            <xsl:when test=".='526aa04d-9289-4511-8866-349299592c18'">
                <mods:genre>cartographic image</mods:genre>
            </xsl:when>
            <xsl:when test=".='80c0c134-0240-4b63-99d0-6ca755d5f433'">
                <mods:genre>cartographic moving image</mods:genre>
            </xsl:when>
            <xsl:when test=".='408f82f0-e612-4977-96a1-02076229e312'">
                <mods:genre>cartographic tactile image</mods:genre>
            </xsl:when>
            <xsl:when test=".='e5136fa2-1f19-4581-b005-6e007a940ca8'">
                <mods:genre>cartographic tactile three-dimensional form</mods:genre>
            </xsl:when>
            <xsl:when test=".='2022aa2e-bdde-4dc4-90bc-115e8894b8b3'">
                <mods:genre>cartographic three-dimensional form</mods:genre>
            </xsl:when>
            <xsl:when test=".='df5dddff-9c30-4507-8b82-119ff972d4d7'">
                <mods:genre>computer dataset</mods:genre>
            </xsl:when>
            <xsl:when test=".='c208544b-9e28-44fa-a13c-f4093d72f798'">
                <mods:genre>computer program</mods:genre>
            </xsl:when>
            <xsl:when test=".='fbe264b5-69aa-4b7c-a230-3b53337f6440'">
                <mods:genre>notated movement</mods:genre>
            </xsl:when>
            <xsl:when test=".='497b5090-3da2-486c-b57f-de5bb3c2e26d'">
                <mods:genre>notated music</mods:genre>
            </xsl:when>
            <xsl:when test=".='a2c91e87-6bab-44d6-8adb-1fd02481fc4f'">
                <mods:genre>other</mods:genre>
            </xsl:when>
            <xsl:when test=".='3be24c14-3551-4180-9292-26a786649c8b'">
                <mods:genre>performed music</mods:genre>
            </xsl:when>
            <xsl:when test=".='9bce18bd-45bf-4949-8fa8-63163e4b7d7f'">
                <mods:genre>sounds</mods:genre>
            </xsl:when>
            <xsl:when test=".='c7f7446f-4642-4d97-88c9-55bae2ad6c7f'">
                <mods:genre>spoken word</mods:genre>
            </xsl:when>
            <xsl:when test=".='535e3160-763a-42f9-b0c0-d8ed7df6e2a2'">
                <mods:genre>still image</mods:genre>
            </xsl:when>
            <xsl:when test=".='efe2e89b-0525-4535-aa9b-3ff1a131189e'">
                <mods:genre>tactile image</mods:genre>
            </xsl:when>
            <xsl:when test=".='e6a278fb-565a-4296-a7c5-8eb63d259522'">
                <mods:genre>tactile notated movement</mods:genre>
            </xsl:when>
            <xsl:when test=".='a67e00fd-dcce-42a9-9e75-fd654ec31e89'">
                <mods:genre>tactile notated music</mods:genre>
            </xsl:when>
            <xsl:when test=".='8105bd44-e7bd-487e-a8f2-b804a361d92f'">
                <mods:genre>tactile text</mods:genre>
            </xsl:when>
            <xsl:when test=".='82689e16-629d-47f7-94b5-d89736cf11f2'">
                <mods:genre>tactile three-dimensional form</mods:genre>
            </xsl:when>
            <xsl:when test=".='6312d172-f0cf-40f6-b27d-9fa8feaf332f'">
                <mods:genre>text</mods:genre>
            </xsl:when>
            <xsl:when test=".='c1e95c2b-4efc-48cf-9e71-edb622cf0c22'">
                <mods:genre>three-dimensional form</mods:genre>
            </xsl:when>
            <xsl:when test=".='3e3039b7-fda0-4ac4-885a-022d457cb99c'">
                <mods:genre>three-dimensional moving image</mods:genre>
            </xsl:when>
            <xsl:when test=".='225faa14-f9bf-4ecd-990d-69433c912434'">
                <mods:genre>two-dimensional moving image</mods:genre>
            </xsl:when>
            <xsl:when test=".='30fffe0e-e985-4144-b2e2-1e8179bdb41f'">
                <mods:genre>unspecified</mods:genre>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
 
    <xsl:template match="instanceFormatIds" mode="instance">
        <mods:physicalDescription>
            <!-- Auto-generated by Python script -->
            <xsl:choose>
                <xsl:when test=".='0d9b1c3d-2d13-4f18-9472-cc1b91bf1752'">
                    <mods:form>audio -- audio belt</mods:form>
                </xsl:when>
                <xsl:when test=".='5642320a-2ab9-475c-8ca2-4af7551cf296'">
                    <mods:form>audio -- audio cartridge</mods:form>
                </xsl:when>
                <xsl:when test=".='6d749f00-97bd-4eab-9828-57167558f514'">
                    <mods:form>audio -- audiocassette</mods:form>
                </xsl:when>
                <xsl:when test=".='485e3e1d-9f46-42b6-8c65-6bb7bd4b37f8'">
                    <mods:form>audio -- audio cylinder</mods:form>
                </xsl:when>
                <xsl:when test=".='5cb91d15-96b1-4b8a-bf60-ec310538da66'">
                    <mods:form>audio -- audio disc</mods:form>
                </xsl:when>
                <xsl:when test=".='7fde4e21-00b5-4de4-a90a-08a84a601aeb'">
                    <mods:form>audio -- audio roll</mods:form>
                </xsl:when>
                <xsl:when test=".='7612aa96-61a6-41bd-8ed2-ff1688e794e1'">
                    <mods:form>audio -- audiotape reel</mods:form>
                </xsl:when>
                <xsl:when test=".='6a679992-b37e-4b57-b6ea-96be6b51d2b4'">
                    <mods:form>audio -- audio wire reel</mods:form>
                </xsl:when>
                <xsl:when test=".='a3549b8c-3282-4a14-9ec3-c1cf294043b9'">
                    <mods:form>audio -- other</mods:form>
                </xsl:when>
                <xsl:when test=".='5bfb7b4f-9cd5-4577-a364-f95352146a56'">
                    <mods:form>audio -- sound track reel</mods:form>
                </xsl:when>
                <xsl:when test=".='549e3381-7d49-44f6-8232-37af1cb5ecf3'">
                    <mods:form>computer -- computer card</mods:form>
                </xsl:when>
                <xsl:when test=".='88f58dc0-4243-4c6b-8321-70244ff34a83'">
                    <mods:form>computer -- computer chip cartridge</mods:form>
                </xsl:when>
                <xsl:when test=".='ac9de2b9-0914-4a54-8805-463686a5489e'">
                    <mods:form>computer -- computer disc</mods:form>
                </xsl:when>
                <xsl:when test=".='e05f2613-05df-4b4d-9292-2ee9aa778ecc'">
                    <mods:form>computer -- computer disc cartridge</mods:form>
                </xsl:when>
                <xsl:when test=".='f4f30334-568b-4dd2-88b5-db8401607daf'">
                    <mods:form>computer -- computer tape cartridge</mods:form>
                </xsl:when>
                <xsl:when test=".='e5aeb29a-cf0a-4d97-8c39-7756c10d423c'">
                    <mods:form>computer -- computer tape cassette</mods:form>
                </xsl:when>
                <xsl:when test=".='d16b19d1-507f-4a22-bb8a-b3f713a73221'">
                    <mods:form>computer -- computer tape reel</mods:form>
                </xsl:when>
                <xsl:when test=".='f5e8210f-7640-459b-a71f-552567f92369'">
                    <mods:form>computer -- online resource</mods:form>
                </xsl:when>
                <xsl:when test=".='fe1b9adb-e0cf-4e05-905f-ce9986279404'">
                    <mods:form>computer -- other</mods:form>
                </xsl:when>
                <xsl:when test=".='cb3004a3-2a85-4ed4-8084-409f93d6d8ba'">
                    <mods:form>microform -- aperture card</mods:form>
                </xsl:when>
                <xsl:when test=".='fc3e32a0-9c85-4454-a42e-39fca788a7dc'">
                    <mods:form>microform -- microfiche</mods:form>
                </xsl:when>
                <xsl:when test=".='b72e66e2-d946-4b01-a696-8fab07051ff8'">
                    <mods:form>microform -- microfiche cassette</mods:form>
                </xsl:when>
                <xsl:when test=".='fc9bfed9-2cb0-465f-8758-33af5bba750b'">
                    <mods:form>microform -- microfilm cartridge</mods:form>
                </xsl:when>
                <xsl:when test=".='b71e5ec6-a15d-4261-baf9-aea6be7af15b'">
                    <mods:form>microform -- microfilm cassette</mods:form>
                </xsl:when>
                <xsl:when test=".='7bfe7e83-d4aa-46d1-b2a9-f612b18d11f4'">
                    <mods:form>microform -- microfilm reel</mods:form>
                </xsl:when>
                <xsl:when test=".='cb96199a-21fb-4f11-b003-99291d8c9752'">
                    <mods:form>microform -- microfilm roll</mods:form>
                </xsl:when>
                <xsl:when test=".='33009ba2-b742-4aab-b592-68b27451e94f'">
                    <mods:form>microform -- microfilm slip</mods:form>
                </xsl:when>
                <xsl:when test=".='788aa9a6-5f0b-4c52-957b-998266ee3bd3'">
                    <mods:form>microform -- microopaque</mods:form>
                </xsl:when>
                <xsl:when test=".='a0f2612b-f24f-4dc8-a139-89c3da5a38f1'">
                    <mods:form>microform -- other</mods:form>
                </xsl:when>
                <xsl:when test=".='b1c69d78-4afb-4d8b-9624-8b3cfa5288ad'">
                    <mods:form>microscopic -- microscope slide</mods:form>
                </xsl:when>
                <xsl:when test=".='55d3b8aa-304e-4967-8b78-55926d7809ac'">
                    <mods:form>microscopic -- other</mods:form>
                </xsl:when>
                <xsl:when test=".='6bf2154b-df6e-4f11-97d0-6541231ac2be'">
                    <mods:form>projected image -- film cartridge</mods:form>
                </xsl:when>
                <xsl:when test=".='47b226c0-853c-40f4-ba2e-2bd5ba82b665'">
                    <mods:form>projected image -- film cassette</mods:form>
                </xsl:when>
                <xsl:when test=".='55a66581-3921-4b50-9981-4fe53bf35e7f'">
                    <mods:form>projected image -- film reel</mods:form>
                </xsl:when>
                <xsl:when test=".='f0e689e8-e62d-4aac-b1c1-198ac9114aca'">
                    <mods:form>projected image -- film roll</mods:form>
                </xsl:when>
                <xsl:when test=".='53f44ae4-167b-4cc2-9a63-4375c0ad9f58'">
                    <mods:form>projected image -- filmslip</mods:form>
                </xsl:when>
                <xsl:when test=".='8e04d356-2645-4f97-8de8-9721cf11ccef'">
                    <mods:form>projected image -- filmstrip</mods:form>
                </xsl:when>
                <xsl:when test=".='f7107ab3-9c09-4bcb-a637-368f39e0b140'">
                    <mods:form>projected image -- filmstrip cartridge</mods:form>
                </xsl:when>
                <xsl:when test=".='9166e7c9-7edb-4180-b57e-e495f551297f'">
                    <mods:form>projected image -- other</mods:form>
                </xsl:when>
                <xsl:when test=".='eb860cea-b842-4a8b-ab8d-0739856f0c2c'">
                    <mods:form>projected image -- overhead transparency</mods:form>
                </xsl:when>
                <xsl:when test=".='b2b39d2f-856b-4419-93d3-ed1851f91b9f'">
                    <mods:form>projected image -- slide</mods:form>
                </xsl:when>
                <xsl:when test=".='7c9b361d-66b6-4e4c-ae4b-2c01f655612c'">
                    <mods:form>stereographic -- other</mods:form>
                </xsl:when>
                <xsl:when test=".='e62f4860-b3b0-462e-92b6-e032336ab663'">
                    <mods:form>stereographic -- stereograph card</mods:form>
                </xsl:when>
                <xsl:when test=".='c3f41d5e-e192-4828-805c-6df3270c1910'">
                    <mods:form>stereographic -- stereograph disc</mods:form>
                </xsl:when>
                <xsl:when test=".='5fa3e09f-2192-41a9-b4bf-9eb8aef0af0a'">
                    <mods:form>unmediated -- card</mods:form>
                </xsl:when>
                <xsl:when test=".='affd5809-2897-42ca-b958-b311f3e0dcfb'">
                    <mods:form>unmediated -- flipchart</mods:form>
                </xsl:when>
                <xsl:when test=".='926662e9-2486-4bb9-ba3b-59bd2e7f2a0c'">
                    <mods:form>unmediated -- object</mods:form>
                </xsl:when>
                <xsl:when test=".='2802b285-9f27-4c86-a9d7-d2ac08b26a79'">
                    <mods:form>unmediated -- other</mods:form>
                </xsl:when>
                <xsl:when test=".='68e7e339-f35c-4be2-b161-0b94d7569b7b'">
                    <mods:form>unmediated -- roll</mods:form>
                </xsl:when>
                <xsl:when test=".='5913bb96-e881-4087-9e71-33a43f68e12e'">
                    <mods:form>unmediated -- sheet</mods:form>
                </xsl:when>
                <xsl:when test=".='8d511d33-5e85-4c5d-9bce-6e3c9cd0c324'">
                    <mods:form>unmediated -- volume</mods:form>
                </xsl:when>
                <xsl:when test=".='98f0caa9-d38e-427b-9ec4-454de81a94d7'">
                    <mods:form>unspecified -- unspecified</mods:form>
                </xsl:when>
                <xsl:when test=".='e3179f91-3032-43ee-be97-f0464f359d9c'">
                    <mods:form>video -- other</mods:form>
                </xsl:when>
                <xsl:when test=".='132d70db-53b3-4999-bd79-0fac3b8b9b98'">
                    <mods:form>video -- video cartridge</mods:form>
                </xsl:when>
                <xsl:when test=".='431cc9a0-4572-4613-b267-befb0f3d457f'">
                    <mods:form>video -- videocassette</mods:form>
                </xsl:when>
                <xsl:when test=".='7f857834-b2e2-48b1-8528-6a1fe89bf979'">
                    <mods:form>video -- videodisc</mods:form>
                </xsl:when>
                <xsl:when test=".='ba0d7429-7ccf-419d-8bfb-e6a1200a8d20'">
                    <mods:form>video -- videotape reel</mods:form>
                </xsl:when>
            </xsl:choose>
        </mods:physicalDescription>
    </xsl:template>
 
    <!-- covering some of the reference data -->
    <xsl:template match="identifiers" mode="instance">
        <xsl:choose>
            <xsl:when test="identifierTypeId='8261054f-be78-422d-bd51-4ed9f33c3422'">
                <mods:identifier type="8261054f-be78-422d-bd51-4ed9f33c3422" displayLabel="ISBN" typeURI="http://id.loc.gov/vocabulary/identifiers/isbn">
                    <xsl:value-of select="value"/>
                </mods:identifier>
            </xsl:when>
            <xsl:when test="identifierTypeId='913300b2-03ed-469a-8179-c1092c991227'">
                <mods:identifier type="913300b2-03ed-469a-8179-c1092c991227" displayLabel="ISSN" typeURI="http://id.loc.gov/vocabulary/identifiers/issn">
                    <xsl:value-of select="value"/>
                </mods:identifier>
            </xsl:when>
            <xsl:when test="identifierTypeId='ebfd00b6-61d3-4d87-a6d8-810c941176d5'">
                <mods:identifier type="ebfd00b6-61d3-4d87-a6d8-810c941176d5" displayLabel="ISMN" typeURI="http://id.loc.gov/vocabulary/identifiers/ismm">
                    <xsl:value-of select="value"/>
                </mods:identifier>
            </xsl:when>
            <xsl:when test="identifierTypeId='39554f54-d0bb-4f0a-89a4-e422f6136316'">
                <mods:identifier type="39554f54-d0bb-4f0a-89a4-e422f6136316" displayLabel="DOI" typeURI="http://id.loc.gov/vocabulary/identifiers/doi">
                    <xsl:value-of select="value"/>
                </mods:identifier>
            </xsl:when>
            <xsl:when test="identifierTypeId='eb7b2717-f149-4fec-81a3-deefb8f5ee6b'">
                <mods:identifier type="eb7b2717-f149-4fec-81a3-deefb8f5ee6b" displayLabel="URN" typeURI="http://id.loc.gov/vocabulary/identifiers/urn">
                    <xsl:value-of select="value"/>
                </mods:identifier>
            </xsl:when>
            <xsl:when test="identifierTypeId='216b156b-215e-4839-a53e-ade35cb5702a'">
                <mods:identifier type="216b156b-215e-4839-a53e-ade35cb5702a" displayLabel="Handle" typeURI="http://id.loc.gov/vocabulary/identifiers/hdl">
                    <xsl:value-of select="value"/>
                </mods:identifier>
            </xsl:when>
            <xsl:otherwise>
                <mods:identifier type="{identifierTypeId}">
                    <xsl:value-of select="value"/>
                </mods:identifier>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="languages" mode="instance">
        <mods:language>
            <mods:languageTerm type="code" authority="iso639-2b"><xsl:value-of select="."/></mods:languageTerm> 
        </mods:language>   
    </xsl:template>
    
    <xsl:template match="notes" mode="instance">
        <xsl:if test="staffOnly=0">
            <mods:note><xsl:value-of select="note"/></mods:note>
        </xsl:if>
    </xsl:template>
   
    <xsl:template match="callNumber" mode="holdings">
        <mods:shelfLocator>
            <xsl:if test="../callNumberPrefix/text()"><xsl:value-of select="../callNumberPrefix"/><xsl:text> </xsl:text></xsl:if>
                <xsl:value-of select="."/>
            <xsl:if test="../callNumberSuffix/text()"><xsl:text> </xsl:text><xsl:value-of select="../callNumberSuffix"/></xsl:if>
        </mods:shelfLocator>
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
            <xsl:apply-templates select="chronology" mode="item"/>
            <xsl:apply-templates select="barcode" mode="item"/>
            <xsl:apply-templates select="copyNumber" mode="item"/>
            <xsl:apply-templates select="hrid" mode="item"/>
            <xsl:apply-templates select="id" mode="item"/>
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
    
    <xsl:template match="bareHoldingsItems/hrid" mode= "item"> <!-- mode not reliable in libxslt -->
        <mods:itemIdentifier type="hrid"><xsl:value-of select="."/></mods:itemIdentifier>
    </xsl:template>
    
    <xsl:template match="copyNumber" mode="item">
        <xsl:if test="text()">
            <mods:itemIdentifier type="copyNumber"><xsl:value-of select="."/></mods:itemIdentifier>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="bareHoldingsItems/id" mode="item"> <!-- mode not reliable in libxslt -->
        <mods:itemIdentifier type="uuid"><xsl:value-of select="."/></mods:itemIdentifier>
    </xsl:template>
    
    <xsl:template match="materialType" mode="item"> 
        <mods:form><xsl:value-of select="name"/></mods:form>
    </xsl:template>
    
    <xsl:template match="holdingsRecords2/notes" mode="item">
        <mods:note type="{holdingsNoteType/name}"><xsl:value-of select="note"/></mods:note>
    </xsl:template>

    <xsl:template match="chronology" mode="item">
        <xsl:if test="text()">
            <mods:enumerationAndChronology unitType="1"><xsl:value-of select="."/></mods:enumerationAndChronology>
        </xsl:if>
    </xsl:template>

    <xsl:template match="text()" mode="instance"/>
</xsl:stylesheet>
