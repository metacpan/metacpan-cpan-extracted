package Net::Amazon::MechanicalTurk::QAPValidator;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk::BaseObject;
use Net::Amazon::MechanicalTurk::ModuleUtil;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };

#TODO: Write an implementation for LibXML or Xerces
our @IMPLEMENTATIONS = qw{
    Net::Amazon::MechanicalTurk::QAPValidator::QAPValidatorMSXML
};

our $QUESTION_FORM_SCHEMA_2005_10_01;
our $QUESTION_FORM_NAMESPACE_2005_10_01 = "http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd";

sub questionFormNamespace {
    return $QUESTION_FORM_NAMESPACE_2005_10_01;
}

sub questionFormXSD {
    return $QUESTION_FORM_SCHEMA_2005_10_01;
}

sub create {
    my $self = shift;
    my $module = Net::Amazon::MechanicalTurk::ModuleUtil->requireFirst(@IMPLEMENTATIONS);
    return $module->new(@_);
}

$QUESTION_FORM_SCHEMA_2005_10_01 = <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd" targetNamespace="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd" elementFormDefault="qualified" attributeFormDefault="unqualified">
    <xs:element name="QuestionForm">
        <xs:complexType>
            <xs:sequence>
                <xs:element name="Overview" type="tns:ContentType" minOccurs="0"/>
                <xs:element name="Question" maxOccurs="unbounded">
                    <xs:complexType>
                        <xs:sequence>
                            <xs:element name="QuestionIdentifier" type="xs:string"/>
                            <xs:element name="DisplayName" type="xs:string" minOccurs="0"/>
                            <xs:element name="IsRequired" type="xs:boolean" minOccurs="0"/>
                            <xs:element name="QuestionContent" type="tns:ContentType"/>
                            <xs:element name="AnswerSpecification" type="tns:AnswerSpecificationType"/>
                        </xs:sequence>
                    </xs:complexType>
                </xs:element>
            </xs:sequence>
        </xs:complexType>
    </xs:element>
    <xs:complexType name="AnswerSpecificationType">
        <xs:choice>
            <xs:element name="FreeTextAnswer" type="tns:FreeTextAnswerType"/>
            <xs:element name="SelectionAnswer" type="tns:SelectionAnswerType"/>
            <xs:element name="FileUploadAnswer" type="tns:FileUploadAnswerType"/>
        </xs:choice>
    </xs:complexType>
    <xs:complexType name="ContentType">
        <xs:choice maxOccurs="unbounded">
            <xs:element name="Title" type="xs:string"/>
            <xs:element name="Text" type="xs:string"/>
            <xs:element name="List">
                <xs:complexType>
                    <xs:sequence>
                        <xs:element name="ListItem" type="xs:string" maxOccurs="unbounded"/>
                    </xs:sequence>
                </xs:complexType>
            </xs:element>
            <xs:element name="FormattedContent" type="xs:string"/>
            <xs:element name="Binary" type="tns:BinaryContentType"/>
            <xs:element name="Application" type="tns:ApplicationContentType"/>
            <xs:element name="EmbeddedBinary" type="tns:EmbeddedBinaryContentType"/>
        </xs:choice>
    </xs:complexType>

	<xs:complexType name="ApplicationContentType">
          <xs:choice>
              <xs:element name="Flash" type="tns:FlashContentType"/>
              <xs:element name="JavaApplet" type="tns:JavaAppletContentType"/>
          </xs:choice>
     </xs:complexType>
     <xs:complexType name="FlashContentType">
      <xs:sequence>
         <xs:element name="FlashMovieURL" type="tns:URLType" />
         <xs:element name="Width"    type="xs:string"  />
         <xs:element name="Height"   type="xs:string" />
         <xs:element name="ApplicationParameter" type="tns:ApplicationParameter" minOccurs="0" maxOccurs="unbounded"/>     
      </xs:sequence>       
    </xs:complexType>

     <xs:complexType name="JavaAppletContentType">
      <xs:sequence>
         <xs:element name="AppletPath" type="tns:URLType" />
         <xs:element name="AppletFilename"    type="xs:string"  />
         <xs:element name="Width" type="xs:string"/> 
         <xs:element name="Height"   type="xs:string" />
         <xs:element name="ApplicationParameter" type="tns:ApplicationParameter" minOccurs="0" maxOccurs="unbounded"/>   
      </xs:sequence>       
    </xs:complexType>

    <xs:complexType name="MimeType">
        <xs:sequence>
            <xs:element name="Type">
                <xs:simpleType>
                    <xs:restriction base="xs:string">
                        <xs:enumeration value="image"/>
                        <xs:enumeration value="audio"/>
                        <xs:enumeration value="video"/>
                    </xs:restriction>
                </xs:simpleType>
            </xs:element>
            <xs:element name="SubType" type="xs:string" minOccurs="0"/>
        </xs:sequence>
    </xs:complexType>
    
    <!-- Content  of this  type opens  a new window -->
    <xs:complexType name="BinaryContentType">    
      <xs:sequence>
            <xs:element name="MimeType" type="tns:MimeType"/>
            <xs:element name="DataURL"  type="tns:URLType"/>
            <xs:element name="AltText"  type="xs:string"/>
         </xs:sequence>       
    </xs:complexType>
    
    <xs:complexType name="EmbeddedMimeType">
        <xs:sequence>
            <xs:element name="Type"    type="xs:string" />
            <xs:element name="SubType" type="xs:string" />
         </xs:sequence>
    </xs:complexType>
    
    
   <!-- Content of this type displays within the user's browser, plug-in dependent -->
    
   <xs:complexType name="EmbeddedBinaryContentType">    
      <xs:sequence>
            <xs:element name="EmbeddedMimeType" type="tns:EmbeddedMimeType"/>
            <xs:element name="DataURL"  type="tns:URLType"/>
            <xs:element name="AltText"  type="xs:string"/>
            <xs:element name="Width"    type="xs:string"/>
            <xs:element name="Height"   type="xs:string"/>
            <xs:element name="ApplicationParameter" type="tns:ApplicationParameter" minOccurs="0" maxOccurs="unbounded"/>   
        </xs:sequence>       
    </xs:complexType>  
       
    <xs:complexType name="FreeTextAnswerType">
        <xs:sequence>
            <xs:element name="Constraints" minOccurs="0">
                <xs:complexType>
                    <xs:sequence>
                        <xs:element name="IsNumeric" minOccurs="0">
                            <xs:complexType>
                                <xs:simpleContent>
                                    <xs:extension base="xs:anySimpleType">
                                        <xs:attribute name="minValue" type="xs:int" use="optional"/>
                                        <xs:attribute name="maxValue" type="xs:int" use="optional"/>
                                    </xs:extension>
                                </xs:simpleContent>
                            </xs:complexType>
                        </xs:element>
                        <xs:element name="Length" minOccurs="0">
                            <xs:complexType>
                                <xs:simpleContent>
                                    <xs:extension base="xs:anySimpleType">
                                        <xs:attribute name="minLength" type="xs:nonNegativeInteger" use="optional"/>
                                        <xs:attribute name="maxLength" type="xs:positiveInteger" use="optional"/>
                                    </xs:extension>
                                </xs:simpleContent>
                            </xs:complexType>
                        </xs:element>
                    </xs:sequence>
                </xs:complexType>
            </xs:element>
            <xs:element name="DefaultText" type="xs:string" minOccurs="0"/>
            <xs:element name="NumberOfLinesSuggestion" type="xs:positiveInteger" minOccurs="0"/>
        </xs:sequence>
    </xs:complexType>
    <xs:complexType name="SelectionAnswerType">
        <xs:sequence>
            <xs:element name="MinSelectionCount" type="xs:nonNegativeInteger" minOccurs="0"/>
            <xs:element name="MaxSelectionCount" type="xs:positiveInteger" minOccurs="0"/>
            <xs:element name="StyleSuggestion" minOccurs="0">
                <xs:simpleType>
                    <xs:restriction base="xs:string">
                        <xs:enumeration value="radiobutton"/>
                        <xs:enumeration value="checkbox"/>
                        <xs:enumeration value="list"/>
                        <xs:enumeration value="dropdown"/>
                        <xs:enumeration value="combobox"/>
                        <xs:enumeration value="multichooser"/>
                    </xs:restriction>
                </xs:simpleType>
            </xs:element>
            <xs:element name="Selections">
                <xs:complexType>
                    <xs:sequence>
                        <xs:element name="Selection" maxOccurs="unbounded">
                            <xs:complexType>
                                <xs:sequence>
                                    <xs:element name="SelectionIdentifier" type="xs:string"/>
                                    <xs:choice>
                                        <xs:element name="Text" type="xs:string"/>
                                        <xs:element name="Binary" type="tns:BinaryContentType"/>
                                    </xs:choice>
                                </xs:sequence>
                            </xs:complexType>
                        </xs:element>
                        <xs:element name="OtherSelection" type="tns:FreeTextAnswerType" minOccurs="0"/>
                    </xs:sequence>
                </xs:complexType>
            </xs:element>
        </xs:sequence>
    </xs:complexType>
    
    <xs:complexType name="FileUploadAnswerType">
        <xs:sequence>
          <xs:element type="tns:MaxFileSizeType" name="MaxFileSizeInBytes"/>
          <xs:element type="tns:MinFileSizeType" name="MinFileSizeInBytes"/>
        </xs:sequence>
    </xs:complexType>

    <xs:simpleType name="MaxFileSizeType">
      <xs:restriction base="xs:positiveInteger">
        <xs:maxInclusive value="2000000000"/>
      </xs:restriction>
    </xs:simpleType>
    
    <xs:simpleType name="MinFileSizeType">
      <xs:restriction base="xs:positiveInteger">
        <xs:maxInclusive value="2000000000"/>
      </xs:restriction>
    </xs:simpleType>

    <xs:simpleType name="URLType">
        <xs:restriction base="xs:anyURI">
            <xs:pattern value="(http|https)://.*"/>
        </xs:restriction>
    </xs:simpleType>


    <xs:complexType name="ApplicationParameter">
        <xs:sequence>
            <xs:element name="Name"  type="xs:string" />    
            <xs:element name="Value" type="xs:string" />     
        </xs:sequence>
    </xs:complexType> 
    
</xs:schema>
END_XML

return 1;
