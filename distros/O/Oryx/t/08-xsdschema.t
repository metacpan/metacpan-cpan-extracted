# vim: set ft=perl:
use lib 't', 'lib';

use Oryx;
use YAML;

use Test::More qw(no_plan);
use Oryx::Class(auto_deploy => 1);
use CMS::Schema;
use Oryx::Schema::XSD;

my $storage = Oryx->connect(['dbi:SQLite:dbname=test'], CMS::Schema);

my $xml = Oryx::Schema::XSD->generate(CMS::Schema)->xml;
is($xml, <<'XSD');
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <xsd:complexType name="CMS::Paragraph">
    <xsd:all>
      <xsd:attribute name="content" type="xsd:string" />
    </xsd:all>
  </xsd:complexType>
  <xsd:complexType name="CMS::Author">
    <xsd:all>
      <xsd:attribute name="last_name" type="xsd:token" />
      <xsd:attribute name="first_name" type="xsd:token" />
    </xsd:all>
  </xsd:complexType>
  <xsd:complexType name="CMS::Page">
    <xsd:all>
      <xsd:attribute name="page_num" type="xsd:integer" />
      <xsd:attribute name="title" type="xsd:token" />
      <xsd:element name="paragraphs">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element name="paragraph" type="CMS::Paragraph" />
          </xsd:sequence>
        </xsd:complexType>
      </xsd:element>
      <xsd:element name="author" type="CMS::Author" />
    </xsd:all>
  </xsd:complexType>
</xsd:schema>
XSD
