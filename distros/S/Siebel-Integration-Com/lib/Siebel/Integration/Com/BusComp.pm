package Siebel::Integration::Com::BusComp 0.02;

use 5.006;
use Moose;
use namespace::autoclean;
use strict;
use warnings;
use Win32::OLE;
use Win32::OLE::Variant;
use Carp;


has constants	=>(
					is=>'ro',
					isa=>'HashRef',
					default=> sub {{
						#View Constants
						SalesRepView			=> 0,
						ManagerView				=> 1,
						PersonalView			=> 2,
						AllView					=> 3,
						OrganizationView		=> 4,
						GroupView				=> 5,
						CatalogView				=> 6,
						SubOrganizationView		=> 7,
						#Query Constants
						ForwardBackward			=> 0,
						ForwardOnly				=> 1,
						#New Record Constants
						NewBefore				=> 0,
						NewAfter				=> 1,
						NewBeforeCopy			=> 2,
						NewAfterCopy			=> 3,
						#allow use of numbers as well
						0						=> 0,
						1						=> 1,
						2						=> 2,
						3						=> 3,
						4						=> 4,
						5						=> 5,
						6						=> 6,
						7						=> 7,
					}},
				);
has Error 		=>(
					is => 'rw', 
					isa=>'Str', 
					default=> '',
				);

has _ThickError =>(
					is => 'rw', 
				);
				
has ConnectionType =>( 
					is => 'rw', 
					isa=>'Str', 
					required => 1,
				);
has SApp 		=>(
					is => 'rw',
					required => 1,
				);
has _BO			=>(
					is => 'rw',
					required => 1,
				);
has _BC			=>(
					is => 'rw',
				);
has BCName =>( 
					is => 'rw', 
					isa=>'Str', 
					required => 1,
				);
				
sub BUILD{
	my $self = shift;
	if(($self->BCName eq 'MVG') || ($self->BCName eq 'PICK') || ($self->BCName eq 'ASSOC') || ($self->BCName eq 'PAR')){#BC is a MVG BC and will be provided rather than set here just get error var set if Thick
		if($self->ConnectionType ne 'Thin'){
			$self->_ThickError(Variant(VT_I2|VT_BYREF, 0));
		}
	}else{
		if($self->ConnectionType eq 'Thin'){
			$self->_BC($self->_BO->GetBusComp($self->BCName)); 												return undef if $self->_chkErr("Can't create BC");
		}else{
			$self->_ThickError(Variant(VT_I2|VT_BYREF, 0));
			$self->_BC($self->_BO->GetBusComp($self->BCName, $self->_ThickError)); 							return undef if $self->_chkErr("Can't create BC");
		}
	}
}

sub ParentBusComp{#returns a BC object
	my $self = shift;
	$self->Error('');
	my $ParBC;
	if($self->ConnectionType eq 'Thin'){
		$ParBC = $self->_BC->ParentBusComp(); 											return undef if $self->_chkErr("Can't create Par BC");
	}else{
		$ParBC = $self->_BC->ParentBusComp($self->_ThickError);	 						return undef if $self->_chkErr("Can't create Par BC");
	}
	return Siebel::Integration::Com::BusComp->new(_BC => $ParBC, BCName => 'PAR', _BO => $self->_BO, ConnectionType => $self->ConnectionType, SApp => $self->SApp);
}
	

sub GetMVGBusComp{
	my $self = shift;
	$self->Error('');
	my $MVGFieldName = shift;
	my $MVGBC;
	if($self->ConnectionType eq 'Thin'){
		$MVGBC = $self->_BC->GetMVGBusComp($MVGFieldName); 												return undef if $self->_chkErr("Can't create MVG BC");
	}else{
		$MVGBC = $self->_BC->GetMVGBusComp($MVGFieldName, $self->_ThickError);	 						return undef if $self->_chkErr("Can't create MVG BC");
	}
	return Siebel::Integration::Com::BusComp->new(_BC => $MVGBC, BCName => 'MVG', _BO => $self->_BO, ConnectionType => $self->ConnectionType, SApp => $self->SApp);
}
sub GetPicklistBusComp{
	my $self = shift;
	$self->Error('');
	my $PickFieldName = shift;
	my $PickBC;
	if($self->ConnectionType eq 'Thin'){
		$PickBC = $self->_BC->GetPicklistBusComp($PickFieldName); 											return undef if $self->_chkErr("Can't create MVG BC");
	}else{
		$PickBC = $self->_BC->GetPicklistBusComp($PickFieldName, $self->_ThickError);	 					return undef if $self->_chkErr("Can't create MVG BC");
	}
	return Siebel::Integration::Com::BusComp->new(_BC => $PickBC, BCName => 'PICK', _BO => $self->_BO, ConnectionType => $self->ConnectionType, SApp => $self->SApp);
}

sub Pick{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->Pick();												return undef if $self->_chkErr("Can't Pick");
	}else{
		$self->_BC->Pick($self->_ThickError);							return undef if $self->_chkErr("Can't Pick");
	}
	return 1;
}


sub GetAssocBusComp{
	my $self = shift;
	$self->Error('');
	my $assoc_BC;
	if($self->ConnectionType eq 'Thin'){
		$assoc_BC = $self->_BC->GetAssocBusComp(); 											return undef if $self->_chkErr("Can't create AssocBusComp BC");
	}else{
		$assoc_BC = $self->_BC->GetAssocBusComp($self->_ThickError);	 					return undef if $self->_chkErr("Can't create AssocBusComp BC");
	}
	return Siebel::Integration::Com::BusComp->new(_BC => $assoc_BC, BCName => 'ASSOC', _BO => $self->_BO, ConnectionType => $self->ConnectionType, SApp => $self->SApp);
}

sub Associate{
	my $self = shift;
	$self->Error('');
	my $mode = shift;
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->Associate($self->constants->{$mode});											return undef if $self->_chkErr("Can't Associate");
	}else{
		$self->_BC->Associate($self->constants->{$mode}, $self->_ThickError);						return undef if $self->_chkErr("Can't Associate");
	}
	return 1;
}

		
sub ClearToQuery{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->ClearToQuery();																		return undef if $self->_chkErr("Can't ClearToQuery");
	}else{
		$self->_BC->ClearToQuery($self->_ThickError);													return undef if $self->_chkErr("Can't ClearToQuery");
	}
	return 1;
}
sub SetViewMode{
	my $self = shift;
	my $mode =  shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->SetViewMode($self->constants->{$mode});												return undef if $self->_chkErr("Can't SetViewMode");
	}else{
		$self->_BC->SetViewMode($self->constants->{$mode}, $self->_ThickError);							return undef if $self->_chkErr("Can't SetViewMode");
	}
	return 1;
}
sub ActivateField{
	my $self = shift;
	my $field = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->ActivateField($field);																return undef if $self->_chkErr("Can't ActivateField");
	}else{
		$self->_BC->ActivateField($field, $self->_ThickError);											return undef if $self->_chkErr("Can't ActivateField");
	}
	return 1;
}
sub ActivateFields{#take an array and activate all
	my $self = shift;
	my @fields = @_;
	$self->Error('');
	foreach my $field(@fields){
		return undef if !$self->ActivateField($field);
	}
	return 1;
}
sub SetSearchSpec{
	my $self = shift;
	my $field = shift;
	my $value = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->SetSearchSpec($field, $value);														return undef if $self->_chkErr("Can't SetSearchSpec");
	}else{
		$self->_BC->SetSearchSpec($field, $value, $self->_ThickError);									return undef if $self->_chkErr("Can't SetSearchSpec");
	}
	return 1;
}
sub SetSearchExpr{
	my $self = shift;
	my $Spec = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->SetSearchExpr($Spec);																return undef if $self->_chkErr("Can't SetSearchExpr");
	}else{
		$self->_BC->SetSearchExpr($Spec, $self->_ThickError);											return undef if $self->_chkErr("Can't SetSearchExpr");
	}
	return 1;
}
sub ExecuteQuery{
	my $self = shift;
	my $mode =  shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->ExecuteQuery($self->constants->{$mode});												return undef if $self->_chkErr("Can't ExecuteQuery");
	}else{
		$self->_BC->ExecuteQuery($self->constants->{$mode}, $self->_ThickError);							return undef if $self->_chkErr("Can't ExecuteQuery");
	}
	return 1;
}

sub ExecuteQuery2{
	my $self = shift;
	my $mode =  shift;
	my $cursor = shift;
	$self->Error('');
	#Thick client wants true/false thin wants 0/1
	my %mapper = (
		true => 1,
		false => 0,
		1 => 'true',
		0 => 'false',
	);
	
	if($self->ConnectionType eq 'Thin'){
		$cursor = $mapper{$cursor} if $cursor =~ /true|false/;
		$self->_BC->ExecuteQuery2($self->constants->{$mode}, $cursor);												return undef if $self->_chkErr("Can't ExecuteQuery2");
	}else{
		$cursor = $mapper{$cursor} if $cursor =~ /0|1/;
		$self->_BC->ExecuteQuery2($self->constants->{$mode}, $cursor, $self->_ThickError);							return undef if $self->_chkErr("Can't ExecuteQuery2");
	}
	return 1;
}
	
sub FirstRecord{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_BC->FirstRecord();
	}else{
		return $self->_BC->FirstRecord($self->_ThickError);
	}
}
sub NextRecord{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_BC->NextRecord();
	}else{
		return $self->_BC->NextRecord($self->_ThickError);
	}
}

sub GetFieldValue{
	my $self = shift;
	my $fieldName =  shift;
	$self->Error('');
	my $value;
	if($self->ConnectionType eq 'Thin'){
		$value = $self->_BC->GetFieldValue($fieldName);												return undef if $self->_chkErr("Can't GetFieldValue");
	}else{
		$value = $self->_BC->GetFieldValue($fieldName, $self->_ThickError);							return undef if $self->_chkErr("Can't GetFieldValue");
	}
	return $value;
}
sub SetFieldValue{
	my $self = shift;
	my $fieldName =  shift;
	my $value = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->SetFieldValue($fieldName, $value);												return undef if $self->_chkErr("Can't SetFieldValue");
	}else{
		$self->_BC->SetFieldValue($fieldName, $value, $self->_ThickError);							return undef if $self->_chkErr("Can't SetFieldValue");
	}
	return 1;
}

sub SetFormattedFieldValue{
	my $self = shift;
	my $fieldName =  shift;
	my $value = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->SetFormattedFieldValue($fieldName, $value);												return undef if $self->_chkErr("Can't SetFormattedFieldValue");
	}else{
		$self->_BC->SetFormattedFieldValue($fieldName, $value, $self->_ThickError);							return undef if $self->_chkErr("Can't SetFormattedFieldValue");
	}
	return 1;
}

sub GetFormattedFieldValue{
	my $self = shift;
	my $fieldName =  shift;
	$self->Error('');
	my $value;
	if($self->ConnectionType eq 'Thin'){
		$value = $self->_BC->GetFormattedFieldValue($fieldName);												return undef if $self->_chkErr("Can't GetFormattedFieldValue");
	}else{
		$value = $self->_BC->GetFormattedFieldValue($fieldName, $self->_ThickError);							return undef if $self->_chkErr("Can't GetFormattedFieldValue");
	}
	return $value;
}

sub WriteRecord{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->WriteRecord();												return undef if $self->_chkErr("Can't WriteRecord");
	}else{
		$self->_BC->WriteRecord($self->_ThickError);							return undef if $self->_chkErr("Can't WriteRecord");
	}
	return 1;
}


sub SetSortSpec{
	my $self = shift;
	my $sort_spec =  shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->SetSortSpec($sort_spec);												return undef if $self->_chkErr("Can't SetSortSpec");
	}else{
		$self->_BC->SetSortSpec($sort_spec, $self->_ThickError);							return undef if $self->_chkErr("Can't SetSortSpec");
	}
	return 1;
}

sub DeactivateFields{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->DeactivateFields();												return undef if $self->_chkErr("Can't DeactivateFields");
	}else{
		$self->_BC->DeactivateFields($self->_ThickError);							return undef if $self->_chkErr("Can't DeactivateFields");
	}
	return 1;
}

sub DeleteRecord{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->DeleteRecord();												return undef if $self->_chkErr("Can't DeleteRecord");
	}else{
		$self->_BC->DeleteRecord($self->_ThickError);							return undef if $self->_chkErr("Can't DeleteRecord");
	}
	return 1;
}


sub GetNamedSearch{
	my $self = shift;
	my $search_name =  shift;
	$self->Error('');
	my $value;
	if($self->ConnectionType eq 'Thin'){
		$value = $self->_BC->GetNamedSearch($search_name);												return undef if $self->_chkErr("Can't GetNamedSearch");
	}else{
		$value = $self->_BC->GetNamedSearch($search_name, $self->_ThickError);							return undef if $self->_chkErr("Can't GetNamedSearch");
	}
	return $value;
}

sub GetSearchExpr{
	my $self = shift;
	$self->Error('');
	my $value;
	if($self->ConnectionType eq 'Thin'){
		$value = $self->_BC->GetSearchExpr();											return undef if $self->_chkErr("Can't GetSearchExpr");
	}else{
		$value = $self->_BC->GetSearchExpr($self->_ThickError);							return undef if $self->_chkErr("Can't GetSearchExpr");
	}
	return $value;
}

sub GetSearchSpec{
	my $self = shift;
	my $field_name = shift;
	$self->Error('');
	my $value;
	if($self->ConnectionType eq 'Thin'){
		$value = $self->_BC->GetSearchSpec($field_name);											return undef if $self->_chkErr("Can't GetSearchSpec");
	}else{
		$value = $self->_BC->GetSearchSpec($field_name, $self->_ThickError);							return undef if $self->_chkErr("Can't GetSearchSpec");
	}
	return $value;
}

sub GetSortSpec{
	my $self = shift;
	$self->Error('');
	my $value;
	if($self->ConnectionType eq 'Thin'){
		#not supported on Thin Client
		carp "Thin Client does not support GetSortSpec, V7.7, unknown if fixed in other versions of Siebel";
		$value = $self->_BC->GetSortSpec();											return undef if $self->_chkErr("Can't GetSortSpec");
	}else{
		$value = $self->_BC->GetSortSpec($self->_ThickError);						return undef if $self->_chkErr("Can't GetSortSpec");
	}
	return $value;
}

sub GetUserProperty{
	my $self = shift;
	my $prop_name = shift;
	$self->Error('');
	my $value;
	if($self->ConnectionType eq 'Thin'){
		$value = $self->_BC->GetUserProperty($prop_name);											return undef if $self->_chkErr("Can't GetUserProperty");
	}else{
		$value = $self->_BC->GetUserProperty($prop_name, $self->_ThickError);						return undef if $self->_chkErr("Can't GetUserProperty");
	}
	return $value;
}

sub GetViewMode{
	my $self = shift;
	$self->Error('');
	my $value;
	if($self->ConnectionType eq 'Thin'){
		$value = $self->_BC->GetViewMode();											return undef if $self->_chkErr("Can't GetViewMode");
	}else{
		$value = $self->_BC->GetViewMode($self->_ThickError);						return undef if $self->_chkErr("Can't GetViewMode");
	}
	return $value;
}

sub LastRecord{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_BC->LastRecord();
	}else{
		return $self->_BC->LastRecord($self->_ThickError);
	}
}

sub PreviousRecord{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_BC->PreviousRecord();
	}else{
		return $self->_BC->PreviousRecord($self->_ThickError);
	}
}

sub RefineQuery{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->RefineQuery();											return undef if $self->_chkErr("Can't RefineQuery");
	}else{
		$self->_BC->RefineQuery($self->_ThickError);						return undef if $self->_chkErr("Can't RefineQuery");
	}
	return 1;
}

sub UndoRecord{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->UndoRecord();										return undef if $self->_chkErr("Can't UndoRecord");
	}else{
		$self->_BC->UndoRecord($self->_ThickError);						return undef if $self->_chkErr("Can't UndoRecord");
	}
	return 1;
}

sub Name{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_BC->Name();
	}else{
		return $self->_BC->Name($self->_ThickError);
	}
}

sub NewRecord{
	my $self = shift;
	my $mode = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->NewRecord($self->constants->{$mode});											return undef if $self->_chkErr("Can't NewRecord");
	}else{
		$self->_BC->NewRecord($self->constants->{$mode}, $self->_ThickError);						return undef if $self->_chkErr("Can't NewRecord");
	}
	return 1;
}

sub SetNamedSearch{
	my $self = shift;
	my $search_name = shift;
	my $search_spec = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->SetNamedSearch($search_name, $search_spec);																return undef if $self->_chkErr("Can't SetNamedSearch");
	}else{
		$self->_BC->SetNamedSearch($search_name, $search_spec, $self->_ThickError);											return undef if $self->_chkErr("Can't SetNamedSearch");
	}
	return 1;
}
	
sub SetUserProperty{
	my $self = shift;
	my $property_name = shift;
	my $value = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_BC->SetUserProperty($property_name, $value);																return undef if $self->_chkErr("Can't SetUserProperty");
	}else{
		$self->_BC->SetUserProperty($property_name, $value, $self->_ThickError);											return undef if $self->_chkErr("Can't SetUserProperty");
	}
	return 1;
}

sub InvokeMethod{#InvokeMethod(methodName as String, methArg1, methArg2, methArgN as String or StringArray)
	my $self = shift;
	my $methodName = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		my $attrVal;
		if (@_){
			$attrVal = $self->_BC->InvokeMethod($methodName, @_); 										return undef if $self->_chkErr("Can't InvokeMethod");
		}else{
			#must pass an empty string if no args or error.
			$attrVal = $self->_BC->InvokeMethod($methodName, ''); 										return undef if $self->_chkErr("Can't InvokeMethod");
		}
		return $attrVal;
	}else{
		my $attrVal;
		if (@_){
			$attrVal = $self->_BC->InvokeMethod($methodName, @_, $self->_ThickError); 					return undef if $self->_chkErr("Can't InvokeMethod");
		}else{
			#must pass an empty string if no args or error.
			$attrVal = $self->_BC->InvokeMethod($methodName, '', $self->_ThickError); 					return undef if $self->_chkErr("Can't InvokeMethod");
		}
		return $attrVal;
	}
}

	
sub _chkErr{
	my $self = shift;
	my $what = shift;
	my $ErrorCode;
	if($self->ConnectionType eq 'Thin'){
		$ErrorCode = $self->SApp->GetLastErrCode();
	}else{
		$ErrorCode = $self->_ThickError;
	}
	if(($ErrorCode // 0) != 0){
		$self->Error("[$what] " . $ErrorCode . ': ' . $self->SApp->GetLastErrText());
		return 1;
	}
	return 0;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Siebel::Integration::Com::BusComp - Abstraction of Siebel Business Component

=head1 SYNOPSIS

	use Siebel::Integration::Com;
	
	my $sa = Siebel::Integration::Com->new(
			ConnectionType=>'Thick', 
			UserName=>$inputs{user}, 
			PassWord=>$inputs{pass}, 
			CFG=>$inputs{cfg}, 
			DataSource=>$inputs{DataSource}
		);

	#Query for and print employee's with logins containing ADMIN
	my @Fields = ('First Name','Last Name','Login Name'); #fields to activate and print
	my $BO = $sa->GetBusObject('Employee');
	my $BC = $BO->GetBusComp('Employee');
	$BC->ClearToQuery();
	$BC->SetSearchExpr('[Login Name] LIKE "*ADMIN*"');#logins containing ADMIN
	$BC->SetViewMode('AllView');#all view mode constants can be used as strings or you can use the int value
	$BC->ActivateFields(@Fields);
	$BC->ExecuteQuery('ForwardOnly');
	if($BC->FirstRecord()){
		print "Record(s) Found\n";
		do{
			print "Id: " . $BC->GetFieldValue('Id') . "\t";
			foreach my $field (@Fields){
				print "$field: " . ($BC->GetFieldValue($field) // '') . "\t";
			}
			print "\n";
		}while($BC->NextRecord());
		print "Record Limit Reached\n";
	}else{
		print "No Records Found\n";
	}
	
	#Create a sys preference, then delete it
	my $BOPrefs = $sa->GetBusObject('System Preferences');
	my $BCPrefs = $BOPrefs->GetBusComp('System Preferences');
	if(!$BCPrefs->NewRecord('NewBefore')){
		die print "New record failed: " . $BCPrefs->Error();
	}
	$BCPrefs->SetFieldValue('Name','Test Pref');
	$BCPrefs->SetFieldValue('Value','Test Pref Value');
	$BCPrefs->WriteRecord();
	my $PrefId = $BCPrefs->GetFieldValue('Id');
	#Delete the sys preference, could just call delete since the record is still focused, but will query for the example.
	$BCPrefs->ClearToQuery();
	$BCPrefs->SetSearchSpec('Id', $PrefId);
	$BCPrefs->ExecuteQuery('ForwardOnly');
	if($BCPrefs->FirstRecord()){
		if($BCPrefs->DeleteRecord()){
			print "New Preference Record Deleted\n";
		}else{
			print "Delete failed: " . $BCPrefs->Error() . "\n";
		}
	}else{
		print "Can not find record to delete!\n";
	}
	
	#Query for current user. Update the users title and associate a new position. If the position is already associated disassociate it
	my $BOEmp = $sa->GetBusObject('Employee');
	my $BCEmp = $BOEmp->GetBusComp('Employee');
	$BCEmp->ClearToQuery();
	$BCEmp->SetViewMode('AllView');
	$BCEmp->ActivateFields('Personal Title', 'First Name');
	$BCEmp->SetSearchSpec('Login Name', $sa->LoginName());#query for current user
	$BCEmp->ExecuteQuery('ForwardOnly');
	if($BCEmp->FirstRecord()){
		my ($NewTitle);
		if($BCEmp->GetFieldValue('Personal Title') =~ /Mr/){#toggle users title between Mr, and Miss
			$NewTitle = 'Miss';
		}else{
			$NewTitle = 'Mr';
		}
		print "Setting " . $BCEmp->GetFieldValue('First Name') . "'s title to $NewTitle\n";
		
		my $PickTitleBC = $BCEmp->GetPicklistBusComp('Personal Title');
		$PickTitleBC->ClearToQuery();
		$PickTitleBC->SetSearchSpec('Value', $NewTitle);
		$PickTitleBC->SetViewMode('AllView');
		$PickTitleBC->ExecuteQuery('ForwardOnly');
		if($PickTitleBC->FirstRecord()){
			if(!$PickTitleBC->Pick()){
				print "Picking title failed: " . $PickTitleBC->Error();
			}else{
				$BCEmp->WriteRecord();
			}
		}else{
			print "Can not find title " . $NewTitle . " in the picklist BC\n";
		}
		#associate proxy employee position, if already assosiated then remove.
		my $MVGBC = $BCEmp->GetMVGBusComp('Position Id');
		#find out if Proxy position already associated, if found disassociate, if not found associate
		$MVGBC->ClearToQuery();
		$MVGBC->SetSearchSpec('Id', '0-57T1J');#proxy employee
		$MVGBC->ExecuteQuery('ForwardOnly');
		if($MVGBC->FirstRecord()){
			$MVGBC->DeleteRecord();
			print "Removed Proxy Employee\n";
		}else{
			my $AssocMVG = $MVGBC->GetAssocBusComp();
			$AssocMVG->ClearToQuery();
			$AssocMVG->SetSearchSpec('Id', '0-57T1J');#proxy employee
			$AssocMVG->ExecuteQuery('ForwardOnly');
			if($AssocMVG->FirstRecord()){
				if($AssocMVG->Associate('NewBefore')){
					print "Associated Proxy position\n";
				}else{
					print "failed to associate Proxy position\n";
				}
			}else{
				print "Can not find proxy employee record!\n";
			}
		}
		$BCEmp->WriteRecord();
	}else{
		print "Can not find employee record something is wrong!\n";
	}


=head1 DESCRIPTION

The Siebel::Integration::Com modules are designed to remove the different method calls and error checking between the COM Data Control and COM Data Server interfaces. 
Changing between the two interfaces only requires a change in the parameters to Siebel::Integration::Com->new() rather than a rewrite of all calls.
Beyond just replicating the base functions of the interfaces it is hoped that additional methods will be added to these modules to extend the functionality provided by the Siebel COM framework.

All methods that have been exposed keep the same names so there is no additional learning curve, you can program in Perl using the same method names as eScript

=head2 Base Methods

=over 8

=item BC->Error()

	Returns the error text for the last operation, returns '' if no error.

=item BC->ClearToQuery()

	The ClearToQuery method clears the current query
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->SetViewMode(VisibilityType)

	The SetViewMode method sets the visibility type
	This will accept the numbers as per Siebel or you can use a string version of the type
	
	SalesRepView				=> 0
	ManagerView				=> 1
	PersonalView				=> 2
	AllView					=> 3
	OrganizationView			=> 4
	GroupView				=> 5
	CatalogView				=> 6
	SubOrganizationView			=> 7

	Example: $bc->SetViewMode('AllView') is the same as $bc->SetViewMode(3), readability would be better served by AllView
	
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->ActivateField(FieldName)

	Activates a field so that the next query on the BC will return the fields value
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->ActivateFields(FieldName, FieldName, FieldName, ....)

	Activates an array of fields so that the next query on the BC will return the fields values
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->SetSearchSpec(FieldName, FieldValue)

	Sets the search specification for the BC you can call this multiple times to setup your query
	
	Examples: 
	BC->SetSearchSpec('Id', '0-1')
	BC->SetSearchSpec('Status', " <> 'New'")
	BC->SetSearchSpec('Status', "IS NULL")

	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->SetSearchExpr(Expr)

	Sets the search expression for the BC
	
	Example: BC->SetSearchExpr('[Name] = "Bob"')
	
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->ExecuteQuery(CursorMode)

	Queries the BC based on your SearchSpec, SearchExpr and any other settings
	This will accept the numbers as per Siebel or you can use a string version of the type
	
	ForwardBackward			=> 0
	ForwardOnly			=> 1

	Example: $bc->ExecuteQuery('ForwardOnly') is the same as $bc->ExecuteQuery(1), readability would be better served by ForwardOnly
	
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->FirstRecord()

	Returns 1 if there is a record to focus or 0 if there is no record to focus on

=item BC->NextRecord()

	Returns 1 if there is a record to focus or 0 if there is no record to focus on

=item BC->GetFieldValue(FieldName)

	Returns the field value.
	Returns undef for failure. A failure will set BC->Error

=item BC->SetFieldValue(FieldName, Value)

	Sets the field value
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->GetMVGBusComp(FieldName)

	Returns the MVG business component releated to the input field

=item BC->SetSortSpec(SortSpec)

	Sets the sort spec for the BC, See BUGS/LIMITATIONS this does not seem to work
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->DeactivateFields()

	Deactivates all fields not explicity needed to form the SQL or set as force active in the BC

=item BC->ExecuteQuery2(CursorMode, ignoreMaxCursorSize)

	Queries the BC based on your SearchSpec, SearchExpr and any other settings
	This will accept the numbers as per Siebel or you can use a string version of the type
	
	ForwardBackward			=> 0
	ForwardOnly			=> 1

	Example: $bc->ExecuteQuery2('ForwardOnly', 1) is the same as $bc->ExecuteQuery2(1, 1), readability would be better served by ForwardOnly
	
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

	The Thin and Thick clients expect different values for ignoreMaxCursorSize. 
	The cover method will automaticly select the appropriate inputs to the underlying ExecuteQuery2 method possible inputs are 0, 1, true, false.

=item BC->GetFormattedFieldValue(FieldName)

	Returns a string that contains a field value that is in the same format that the Siebel client uses or undef if there was an error. 
	A failure will set BC->Error

=item BC->GetNamedSearch(SearchName)

	Rerurns the search related to the input name
	Returns undef for failure. A failure will set BC->Error

=item BC->SetNamedSearch(searchName, searchSpec)

	Sets a named search on the BC, this can not be overriden except using scripting
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->GetSearchExpr()

	Returns the full search expression for the BC
	Returns undef for failure. A failure will set BC->Error

=item BC->GetSearchSpec(FieldName)

	Returns the search expression for the specified field only
	Returns undef for failure. A failure will set BC->Error

=item BC->GetSortSpec()

	Returns the Sort Specification for the BC. See BUGS/LIMITATIONS this does not work for thin client connections
	Returns undef for failure. A failure will set BC->Error

=item BC->GetViewMode()

	Rerurns the view mode of the BC, this will be an integer number
	
	SalesRepView				=> 0
	ManagerView				=> 1
	PersonalView				=> 2
	AllView					=> 3
	OrganizationView			=> 4
	GroupView				=> 5
	CatalogView				=> 6
	SubOrganizationView			=> 7
	
	Returns undef for failure. A failure will set BC->Error

=item BC->LastRecord()

	Returns 1 if there is a record to focus or 0 if there is no record to focus on

=item BC->PreviousRecord()

	Returns 1 if there is a record to focus or 0 if there is no record to focus on

=item BC->RefineQuery()

	Allows you to start refining the query, use after ExecuteQuery when you do not wish to clear the existing Query information
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->ParentBusComp()

	Returns a new Siebel::Integration::Com::BusComp Object

=item BC->Name()

	Reruns the BC name most useful with Pick, MVG and Assoc BC's where the name is not known at creation.

=item BC->GetUserProperty(PropertyName)

	Returns the value of the user property. Do not confuse it with User Properties as defined in Siebel tools
	Returns undef for failure. A failure will set BC->Error

=item BC->SetUserProperty(PropertyName, Value)

	Sets a user property to the BC, this is effectivly a global variable. Do not confuse it with User Properties as defined in Siebel tools
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->InvokeMethod(MethodName, MethodArg1, MethodArg2, ..., MethodArgN)

	Invokes a method on the business component object
	Returns the result of the Method call if there is an error it sets BC->Error

=item BC->GetPicklistBusComp(FieldName)

	Returns a new Siebel::Integration::Com::BusComp object based on the input fields picklist Business Component

=item BC->Pick()

	Used on a picklist Business Component returned from GetPicklistBusComp to pick the selected record in to the parent Business Component
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->SetFormattedFieldValue(FieldName, FieldValue)

	Sets the field value using the local format
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->WriteRecord()

	Write changes to the database
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->DeleteRecord()

	Delete the selected record and focus on the next record
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->GetAssocBusComp()

Returns a Siebel::Integration::Com::BusComp object.
Called on a MVG Business Component to get the Associate Business Component. Query the Business Component returned from this call for the record you wish to associate to the base Business Component and then call the Associate method.

=item BC->Associate(NewBefore/NewAfter)

	Called on an Associate Business Component as returned from GetAssocBusComp to associate the selected record to the base record
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->UndoRecord()

	Undo changes made to the Business Component
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item BC->NewRecord(NewBefore/NewAfter/etc)

	Insert a new record
	Returns 1 for success
	Returns undef for failure. A failure will set BC->Error

=item New(ConnectionType=>'Thin/Thick', _BO=>Siebel::Integration::Com::BusObj, SApp=>Siebel::Integration::Com)

	Only called internally from Siebel::Integration::Com::BusObj->GetBusComp()
	Returns a Siebel::Integration::Com::BusComp object
	Sets BC->Error if an error occurs

=back

=head1 REQUIREMENTS

See L<Siebel::Integration::Com>

=head1 TESTING

See L<Siebel::Integration::Com>

=head1 BUGS/LIMITATIONS

	SetSortSpec, does not apear to work, need to prove this is the DLL. Maybe specific to Siebel version.
	GetSortSpec does not work on thin client, seems the DLL does not support it.

=head1 SEE ALSO

The documentation for L<Siebel::Integration::Com> contains additional information

=head2 REFERENCES

L<Oracle Help Business Component Methods|http://docs.oracle.com/cd/E14004_01/books/OIRef/OIRef_Interfaces_Reference11.html>

=head1 AUTHOR

Kyle Mathers, C<< <kyle.perl at mathersit.com> >>

=head1 COPYRIGHT

The same as L<Siebel::Integration::Com>

=head1 VERSION

Version 0.02 March 2013

=cut


