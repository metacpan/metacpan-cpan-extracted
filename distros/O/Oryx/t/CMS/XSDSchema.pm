package CMS::Schema;
use base qw(Oryx::Schema);
1;
__DATA__
<xsd:schema
  xmlns:CMS="http://www.oryx-test.com"
  targetNamespace="http://www.oryx-test.com"
  >
  <xsd:complexType name="CMS:Author">
    <xsd:all>
      <xsd:attribute name="first_name" type="xsd:token"/>
      <xsd:attribute name="last_name" type="xsd:token"/>
    </xsd:all>
  </xsd:complexType>

  <xsd:complexType name="CMS:Paragraph">
    <xsd:all>
      <xsd:attribute name="content" type="xsd:string"/>
    </xsd:all>
  </xsd:complexType>

  <xsd:complexType name="CMS:Page">
    <xsd:all>
      <xsd:attribute name="title" type="xsd:token"/>
      <xsd:attribute name="page_num" type="xsd:integer"/>
      <xsd:element name="author" type="CMS:Author"/>
      <xsd:element name="paragraphs">
        <xsd:complexType>
          <xsd:all>
            <xsd:attribute name="keys" type="NMTOKENS"/>
            <xsd:element name="paragraph" type="CMS:Paragraph"/>
          </xsd:all>
        </xsd:complexType>
      </xsd:element>
    </xsd:all>
  </xsd:complexType>

</xsd:schema>
