package Siebel::Integration::Com::BusObj 0.02;

use 5.006;
use Moose;
use namespace::autoclean;
use strict;
use warnings;
use Win32::OLE;
use Win32::OLE::Variant;
use Siebel::Integration::Com::BusComp;

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
				);
				
has Name =>( 
					is => 'rw', 
					isa=>'Str', 
					required => 1,
				);
		
sub BUILD{
	my $self = shift;
	if($self->ConnectionType eq 'Thin'){
		$self->_BO($self->SApp->GetBusObject($self->Name)); 																return undef if $self->_chkErr("Can't create BO");
	}else{
		$self->_ThickError(Variant(VT_I2|VT_BYREF, 0));
		$self->_BO($self->SApp->GetBusObject($self->Name, $self->_ThickError)); 											return undef if $self->_chkErr("Can't create BO");
	}
}

sub GetBusComp{
	my $self = shift;
	my $BCName = shift;
	return Siebel::Integration::Com::BusComp->new(BCName => $BCName, _BO => $self->_BO, ConnectionType => $self->ConnectionType, SApp => $self->SApp);
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

Siebel::Integration::Com::BusObj - Abstraction of Siebel Business Object

=head1 SYNOPSIS

	use Siebel::Integration::Com;
	
	my $SiebelApp = Siebel::Integration::Com->new(
			ConnectionType=>'Thick', 
			UserName=>$inputs{user}, 
			PassWord=>$inputs{pass}, 
			CFG=>$inputs{cfg}, 
			DataSource=>$inputs{DataSource}
		);
																	
	my $BO = $SiebelApp->GetBusObject('Employee');
	if($BO->Error eq ''){
		print "I got some BO\n";
	}else{
		die print 'Failed to get BO!';
	}

	#See Siebel::Integration::Com::BusComp for BC details
	my $BC = $BO->GetBusComp('Employee');
	if($BC->Error eq ''){
		print "I have the Employee BC\n";
	}else{
		die print 'Failed to get Employee BC!';
	}

=head1 DESCRIPTION

The Siebel::Integration::Com modules are designed to remove the different method calls and error checking between the COM Data Control and COM Data Server interfaces. 
Changing between the two interfaces only requires a change in the parameters to Siebel::Integration::Com->new() rather than a rewrite of all calls.
Beyond just replicating the base functions of the interfaces it is hoped that additional methods will be added to these modules to extend the functionality provided by the Siebel COM framework.

All methods that have been exposed keep the same names so there is no additional learning curve, you can program in Perl using the same method names as eScript

=head2 Base Methods

=over 8

=item BO->GetBusComp(BusCompName)

	Returns a Siebel::Integration::Com::BusComp object
	Sets BusComp->Error if an error occurs

=item BO->Error()

	Returns the error text for the last operation, returns '' if no error.

=item New(Name=>'BusObjName', ConnectionType=>'Thin/Thick', SApp=>Siebel::Integration::Com)

	Only called internally from Siebel::Integration::Com->GetBusObject()
	Returns a Siebel::Integration::Com::BusObj object
	Sets BO->Error if an error occurs

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


