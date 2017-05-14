package Siebel::Integration::Com 0.02;

use 5.006;
use Moose;
use namespace::autoclean;
use strict;
use warnings;

BEGIN{
	die print "This requires windows :-(" if $^O !~ /MSWin32/;
}

use Win32::OLE;
use Win32::OLE::Variant;

use Siebel::Integration::Com::BusObj;
use Siebel::Integration::Com::BusSrv;
use Siebel::Integration::Com::PropSet;

has Error 		=>(
					is => 'rw', 
					isa=>'Str', 
					default=> '',
				);

has ThinDLL		=>( 
					is => 'ro', 
					isa=>'Str', 
					default=> 'SiebelDataControl.SiebelDataControl.1'
				);
has ThickDLL 	=>( 
					is => 'ro', 
					isa=>'Str', 
					default=> 'SiebelDataServer.ApplicationObject'
				);
has SApp 		=>(
					is => 'rw',
				);


has _ThickError =>(
					is => 'rw', 
				);
				
has ConnectionType =>( 
					is => 'rw', 
					isa=>'Str', 
					required => 1,
				);
has UserName =>( 
					is => 'rw', 
					isa=>'Str', 
					required => 1,
				);
has PassWord =>( 
					is => 'rw', 
					isa=>'Str', 
					required => 1,
				);
has CFG =>( 
					is => 'rw', 
					isa=>'Str', 
				);
has DataSource =>( 
					is => 'rw', 
					isa=>'Str', 
				);
has Host =>( 
					is => 'rw', 
					isa=>'Str', 
				);				
has Ent =>( 
					is => 'rw', 
					isa=>'Str', 
				);	
has ObjMgr =>( 
					is => 'rw', 
					isa=>'Str', 
				);					
	
sub BUILD{
	#ConnectionType
	#UserName
	#PassWord
	#If Connection Type Thick
		#CFG
		#DataSource
	#If Connection Type Thin
		#Host
		#Ent
		#ObjMgr

	my $self = shift;

	if ($self->ConnectionType eq 'Thick'){
		if (!$self->CFG){
			$self->Error('CFG is mandatory');
			return 0;
		}
		if (!$self->DataSource){
			$self->Error('DataSource is mandatory');
			return 0;
		}
		$self->_ThickError(Variant(VT_I2|VT_BYREF, 0));
	}elsif($self->ConnectionType eq 'Thin'){
		if (!$self->Host){
			$self->Error('Host is mandatory');
			return 0;
		}
		if (!$self->Ent){
			$self->Error('Ent is mandatory');
			return 0;
		}
		if (!$self->ObjMgr){
			$self->Error('ObjMgr is mandatory');
			return 0;
		}
	}else{
		$self->Error('ConnectionType must be Thin or Thick');
		return 0;
	}

	if($self->ConnectionType eq 'Thin'){
		my $sa = Win32::OLE->new($self->ThinDLL) or die "Failed to load thin DLL";
		$self->SApp($sa);
		#"host=""siebel://hostname/EnterpriseServer/AppObjMgr""", "USER", "PASS"
		my $connection = 'host="siebel://' . $self->Host . '/' . $self->Ent . '/' . $self->ObjMgr . '"';
		$self->SApp->Login($connection, $self->UserName, $self->PassWord); 								return undef if $self->_chkErr("Login");
	}else{
		my $sa  = Win32::OLE->new($self->ThickDLL) or die "Failed to load thick DLL";
		$self->SApp($sa);
		$self->SApp->LoadObjects($self->CFG . ',' . $self->DataSource, $self->_ThickError);				return undef if $self->_chkErr("Can't load thick objects");
		$self->SApp->Login($self->UserName, $self->PassWord, $self->_ThickError);						return undef if $self->_chkErr("Login");
	}
	
	
	
}

sub GetBusObject{
	my $self = shift;
	my $BOName = shift;
	return Siebel::Integration::Com::BusObj->new(Name => $BOName, ConnectionType => $self->ConnectionType, SApp => $self->SApp);
}

sub GetProfileAttr{
	my $self = shift;
	my $attrName = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		my $attrVal = $self->SApp->GetProfileAttr($attrName); 											return undef if $self->_chkErr("Can't get profile attrubute");
		return $attrVal;
	}else{
		my $attrVal = $self->SApp->GetProfileAttr($attrName, $self->_ThickError); 						return undef if $self->_chkErr("Can't get profile attrubute");
		return $attrVal;
	}
}

sub InvokeMethod{#InvokeMethod(methodName as String, methArg1, methArg2, methArgN as String or StringArray)
	my $self = shift;
	my $methodName = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		my $attrVal;
		if (@_){
			if(@_ > 1){warn 'Invoke Method with more than 1 param does not work'; return 0;};
			$attrVal = $self->SApp->InvokeMethod($methodName, @_); 										return undef if $self->_chkErr("Can't InvokeMethod");
		}else{
			#must pass an empty string if no args or error.
			$attrVal = $self->SApp->InvokeMethod($methodName, ''); 										return undef if $self->_chkErr("Can't InvokeMethod");
		}
		return $attrVal;
	}else{
		my $attrVal;
		if (@_){
			if(@_ > 1){warn 'Invoke Method with more than 1 param does not work'; return 0;};
			$attrVal = $self->SApp->InvokeMethod($methodName, @_, $self->_ThickError); 					return undef if $self->_chkErr("Can't InvokeMethod");
		}else{
			#must pass an empty string if no args or error.
			$attrVal = $self->SApp->InvokeMethod($methodName, '', $self->_ThickError); 					return undef if $self->_chkErr("Can't InvokeMethod");
		}
		return $attrVal;
	}
}


sub SetProfileAttr{
	my $self = shift;
	my $attrName = shift;
	my $attrValue = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->SApp->SetProfileAttr($attrName, $attrValue); 											return undef if $self->_chkErr("Can't set profile attrubute");
	}else{
		$self->SApp->SetProfileAttr($attrName, $attrValue, $self->_ThickError); 						return undef if $self->_chkErr("Can't set profile attrubute");
	}
	return 1;
}

sub GetSharedGlobal{
	my $self = shift;
	my $attrName = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		my $attrVal = $self->SApp->GetSharedGlobal($attrName); 											return undef if $self->_chkErr("Can't GetSharedGlobal");
		return $attrVal;
	}else{
		my $attrVal = $self->SApp->GetSharedGlobal($attrName, $self->_ThickError); 						return undef if $self->_chkErr("Can't GetSharedGlobal");
		return $attrVal;
	}
}

sub SetSharedGlobal{
	my $self = shift;
	my $attrName = shift;
	my $attrValue = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->SApp->SetSharedGlobal($attrName, $attrValue); 											return undef if $self->_chkErr("Can't SetSharedGlobal");
	}else{
		$self->SApp->SetSharedGlobal($attrName, $attrValue, $self->_ThickError); 						return undef if $self->_chkErr("Can't SetSharedGlobal");
	}
	return 1;
}

sub GetLastErrCode{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->SApp->GetLastErrCode();
	}else{
		return $self->SApp->GetLastErrCode($self->_ThickError);
	}
}
sub GetLastErrText{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->SApp->GetLastErrText();
	}else{
		return $self->SApp->GetLastErrText($self->_ThickError);
	}
}


sub LogOff{
	#Myabe should do cleanup?, keep list of all prop sets, bc, bo, bs created and destory at logoff? what about underlying ole objects?
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->SApp->LogOff();
		$self->SApp(undef);
	}else{
		#logoff is not a valid method for thick client
		#return $self->SApp->LogOff($self->_ThickError);
		$self->SApp(undef);
	}
	return 1;
}

sub GetService{
	my $self = shift;
	my $BSName = shift;
	$self->Error('');
	return Siebel::Integration::Com::BusSrv->new(Name => $BSName, ConnectionType => $self->ConnectionType, SApp => $self->SApp);
}

sub NewPropertySet{
	my $self = shift;
	$self->Error('');
	return Siebel::Integration::Com::PropSet->new(ConnectionType => $self->ConnectionType, SApp => $self->SApp);
}

sub PositionName{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->SApp->PositionName();
	}else{
		return $self->SApp->PositionName($self->_ThickError);
	}
}
sub PositionId{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->SApp->PositionId();
	}else{
		return $self->SApp->PositionId($self->_ThickError);
	}
}
sub LoginName{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->SApp->LoginName();
	}else{
		return $self->SApp->LoginName($self->_ThickError);
	}
}
sub LoginId{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->SApp->LoginId();
	}else{
		return $self->SApp->LoginId($self->_ThickError);
	}
}
sub CurrencyCode{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->SApp->CurrencyCode();
	}else{
		return $self->SApp->CurrencyCode($self->_ThickError);
	}
}

sub SetPositionId{
	my $self = shift;
	my $posId = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->SApp->SetPositionId($posId); 												return undef if $self->_chkErr("Can't SetPositionId");
	}else{
		 $self->SApp->SetPositionId($posId, $self->_ThickError); 							return undef if $self->_chkErr("Can't SetPositionId");
	}
	return 1;
}
sub SetPositionName{
	my $self = shift;
	my $posName = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->SApp->SetPositionName($posName); 											return undef if $self->_chkErr("Can't SetPositionName");
	}else{
		$self->SApp->SetPositionName($posName, $self->_ThickError); 						return undef if $self->_chkErr("Can't SetPositionName");
	}
	return 1;
}

sub TraceOn{
	my $self = shift;
	my $file_name = shift;
	my $trace_type = shift;#type = [Allocation/SQL]
	my $selection = shift;#Selection = [Script/OLE/All]
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->SApp->TraceOn($file_name, $trace_type, $selection); 							return undef if $self->_chkErr("Can't TraceOn");
	}else{
		 $self->SApp->TraceOn($file_name, $trace_type, $selection, $self->_ThickError); 	return undef if $self->_chkErr("Can't TraceOn");
	}
	return 1;
}

sub Trace{
	my $self = shift;
	my $message = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->SApp->Trace($message); 														return undef if $self->_chkErr("Can't TraceOn");
	}else{
		 $self->SApp->Trace($message, $self->_ThickError); 									return undef if $self->_chkErr("Can't TraceOn");
	}
	return 1;
}


sub TraceOff{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->SApp->TraceOff(); 															return undef if $self->_chkErr("Can't TraceOff");
	}else{
		$self->SApp->TraceOff($self->_ThickError); 											return undef if $self->_chkErr("Can't TraceOff");
	}
	return 1;
}

sub EnableExceptions{
	my $self = shift;
	my $setting = shift; # 0 or 1
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->SApp->EnableExceptions($setting); 											return undef if $self->_chkErr("Can't EnableExceptions");
	}else{
		 #not available in thick client
		 #$self->SApp->EnableExceptions($setting, $self->_ThickError); 						return undef if $self->_chkErr("Can't EnableExceptions");
	}
	return 1;
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

Siebel::Integration::Com - Abstraction of Siebel Application

=head1 SYNOPSIS

	use Siebel::Integration::Com;

	my %inputs = (
		user => 'SADMIN',
		pass => 'PASSWORD',
		ObjMgr => 'ObjMgr',#thin client only
		ent => 'MYENT',#thin client only
		host => 'MYHOSTNAME',#thin client only
		cfg => 'C:/Siebel/publicsector.cfg',#thick client only
		DataSource => 'ServerDataSrc',#thick client only
	);
	
	#Thin (Server)
	my $SiebelThin = Siebel::Integration::Com->new(
			ConnectionType=>'Thin', 
			UserName=>$inputs{user}, 
			PassWord=>$inputs{pass}, 
			Host=>$inputs{host}, 
			Ent=>$inputs{ent}, 
			ObjMgr=>$inputs{ObjMgr}
		);

	#Thick (Dedicated)
	my $SiebelThick = Siebel::Integration::Com->new(
			ConnectionType=>'Thick', 
			UserName=>$inputs{user}, 
			PassWord=>$inputs{pass}, 
			CFG=>$inputs{cfg}, 
			DataSource=>$inputs{DataSource}
		);
	
	#get and set some basic values
	print "Prof Attr Set\n" if $SiebelApp->SetProfileAttr("Test Attr 1", "TestVal 1");
	print 'Get Prof Attr: ' . $SiebelApp->GetProfileAttr("Test Attr 1") . "\n";
	print 'CurrencyCode: ' . $SiebelApp->CurrencyCode() . "\n";
	print 'LoginId: ' . $SiebelApp->LoginId() . "\n";
	print 'LoginName: ' . $SiebelApp->LoginName() . "\n";
	print 'PositionId: ' . $SiebelApp->PositionId() . "\n";
	print 'PositionName: ' . $SiebelApp->PositionName() . "\n";
	print "Shared Global Set\n" if $SiebelApp->SetSharedGlobal('COMGlobal','Set');
	print 'GetSharedGlobal - COMGlobal: ' . $SiebelApp->GetSharedGlobal('COMGlobal') . "\n";	

	#Query for Current user. See Siebel::Integration::Com::BusObj and Siebel::Integration::Com::BusComp for full details
	my $BO = $SiebelApp->GetBusObject('Employee');
	my $BC = $BO->GetBusComp('Employee');

	$BC->ClearToQuery();
	$BC->SetViewMode('AllView');
	$BC->ActivateFields('First Name','Last Name','Login Name');
	$BC->SetSearchSpec('Id', $SiebelApp->LoginId());
	$BC->ExecuteQuery('ForwardOnly');
	if($BC->FirstRecord()){
		print "FName: " . $BC->GetFieldValue('First Name') . "\t";
		print "LName: " . $BC->GetFieldValue('Last Name') . "\t";
		print "Login: " . $BC->GetFieldValue('Login Name') . "\n";
	}else{
		die print "Something is wrong!";
	}

	#Business Service Call with Property Set. See Siebel::Integration::Com::BusSrv and Siebel::Integration::Com::PropSet for full details
	my $BS = $SiebelApp->GetService('Workflow Utilities');
	my $PS = $SiebelApp->NewPropertySet();
	my $PSChild = $SiebelApp->NewPropertySet();
	my $Outputs = $SiebelApp->NewPropertySet();
	
	$PS->SetProperty('Prop Par 1', 'Prop Par 1 Value');
	$PS->SetType('This is a type');
	$PS->SetValue('And this is its value');
	$PSChild->SetProperty('Prop Child 1', 'Prop Child 1 Value');
	$PS->AddChild($PSChild);
	
	if($BS->InvokeMethod('Echo', $PS, $Outputs)){
		print "Called BS method Echo, all OK";
	}else{
		print "Failed to call BS method Echo: " . $BS->Error;
	}
	
	
	$SiebelApp->LogOff();

=head1 DESCRIPTION

The Siebel::Integration::Com modules are designed to remove the different method calls and error checking between the COM Data Control and COM Data Server interfaces. 
Changing between the two interfaces only requires a change in the parameters to Siebel::Integration::Com->new() rather than a rewrite of all calls.
Beyond just replicating the base functions of the interfaces it is hoped that additional methods will be added to these modules to extend the functionality provided by the Siebel COM framework.

All methods that have been exposed keep the same names so there is no additional learning curve, you can program in Perl using the same method names as eScript

COM Data Control uses the Siebel server (the server must be up and running). This is considered a thin client connection

COM Data Server does not require the Siebel server as it uses the local machine to do the work. This is considered a thick client connection

=head2 Base Methods

=over 8

=item New(%inputs)

	my %inputs = (
		user => 'SADMIN',
		pass => 'PASSWORD',
		ObjMgr => 'ObjMgr',#thin client only
		ent => 'MYENT',#thin client only
		host => 'MYHOSTNAME',#thin client only
		cfg => 'C:/Siebel/publicsector.cfg',#thick client only
		DataSource => 'ServerDataSrc',#thick client only
	);

	#Thin Client Connection
	
	my $SiebelThin = Siebel::Integration::Com->new(
			ConnectionType=>'Thin', 
			UserName=>$inputs{user}, 
			PassWord=>$inputs{pass}, 
			Host=>$inputs{host}, 
			Ent=>$inputs{ent}, 
			ObjMgr=>$inputs{ObjMgr}
		);
	
	#Thick Client Connection
	
	my $SiebelThick = Siebel::Integration::Com->new(
			ConnectionType=>'Thick', 
			UserName=>$inputs{user}, 
			PassWord=>$inputs{pass}, 
			CFG=>$inputs{cfg}, 
			DataSource=>$inputs{DataSource}
		);
	
	Sets SAPP->Error if an error occurs

=item SAPP->Error

	Returns the error text for the last operation, returns '' if no error.

=item SAPP->GetProfileAttr(Name)

	Returns the value of the profile attribute. Using an attribute name that does not exist will return ''
	Returns undef for failure. A failure will set SAPP->Error

=item SAPP->SetProfileAttr(Name, Value)

	Creates or updates a profile attribute
	Returns 1 for success
	Returns undef for failure. A failure will set SAPP->Error

=item SAPP->LogOff

Only the Thin client actually supports this as a method. Calling this will log off if connection type is Thin and undef the Siebel App OLE for both Thin and Thick clients.

=item SAPP->GetBusObject(Name)

	Returns a Siebel::Integration::Com::BusObj Object
	Failure to create will set Siebel::Integration::Com::BusObj->Error

=item SAPP->GetService(Name)

	Returns a Siebel::Integration::Com::BusSrv Object
	Failure to create will set Siebel::Integration::Com::BusSrv->Error

=item SAPP->NewPropertySet

	Returns a Siebel::Integration::Com::PropSet Object
	Failure to create will set Siebel::Integration::Com::PropSet->Error

=item SAPP->GetSharedGlobal(Name)

	Returns the value of the shared global. Using a shared global name that does not exist will return ''
	Returns undef for failure. A failure will set SAPP->Error

=item SAPP->SetSharedGlobal(Name, Value)

	Creates or updates a shared global
	Returns 1 for success
	Returns undef for failure. A failure will set SAPP->Error

=item SAPP->CurrencyCode

	Returns the currency code that is associated with the division of the user position

=item SAPP->LoginId

	Returns the login Id of the user who started the Siebel application

=item SAPP->LoginName

	Returns the login name of the user who started the Siebel application

=item SAPP->PositionId

	Returns the position Id of the user position

=item SAPP->PositionName

	Returns the name of the current user position

=item SAPP->SetPositionId(sPosId)

	Sets the active position to a Position Id
	Returns 1 for success
	Returns undef for failure. A failure will set SAPP->Error

=item SAPP->SetPositionName(sPosName)

	Sets the active position to a position name
	Returns 1 for success
	Returns undef for failure. A failure will set SAPP->Error

=item SAPP->InvokeMethod(MethodName, Arg1, Arg2, ArgN)

	B<See Bugs>
	Currently this only allows for 0 or 1 argument to be passed. I have not yet worked out if this is due to me or a fault in the DLL.
	Invokes a method on the application object

=item SAPP->EnableExceptions(true/false)

	Only in thin client: Enables or disables native COM error handling. Acepts 0 or 1. If using the thick client this call is supressed

=item SAPP->TraceOff

	Turns tracing off
	Returns 1 for success
	Returns undef for failure. A failure will set SAPP->Error

=item SAPP->TraceOn(FileName, Type, Selection)

	Starts appliaction tracing
	FileName: Output filename
	Type: [Allocation/SQL]
		Allocation: Traces allocations and deallocations of Siebel objects
		SQL: Traces SQL statements
	Selection: [Script/OLE/All]
		Script: Traces Siebel VB and Siebel eScript objects.
		OLE: Traces allocations for data server or automation server programs.
		All: Traces all objects that Siebel creates as a result of scripting. 
	Returns 1 for success
	Returns undef for failure. A failure will set SAPP->Error

=item SAPP->Trace(Message)

	Writes the message to the trace file if tracing is on
	Returns 1 for success
	Returns undef for failure. A failure will set SAPP->Error

=item SAPP->GetLastErrCode

	The error handler that sets SAPP->Error calls this method causing the value to be wiped out. Use SAPP->Error for error details

=item SAPP->GetLastErrText

	The error handler that sets SAPP->Error calls this method causing the value to be wiped out. Use SAPP->Error for error details

=item SAPP->ConnectionType

	The current connection type Thin or Thick

=item SAPP->UserName

	The current user name

=item SAPP->PassWord

	The current password

=item SAPP->CFG

	The current CFG file location, only valid for Thick connections

=item SAPP->DataSource

	The current data source, only valid for Thick connections

=item SAPP->Host

	The current siebl host, only valid for Thin connections

=item SAPP->Ent

	The current siebl Enterprise, only valid for Thin connections

=item SAPP->ObjMgr

	The current siebl Object Manager, only valid for Thin connections

=back

=head1 REQUIREMENTS

Windows

Siebel Dedicated Client or more specifically, 	

sstchca.dll - This provides COM interface to Siebel application. This DLL is provided by Siebel and gets registered on your system when you install Siebel Dedicated (Thick) Client. 

The modules will install if the DLL is not present however until the DLL is registered on the system they will not work.

=head1 TESTING

WinXP x86 Active State Perl 32 Bit 5.16

Windows 2003x64 Strawberry Perl 32Bit 5.16.2

Siebel 7.7

Siebel 8.1

=head2 test.t

test.t has a full set of tests however due to almost all tests requiring a user name and password along with system settings to get the full set of tests you must update the %inputs and %testData
variables with the appropriate values. You can then select the tests you wish to preform using the constants at the top of the script.

The test full.t has over 400 tests if all are run in one go this seems to cause problems. Please run only thin or thick client tests at one time.
Run standalone (without Test::More) there is no issue but as part of the test suite it just stops after some tests and does not give a report.
Any help appreciated in understanding this would be appreciated.


=head1 NOTES

The Siebel Application base method Login is called as part of the New method and is not exposed to the user by the resulting Siebel::Integration::Com object

EnableExceptions - only in thin client, thick throws exception, have suppressed call when on thick.

=head1 BUGS/LIMITATIONS

InvokeMethod - only takes zero or one argument

=head1 SEE ALSO

L<Siebel::Integration::Com::BusObj>

L<Siebel::Integration::Com::BusComp>

L<Siebel::Integration::Com::BusSrv>

L<Siebel::Integration::Com::PropSet>

=head2 REFERENCES

L<Oracle Help Application Methods|http://docs.oracle.com/cd/E14004_01/books/OIRef/OIRef_Interfaces_Reference9.html>

L<Oracle Help Business Component Methods|http://docs.oracle.com/cd/E14004_01/books/OIRef/OIRef_Interfaces_Reference11.html>

L<Oracle Help Property Set Methods|http://docs.oracle.com/cd/E14004_01/books/OIRef/OIRef_Siebel_eScript_Quick_Reference11.html>


=head1 AUTHOR

Kyle Mathers, C<< <kyle.perl at mathersit.com> >>

=head1 COPYRIGHT

Copyright (C) 2013 Kyle Mathers

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=head1 VERSION

Version 0.02	  March 2013

=cut





