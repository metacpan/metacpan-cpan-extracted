package OpenXML::Properties;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Moose;

use XML::XPath;
use XML::XPath::XMLParser;
use Data::Dumper;
use String::Random;
use File::Basename;
use Archive::Zip;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use Readonly;

Readonly::Scalar our $CUSTOM_XML_TOP_LEVEL => qq^<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>^.
						qq^<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"^ .
						qq^  xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">^ .
						qq^</Properties>^;

Readonly::Scalar our $MSO_2010_RELS_TYPE =>	"http://schemas.openxmlformats.org/officeDocument/2006/relationships/custom-properties";

Readonly::Scalar our $MSO_2010_CONTENT_TYPE => "application/vnd.openxmlformats-officedocument.custom-properties+xml";

# Constant format id used for all custom props
Readonly::Scalar our $MSO_2010_CUSTOM_FMTID => "{D5CDD505-2E9C-101B-9397-08002B2CF9AE}";


has 'FileName' =>
(
	is       => 'rw',
	isa      => 'Str',
	required => 1
);

has 'zip' =>
(
	is      => 'rw',
	isa     => 'Archive::Zip',
	lazy    => 1,
	builder => 'read_doc',
);

has 'properties' => 
(
	traits     => ['Hash'],
	is         => 'rw',
	isa        => 'HashRef',
	builder    => 'get_custom_props',
	lazy       => 1,
	auto_deref => 1,
	handles    => 
	{
		custom_prop          => 'accessor',
		has_custom_property  => 'exists',
		custom_properties_names         => 'keys',
		custom_prop_values   => 'values',
		has_custom_properties     => 'count',
		delete_custom_prop   => 'delete',
	},
);

has 'pids' =>
(
	traits     => ['Hash'],
	is         => 'rw',
	isa        => 'HashRef',
	default    => sub{{}},
	auto_deref => 1,
	lazy       => 1,
	handles    => 
	{
		all_pids   => 'keys',
		pid        => 'accessor',
		has_pid    => 'exists',
		count_pids => 'count',
		delete_pid => 'delete'
	},
);

has 'custom_xml' => 
(
	traits  => ['Bool'],
	is      => 'rw',
	isa	    => 'Bool',
	lazy    => 1,
	default => 0,
);

has 'custom_xp' =>
(
	is      => 'rw',
	isa     => 'XML::XPath',
	lazy    => 1,
	builder => 'get_custom_xp'
);

has 'verbose' =>
(
	is       => 'rw',
	isa      => 'Int',
	default  => 0
);

our $logfh;

sub verify
{
	my ($doc) = @_;

	my $temp;
	my %info;
	my $i;
	my @n;

	if(! -e $doc)
	{
		Carp::croak("File $doc does not exist");
	}

	# verify the structure of the file before moving on
	open(DOC, $doc) or return "Could not open $doc: $!";
	binmode(DOC);

	# read the header (30 bytes + name)
	seek(DOC, 0, 0);
	read(DOC, $temp, 30);

	# and the to parse the header into appropriate variables
	(
		$info{'magic'},       $info{'version'},       $info{'general'},
		$info{'comp_method'}, $info{'last_mod_time'}, $info{'last_mod_date'},
		$info{'crc2'},        $info{'compr_size'},    $info{'size'},
		$info{'filename_length'}, $info{'extra_length'} 
	) = unpack( "VvvvvvVVVvv", $temp );

	# now to read the name part
	for( my $i = 0; $i < $info{'filename_length'} ; $i++ )
	{	
		seek(DOC, 30 + $i, 0);
		read(DOC, $temp, 1);

		push(@n, $temp); 
	}

	# join the name part
	$info{'filename'} = join('', @n);
	# remove control characters
	$info{'filename'} =~ s/[[:cntrl:]]//g;

	close(DOC);

	# now to verify structure
	if( $info{'magic'} eq 0x04034b50 )
	{
		# this is a ZIP archive, now confirm that this is an OpenXML document
		if( $info{'filename'} !~ m/Content_Types/ )
		{
			return "$doc is a ZIP file but not an OpenXML document";
		}
	}
	else
	{
		return "This document( $doc ) is not a ZIP archive " .
		       "and therefore cannot be an OpenXML document";
	}
	
	return "";
}

sub add_custom_property
{
	my ($self, $prop_name, $prop_value) = ($_[0], $_[1], $_[2], $_[3]);

	print "Adding custom prop $prop_name to file: " . $self->FileName . "\n";

	my $pid;
	my %props;
	my %pids;
	my %classes;
	my $custom_xp;

	if ($self->has_custom_properties == 0)
	{
		$pid = 2;
		if ($self->custom_xml == 0)
		{
			print "Custom xml does not exist, adding first custom prop\n";
			add_first_custom_prop($self, $prop_name, $prop_value);
		}
	}
	else
	{
		$pid = $self->pid('max') + 1;
	}

	if ($self->has_custom_property($prop_name))
	{
		print "Custom property $prop_name already exists, removing\n";
		remove_custom_property($self, $prop_name);
	}


	my $custom_xml = add_node($self, 'docProps/custom.xml', 
							'//Properties', "property",
							["fmtid", $MSO_2010_CUSTOM_FMTID],
							["pid", $pid],
							["name", $prop_name],
							{"vt:lpwstr" => $prop_value});

	my ($content, $error) = $self->zip->contents('docProps/custom.xml',
													$custom_xml);
	if ($error)
	{
		Carp::croak('Could not write back modified contents ' . 
					'to docProps/custom.xml');
	}
	
	$self->custom_prop($prop_name => {'pid'       => $pid, 
									  'vt:lpwstr' => $prop_value, 
									  'property'  => 'property'});
	$self->pid($pid => $prop_name);
	$self->pid('max' => $pid);

	logit("custom.xml after adding property\n" . 
			$self->zip->contents('docProps/custom.xml')) if $self->verbose;

	return "";
}

sub remove_custom_property
{
	my ($self, $prop) = @_;
	my $xp;
	my $xml;

	if ($self->has_custom_property($prop))
	{
		$xp = XML::XPath->new(xml => 
								$self->zip->contents('docProps/custom.xml'));

		my ($node) = $xp->findnodes('//property[@name="' . $prop . '"' );
		my $parent = $node->getParentNode;
		logit("custom.xml contents before removing property\n" . 
				$parent->toString . "\n");

		$parent->removeChild($node);
		$xml = $parent->toString;
	}
	else
	{
		return "Property $prop does not exist";
	}
	
	$self->zip->contents('docProps/custom.xml', $xml);

	$self->delete_custom_prop($prop);
	my %pids = %{$self->pids};
	my $max = 0;
	my $deleted_pid;
	foreach my $pid (keys %pids)
	{
		if ($pids{$pid} eq $prop)
		{
			$self->delete_pid($pid);
			$deleted_pid = $pid;
			$self->delete_pid('max') if ($pids{max} == $pid);
		}
	}


	if ($self->count_pids != 0)
	{
		if (not $self->has_pid('max'))
		{
			%pids = %{$self->pids};
			my @sorted_pids = sort keys %pids;
			$self->pid('max' => $sorted_pids[-1]);
		}
	}

	logit("custom.xml contents after removing property\n$xml\n");

	return "";
}

sub read_doc
{
	my ($self) = @_;
	my $file = $self->FileName;
	my $err;

	if ($err = verify($file))
	{
		Carp::cluck("not an openxml office file: $err\n");
		return undef;
	}

	if ($self->verbose)
	{
		my $file = 'C:\temp\openxml_properties_log_' . $$ . '.txt';
		open ($logfh, "> $file") or return "Can not open $file: $!\n";
		$logfh->autoflush(1);
	}

	my $zip = Archive::Zip->new();

	unless ( $zip->read($self->FileName) == AZ_OK )
	{
		Carp::cluck("Could not read zip: $!");
		return undef;
	}
	return $zip;
}

sub custom_properties
{
	my ($self) = @_;

	my %props = %{$self->properties};
	my %all_props;

	foreach my $key (keys %props)
	{
		my %h = %{$props{$key}};
		$all_props{$key} = $h{'vt:lpwstr'};
	}
	return %all_props;
}

sub get_custom_xp
{
	my ($self) = @_;

	my $xp = XML::XPath->new(xml => 
								$self->zip->contents('docProps/custom.xml'));

	return $xp;
}

sub get_custom_props
{
	my ($self) = @_;

	my $path = dirname($self->FileName);
	my %properties;
	my %pids;
	my %classes;
	my $property_name = "property";

	$pids{max} = 0;

	if (not defined ($self->zip->memberNamed('docProps/custom.xml')))
	{
		print "There is no custom.xml for this doc\n";
		$self->pids({});
		$self->custom_xml(0);
		return {};
	}

	my $xp = XML::XPath->new(xml => 
								$self->zip->contents('docProps/custom.xml'));

	my @element_nodes = $xp->findnodes('//property');
	if (! @element_nodes)
	{
		logit("no property, checking for op:property") if $self->verbose;
		@element_nodes = $xp->findnodes('//op:property');
		$property_name = "op:property"
	}
	if (! @element_nodes)
	{
		logit("no custom properties in this file") if $self->verbose;
		$self->pids({});
		$self->custom_xml(1);
		return {};
	}

	foreach my $element  (@element_nodes)
	{
		my %prop;
		my $wmname;
		my $wmvalue;
		my $pid;

		logit($element->getName . "\n") if $self->verbose;
		foreach my $attribute ($element->getAttributes)
		{
			my $name  = $attribute->getName;
			my $value = $attribute->getData;

			logit(" $name => $value\n") if $self->verbose;
			$pid = $prop{$name} = $value if ($name eq "pid");
			$wmname = $value if ($name eq "name");
		}

		$prop{property} = $property_name;
		foreach my $child ($element->getChildNodes)
		{
			logit('  ' . $child->getName . ' => ' . 
					     $child->string_value . "\n") if $self->verbose;
			$prop{$child->getName} = $child->string_value;
		}
		$pids{$pid} = $wmname;
		$pids{max} = $pid if ($pid > $pids{max});
		$properties{$wmname} = {%prop};
	}
	logit("Properties = " . Dumper(\%properties) . "\n") if $self->verbose;
	logit("property ids = " . Dumper(\%pids) . "\n") if $self->verbose;

	$self->pids(\%pids);
	$self->custom_xml(1);
	return \%properties;
}

sub add_node
{
	my ($self, $zipmember, $root, $node) = @_;

	print "Adding node to $zipmember\n";
	my $xp = XML::XPath->new(xml => $self->zip->contents($zipmember));
	my($rootnode) = $xp->findnodes($root);

	logit("\n $zipmember xml before adding node\n" . 
			$rootnode->toString) if $self->verbose;

	my $newrel = XML::XPath::Node::Element->new($node);
	my $newprop = undef;
	foreach my $prop (@_)
	{
		if (ref($prop) eq "ARRAY")
		{
			my $key = ${$prop}[0];
			my $value = ${$prop}[1];
			$newrel->appendAttribute(XML::XPath::Node::Attribute->new($key, $value));
		}
		if (ref($prop) eq "HASH")
		{
			my ($key) = keys %{$prop};
			my $value = ${$prop}{$key};
			if (not defined $newprop)
			{
				$newprop = XML::XPath::Node::Element->new($key);
				$newprop->appendChild(XML::XPath::Node::Text->new($value));
				$newrel->appendChild($newprop);
			}
		}
	}
	
	$rootnode->appendChild($newrel);
	logit("\n $zipmember xml after adding node\n" . 
			$rootnode->toString) if $self->verbose;

	return $rootnode->toString;
}

sub add_first_custom_prop
{
	my ($self, $prop_name, $prop_value) = @_;

	print "Adding first custom prop\n";

	# Add node to relationships xml ('_rels/.rels')
	my $id = new String::Random;
	my $relxml = add_node($self, 
						'_rels/.rels', '//Relationships', "Relationship",
						["Id", "R". $id->randpattern("CCccnccn")],
						["Type", $MSO_2010_RELS_TYPE],
						["Target", "docProps/custom.xml"]);

	my ($content, $error) = $self->zip->contents('_rels/.rels', $relxml);
	if ($error)
	{
		Carp::croak('Could not write modified contents back to _rels/.rels');
	}

	# Add node to Content types xml ('_rels/.rels')
	my $content_type_xml = add_node($self, 
								'[Content_Types].xml', '//Types', "Override",
								["PartName", "/docProps/custom.xml"],
								["ContentType", $MSO_2010_CONTENT_TYPE]);

	($content, $error) = $self->zip->contents('[Content_Types].xml', 
												$content_type_xml);
	if ($error)
	{
		Carp::croak('Could not write modified contents' . 
					' back to [Content_Types].xml');
	}

	# Create custom.xml as it won't be present 
	# because this is the first custom prop
	if (not defined $self->zip->memberNamed('docProps/custom.xml'))
	{
		$error  = $self->zip->addString($CUSTOM_XML_TOP_LEVEL, 
										'docProps/custom.xml');
	}

	$self->custom_xml(1);

	return "";
}

sub custom_xml_exists
{
	my ($self) = @_;

	print "Checking custom xml exists or not\n";

	if ($self->zip->memberNamed('docProps/custom.xml'))
	{
		print "Custom xml exists\n";
		return 1;
	}

	print "Custom xml does not exist\n";
	return 0;
}

sub save
{
	my ($self) = @_;
	my $err;

	if ($err = $self->zip->overwrite())
	{
		return "Error writing to zip $self->FileName";
	}
	return "";
}

sub logit
{
	my ($msg) = @_;

	print $logfh scalar(localtime) . ": $msg\n";
}



__PACKAGE__->meta->make_immutable;

1; # End of OpenXML::Properties

__END__


=pod

=head1 NAME

OpenXML::Properties - Read/Write custom properties from Microsoft documents in OpenXML format (MS Office 2007 onwards).

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use OpenXML::Properties;

    $doc = OpenXML::Properties->new(FileName => 'C:\temp\test.xlsx');

    # To check if a custom property exists in the document
    if ($doc->has_custom_property($custom_property_name))
    {
        print "Document has $custom_property_name\n";
    }

    # To get the number of custom properties in the document
    $count = $doc->has_custom_properties
	print "Document has $count properties\n";
    

    # To list all custom properties in the document
    my @props = $doc->custom_properties_names;
    print "The document has the following custom properties: \n", join("\n", @props);

	# To list all custom property names along with values
	my %props = $doc->custom_properties;

	# To add a custom property
    my $err = $doc->add_custom_property($custom_property_name, $custom_property_value);
    print "Adding failed with error: $err\n" if $err;


    # To remove an existing custom property
    $err = $doc->remove_custom_property($custom_property_name);
    print "Removing failed with error: $err\n" if $err;

    $doc->save();


=head1 DESCRIPTION

OpenXML::Properties helps to check, set and remove custom properties in a 
MS Office Word, Excel and Powerpoint documents in OpenXML format, 
i.e., 2007 and higher.

Custom properties in documents of older versions of MS Office could be 
accessed/modified using the module Win32::OLE, but there are no such 
modules for OpenXML documents.

OpenXML documents are nothing but a group of xml files combined in a zip format.

Please check http://msdn.microsoft.com/en-us/office/bb265236.aspx 
for further info on OpenXML

This module uses L<Archive::Zip> to read the Office files (.docx, .xlsx and 
.pptx) and L<XML::Xpath> to read/write the xml files.

Code is written using L<Moose>.

=head1 NOTE

This module changes only the custom properties in the document but does not 
change the data. However, since this is still in a development phase, please 
take a backup of your documents before using this module.


=head1 Constructor

=over 4

The constructor to OpenXML::Properties requires the FileName argument.
The FileName is the file to which you wish to view/add/remove 
custom properties.

    my $doc = OpenXML::Properties->new(FileName => 'C:\temp\test.xlsx');

The constructor also takes an optional 'verbose' parameter. 

    my $doc = OpenXML::Properties->new(FileName => 'C:\temp\test.xlsx', verbose => 1);

'verbose' will write debugging information to 'C:\temp\openxml_properties_log_$$.txt' 
where $$ is the pid of the process.

=back

=head1 Methods

=over 4

=item add_custom_property($custom_property_name, $custom_property_value)

add_custom_property requires 2 parameters to be passed, the property name 
and value to be applied to the document. It returns error as a string, if any.
If nothing is returned, then the property was added successfully.

    $doc->add_custom_property($custom_property_name, $custom_property_value);


=item remove_custom_property($custom_property_name)

remove_custom_property requires 1 parameter, i.e., the property name to be 
removed from the document. It returns error as a string, if any.
If nothing is returned, then the property was removed successfully.

    $doc->remove_custom_property($custom_property_name);

=item has_custom_property($custom_property_name)

has_custom_property checks if the custom property exists. Returns true 
if exists, false if it does not.
    
	if ($doc->has_custom_property($custom_property_name))
    {
        print "Document has $custom_property_name\n";
    }


=item has_custom_properties($custom_property_name)

has_custom_properties returns the number of custom properties currently 
applies to the document.

    $count = $doc->has_custom_properties


=item custom_properties

custom_properties returns all custom property names and values in 
the document, as a hash.

    my %props = $doc->custom_properties;


=item custom_properties_names

custom_properties_names returns all custom properties in the document, 
as an array.

    my @props = $doc->custom_properties_names;


=back

=head1 AUTHOR

Ananth Venugopal, C<< <ananthbv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-openxml-properties at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenXML-Properties>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenXML::Properties


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenXML-Properties>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenXML-Properties>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenXML-Properties>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenXML-Properties/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ananth Venugopal.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
