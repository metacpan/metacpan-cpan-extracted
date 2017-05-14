#!/usr/bin/perl -w

use strict;

use Test::More 'no_plan';
BEGIN { 
	use_ok('Win32::OLE');
	use_ok('Siebel::Integration::Com');
}

#maybe you dont want to test everything? set to 0 to skip
use constant TEST_THICK => 0;
use constant TEST_THIN => 0;

use constant TEST_APP => 0; #test all app methods except trace
use constant TEST_APP_TRACE => 0;#Test the application methods for trace. Will create a file on local drive or server
use constant TEST_PROPSET => 0; #Test all property set methods
use constant TEST_BO_BC_RW => 0;#Test New and Delete. Will make changes to your data!
use constant TEST_BO_BC_RO => 0;
use constant TEST_BS => 0; #BS tests use prop sets, if prop sets have failures you will (may) have problems here


my %inputs = (
	user => 'CHANGE_ME',
	pass => 'CHANGE_ME',
	ObjMgr => 'CHANGE_ME', #Thin
	ent => 'CHANGE_ME', #Thin
	host => 'CHANGE_ME', #Thin
	cfg => 'CHANGE_ME', #Thick
	DataSource => 'CHANGE_ME', #Thick
);

#If you are logged in as SADMIN, updates will not work. To test these write methods you need to be logged in as a non seed data user.
#some tests require input data specific to your system, if these values are not set the tests will skip.
my %testData = (
	SetPositionId => undef, #Id of a non primary position related to the loged in user
	SetPositionIdName => undef,#The Position Name related to SetPositionId
	FormattedDateTimeFieldValue => undef,#BC RW Methods: Please set to valid Formatted date time
	PositionIdToAssociate => undef, #used to associate a new position to the logged in employee to test Associate methods
);


#Base tests requires no user/pass etc
my $ThickDLL = 'SiebelDataServer.ApplicationObject';
my $thinDLL = 'SiebelDataControl.SiebelDataControl.1';
my ($saThick,$saThin);
eval{
	$saThick = Win32::OLE->new($ThickDLL) or die "Failed to load thin DLL";
};

ok(defined $saThick, 'Thick DLL Loaded');

$saThick = undef;#must undef or another instance can not be loaded.

if(TEST_THICK){
	print "Thick\n";
	my $SiebelThick = Siebel::Integration::Com->new(ConnectionType=>'Thick', UserName=>$inputs{user}, PassWord=>$inputs{pass}, CFG=>$inputs{cfg}, DataSource=>$inputs{DataSource});
	is($SiebelThick->Error, '', 'Siebel thick client connection created');
	tests($SiebelThick);

}

eval{#loading this DLL before completing thick client tests causes ExecuteQuery to fail. I have no idea why.
	$saThin = Win32::OLE->new($thinDLL) or die "Failed to load thin DLL";
};

ok(defined $saThin, 'Thin DLL Loaded');                # check that we got something
$saThin = undef;

if(TEST_THIN){
	print "Thin\n";
	my $SiebelThin = Siebel::Integration::Com->new(ConnectionType=>'Thin', UserName=>$inputs{user}, PassWord=>$inputs{pass}, Host=>$inputs{host}, Ent=>$inputs{ent}, ObjMgr=>$inputs{ObjMgr});
	is($SiebelThin->Error, '', 'Siebel thin client connection created');
	tests($SiebelThin);
}


sub tests{
	my $SiebelApp = shift;

	TestAppMethods($SiebelApp) if TEST_APP;
	TestAPPTrace($SiebelApp) if TEST_APP_TRACE;
	TestPropSet($SiebelApp) if TEST_PROPSET;

	TestBS($SiebelApp) if TEST_BS;
	
	my $res = TestBO_BC_RO($SiebelApp) if TEST_BO_BC_RO;
	diag('BO and BC RO tests failed, not all tested were executed!') if ($res // '') eq 'Error';
	
	my $res2 = TestBO_BC_RW($SiebelApp) if TEST_BO_BC_RW;
	diag('BO and BC RW tests failed, not all tested were executed!') if ($res2 // '') eq 'Error';
	
	ok($SiebelApp->LogOff(), 'Logged off');
}


########################################################################################################################################################
###############################					START APP TESTS							################################################################
########################################################################################################################################################


sub TestAppMethods{
	my $SiebelApp = shift;
	
	my %appData = (
		profAttrName => 'Test Attr 1',
		profAttrVal => 'TestVal 1',
		globalAttrName => 'Global Attr 1',
		globalAttrVal => 'Global Val 1',
	);
	
	is($SiebelApp->GetProfileAttr("Me.Login Name"), $inputs{user}, 'GetProfileAttr Me.Login Name');
	ok($SiebelApp->SetProfileAttr($appData{profAttrName}, $appData{profAttrVal}), "SetProfileAttr $appData{profAttrName}");
	is($SiebelApp->GetProfileAttr($appData{profAttrName}), $appData{profAttrVal}, "GetProfileAttr $appData{profAttrName}");
	ok($SiebelApp->CurrencyCode(), "CurrencyCode");
	ok($SiebelApp->LoginId(), "LoginId");
	is($SiebelApp->LoginName(), $inputs{user}, "LoginName");
	ok($SiebelApp->PositionId(), "PositionId");
	ok($SiebelApp->PositionName(), "PositionName");
	ok($SiebelApp->SetSharedGlobal($appData{globalAttrName}, $appData{globalAttrVal}), "SetSharedGlobal $appData{globalAttrName}");
	is($SiebelApp->GetSharedGlobal($appData{globalAttrName}), $appData{globalAttrVal}, "GetSharedGlobal $appData{profAttrName}");
	ok($SiebelApp->InvokeMethod("GetDataSource"), "InvokeMethod GetDataSource");
	ok($SiebelApp->EnableExceptions(1), "EnableExceptions On");
	ok($SiebelApp->EnableExceptions(0), "EnableExceptions Off");
	
	SKIP: {
        skip('Test data not set for Set Position methods', 4) if ((!defined $testData{SetPositionId}) || (!defined $testData{SetPositionIdName}));
		my $orig_pos_id = $SiebelApp->PositionId();
		my $orig_pos_name = $SiebelApp->PositionName();
		ok($SiebelApp->SetPositionId($testData{SetPositionId}),"SetPositionId $testData{SetPositionId}");
		is($SiebelApp->PositionName(), $testData{SetPositionIdName}, "PositionName $testData{SetPositionIdName}");
		ok($SiebelApp->SetPositionName($orig_pos_name),"Reset SetPositionName $orig_pos_name");
		is($SiebelApp->PositionId(), $orig_pos_id, "PositionId $orig_pos_id");
	}
    #TODO: {
        #local $TODO = 'Multiple Arguments to InvokeMethod is not working....';
		#need to work out best method to call to test this.....
		#ok($SiebelApp->InvokeMethod("AMethodName", 'Arg1','Arg2'), "InvokeMethod Multi args");
    #}
}


sub TestAPPTrace{
	my $SiebelApp = shift;
	ok($SiebelApp->TraceOn('c:/temp/trace_$p_$t.log','Allocation','All'), 'TraceOn c:/temp/trace_$p_$t.log');
	ok($SiebelApp->Trace('Trace on line: ' . __LINE__), 'Trace: Trace on line: ' . __LINE__);
	ok($SiebelApp->TraceOff(), 'TraceOff');
}

########################################################################################################################################################
###############################					END APP TESTS							################################################################
########################################################################################################################################################

########################################################################################################################################################
###############################					START PROPSET TESTS						################################################################
########################################################################################################################################################

sub TestPropSet{
	my $SiebelApp = shift;
	
	my %props = (
		Type => 'A Test Value For Type',
		Value => 'ABCD',
		Prop1 => 'This is Test Prop 1 Value set',
		Prop2 => '2',
		Prop3 => '3',
		Prop4 => '4',
		Prop5 => '5',
		Prop6 => '6',
	);
	
	my $PS = $SiebelApp->NewPropertySet();
	isa_ok($PS,'Siebel::Integration::Com::PropSet', 'COM Siebel propset created 1');
	is($PS->Error, '', 'Com Siebel Propset created 2');

	my $PSChild1 = $SiebelApp->NewPropertySet();
	is($PSChild1->Error, '', 'Com Siebel Propset created 3');
	my $PSChild2 = $SiebelApp->NewPropertySet();
	is($PSChild2->Error, '', 'Com Siebel Propset created 4');
	my $PSChild3 = $SiebelApp->NewPropertySet();
	is($PSChild3->Error, '', 'Com Siebel Propset created 5');
	my $PSGrandChild1 = $SiebelApp->NewPropertySet();
	is($PSGrandChild1->Error, '', 'Com Siebel Propset created 6');
	my $PSGrandChild2 = $SiebelApp->NewPropertySet();
	is($PSGrandChild2->Error, '', 'Com Siebel Propset created 7');

	is($PS->GetPropertyCount(), 0, 'GetPropertyCount PS has no properties');
	
	is($PS->GetType(), '', 'GetType PS has no type');
	is($PS->GetValue(), '', 'GetValue PS has no value');

	ok($PS->SetType($props{Type}), "SetType PS has had its type set");
	is($PS->GetType(), $props{Type}, "GetType PS type value returned = type set");
	
	ok($PS->SetValue($props{Value}), "SetValue PS has had its value set");
	is($PS->GetValue(), $props{Value}, "GetValue PS type value returned = value set");

	ok($PS->SetProperty('Prop1', $props{Prop1}), "SetProperty PS has had property Prop1");
	ok($PS->SetProperty('Prop2', $props{Prop2}), "SetProperty PS has had property Prop2");
	ok($PS->SetProperty('Prop3', $props{Prop3}), "SetProperty PS has had property Prop3");
	ok($PS->SetProperty('Prop4', $props{Prop4}), "SetProperty PS has had property Prop4");
	ok($PS->SetProperty('Prop5', $props{Prop5}), "SetProperty PS has had property Prop5");
	ok($PS->SetProperty('Prop6', $props{Prop6}), "SetProperty PS has had property Prop6");

	is($PS->GetProperty('Prop1'), $props{Prop1}, "GetProperty PS has had property Prop1, This is Test Prop 1 Value set");

	is($PS->GetPropertyCount(), 6, 'GetPropertyCount PS has 6 properties');

	is($PS->PropertyExists('DoesNot'), 0, "PropertyExists PS Property does not Exist");
	is($PS->PropertyExists('Prop1'), 1, "PropertyExists PS Property does Exist");
	
	if(my $Prop = $PS->GetFirstProperty()){
		my $count;
		pass("GetFirstProperty PS");
		do{
			is($PS->GetProperty($Prop), $props{$Prop}, "GetProperty/GetNextProperty PS Input Prop = Output Prop: $Prop => $props{$Prop}");
			$count++;
		}while($Prop = $PS->GetNextProperty());
		is($count, 6, 'Correct number of props were looped with GetNextProperty');
	}else{
		fail("GetFirstProperty PS");
	}

	#load up child PS's
	foreach my $key(keys %props){
		ok($PSChild1->SetProperty($key, 'Child1:' . $props{$key}), "SetProperty Child1: $key");
		ok($PSChild2->SetProperty($key, 'Child2:' . $props{$key}), "SetProperty Child2:$key");
		ok($PSChild3->SetProperty($key, 'Child3:' . $props{$key}), "SetProperty Child3:$key");
		ok($PSGrandChild1->SetProperty($key, 'GrandChild1:' . $props{$key}), "SetProperty GrandChild1:$key");
		ok($PSGrandChild2->SetProperty($key, 'GrandChild2:' . $props{$key}), "SetProperty GrandChild2:$key");
	}
	
	is($PS->GetChildCount(), 0, "GetChildCount PS has no child");
	
	is($PSChild1->AddChild($PSGrandChild1), 0, "AddChild 1 as Siebel::Integration::Com::PropSet");#returns index
	is($PSChild1->AddChild($PSGrandChild1->_PS), 1, "AddChild 2 as Siebel raw PS (Win32::OLE)");#returns index
	is($PS->AddChild($PSChild1), 0, "AddChild 3 added prop set with a child to main PS as Siebel::Integration::Com::PropSet");#returns index
	is($PS->AddChild($PSChild2->_PS), 1, "AddChild 4 added prop set without a child to main PS as Siebel raw PS (Win32::OLE)");#returns index

	is($PS->GetChildCount(), 2, "GetChildCount PS has 2 children");

	ok($PS->InsertChildAt($PSChild3,0), "InsertChildAt index 0, Child 1 and 2 will now be in 2 and 3 pos");
	
	is($PS->GetChildCount(), 3, "GetChildCount PS has 3 children");

	my $ChildPS1 = $PS->GetChild(1);
	isa_ok($ChildPS1,'Siebel::Integration::Com::PropSet', 'GetChild, Child PS index 1');
	is($ChildPS1->GetProperty('Prop1'), 'Child1:' . $props{Prop1}, "GetChild/GetProperty PS has had property Prop1, This is Test Prop 1 Value set");
	
	my $CopyPS = $PS->Copy();
	isa_ok($CopyPS,'Siebel::Integration::Com::PropSet', 'Copy PropSet');
	
	ok($CopyPS->RemoveProperty('Prop1'), "RemoveProperty");
	is($CopyPS->GetProperty('Prop1'), '', "Validated RemoveProperty Worked");
	isnt($CopyPS->GetProperty('Prop2'), '', "Copy PS has prop 2");
	
	my $beforeRemoval = $CopyPS->GetChildCount();
	ok($CopyPS->RemoveChild(1), "Removed Child 1");
	ok($CopyPS->GetChildCount() == ($beforeRemoval-1), "Removed Child 1, count validated");
	
	ok($CopyPS->Reset(1), "Reset PS");

	ok(($CopyPS->GetChildCount() == 0 && $CopyPS->GetPropertyCount() == 0), "Reset PS, validated");
}

########################################################################################################################################################
###############################					END PROPSET TESTS						################################################################
########################################################################################################################################################

########################################################################################################################################################
###############################					START BC/BO RO TESTS					################################################################
########################################################################################################################################################
sub TestBO_BC_RO{
	my $SiebelApp = shift;

	my $BO = $SiebelApp->GetBusObject('Employee');
	isa_ok($BO,'Siebel::Integration::Com::BusObj', 'COM Siebel busobj created 1');
	is($BO->Error, '', 'COM Siebel busobj created 2') || return 'Error';

	
	my $BC = $BO->GetBusComp('Employee');
	isa_ok($BC,'Siebel::Integration::Com::BusComp', 'COM Siebel buscomp created 1');
	is($BC->Error, '', 'COM Siebel buscomp created 2') || return 'Error';

	is($BC->Name(), 'Employee', "Name Employee" . $BC->Error);
	
	ok($BC->ClearToQuery(), "ClearToQuery"  . $BC->Error);
	
	ok($BC->SetViewMode('AllView'), "SetViewMode AllView"  . $BC->Error);
	
	is($BC->GetViewMode(), 3, "GetViewMode AllView (3)"  . $BC->Error);

	ok($BC->ActivateField('Login Name'), "ActivateField Login Name"  . $BC->Error);
	ok($BC->ActivateFields('EMail Addr', 'Job Title'), "ActivateFields 'EMail Addr', 'Job Title'"  . $BC->Error);
	ok($BC->SetSearchSpec('Id', '0-1'), "SetSearchSpec 'Id', '0-1'"  . $BC->Error);
	
	ok($BC->ExecuteQuery('ForwardOnly'), "ExecuteQuery ForwardOnly"  . $BC->Error) || return 'Error';
	

	if($BC->FirstRecord()){
		pass('Record Found for 0-1');

		is($BC->GetFieldValue('Login Name'), 'SADMIN', "GetFieldValue Login Name, SADMIN Found");
		isnt($BC->GetFieldValue('EMail Addr'), undef, 'GetFieldValue EMail Addr');
		isnt($BC->GetFieldValue('Job Title'), undef, 'GetFieldValue Job Title');

		my $MVGBC = $BC->GetMVGBusComp('Position Id');
		is($MVGBC->Error, '', 'GetMVGBusComp Position Id') || return 'Error';

		if($MVGBC->FirstRecord()){
			pass('MVG Rec Found');
			isnt($MVGBC->GetFieldValue('Id'), undef, 'GetFieldValue Id on MVG Position');
		}else{
			fail("No MVG Records Found");
		}
		ok(!$BC->NextRecord(), "NextRecord found no record");
	}else{
		fail("No Records Found");
	}
	is($BC->GetSearchSpec('Id'), '0-1', "GetSearchSpec 'Id', '0-1'");

	like($BC->GetFormattedFieldValue('Created'), qr/1980|1979/, "GetFormattedFieldValue, returned val (1980|1979) for Created actual format not checked:" . $BC->GetFormattedFieldValue('Created'));

	ok($BC->DeactivateFields(), "DeactivateFields");

	ok($BC->ExecuteQuery2('ForwardOnly', 1), "ExecuteQuery2 ForwardOnly, 'true'") || return 'Error';
	
	if($BC->FirstRecord()){
		pass('Record Found ExecuteQuery2 for 0-1');
		my $jobtitle = $BC->GetFieldValue('Job Title');
		ok(((!defined $jobtitle) && ($BC->Error() =~ /not active/)), "Job Title Feild Deactivated")

	}else{
		fail("No Records Found ExecuteQuery2 for 0-1");
	}
	
	my $propName = 'UserPropA';
	my $propValue = 'ValueOfUserPropA';
	ok($BC->SetUserProperty($propName, $propValue),"SetUserProperty, $propName:$propValue");
	is($BC->GetUserProperty($propName), $propValue, "GetUserProperty, $propName:$propValue");
		
	my $BO2 = $SiebelApp->GetBusObject('View Access');
	isa_ok($BO2,'Siebel::Integration::Com::BusObj', 'COM Siebel busobj created 3');
	is($BO2->Error, '', 'COM Siebel busobj created 4') || return 'Error';
	
	my $BC_Views = $BO2->GetBusComp('Feature Access');
	isa_ok($BC_Views,'Siebel::Integration::Com::BusComp', 'COM Siebel buscomp created 3');
	is($BC_Views->Error, '', 'COM Siebel buscomp created 4') || return 'Error';
	
	my $BC_Resp = $BO2->GetBusComp('Responsibility');
	isa_ok($BC_Resp,'Siebel::Integration::Com::BusComp', 'COM Siebel buscomp created 5');
	is($BC_Resp->Error, '', 'COM Siebel buscomp created 6') || return 'Error';
	
	my $par_BC = $BC_Resp->ParentBusComp();
	if((!$par_BC->Error) && ($par_BC->Name() eq 'Feature Access')){
		pass("ParentBusComp, Feature Access");
	}else{
		fail("ParentBusComp, Feature Access:" . $par_BC->Error);
	}
	
	ok($BC_Views->ClearToQuery(), 'ClearToQuery');

	ok($BC_Views->SetViewMode('AllView'), 'SetViewMode AllView');
	ok($BC_Views->ActivateField('Name'), 'ActivateField Name');
	
	#returned results for search expr convert ' to " so best to just give it what it wants for this test.
	my $searchExpr = '[Name] = "Quote List View" OR [Name] = "Activity List View" OR [Name] = "Account List View"';
	my $sortSpec = "Name(DESCENDING)";

	ok($BC_Views->SetSearchExpr($searchExpr), "SetSearchExpr $searchExpr");
	ok($BC_Views->SetSortSpec($sortSpec), "SetSortSpec $sortSpec");
	ok($BC_Views->ExecuteQuery('ForwardBackward'), "ExecuteQuery ForwardBackward");
	
	#Not supported on Thin Client......
	if($SiebelApp->ConnectionType eq 'Thin'){
		TODO: {
			local $TODO = 'GetSortSpec is not supported on thin client';
			is($BC_Views->GetSortSpec(), $sortSpec, "GetSortSpec" . $BC_Views->Error);
		}
	}else{
		is($BC_Views->GetSortSpec(), $sortSpec, "GetSortSpec" . $BC_Views->Error);
	}
	
	
	is($BC_Views->GetSearchExpr(), $searchExpr, "GetSearchExpr");
	
	my ($recCount, @views);
	if($BC_Views->LastRecord()){
		do{
			push(@views,$BC_Views->GetFieldValue('Name'));
			$recCount++;
		}while($BC_Views->PreviousRecord());
		is($recCount, 3, "LastRecord, PreviousRecord or SetSearchExpr");

		TODO: {
			local $TODO = 'Multiple Arguments to InvokeMethod is not working....';
			if($views[0] =~ /^Q/ && $views[1] =~ /^Activity/ && $views[2] =~ /^Account/){
				pass("Views in correct order: @views");
			}else{
				fail("Views in correct order: @views");
			}
		}
	}else{
		fail("No Records Found, SetSearchExpr/LastRecord");
	}
	
	ok($BC_Views->RefineQuery(), "RefineQuery");
	
	#returned results for search expr convert ' to " so best to just give it what it wants for this test.
	my $namedSearch = '[Name] LIKE "A*"';
	ok($BC_Views->SetNamedSearch('Search1',$namedSearch), "SetNamedSearch $namedSearch");
	ok($BC_Views->ExecuteQuery('ForwardBackward'), "ExecuteQuery ForwardBackward");
	
	is($BC_Views->GetNamedSearch('Search1'), $namedSearch, "GetNamedSearch $namedSearch");

	my ($recCount2);
	if($BC_Views->FirstRecord()){
		do{
			$recCount2++;
		}while($BC_Views->NextRecord());
		is($recCount2, 2, "SetNamedSearch 2 records returned");
	}else{
		fail("No Records Found, SetNamedSearch??");
	}

	is($BC_Views->InvokeMethod('RefreshBusComp'), defined, 'InvokeMethod RefreshBusComp');
	is($BC_Views->InvokeMethod('SetAdminMode', 1), defined, 'InvokeMethod SetAdminMode 1');
	
}

########################################################################################################################################################
###############################					END BC/BO RO TESTS						################################################################
########################################################################################################################################################

########################################################################################################################################################
###############################					START BC/BO RW TESTS					################################################################
########################################################################################################################################################

sub TestBO_BC_RW{
	my $SiebelApp = shift;
	
	my $BO = $SiebelApp->GetBusObject('Employee');
	isa_ok($BO,'Siebel::Integration::Com::BusObj', 'COM Siebel busobj created 1');
	is($BO->Error, '', 'COM Siebel busobj created 2') || return 'Error';

	
	my $BC = $BO->GetBusComp('Employee');
	isa_ok($BC,'Siebel::Integration::Com::BusComp', 'COM Siebel buscomp created 1');
	is($BC->Error, '', 'COM Siebel buscomp created 2') || return 'Error';

	is($BC->Name(), 'Employee', "Name Employee" . $BC->Error);
	
	ok($BC->ClearToQuery(), "ClearToQuery"  . $BC->Error);
	
	ok($BC->SetViewMode('AllView'), "SetViewMode AllView"  . $BC->Error);
	
	is($BC->GetViewMode(), 3, "GetViewMode AllView (3)"  . $BC->Error);

	ok($BC->ActivateFields('Personal Title'), "ActivateFields Personal Title"  . $BC->Error);
	ok($BC->SetSearchSpec('Id', $SiebelApp->LoginId()), "SetSearchSpec 'Id', LoginId"  . $BC->Error);
	
	ok($BC->ExecuteQuery('ForwardOnly'), "ExecuteQuery ForwardOnly"  . $BC->Error) || return 'Error';
	
	my %data = (
		Mr => 'Miss',
		Miss => 'Mr',
	);

	if($BC->FirstRecord()){
		my $Title = $BC->GetFieldValue('Personal Title');
		$Title = 'Mr' if $Title !~ /Mr|Miss/;
		
		is($BC->GetFieldValue('Login Name'), $SiebelApp->LoginName(), "Validate correct record returned for update");
		my $PickTitleBC = $BC->GetPicklistBusComp('Personal Title');
		isa_ok($PickTitleBC,'Siebel::Integration::Com::BusComp', 'GetPicklistBusComp Created 1');
		is($PickTitleBC->Error, '', 'GetPicklistBusComp Created 1') || return 'Error';
		
		ok($PickTitleBC->ClearToQuery(), "ClearToQuery"  . $PickTitleBC->Error);
		ok($PickTitleBC->SetSearchSpec('Value', $data{$Title}), "SetSearchSpec 'Value', " . $data{$Title} . $PickTitleBC->Error);
		ok($PickTitleBC->SetViewMode('AllView'), "SetViewMode AllView"  . $PickTitleBC->Error);
		ok($PickTitleBC->ExecuteQuery('ForwardOnly'), "ExecuteQuery ForwardOnly"  . $PickTitleBC->Error) || return 'Error';
		if($PickTitleBC->FirstRecord()){
			ok($PickTitleBC->Pick(),"$data{$Title} Picked");
		}else{
			fail("No Pick BC Records Found");
		}
		is($BC->GetFieldValue('Personal Title'), $data{$Title}, "$data{$Title} returned");
		$BC->WriteRecord();
		#write back old title and then UndoRecord
		$Title = $data{$Title};#toggle
		ok($PickTitleBC->ClearToQuery(), "ClearToQuery"  . $PickTitleBC->Error);
		ok($PickTitleBC->SetSearchSpec('Value', $data{$Title}), "SetSearchSpec 'Value', " . $data{$Title} . $PickTitleBC->Error);
		ok($PickTitleBC->SetViewMode('AllView'), "SetViewMode AllView"  . $PickTitleBC->Error);
		ok($PickTitleBC->ExecuteQuery('ForwardOnly'), "ExecuteQuery ForwardOnly"  . $PickTitleBC->Error) || return 'Error';
		if($PickTitleBC->FirstRecord()){
			ok($PickTitleBC->Pick(),"$data{$Title} Picked");
		}else{
			fail("No Pick BC Records Found");
		}
		ok($BC->UndoRecord(), 'Undo Record');
		is($BC->GetFieldValue('Personal Title'), $Title, "Title not updated");#should not have updated.
		
		my $BC_EmpCompAdmin = $BO->GetBusComp('CMS Employee Competency Administration');
		isa_ok($BC_EmpCompAdmin,'Siebel::Integration::Com::BusComp', 'COM Siebel buscomp created BC_EmpCompAdmin 1');
		is($BC_EmpCompAdmin->Error, '', 'COM Siebel buscomp created BC_EmpCompAdmin 2') || return 'Error';
		
		ok($PickTitleBC->ClearToQuery(), "ClearToQuery"  . $PickTitleBC->Error);
		ok($PickTitleBC->ActivateFields('Date of Accomplishment','Employee Comments'), "ActivateFields Date of Accomplishment, Employee Comments"  . $PickTitleBC->Error);
		ok($PickTitleBC->ExecuteQuery('ForwardOnly'), "ExecuteQuery ForwardOnly"  . $PickTitleBC->Error) || return 'Error';
		
		my $existingRecordId = "A";	
		if($BC_EmpCompAdmin->FirstRecord()){
			$existingRecordId = $BC_EmpCompAdmin->GetFieldValue('Id');
		}

		ok($BC_EmpCompAdmin->NewRecord('NewBefore'), "New Record BC_EmpCompAdmin NewBefore");
		#make sure new record exits by checking id is new
		if($BC_EmpCompAdmin->GetFieldValue('Id') eq $existingRecordId){
			fail('NewRecord failed to give a record with a new ROW_ID. Exiting: ' . $existingRecordId . ' New:' . $BC_EmpCompAdmin->GetFieldValue('Id'));
			return 'Error';
		}
		
		ok($BC_EmpCompAdmin->SetFieldValue('Employee Comments', 'Emp Comment'), "SetFieldValue Employee Comments " . $BC_EmpCompAdmin->Error);
		is($BC_EmpCompAdmin->GetFieldValue('Employee Comments'), 'Emp Comment', "GetFieldValue Employee Comments " . $BC_EmpCompAdmin->Error);
		
		SKIP: {
			skip('Test data not set for SetFormattedFieldValue methods', 2) if !defined $testData{FormattedDateTimeFieldValue};
			ok($BC_EmpCompAdmin->SetFormattedFieldValue('Date of Accomplishment', $testData{FormattedDateTimeFieldValue}), "SetFormattedFieldValue:" . $BC_EmpCompAdmin->Error);
			is($BC_EmpCompAdmin->GetFormattedFieldValue('Date of Accomplishment'), $testData{FormattedDateTimeFieldValue}, "GetFormattedFieldValue input: " . $testData{FormattedDateTimeFieldValue} . " Output: " . $BC_EmpCompAdmin->GetFormattedFieldValue('Date of Accomplishment'));
		}
		ok($BC_EmpCompAdmin->DeleteRecord, 'New Record Deleted Before Commit');
	}else{
		fail("No Records Found");
	}
	SKIP: {
		skip('Test data not set for GetAssocBusComp and Associate methods', 8) if !defined $testData{PositionIdToAssociate};
		my $MVGBC = $BC->GetMVGBusComp('Position Id');
		isa_ok($MVGBC,'Siebel::Integration::Com::BusComp', 'COM Siebel buscomp created GetMVGBusComp 1');
		is($MVGBC->Error, '', 'COM Siebel buscomp created GetMVGBusComp 2') || return 'Error';
	
		my $AssocMVG = $MVGBC->GetAssocBusComp();
		isa_ok($AssocMVG,'Siebel::Integration::Com::BusComp', 'COM Siebel buscomp created GetAssocBusComp 1');
		is($AssocMVG->Error, '', 'COM Siebel buscomp created GetAssocBusComp 2') || return 'Error';
		
		ok($AssocMVG->ClearToQuery(), "ClearToQuery"  . $AssocMVG->Error);
		ok($AssocMVG->SetSearchSpec('Id', $testData{PositionIdToAssociate}), "SetSearchSpec 'Id', " . $testData{PositionIdToAssociate} . $AssocMVG->Error);
		ok($AssocMVG->ExecuteQuery('ForwardOnly'), "ExecuteQuery ForwardOnly"  . $AssocMVG->Error) || return 'Error';
		if($AssocMVG->FirstRecord()){
			ok($AssocMVG->Associate('NewBefore'), 'Associate' . $AssocMVG->Error);
		}else{
			fail("No Assoc BC Records Found");
		}
	}
}

########################################################################################################################################################
###############################					END BC/BO RW TESTS						################################################################
########################################################################################################################################################

########################################################################################################################################################
###############################					START BS TESTS							################################################################
########################################################################################################################################################
sub TestBS{
	my $SiebelApp = shift;
	my $BS = $SiebelApp->GetService('Workflow Utilities');
	isa_ok($BS,'Siebel::Integration::Com::BusSrv', 'Business Service Workflow Utilities Created 1');
	is($BS->Error, '', 'Business Service Workflow Utilities Created 2') || return 'Error';
	
	my $PS = $SiebelApp->NewPropertySet();
	isa_ok($PS,'Siebel::Integration::Com::PropSet', 'COM Siebel propset created 1');
	is($PS->Error, '', 'Com Siebel Propset created 2');
	
	my $PSChild = $SiebelApp->NewPropertySet();
	isa_ok($PSChild,'Siebel::Integration::Com::PropSet', 'COM Siebel propset created 3');
	is($PSChild->Error, '', 'Com Siebel Propset created 4');
	
	my $Outputs = $SiebelApp->NewPropertySet();
	isa_ok($Outputs,'Siebel::Integration::Com::PropSet', 'COM Siebel propset created 5');
	is($Outputs->Error, '', 'Com Siebel Propset created 6');
	
	ok($PS->SetProperty('Prop Par 1', 'Prop Par 1 Value'), "SetProperty Par");
	ok($PS->SetType('This is a type'), "SetType Par");
	ok($PS->SetValue('And this is its value'),"SetValue Par");
	ok($PSChild->SetProperty('Prop Child 1', 'Prop Child 1 Value'), "SetProperty Child");
	is($PS->AddChild($PSChild),0,"AddChild");
	
	ok($BS->InvokeMethod('Echo', $PS, $Outputs),"Workflow Utilities Echo Method Called");
	
	is($Outputs->GetPropertyCount(), 1, 'Outputs: GetPropertyCount PS has 1 property');
	is($Outputs->GetType(), 'This is a type', "Outputs: GetType Parent PS");
	is($Outputs->GetValue(), 'And this is its value', "Outputs: GetValue Parent PS");

	is($Outputs->GetProperty('Prop Par 1'), 'Prop Par 1 Value', "Outputs: GetProperty Parent PS");
	is($Outputs->GetChildCount(), 1, "Outputs: GetChildCount Parent PS has 1");
	
	my $newChild = $Outputs->GetChild(0);
	is($newChild->GetChildCount(), 0, "Outputs: GetChildCount Child PS has 0");
	is($newChild->GetPropertyCount(), 1, 'Outputs: GetPropertyCount Child PS has 1 property');
	is($newChild->GetType(), '', "Outputs: GetType Child PS");
	is($newChild->GetValue(), '', "Outputs: GetValue Child PS");
	is($newChild->GetProperty('Prop Child 1'), 'Prop Child 1 Value', "Outputs: GetProperty Child PS");
	
	
}

########################################################################################################################################################
###############################					END BS TESTS							################################################################
########################################################################################################################################################