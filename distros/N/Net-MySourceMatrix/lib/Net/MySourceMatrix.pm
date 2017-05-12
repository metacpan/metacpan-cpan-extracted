package Net::MySourceMatrix;

use strict;
use 5.008005;
use SOAP::Lite;
use MIME::Base64 qw(encode_base64);

our $VERSION = '0.04';

sub new	{
		
	my ($class, $args) = @_;
	my $self = bless($args, $class);
	
	#create and initialise the soap client
	$self->{soap} = $self->create_soap_client();
	return $self;
}

sub create_soap_client {
	
	my ($self, %param) = @_;
	
	my $client = SOAP::Lite->new( proxy => $self->{proxy});
	$client->transport->http_request->header (
		'Authorization' => 'Basic '.encode_base64($self->{username}.":".$self->{password})
	);
	$client->autotype(0);
	$client->default_ns($self->{default_ns});
	return $client;
}

sub create_asset_link {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#CreateAssetLink" });
	my $som = $self->{soap}->call("CreateAssetLink",
		SOAP::Data->name('MajorID')->value($param{MajorID}),
		SOAP::Data->name('MinorID')->value($param{MinorID}),
		SOAP::Data->name('LinkType')->value($param{LinkType}),
		SOAP::Data->name('LinkValue')->value($param{LinkValue}),
		SOAP::Data->name('SortOrder')->value($param{SortOrder}),
		SOAP::Data->name('IsDependant')->value($param{IsDependant}),
		SOAP::Data->name('IsExclusive')->value($param{IsExclusive}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//CreateAssetLinkResult'),);
}

sub delete_asset_link {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#DeleteAssetLink" });
	my $som = $self->{soap}->call("DeleteAssetLink",
		SOAP::Data->name('LinkID')->value($param{LinkID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//DeleteAssetLinkResult'),);
}

sub get_all_child_links {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAllChildLinks" });
	my $som = $self->{soap}->call("GetAllChildLinks",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('LinkType')->value($param{LinkType}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAllChildLinksResult'),);
}

sub get_children {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetChildren" });
	my $som = $self->{soap}->call("GetChildren",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('TypeCode')->value($param{TypeCode}),
		SOAP::Data->name('StrictTypeCode')->value($param{StrictTypeCode}),
		SOAP::Data->name('Dependant')->value($param{Dependant}),
		SOAP::Data->name('SortBy')->value($param{SortBy}),
		SOAP::Data->name('PermissionLevel')->value($param{PermissionLevel}),
		SOAP::Data->name('EffectiveAccess')->value($param{EffectiveAccess}),
		SOAP::Data->name('MinDepth')->value($param{MinDepth}),
		SOAP::Data->name('MaxDepth')->value($param{MaxDepth}),
		SOAP::Data->name('DirectShadowsOnly')->value($param{DirectShadowsOnly}),
		SOAP::Data->name('LinkValueWanted')->value($param{LinkValueWanted}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetChildrenResult'),);
}

sub get_dependant_children {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetDependantChildren" });
	my $som = $self->{soap}->call("GetDependantChildren",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('TypeCode')->value($param{TypeCode}),
		SOAP::Data->name('StrictTypeCode')->value($param{StrictTypeCode}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetDependantChildrenResult'),);
}

sub get_dependant_parents {

	my ($self, %param)    = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetDependantParents" });
	my $som = $self->{soap}->call("GetDependantParents",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('TypeCode')->value($param{TypeCode}),
		SOAP::Data->name('StrictTypeCode')->value($param{StrictTypeCode}),
		SOAP::Data->name('IncludeAllDependants')->value($param{IncludeAllDependants}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetDependantParentsResult'),);
}

sub get_links {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetLinks" });
	my $som = $self->{soap}->call("GetLinks",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('LinkType')->value($param{LinkType}),
		SOAP::Data->name('TypeCode')->value($param{TypeCode}),
		SOAP::Data->name('StrictTypeCode')->value($param{StrictTypeCode}),
		SOAP::Data->name('SideOfLink')->value($param{SideOfLink}),
		SOAP::Data->name('LinkValue')->value($param{LinkValue}),
		SOAP::Data->name('Dependant')->value($param{Dependant}),
		SOAP::Data->name('Exclusive')->value($param{Exclusive}),
		SOAP::Data->name('SortBy')->value($param{SortBy}),
		SOAP::Data->name('PermissionLevel')->value($param{PermissionLevel}),
		SOAP::Data->name('Effective')->value($param{Effective}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetLinksResult'),);
}

sub get_link_by_asset {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetLinkByAsset" });
	my $som = $self->{soap}->call("GetLinkByAsset",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('OtherAssetID')->value($param{OtherAssetID}),
		SOAP::Data->name('LinkType')->value($param{LinkType}),
		SOAP::Data->name('LinkValue')->value($param{LinkValue}),
		SOAP::Data->name('SideOfLink')->value($param{SideOfLink}),
		SOAP::Data->name('IsDependant')->value($param{IsDependant}),
		SOAP::Data->name('IsExclusive')->value($param{IsExclusive}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetLinkByAssetResult'),);
}

sub get_link_lineages {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetLinkLineages" });
	my $som = $self->{soap}->call("GetLinkLineages",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('RootNode')->value($param{RootNode}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetLinkLineagesResult'),);
}

sub move_link {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#MoveLink" });
	my $som = $self->{soap}->call("MoveLink",
		SOAP::Data->name('LinkID')->value($param{LinkID}),
		SOAP::Data->name('LinkType')->value($param{LinkType}),
		SOAP::Data->name('ToParentID')->value($param{ToParentID}),
		SOAP::Data->name('ToParentPosition')->value($param{ToParentPosition}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//MoveLinkResult'),);
}

sub update_link {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#UpdateLink" });
	my $som = $self->{soap}->call("UpdateLink",
		SOAP::Data->name('LinkID')->value($param{LinkID}),
		SOAP::Data->name('LinkType')->value($param{LinkType}),
		SOAP::Data->name('LinkValue')->value($param{LinkValue}),
		SOAP::Data->name('SortOrder')->value($param{SortOrder}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//UpdateLinkResult'),);
}

sub get_parents {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetParents" });
	my $som = $self->{soap}->call("GetParents",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('TypeCode')->value($param{TypeCode}),
		SOAP::Data->name('StrictTypeCode')->value($param{StrictTypeCode}),
		SOAP::Data->name('SortBy')->value($param{SortBy}),
		SOAP::Data->name('PermissionLevel')->value($param{PermissionLevel}),
		SOAP::Data->name('Effective')->value($param{Effective}),
		SOAP::Data->name('MinDepth')->value($param{MinDepth}),
		SOAP::Data->name('MaxDepth')->value($param{MaxDepth}),
		SOAP::Data->name('DirectShadowOnly')->value($param{DirectShadowOnly}),
		SOAP::Data->name('LinkValueWanted')->value($param{LinkValueWanted}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetParentsResult'),);
}

sub get_parents_under_tree {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetParentsUnderTree" });
	my $som = $self->{soap}->call("GetParentsUnderTree",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('RootID')->value($param{RootID}),
		SOAP::Data->name('MinLevel')->value($param{MinLevel}),
		SOAP::Data->name('MaxLevel')->value($param{MaxLevel}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//ParentPaths'),);
}

sub has_access {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#HasAccess" });
	my $som = $self->{soap}->call("HasAccess",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('PermissionLevel')->value($param{PermissionLevel}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//HasAccessResult'),);
}

sub set_permission {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SetPermission" });
	my $som = $self->{soap}->call("SetPermission",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('UserID')->value($param{UserID}),
		SOAP::Data->name('PermissionLevel')->value($param{PermissionLevel}),
		SOAP::Data->name('Grant')->value($param{Grant}),
		SOAP::Data->name('Cascade')->value($param{Cascade}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SetPermissionResult'),);
}

sub get_permission {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetPermission" });
	my $som = $self->{soap}->call("GetPermission",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('PermissionLevel')->value($param{PermissionLevel}),
		SOAP::Data->name('Granted')->value($param{Granted}),
		SOAP::Data->name('AndGreater')->value($param{AndGreater}),
		SOAP::Data->name('ExpandGroups')->value($param{ExpandGroups}),
		SOAP::Data->name('AllInfo')->value($param{AllInfo}),
		SOAP::Data->name('CollapseRoles')->value($param{CollapseRoles}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetPermissionResult'),);
}

sub get_role {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetRole" });
	my $som = $self->{soap}->call("GetRole",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('RoleID')->value($param{RoleID}),
		SOAP::Data->name('UserID')->value($param{UserID}),
		SOAP::Data->name('IncludeAssetID')->value($param{IncludeAssetID}),
		SOAP::Data->name('IncludeGlobals')->value($param{IncludeGlobals}),
		SOAP::Data->name('ExpandGroups')->value($param{ExpandGroups}),
		SOAP::Data->name('IncludeDependants')->value($param{IncludeDependants}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetRoleResult'),);
}

sub set_role {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SetRole" });
	my $som = $self->{soap}->call("SetRole",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('RoleID')->value($param{RoleID}),
		SOAP::Data->name('UserID')->value($param{UserID}),
		SOAP::Data->name('Action')->value($param{Action}),
		SOAP::Data->name('GlobalRole')->value($param{GlobalRole}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SetRoleResult'),);
}

sub apply_design {

	my ($self, %param)     = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#ApplyDesign" });
	my $som = $self->{soap}->call("ApplyDesign",
		SOAP::Data->name('DesignID')->value($param{DesignID}),
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('DesignType')->value($param{DesignType}),
		SOAP::Data->name('UserDefinedDesignName')->value($param{UserDefinedDesignName}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//ApplyDesignResult'),);
}

sub remove_design {

	my ($self, %param)     = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#RemoveDesign" });
	my $som = $self->{soap}->call("RemoveDesign",
		SOAP::Data->name('DesignID')->value($param{DesignID}),
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('DesignType')->value($param{DesignType}),
		SOAP::Data->name('UserDefinedDesignName')->value($param{UserDefinedDesignName}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//RemoveDesignResult'),);
}

sub get_design_from_url {

	my ($self, %param)     = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetDesignFromURL" });
	my $som = $self->{soap}->call("GetDesignFromURL",
		SOAP::Data->name('URL')->value($param{URL}),
		SOAP::Data->name('DesignType')->value($param{DesignType}),
		SOAP::Data->name('UserDefinedDesignName')->value($param{UserDefinedDesignName}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetDesignFromURLResult'),);
}

sub apply_asset_paint_layout {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#ApplyAssetPaintLayout" });
	my $som = $self->{soap}->call("ApplyAssetPaintLayout",
		SOAP::Data->name('PaintLayoutID')->value($param{PaintLayoutID}),
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('PaintLayoutType')->value($param{PaintLayoutType}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//ApplyAssetPaintLayoutResult'),);
}

sub remove_asset_paint_layout {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#RemoveAssetPaintLayout" });
	my $som = $self->{soap}->call("RemoveAssetPaintLayout",
		SOAP::Data->name('PaintLayoutID')->value($param{PaintLayoutID}),
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('PaintLayoutType')->value($param{PaintLayoutType}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//RemoveAssetPaintLayoutResult'),);
}

sub download {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#Download" });
	my $som = $self->{soap}->call("Download",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//FileName'), $som->valueof('//FileType'), $som->valueof('//FileSize'), $som->valueof('//LastModified'), $som->valueof('//FileContentBase64'),);
}

sub get_file_information {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetFileInformation" });
	my $som = $self->{soap}->call("GetFileInformation",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//FileName'), $som->valueof('//FileType'), $som->valueof('//FileSize'), $som->valueof('//LastModified'),);
}

sub get_image_information {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetImageInformation" });
	my $som = $self->{soap}->call("GetImageInformation",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//FileName'), $som->valueof('//FileTitle'), $som->valueof('//FileType'), $som->valueof('//FileSize'), $som->valueof('//MimeType'), $som->valueof('//ImageWidth'), $som->valueof('//ImageHeight'), $som->valueof('//LastModified'),);
}

sub upload {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#Upload" });
	my $som = $self->{soap}->call("Upload",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('FileName')->value($param{FileName}),
		SOAP::Data->name('FileContentBase64')->value($param{FileContentBase64}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//UploadResult'),);
}

sub start_workflow {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#StartWorkflow" });
	my $som = $self->{soap}->call("StartWorkflow",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//StartWorkflowResult'),);
}

sub safe_edit_asset {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SafeEditAsset" });
	my $som = $self->{soap}->call("SafeEditAsset",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SafeEditAssetResult'),);
}

sub cancel_workflow {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#CancelWorkflow" });
	my $som = $self->{soap}->call("CancelWorkflow",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//CancelWorkflowResult'),);
}

sub complete_workflow {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#CompleteWorkflow" });
	my $som = $self->{soap}->call("CompleteWorkflow",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//CompleteWorkflowResult'),);
}

sub set_workflow_schema {

	my ($self, %param)        = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SetWorkflowSchema" });
	my $som = $self->{soap}->call("SetWorkflowSchema",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('SchemaID')->value($param{SchemaID}),
		SOAP::Data->name('Grant')->value($param{Grant}),
		SOAP::Data->name('AutoCascadeToNewChildren')->value($param{AutoCascadeToNewChildren}),
		SOAP::Data->name('Cascade')->value($param{Cascade}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SetWorkflowSchemaResult'),);
}

sub approve_asset_in_workflow {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#ApproveAssetInWorkflow" });
	my $som = $self->{soap}->call("ApproveAssetInWorkflow",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('WorkflowMessage')->value($param{WorkflowMessage}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//ApproveAssetInWorkflowResult'),);
}

sub create_asset {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#CreateAsset" });
	my $som = $self->{soap}->call("CreateAsset",
		SOAP::Data->name('TypeCode')->value($param{TypeCode}),
		SOAP::Data->name('Name')->value($param{Name}),
		SOAP::Data->name('ParentID')->value($param{ParentID}),
		SOAP::Data->name('LinkType')->value($param{LinkType}),
		SOAP::Data->name('LinkValue')->value($param{LinkValue}),
		SOAP::Data->name('SortOrder')->value($param{SortOrder}),
		SOAP::Data->name('IsDependant')->value($param{IsDependant}),
		SOAP::Data->name('IsExclusive')->value($param{IsExclusive}),
		SOAP::Data->name('FileName')->value($param{FileName}),
		SOAP::Data->name('FileContentBase64')->value($param{FileContentBase64}),
		SOAP::Data->name('AttributeInfo')->value($param{AttributeInfo}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//NewAssetID'), $som->valueof('//CreateMessage'),);
}

sub get_asset {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAsset" });
	my $som = $self->{soap}->call("GetAsset",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAssetResult'),);
}

sub get_asset_urls {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAssetURLs" });
	my $som = $self->{soap}->call("GetAssetURLs",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('RootPathAssetID')->value($param{RootPathAssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAssetURLsResult'),);
}

sub get_asset_from_url {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAssetFromURL" });
	my $som = $self->{soap}->call("GetAssetFromURL",
		SOAP::Data->name('URL')->value($param{URL}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAssetFromURLResult'),);
}

sub get_asset_available_statuses {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAssetAvailableStatuses" });
	my $som = $self->{soap}->call("GetAssetAvailableStatuses",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAssetAvailableStatusesResult'),);
}

sub set_attribute_value {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SetAttributeValue" });
	my $som = $self->{soap}->call("SetAttributeValue",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('AttributeName')->value($param{AttributeName}),
		SOAP::Data->name('AttributeValue')->value($param{AttributeValue}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SetAttributeValueResult'),);
}

sub trash_asset {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#TrashAsset" });
	my $som = $self->{soap}->call("TrashAsset",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//TrashAssetResult'),);
}

sub clone_asset {

	my ($self, %param)      = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#CloneAsset" });
	my $som = $self->{soap}->call("CloneAsset",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('NewParentID')->value($param{NewParentID}),
		SOAP::Data->name('NumberOfClone')->value($param{NumberOfClone}),
		SOAP::Data->name('PositionUnderNewParent')->value($param{PositionUnderNewParent}),
		SOAP::Data->name('LinkType')->value($param{LinkType}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//CloneAssetResult'),);
}

sub get_asset_type_attribute {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAssetTypeAttribute" });
	my $som = $self->{soap}->call("GetAssetTypeAttribute",
		SOAP::Data->name('TypeCode')->value($param{TypeCode}),
		SOAP::Data->name('AttributeDetail')->value($param{AttributeDetail}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAssetTypeAttributeResult'),);
}

sub get_asset_type_descendants {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAssetTypeDescendants" });
	my $som = $self->{soap}->call("GetAssetTypeDescendants",
		SOAP::Data->name('TypeCode')->value($param{TypeCode}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAssetTypeDescendantsResult'),);
}

sub get_assets_info {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAssetsInfo" });
	my $som = $self->{soap}->call("GetAssetsInfo",
		SOAP::Data->name('AssetIDs')->value($param{AssetIDs}),
		SOAP::Data->name('FinderAttributes')->value($param{FinderAttributes}),
		SOAP::Data->name('RootNode')->value($param{RootNode}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAssetsInfoResult'),);
}

sub get_asset_available_keywords {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAssetAvailableKeywords" });
	my $som = $self->{soap}->call("GetAssetAvailableKeywords",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAssetAvailableKeywordsResult'),);
}

sub get_attribute_values_by_name {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAttributeValuesByName" });
	my $som = $self->{soap}->call("GetAttributeValuesByName",
		SOAP::Data->name('AssetIDs')->value($param{AssetIDs}),
		SOAP::Data->name('TypeCode')->value($param{TypeCode}),
		SOAP::Data->name('AttributeName')->value($param{AttributeName}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAttributeValuesByNameResult'),);
}

sub get_asset_web_paths {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAssetWebPaths" });
	my $som = $self->{soap}->call("GetAssetWebPaths",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAssetWebPathsResult'),);
}

sub set_tag {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SetTag" });
	my $som = $self->{soap}->call("SetTag",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('ThesaurusID')->value($param{ThesaurusID}),
		SOAP::Data->name('TagName')->value($param{TagName}),
		SOAP::Data->name('Weight')->value($param{Weight}),
		SOAP::Data->name('CascadeTagChange')->value($param{CascadeTagChange}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SetTagResult'),);
}

sub get_all_statuses {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetAllStatuses" });
	my $som = $self->{soap}->call("GetAllStatuses",
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetAllStatusesResult'),);
}

sub set_asset_status {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SetAssetStatus" });
	my $som = $self->{soap}->call("SetAssetStatus",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('StatusValue')->value($param{StatusValue}),
		SOAP::Data->name('DependantsOnly')->value($param{DependantsOnly}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SetAssetStatusResult'),);
}

sub get_page_contents {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetPageContents" });
	my $som = $self->{soap}->call("GetPageContents",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('RootNodeID')->value($param{RootNodeID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//PageContent'), $som->valueof('//PageURL'), $som->valueof('//PageWebPath'),);
}

sub login_user {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#LoginUser" });
	my $som = $self->{soap}->call("LoginUser",
		SOAP::Data->name('Username')->value($param{Username}),
		SOAP::Data->name('Password')->value($param{Password}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SessionID'), $som->valueof('//SessionKey'),);
}

sub get_user_id_by_username {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetUserIdByUsername" });
	my $som = $self->{soap}->call("GetUserIdByUsername",
		SOAP::Data->name('Username')->value($param{Username}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//AssetID'),);
}

sub set_metadata_schema {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SetMetadataSchema" });
	my $som = $self->{soap}->call("SetMetadataSchema",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('SchemaID')->value($param{SchemaID}),
		SOAP::Data->name('Grant')->value($param{Grant}),
		SOAP::Data->name('Cascade')->value($param{Cascade}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SetSchemaResult'),);
}

sub regenerate_metadata_schema {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#RegenerateMetadataSchema" });
	my $som = $self->{soap}->call("RegenerateMetadataSchema",
		SOAP::Data->name('SchemaID')->value($param{SchemaID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//RegenerateMetadataSchemaResult'),);
}

sub regenerate_metadata_asset {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#RegenerateMetadataAsset" });
	my $som = $self->{soap}->call("RegenerateMetadataAsset",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//RegenerateMetadataAssetResult'),);
}

sub set_asset_metadata {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SetAssetMetadata" });
	my $som = $self->{soap}->call("SetAssetMetadata",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('FieldID')->value($param{FieldID}),
		SOAP::Data->name('NewValue')->value($param{NewValue}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SetAssetMetadataResult'),);
}

sub set_metadata_field_default_value {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#SetMetadataFieldDefaultValue" });
	my $som = $self->{soap}->call("SetMetadataFieldDefaultValue",
		SOAP::Data->name('FieldID')->value($param{FieldID}),
		SOAP::Data->name('NewDefaultValue')->value($param{NewDefaultValue}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//SetMetadataFieldDefaultValueResult'),);
}

sub get_metadata_value_by_i_ds {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetMetadataValueByIDs" });
	my $som = $self->{soap}->call("GetMetadataValueByIDs",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('FieldID')->value($param{FieldID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetMetadataValueByIDsResult'),);
}

sub get_schemas_on_asset {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetSchemasOnAsset" });
	my $som = $self->{soap}->call("GetSchemasOnAsset",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetSchemasOnAssetResult'),);
}

sub get_metadata_fields_of_schema {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetMetadataFieldsOfSchema" });
	my $som = $self->{soap}->call("GetMetadataFieldsOfSchema",
		SOAP::Data->name('SchemaID')->value($param{SchemaID}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetMetadataFieldsOfSchemaResult'),);
}

sub get_metadata_field_values {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#GetMetadataFieldValues" });
	my $som = $self->{soap}->call("GetMetadataFieldValues",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('FieldNames')->value($param{FieldNames}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//GetMetadataFieldValuesResult'),);
}

sub basic_search {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#BasicSearch" });
	my $som = $self->{soap}->call("BasicSearch",
		SOAP::Data->name('AssetTypes')->value($param{AssetTypes}),
		SOAP::Data->name('Limit')->value($param{Limit}),
		SOAP::Data->name('Statuses')->value($param{Statuses}),
		SOAP::Data->name('RootIDs')->value($param{RootIDs}),
		SOAP::Data->name('ExcludeRootNodes')->value($param{ExcludeRootNodes}),
		SOAP::Data->name('ResultFormat')->value($param{ResultFormat}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//BasicSearchResult'),);
}

sub advanced_search {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#AdvancedSearch" });
	my $som = $self->{soap}->call("AdvancedSearch",
		SOAP::Data->name('AssetTypes')->value($param{AssetTypes}),
		SOAP::Data->name('ExcludeWords')->value($param{ExcludeWords}),
		SOAP::Data->name('FieldLogic')->value($param{FieldLogic}),
		SOAP::Data->name('Limit')->value($param{Limit}),
		SOAP::Data->name('ResultFormat')->value($param{ResultFormat}),
		SOAP::Data->name('RootIDs')->value($param{RootIDs}),
		SOAP::Data->name('RootLogic')->value($param{RootLogic}),
		SOAP::Data->name('ExcludeRootNodes')->value($param{ExcludeRootNodes}),
		SOAP::Data->name('Statuses')->value($param{Statuses}),
		SOAP::Data->name('SearchFields')->value($param{SearchFields}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//AdvancedSearchResult'),);
}

sub re_index {

	my ($self, %param) = @_;
	$self->{soap}->on_action( sub { $self->{proxy}."#ReIndex" });
	my $som = $self->{soap}->call("ReIndex",
		SOAP::Data->name('AssetID')->value($param{AssetID}),
		SOAP::Data->name('IndexComponents')->value($param{IndexComponents}),
	);
	die $som->fault->{ faultstring } if ($som->fault);
	return ( $som->valueof('//ReIndexResult'),);
}

1;

__END__

=pod

=head1 NAME

Net::MySourceMatrix - A Perl wrapper to the MySource Matrix(TM)/Squiz Matrix(TM) SOAP API.

=head1 VERSION

This documentation refers to version 0.04.

=head1 SYNOPSIS

 use Net::MySourceMatrix;
 
 my $MyM_Conn = Net::MySourceMatrix->new({
			proxy      => 'http://matrixdemo.example.com/_web_services/soap-server',
			username   => 'user',
			password   => 'pass',
			default_ns => 'http://matrixdemo.example.com/_web_services/soap-server'
		  });

=head1 DESCRIPTION

B<Net::MySourceMatrix> provides a Perl wrapper to the MySource Matrix(TM)/Squiz Matrix(TM) SOAP API. It is developed against versions 4.2.3/4.0.7 of Squiz Matrix but also works against version 3.28.9 of MySource Matrix. If a given function doesn't work it may be due to changes between Matrix versions.
 
=head1 METHODS

All methods return an array containing the contents of the tags of the SOAP response. For example, create_asset returns an asset containing the contents of the NewAssetID tags and the CreateMessage tags.

=head2 Construction and setup

=head2 new

	my $MyM_Conn = Net::MySourceMatrix->new({
			proxy      => 'http://matrixdemo.example.com/_web_services/soap-server',
			username   => 'user',
			password   => 'pass',
			default_ns => 'http://matrixdemo.example.com/_web_services/soap-server'
		  });

Construct a new Net::MySourceMatrix object. Takes a required hash reference of config options. The options are:

proxy - The proxy is the server or endpoint to which the client is going to connect. This is from L<SOAP::Lite|http://search.cpan.org/search?q=soap::lite>.

username - The username of the Matrix User able to connect to the SOAP API.

password - The password of the Matrix User able to connect to the SOAP API.

default_ns - Sets the default namespace for the request to the specified uri. This overrides any previous namespace declaration that may have been set using a previous call to ns() or default_ns(). Setting the default namespace causes elements to be serialized without a namespace prefix. This is from L<SOAP::Lite|http://search.cpan.org/search?q=soap::lite>.

=head2 create_asset

L<CreateAsset|http://http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#createasset>

	my @result = $MyM_Conn->create_asset((
			TypeCode		=> $type_code, 
			Name			=> $name, 
			ParentID		=> $parent_id,
			LinkType		=> $link_type,
			LinkValue		=> $link_value,
			SortOrder		=> $sort_order,
			IsDependant		=> $is_dependant,
			IsExclusive		=> $is_exclusive,
			FileName		=> $file_name,
			FileContentBase64	=> $filecontents)
		);
	
=head2 clone_asset

L<CloneAsset|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#cloneasset>

=head2 get_all_statuses

L<GetAllStatuses|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getallstatuses>

=head2 get_asset

L<GetAsset|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getasset>

=head2 get_asset_from_url

L<GetAssetFromURL|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getassetfromurl>

=head2 get_asset_type_attribute

L<GetAssetTypeAttribute|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getassettypeattribute>

=head2 get_asset_type_descendants

L<GetAssetTypeDescendants|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getassettypedescendants>

=head2 get_assets_info

L<GetAssetsInfo|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getassetsinfo>

=head2 get_attribute_values_by_name

L<GetAttributeValuesByName|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getattributevaluesbyname>

=head2 get_asset_available_keywords

L<GetAssetAvailableKeywords|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getassetavailablekeywords>

=head2 get_asset_available_statuses

L<GetAssetAvailableStatuses|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getassetavailablestatuses>

=head2 get_asset_web_paths

L<GetAssetWebPaths|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getassetwebpaths>

=head2 get_asset_urls

L<GetAssetURLs|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getasseturls>

=head2 get_page_contents

L<GetPageContents|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getpagecontents>

=head2 set_attribute_value

L<SetAttributeValue|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#setattributevalue>

=head2 set_tag

L<SetTag|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#settag>

=head2 set_asset_status

L<SetAssetStatus|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#setassetstatus>

=head2 trash_asset

L<TrashAsset|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#trashasset>

=head2 login_user

L<LoginUser|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#loginuser>

=head2 get_user_id_by_username

L<GetUserIdByUsername|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-asset-service/#getuseridbyusername>

=head2 apply_design

L<ApplyDesign|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-design-lookup-service/#applydesign>

=head2 remove_design

L<RemoveDesign|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-design-lookup-service/#removedesign>

=head2 get_design_from_url

L<GetDesignFromURL|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-design-lookup-service/#getdesignfromurl>

=head2 apply_asset_paint_layout

L<ApplyAssetPaintLayout|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-design-lookup-service/#applyassetpaintlayout>

=head2 remove_asset_paint_layout

L<RemoveAssetPaintLayout|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-design-lookup-service/#removeassetpaintlayout>

=head2 download

L<Download|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-file-retrieval-service/#download>

=head2 upload

L<Upload|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-file-retrieval-service/#upload>

=head2 get_file_information

L<GetFileInformation|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-file-retrieval-service/#getfileinformation>

=head2 get_image_information

L<GetImageInformation|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-file-retrieval-service/#getimageinformation>

=head2 create_asset_link

L<CreateAssetLink|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#createassetlink>

=head2 delete_asset_link

L<DeleteAssetLink|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#deleteassetlink>

=head2 get_all_child_links

L<GetAllChildLinks|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#getallchildlinks>

=head2 get_children

L<GetChildren|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#getchildren>

=head2 get_dependant_children

L<GetDependantChildren|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#getdependantchildren>

=head2 get_dependant_parents

L<GetDependantParents|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#getdependantparents>

=head2 get_links

L<GetLinks|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#getlinks>

=head2 get_link_by_asset

L<GetLinkByAsset|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#getlinkbyasset>

=head2 get_link_lineages

L<GetLinkLineages|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#getlinklineages>

=head2 get_parents

L<GetParents|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#getparents>

=head2 get_parents_under_tree

L<GetParentsUnderTree|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#getparentsundertree>

=head2 move_link

L<MoveLink|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#movelink>

=head2 update_link

L<UpdateLink|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-link-service/#updatelink>

=head2 set_metadata_schema

L<SetMetadataSchema|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-metadata-service/#setmetadataschema>

=head2 get_metadata_fieldsof_schema

L<GetMetadataFieldsofSchema|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-metadata-service/#getmetadatafieldsofschema>

=head2 get_metadata_field_values

L<GetMetadataFieldValues|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-metadata-service/#getmetadatafieldvalues>

=head2 regenerate_metadata_schema

L<RegenerateMetadataSchema|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-metadata-service/#regeneratemetadataschema>

=head2 regenerate_metadata_asset

L<RegenerateMetadataAsset|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-metadata-service/#regeneratemetadataasset>

=head2 get_metadata_value_by_i_ds

L<GetMetadataValueByIDs|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-metadata-service/#getmetadatavaluebyids>

=head2 set_asset_metadata

L<SetAssetMetadata|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-metadata-service/#setassetmetadata>

=head2 set_metadata_field_default_value

L<SetMetadataFieldDefaultValue|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-metadata-service/#setmetadatafielddefaultvalue>

=head2 get_schemas_on_asset

L<GetSchemasOnAsset|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-metadata-service/#getschemasonasset>

=head2 has_access

L<HasAccess|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-permissions-and-role-service/#hasaccess>

=head2 get_permission

L<GetPermission|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-permissions-and-role-service/#getpermission>

=head2 get_role

L<GetRole|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-permissions-and-role-service/#getrole>

=head2 set_permission

L<SetPermission|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-permissions-and-role-service/#setpermission>

=head2 set_role

L<SetRole|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-permissions-and-role-service/#setrole>

=head2 basic_search

L<BasicSearch|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-search-service/#basicsearch>

=head2 advanced_search

L<AdvancedSearch|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-search-service/#advancedsearch>

=head2 re_index

L<ReIndex|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-search-service/#reindex>

=head2 start_workflow

L<StartWorkflow|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-workflow-service/#startworkflow>

=head2 safe_edit_asset

L<SafeEditAsset|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-workflow-service/#safeeditasset>

=head2 cancel_workflow

L<CancelWorkflow|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-workflow-service/#cancelworkflow>

=head2 complete_workflow

L<CompleteWorkflow|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-workflow-service/#completeworkflow>

=head2 set_workflow_schema

L<SetWorkflowSchema|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-workflow-service/#setworkflowschema>

=head2 approve_asset_in_workflow

L<ApproveAssetInWorkflow|http://manuals.matrix.squizsuite.net/web-services/chapters/soap-api-workflow-service/#approveassetinworkflow>

=head1 BUGS

Bugs should be reported via the CPAN bug tracker at

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-MySourceMatrix>

=head1 ACKNOWLEDGEMENTS

Thanks once again to the inimitable Adam Kennedy, good friend and Perl genius, for his continuing assistance in my experiments in Perl.

=head1 AUTHOR

Jeffery Candiloro E<lt>jeffery@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 Jeffery Candiloro.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

Squiz Matrix and MySource Matrix are registered trademarks of Squiz Pty Ltd or its subsidiaries in Australia and other countries.

=cut
