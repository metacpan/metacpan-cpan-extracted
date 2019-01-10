package OTRS::OPM::Maker::Command::sopmtest;

# ABSTRACT: Check if sopm is valid

use strict;
use warnings;

use Path::Class ();
use XML::LibXML;

use OTRS::OPM::Maker -command;

our $VERSION = '0.16';

sub abstract {
    return "check .sopm if it is valid";
}

sub usage_desc {
    return "opmbuild sopmtest <path_to_sopm>";
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    
    $self->usage_error( 'need path to .sopm' ) if
        !$args or
        'ARRAY' ne ref $args or
        !defined $args->[0] or
        $args->[0] !~ /\.sopm\z/ or
        !-f $args->[0];
}

sub execute {
    my ($self, $opt, $args) = @_;
    
    my $file = $args->[0];
    
    my $check_result;
    my $tree;
    
    eval {
        my $parser = XML::LibXML->new;
        $tree      = $parser->parse_file( $file );
        1;
    } or do { print "Cannot parse .sopm: $@\n"; return };
    
    eval {
        my $xsd    = do{ local $/; <DATA> };
        my $schema = XML::LibXML::Schema->new( string => $xsd );
        $schema->validate( $tree );
        1;
    } or do {
        print ".sopm is not valid: $@\n";
        return;
    };
    
    return 1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Maker::Command::sopmtest - Check if sopm is valid

=head1 VERSION

version 0.16

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__DATA__
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:import namespace="http://www.w3.org/XML/1998/namespace"/>
    
    <xs:element name="otrs_package">
        <xs:complexType>
            <xs:choice maxOccurs="unbounded">
                <xs:element ref="CVS" minOccurs="0" />
                <xs:element ref="Name"/>
                <xs:element ref="Version"/>
                <xs:element ref="Vendor"/>
                <xs:element ref="URL"/>
                <xs:element ref="License"/>
                <xs:element ref="ChangeLog" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="Description" maxOccurs="unbounded" />
                <xs:element ref="Framework" maxOccurs="unbounded" />
                <xs:element ref="OS" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IntroInstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IntroUninstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IntroReinstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IntroUpgrade" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="PackageRequired" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="ModuleRequired" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="CodeInstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="CodeUpgrade" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="CodeUninstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="CodeReinstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="BuildDate" minOccurs="0" />
                <xs:element ref="BuildHost" minOccurs="0" />
                <xs:element ref="Filelist"/>
                <xs:element ref="DatabaseInstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="DatabaseUpgrade" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="DatabaseReinstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="DatabaseUninstall" minOccurs="0" maxOccurs="unbounded" />
            </xs:choice>
            <xs:attribute name="version" use="required" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="ChangeLog">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Date" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Version" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="Description">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Lang" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Format" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Translatable" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="Filelist">
        <xs:complexType>
            <xs:sequence>
                <xs:element ref="File" maxOccurs="unbounded" />
            </xs:sequence>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="File">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Location" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Permission" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="PackageRequired">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Version" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="ModuleRequired">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Version" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="IntroInstall">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Lang" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Title" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Translatable" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Format" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="IntroUninstall">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Lang" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Title" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Translatable" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Format" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="IntroReinstall">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Lang" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Title" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Translatable" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Format" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="IntroUpgrade">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Lang" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Title" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Translatable" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Format" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="CodeInstall">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="CodeUninstall">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="CodeReinstall">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="CodeUpgrade">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="CVS" type="xs:token"/>
    <xs:element name="Name" type="xs:token"/>
    <xs:element name="Vendor" type="xs:token"/>
    <xs:element name="URL" type="xs:token"/>
    <xs:element name="Framework" type="xs:token"/>
    <xs:element name="Version" type="xs:token"/>
    <xs:element name="License" type="xs:token"/>
    <xs:element name="OS" type="xs:token"/>
    <xs:element name="BuildDate" type="xs:token"/>
    <xs:element name="BuildHost" type="xs:token"/>
    
    
    <!--                -->
    <!-- Database stuff -->
    <!--                -->
    
    <xs:element name="DatabaseInstall">
        <xs:complexType>
            <xs:choice maxOccurs="unbounded">
                <xs:element ref="TableCreate" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="TableAlter" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="Insert" minOccurs="0" maxOccurs="unbounded" />
            </xs:choice>
            <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    <xs:element name="DatabaseUninstall">
        <xs:complexType>
            <xs:choice maxOccurs="unbounded">
                <xs:element ref="TableDrop" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="TableAlter" minOccurs="0" maxOccurs="unbounded" />
            </xs:choice>
            <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    <xs:element name="DatabaseReinstall">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="DatabaseUpgrade">
        <xs:complexType>
            <xs:choice maxOccurs="unbounded">
                <xs:element ref="TableCreate" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="TableAlter" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="Insert" minOccurs="0" maxOccurs="unbounded" />
            </xs:choice>
            <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="TableCreate">
        <xs:complexType>
            <xs:choice maxOccurs="unbounded">
                <xs:element ref="Column" maxOccurs="unbounded" />
                <xs:element ref="ForeignKey" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="Index" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="Unique" minOccurs="0" maxOccurs="unbounded" />
            </xs:choice>
            <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            <xs:attribute name="Name" use="optional" type="xs:anySimpleType"/>
            <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="TableAlter">
        <xs:complexType>
            <xs:choice maxOccurs="unbounded">
                <xs:element ref="ColumnAdd" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="ColumnChange" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="ColumnDrop" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="ForeignKeyCreate" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="ForeignKeyDrop" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IndexCreate" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IndexDrop" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="UniqueCreate" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="UniqueDrop" minOccurs="0" maxOccurs="unbounded" />
            </xs:choice>
            <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            <xs:attribute name="Name" use="optional" type="xs:anySimpleType"/>
            <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="TableDrop">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <!-- Columns -->
    
    <xs:element name="Column">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="AutoIncrement" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Required" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Size" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="PrimaryKey" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Default" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="ColumnAdd">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="AutoIncrement" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Required" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Size" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="PrimaryKey" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Default" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="ColumnChange">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Default" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="NameOld" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="NameNew" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="AutoIncrement" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Required" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Size" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="PrimaryKey" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    <xs:element name="ColumnDrop">
        <xs:complexType>
            <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <!-- Foreign Keys -->
    
    <xs:element name="ForeignKey">
        <xs:complexType>
            <xs:sequence>
                <xs:element ref="Reference" maxOccurs="unbounded" />
            </xs:sequence>
            <xs:attribute name="ForeignTable" use="required" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="ForeignKeyCreate">
        <xs:complexType>
            <xs:sequence>
                <xs:element ref="Reference" maxOccurs="unbounded" />
            </xs:sequence>
            <xs:attribute name="ForeignTable" use="required" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="ForeignKeyDrop">
        <xs:complexType>
            <xs:sequence>
                <xs:element ref="Reference" maxOccurs="unbounded" />
            </xs:sequence>
            <xs:attribute name="ForeignTable" use="required" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="Reference">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Local" use="required" type="xs:anySimpleType"/>
                    <xs:attribute name="Foreign" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <!-- Unique columns -->
    
    <xs:element name="Unique">
        <xs:complexType>
            <xs:sequence>
                <xs:element ref="UniqueColumn" maxOccurs="unbounded" />
            </xs:sequence>
            <xs:attribute name="Name" use="optional" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="UniqueColumn">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="UniqueCreate">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="UniqueDrop">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <!-- Index columns -->
    
    <xs:element name="Index">
        <xs:complexType>
            <xs:sequence>
                <xs:element ref="IndexColumn" maxOccurs="unbounded" />
            </xs:sequence>
            <xs:attribute name="Name" use="optional" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="IndexColumn">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="IndexCreate">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="IndexDrop">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
    <!-- Insert stuff into database -->
    
    <xs:element name="Insert">
        <xs:complexType>
            <xs:sequence>
                <xs:element ref="Data" maxOccurs="unbounded" />
            </xs:sequence>
            <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            <xs:attribute name="Table" use="required" type="xs:anySimpleType"/>
            <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="Data">
        <xs:complexType>
            <xs:simpleContent>
                <xs:extension base="xs:string">
                    <xs:attribute name="Key" use="optional" type="xs:anySimpleType"/>
                    <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xs:element>
    
</xs:schema>
