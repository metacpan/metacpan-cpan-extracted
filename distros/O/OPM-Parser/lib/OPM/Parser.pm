package OPM::Parser;

use v5.24;

# ABSTRACT: Parser for the .opm file

use strict;
use warnings;

our $VERSION = '1.06'; # VERSION

use Moo;
use MooX::HandlesVia;
use OPM::Parser::Types qw(:all);

use MIME::Base64 ();
use OPM::Validate;
use Path::Class;
use Try::Tiny;
use XML::LibXML;

# declare attributes
has product      => ( is  => 'rw', isa => Str, );
has name         => ( is  => 'rw', isa => Str, );
has version      => ( is  => 'rw', isa => VersionString, );
has vendor       => ( is  => 'rw', isa => Str, );
has url          => ( is  => 'rw', isa => Str, );
has license      => ( is  => 'rw', isa => Str, );
has description  => ( is  => 'rw', isa => Str, );
has error_string => ( is  => 'rw', isa => Str, );
has tree         => ( is  => 'rw', isa => XMLTree, );

has opm_file => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has files => (
    is          => 'rw',
    isa         => ArrayRef[HashRef],
    default     => sub{ [] },
    handles_via => 'Array',
    handles     => {
        add_file => 'push',
    },
);

has framework  => (
    handles_via => 'Array',
    is          => 'rw',
    isa         => ArrayRef[FrameworkVersionString],
    default     => sub { [] },
    handles     => {
        add_framework => 'push',
    },
);

has framework_details => (
    handles_via => 'Array',
    is          => 'rw',
    isa         => ArrayRef[HashRef],
    default     => sub { [] },
    handles     => {
        add_framework_detail => 'push',
    },
);

has dependencies => (
    handles_via => 'Array',
    is          => 'rw',
    isa         => ArrayRef[HashRef[Str]],
    default     => sub { [] },
    handles     => {
        add_dependency => 'push',
    },
);


sub documentation {
    my ($self,%params) = @_;
    
    my $doc_file;
    my $found_file;
    
    my $lang = $params{lang} || 'en';
    my $type = $params{type} || '';

    for my $file ( $self->files->@* ) {

        my $filename = $file->{filename};
        next if $filename !~ m{ \A doc/ }x;
        
        if ( !$doc_file ) {
            $doc_file   = $file;
            $found_file = $filename;
        }
        
        next if $filename !~ m{ \A doc/$lang/ }x;
        
        if ( $found_file !~ m{ \A doc/$lang/ }x ) {
            $doc_file   = $file;
            $found_file = $filename;
        }
        
        next if $type && $filename !~ m{ \A doc/[^/]+/.*\.$type \z }x;
        
        if ( $type && $found_file !~ m{ \A doc/[^/]+/.*\.$type \z }x ) {
            $doc_file   = $file;
            $found_file = $filename;
        }

        last if $found_file =~ m{ \A doc/$lang/.*\.$type \z }x;
    }
    
    return $doc_file;
}

sub validate {
    my ($self) = @_;

    $self->error_string( '' );
    
    if ( !-e $self->opm_file ) {
        $self->error_string( 'File does not exist' );
        return;
    }

    try {
        my $fh      = IO::File->new( $self->opm_file, 'r' );
        my $content = join '', $fh->getlines;
        OPM::Validate->validate( $content );
    }
    catch {
        $self->error_string( 'opm file is invalid: ' . $_ );
    };

    return if $self->error_string;
    return 1;
}

sub parse {
    my ($self, %params) = @_;

    $self->error_string( '' );
    
    if ( !-e $self->opm_file ) {
        $self->error_string( 'File does not exist' );
        return;
    }
   
    my $tree;
    try {
        my $parser = XML::LibXML->new;
        $tree      = $parser->parse_file( $self->opm_file );

        $self->tree( $tree );
    }
    catch {
        $self->error_string( 'Could not parse .opm: ' . $_ );
        return;
    };

    return if $self->error_string;
    
    my $is_valid = $self->validate;
    if ( !$params{ignore_validation} && !$is_valid ) {
        return;
    }
    
    my $root = $tree->getDocumentElement;
    
    # collect basic data
    $self->vendor(    $root->findvalue( 'Vendor' ) );
    $self->name(      $root->findvalue( 'Name' ) );
    $self->license(   $root->findvalue( 'License' ) );
    $self->version(   $root->findvalue( 'Version' ) );
    $self->url(       $root->findvalue( 'URL' ) );

    my $root_name = $root->nodeName;
    $root_name    =~ s{_package}{};

    $self->product( $root_name );
    
    # retrieve framework information
    my @frameworks = $root->findnodes( 'Framework' );
    
    FILE:
    for my $framework ( @frameworks ) {
        my $framework_version = $framework->textContent;
        
        my %details = ( Content => $framework_version );
        my $maximum = $framework->findvalue( '@Maximum' );
        my $minimum = $framework->findvalue( '@Minimum' );

        $details{Maximum} = $maximum if $maximum;
        $details{Minimum} = $minimum if $minimum;
        
        # push framework info to attribute
        $self->add_framework( $framework_version );
        $self->add_framework_detail( \%details );
    }

    # retrieve file information
    my @files = $root->findnodes( 'Filelist/File' );
    
    FILE:
    for my $file ( @files ) {
        my $name = $file->findvalue( '@Location' );
        
        #next FILE if $name !~ m{ \. (?:pl|pm|pod|t) \z }xms;
        my $encode         = $file->findvalue( '@Encode' );
        next FILE if $encode ne 'Base64';
        
        my $content_base64 = $file->textContent;
        my $content        = MIME::Base64::decode( $content_base64 );
        
        # push file info to attribute
        $self->add_file({
            filename => $name,
            content  => $content,
        });
    }
    
    # get description - english if available, any other language otherwise
    my @descriptions = $root->findnodes( 'Description' );
    my $description_string;
    
    DESCRIPTION:
    for my $description ( @descriptions ) {
        $description_string = $description->textContent;
        my $language        = $description->findvalue( '@Lang' );
        
        last DESCRIPTION if $language eq 'en';
    }
    
    $self->description( $description_string );
    
    # get Addon and CPAN dependencies
    my @addon_deps = $root->findnodes( 'PackageRequired' );
    my @cpan_deps  = $root->findnodes( 'ModuleRequired' );
    
    my %types     = (
        PackageRequired => 'Addon',
        ModuleRequired  => 'CPAN',
    );
    
    for my $dep ( @addon_deps, @cpan_deps ) {
        my $node_type = $dep->nodeName;
        my $version   = $dep->findvalue( '@Version' );
        my $dep_name  = $dep->textContent;
        my $dep_type  = $types{$node_type};
        
        $self->add_dependency({
            type    => $dep_type,
            version => $version,
            name    => $dep_name,
        });
    }
    
    return 1;
}

sub as_sopm {
    my ($self) = @_;

    my $tree = $self->tree->cloneNode(1);
    my $root = $tree->getDocumentElement;
    
    my @build_host = $root->findnodes( 'BuildHost' );
    my @build_date = $root->findnodes( 'BuildDate' );
    
    $root->removeChild( $_ ) for @build_host;
    $root->removeChild( $_ ) for @build_date;

    #$build_host->unbindNode() if $build_host;
    #$build_date->unbindNode() if $build_date;
    
    my @files = $root->findnodes( 'Filelist/File' );
    for my $file ( @files ) {
        my ($encode) = $file->findnodes( '@Encode' );
        $encode->unbindNode() if $encode;
    
        $file->removeChildNodes();
    }
    
    return $tree->toString;
}


sub _get_xsd {

    return q~<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:import namespace="http://www.w3.org/XML/1998/namespace"/>
    
    <xs:element name="otrs_package" type="Package"/>
    <xs:element name="otobo_package" type="Package" />

    <xs:complexType name="Package">
        <xs:all>
            <xs:element name="CVS" minOccurs="0" maxOccurs="1" type="xs:token"/>
            <xs:element name="Name" minOccurs="1" maxOccurs="1" type="xs:token"/>
            <xs:element name="Version" maxOccurs="1" type="xs:token"/>
            <xs:element name="Vendor" maxOccurs="1" type="xs:token"/>
            <xs:element name="URL" maxOccurs="1" type="xs:token"/>
            <xs:element name="License" maxOccurs="1" type="xs:token"/>
            <xs:element name="ChangeLog" minOccurs="0" type="ChangeLog" />
            <xs:element name="Description" maxOccurs="unbounded" type="Description" />
            <xs:element name="Framework" maxOccurs="unbounded" type="Framework" />
            <xs:element name="OS" minOccurs="0" maxOccurs="unbounded" type="xs:token"/>
            <xs:element name="IntroInstall" minOccurs="0" maxOccurs="unbounded" type="IntroInstall"/>
            <xs:element name="IntroUninstall" minOccurs="0" maxOccurs="unbounded" type="IntroUninstall"/>
            <xs:element name="IntroReinstall" minOccurs="0" maxOccurs="unbounded" type="IntroReinstall"/>
            <xs:element name="IntroUpgrade" minOccurs="0" maxOccurs="unbounded" type="IntroUpgrade"/>
            <xs:element name="PackageRequired" minOccurs="0" maxOccurs="unbounded" type="PackageRequired"/>
            <xs:element name="ModuleRequired" minOccurs="0" maxOccurs="unbounded" type="ModuleRequired"/>
            <xs:element name="CodeInstall" minOccurs="0" maxOccurs="unbounded" type="CodeInstall"/>
            <xs:element name="CodeUpgrade" minOccurs="0" maxOccurs="unbounded" type="CodeUpgrade" />
            <xs:element name="CodeUninstall" minOccurs="0" maxOccurs="unbounded" type="CodeUninstall" />
            <xs:element name="CodeReinstall" minOccurs="0" maxOccurs="unbounded" type="CodeReinstall" />
            <xs:element name="BuildDate" minOccurs="0" maxOccurs="1" type="xs:token"/>
            <xs:element name="BuildHost" minOccurs="0" maxOccurs="1" type="xs:token"/>
            <xs:element name="Filelist" minOccurs="1" maxOccurs="1" type="Filelist"/>
            <xs:element name="DatabaseInstall" minOccurs="0" maxOccurs="unbounded" type="DatabaseInstall" />
            <xs:element name="DatabaseUpgrade" minOccurs="0" maxOccurs="unbounded" type="DatabaseUpgrade" />
            <xs:element name="DatabaseReinstall" minOccurs="0" maxOccurs="unbounded" type="DatabaseReinstall" />
            <xs:element name="DatabaseUninstall" minOccurs="0" maxOccurs="unbounded" type="DatabaseUninstall" />
        </xs:all>
        <xs:attribute name="version" use="required" type="xs:anySimpleType"/>
    </xs:complexType>
    
    <xs:complexType name="ChangeLog">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Date" use="required" type="xs:anySimpleType"/>
                <xs:attribute name="Version" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <xs:complexType name="Description">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Lang" use="optional" type="xs:anySimpleType"/>
                <xs:attribute name="Format" use="optional" type="xs:anySimpleType"/>
                <xs:attribute name="Translatable" use="optional" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <xs:complexType name="Framework">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Minimum" use="optional" type="xs:anySimpleType"/>
                <xs:attribute name="Maximum" use="optional" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>

    <xs:complexType name="Filelist">
        <xs:sequence>
            <xs:element name="File" maxOccurs="unbounded" type="File" />
        </xs:sequence>
    </xs:complexType>
    
    <xs:complexType name="File">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Location" use="required" type="xs:anySimpleType"/>
                <xs:attribute name="Permission" use="required" type="xs:anySimpleType"/>
                <xs:attribute name="Encode" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <xs:complexType name="PackageRequired">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Version" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <xs:complexType name="ModuleRequired">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Version" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <xs:complexType name="IntroInstall">
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
    <xs:complexType name="IntroUninstall">
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
    <xs:complexType name="IntroReinstall">
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
    <xs:complexType name="IntroUpgrade">
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
    
    <xs:complexType name="CodeInstall">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    <xs:complexType name="CodeUninstall">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    <xs:complexType name="CodeReinstall">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    <xs:complexType name="CodeUpgrade">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
                <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <!--                -->
    <!-- Database stuff -->
    <!--                -->
    
    <xs:complexType name="DatabaseInstall">
        <xs:choice maxOccurs="unbounded">
            <xs:element name="TableCreate" minOccurs="0" maxOccurs="unbounded" type="TableCreate" />
            <xs:element name="TableAlter" minOccurs="0" maxOccurs="unbounded" type="TableAlter" />
            <xs:element name="Insert" minOccurs="0" maxOccurs="unbounded" type="Insert" />
        </xs:choice>
        <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
    </xs:complexType>
    <xs:complexType name="DatabaseUninstall">
        <xs:choice maxOccurs="unbounded">
            <xs:element name="TableDrop" minOccurs="0" maxOccurs="unbounded" type="TableDrop" />
            <xs:element name="TableAlter" minOccurs="0" maxOccurs="unbounded" type="TableAlter" />
        </xs:choice>
        <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
    </xs:complexType>
    <xs:complexType name="DatabaseReinstall">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    <xs:complexType name="DatabaseUpgrade">
        <xs:choice maxOccurs="unbounded">
            <xs:element name="TableCreate" minOccurs="0" maxOccurs="unbounded" type="TableCreate"/>
            <xs:element name="TableAlter" minOccurs="0" maxOccurs="unbounded" type="TableAlter"/>
            <xs:element name="Insert" minOccurs="0" maxOccurs="unbounded" type="Insert"/>
        </xs:choice>
        <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
        <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
    </xs:complexType>
    
    <xs:complexType name="TableCreate">
        <xs:choice maxOccurs="unbounded">
            <xs:element name="Column" maxOccurs="unbounded" type="Column"/>
            <xs:element name="ForeignKey" minOccurs="0" maxOccurs="unbounded" type="ForeignKey"/>
            <xs:element name="Index" minOccurs="0" maxOccurs="unbounded" type="Index"/>
            <xs:element name="Unique" minOccurs="0" maxOccurs="unbounded" type="Unique"/>
        </xs:choice>
        <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
        <xs:attribute name="Name" use="optional" type="xs:anySimpleType"/>
        <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
    </xs:complexType>

    <xs:complexType name="TableAlter">
        <xs:choice maxOccurs="unbounded">
            <xs:element name="ColumnAdd" minOccurs="0" maxOccurs="unbounded" type="ColumnAdd"/>
            <xs:element name="ColumnChange" minOccurs="0" maxOccurs="unbounded" type="ColumnChange"/>
            <xs:element name="ColumnDrop" minOccurs="0" maxOccurs="unbounded" type="ColumnDrop"/>
            <xs:element name="ForeignKeyCreate" minOccurs="0" maxOccurs="unbounded" type="ForeignKeyCreate"/>
            <xs:element name="ForeignKeyDrop" minOccurs="0" maxOccurs="unbounded" type="ForeignKeyDrop"/>
            <xs:element name="IndexCreate" minOccurs="0" maxOccurs="unbounded" type="IndexCreate"/>
            <xs:element name="IndexDrop" minOccurs="0" maxOccurs="unbounded" type="IndexDrop"/>
            <xs:element name="UniqueCreate" minOccurs="0" maxOccurs="unbounded" type="UniqueCreate"/>
            <xs:element name="UniqueDrop" minOccurs="0" maxOccurs="unbounded" type="UniqueDrop"/>
        </xs:choice>
        <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
        <xs:attribute name="Name" use="optional" type="xs:anySimpleType"/>
        <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
    </xs:complexType>
    
    <xs:complexType name="TableDrop">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
                <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <!-- Columns -->
    
    <xs:complexType name="Column">
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
    <xs:complexType name="ColumnAdd">
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
    <xs:complexType name="ColumnChange">
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
    <xs:complexType name="ColumnDrop">
        <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
    </xs:complexType>
    
    <!-- Foreign Keys -->
    
    <xs:complexType name="ForeignKey">
        <xs:sequence>
            <xs:element name="Reference" type="Reference" maxOccurs="unbounded" />
        </xs:sequence>
        <xs:attribute name="ForeignTable" use="required" type="xs:anySimpleType"/>
    </xs:complexType>

    <xs:complexType name="ForeignKeyCreate">
        <xs:sequence>
            <xs:element name="Reference" type="Reference" maxOccurs="unbounded" />
        </xs:sequence>
        <xs:attribute name="ForeignTable" use="required" type="xs:anySimpleType"/>
    </xs:complexType>

    <xs:complexType name="ForeignKeyDrop">
        <xs:sequence>
            <xs:element name="Reference" type="Reference" maxOccurs="unbounded" />
        </xs:sequence>
        <xs:attribute name="ForeignTable" use="required" type="xs:anySimpleType"/>
    </xs:complexType>

    <xs:complexType name="Reference">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Local" use="required" type="xs:anySimpleType"/>
                <xs:attribute name="Foreign" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <!-- Unique columns -->
    
    <xs:complexType name="Unique">
        <xs:sequence>
            <xs:element name="UniqueColumn" maxOccurs="unbounded" type="UniqueColumn"/>
        </xs:sequence>
        <xs:attribute name="Name" use="optional" type="xs:anySimpleType"/>
    </xs:complexType>

    <xs:complexType name="UniqueColumn">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>

    <xs:complexType name="UniqueCreate">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>

    <xs:complexType name="UniqueDrop">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <!-- Index columns -->
    
    <xs:complexType name="Index">
        <xs:sequence>
            <xs:element name="IndexColumn" type="IndexColumn" maxOccurs="unbounded" />
        </xs:sequence>
        <xs:attribute name="Name" use="optional" type="xs:anySimpleType"/>
    </xs:complexType>

    <xs:complexType name="IndexColumn">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>

    <xs:complexType name="IndexCreate">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>

    <xs:complexType name="IndexDrop">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Name" use="required" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
    
    <!-- Insert stuff into database -->
    
    <xs:complexType name="Insert">
        <xs:sequence>
            <xs:element name="Data" maxOccurs="unbounded" type="Data"/>
        </xs:sequence>
        <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
        <xs:attribute name="Table" use="required" type="xs:anySimpleType"/>
        <xs:attribute name="Version" use="optional" type="xs:anySimpleType"/>
    </xs:complexType>

    <xs:complexType name="Data">
        <xs:simpleContent>
            <xs:extension base="xs:string">
                <xs:attribute name="Key" use="optional" type="xs:anySimpleType"/>
                <xs:attribute name="Type" use="optional" type="xs:anySimpleType"/>
            </xs:extension>
        </xs:simpleContent>
    </xs:complexType>
</xs:schema>
~;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Parser - Parser for the .opm file

=head1 VERSION

version 1.06

=head1 SYNOPSIS

    use OPM::Parser;
    
    my $opm_file = 'QuickMerge-3.3.2.opm';
    my $opm      = OPM::Parser->new( opm_file => $opm_file );
    $opm->parse or die "OPM parse failed: ", $opm->error_string;
    
    say sprintf "This is version %s of package %s",
        $opm->version,
        $opm->name;
    
    say "You can install it on those framework versions: ", join ", ", @{ $opm->framework };
    
    say "Dependencies: ";
    for my $dep ( @{ $opm->dependencies } ) {
        say sprintf "%s (%s) - (%s)", 
            $dep->{name},
            $dep->{version},
            $dep->{type};
    }

=head1 METHODS

=head2 new

=head2 parse

Validates and parses the I<.opm> file. It returns C<1> on success and C<undef> on error.
If an error occurs, one can get the error message with C<error_string>:

    my $opm_file = 'QuickMerge-3.3.2.opm';
    my $opm      = OPM::Parser->new( opm_file => $opm_file );
    $opm->parse or die "OPM parse failed: ", $opm->error_string;

If you want to ignore validation result, you can pass C<< ignore_validation => 1 >>:

    my $opm_file = 'QuickMerge-3.3.2.opm';
    my $opm      = OPM::Parser->new( opm_file => $opm_file );
    $opm->parse( ignore_validation => 1 )
        or die "OPM parse failed: ", $opm->error_string;

=head2 as_sopm

=head2 documentation

=head2 validate

=head1 ATTRIBUTES

=over 4

=item * opm_file

=item * tree

=item * framework

=item * dependencies

=item * files

=item * error_string

=item * description

=item * license

=item * url

=item * vendor

=item * version

=item * name

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
