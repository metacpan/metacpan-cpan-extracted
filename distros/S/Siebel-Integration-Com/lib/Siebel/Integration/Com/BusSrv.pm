package Siebel::Integration::Com::BusSrv 0.02;

use 5.006;
use Moose;
use namespace::autoclean;
use strict;
use warnings;
use Win32::OLE;
use Win32::OLE::Variant;

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
has _BS			=>(
					is => 'rw',
				);
				
has Name =>( 
					is => 'rw', 
					isa=>'Str', 
					required => 1,
				);
		
sub BUILD{
	my $self = shift;
	if($self->ConnectionType eq 'Thin'){
		$self->_BS($self->SApp->GetService($self->Name)); 																return undef if $self->_chkErr("Can't create BS");
	}else{
		$self->_ThickError(Variant(VT_I2|VT_BYREF, 0));
		$self->_BS($self->SApp->GetService($self->Name, $self->_ThickError)); 											return undef if $self->_chkErr("Can't create BS");
	}
}

sub InvokeMethod{
	my $self = shift;
	my $MethodName = shift;
	my $Inputs = shift;
	my $Outputs = shift;
	$self->Error('');
	
	#allow raw PS to be used.
	$Inputs = $Inputs->_PS if(ref $Inputs eq 'Siebel::Integration::Com::PropSet');
	$Outputs = $Outputs->_PS if(ref $Outputs eq 'Siebel::Integration::Com::PropSet');
	
	if($self->ConnectionType eq 'Thin'){
		$self->_BS->InvokeMethod($MethodName, $Inputs, $Outputs);														return undef if $self->_chkErr("Can't call $MethodName");
	}else{
		$self->_BS->InvokeMethod($MethodName, $Inputs, $Outputs, $self->_ThickError);									return undef if $self->_chkErr("Can't call $MethodName");
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

Siebel::Integration::Com::BusSrv - Abstraction of Siebel Business Service

=head1 SYNOPSIS

	use Siebel::Integration::Com;
	
	my $sa = Siebel::Integration::Com->new(
			ConnectionType=>'Thick', 
			UserName=>$inputs{user}, 
			PassWord=>$inputs{pass}, 
			CFG=>$inputs{cfg}, 
			DataSource=>$inputs{DataSource}
		);
																	
	my $BS = $SiebelApp->GetService('Workflow Utilities');
	
	my $PS = $SiebelApp->NewPropertySet();
	my $Outputs = $SiebelApp->NewPropertySet();

	$PS->SetProperty('Prop Par 1', 'Prop Par 1 Value');
	$BS->InvokeMethod('Echo', $PS, $Outputs);

=head1 DESCRIPTION

The Siebel::Integration::Com modules are designed to remove the different method calls and error checking between the COM Data Control and COM Data Server interfaces. 
Changing between the two interfaces only requires a change in the parameters to Siebel::Integration::Com->new() rather than a rewrite of all calls.
Beyond just replicating the base functions of the interfaces it is hoped that additional methods will be added to these modules to extend the functionality provided by the Siebel COM framework.

All methods that have been exposed keep the same names so there is no additional learning curve, you can program in Perl using the same method names as eScript

=head2 Base Methods

=over 8

=item BS->Error()

	Returns the error text for the last operation, returns '' if no error.

=item BS->InvokeMethod(MethodName, InputPS, OutputPS)

	This updates the OutputPS variable with the results of the business service call
	Returns 1 for success
	Returns undef for failure. A failure will set BS->Error

=item New(Name=>'BusSrvName', ConnectionType=>'Thin/Thick', SApp=>Siebel::Integration::Com)

	Only called internally from Siebel::Integration::Com->GetService()
	Returns a Siebel::Integration::Com::BusObj object
	Sets BS->Error if an error occurs

=back

=head1 REQUIREMENTS

See L<Siebel::Integration::Com>
	
=head1 TESTING

See L<Siebel::Integration::Com>

=head1 SEE ALSO

The documentation for L<Siebel::Integration::Com> contains additional information

=head1 AUTHOR

Kyle Mathers, C<< <kyle.perl at mathersit.com> >>

=head1 COPYRIGHT

The same as L<Siebel::Integration::Com>

=head1 VERSION

Version 0.02 March 2013

=cut


