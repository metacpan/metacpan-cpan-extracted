package SagePay::XORForm;

use strict;
use warnings;

use Carp;
use MIME::Base64;

use vars qw($VERSION);

our $VERSION = '0.05';


## * Constructor and methods....

sub new {
	my $class 	= shift;
	my $self 	= {};	
	bless $self, $class;
	$self->_init(@_);      										
    return $self;  
}

sub _init {
	my $self   = shift;
	my (%part) = @_;
	
	croak "Must have load the query string to encrypt"
		unless defined $part{'query_string'};
		
	croak "Must have load the key with which to encrypt message"
		unless defined $part{'key'};
	
	$self->{'query_string'} = $part{'query_string'};
	$self->{'key'} 			= $part{'key'};
}


sub sage_xor_string {
	my $self = shift;
	my ($options) = @_;
	
	my $ret = encode_base64($self->_simpleXor);
	$ret =~ s/(\r|\n)//g if $options->{'strip_newlines'}; 
	return $ret;
	
}


  
## * ------------------------------------------------- 
## * do the simple method to return an xor'd str 
##  
sub _simpleXor {  
	my $self = shift;
	
	my $InString = $self->{'query_string'};
	my $Key		 = $self->{'key'};
	
	my @KeyList = ();
	#Initialise out variable
	my $output = "";
	
	#Convert $Key into array of ASCII values
	for(my $i = 0; $i < length($Key); $i++){
		$KeyList[$i] = ord(substr($Key, $i, 1));
	}	
	
	# Step through string a character at a time
	for(my $i = 0; $i < length($InString); $i++) {
		# Get ASCII code from string, get ASCII code from key (loop through with MOD), XOR the two, get the character from the result
		#% is MOD (modulus), ^ is XOR
		$output.= chr(ord(substr($InString, $i, 1)) ^ ($KeyList[$i % length($Key)]));		
	}

	return $output;  
} 



1;
__END__

# Docs

=head1 NAME

SagePay::XORForm - Perl extension for SagePay XOR form encryption

=head1 SYNOPSIS

  use SagePay::XORForm;
  
  my $obj = SagePay::XORForm->new( query_string => 'my form details string', 
				   key => 'my password string to encrypt with');

  my $encrypted_str = $obj->sage_xor_string(\%options);  

=head1 DESCRIPTION

Documentation for SagePay::XORForm. This module has been created to help ease the pain in creating a Perl side solution
with the SagePay Form integration where an XOR encryption type format is required when posting data 


=head2 new()

Class constructor, simply pass in the query string and password key strings, the module will croak without these values included. NB you must know what 
your account password is as this will serve as the key

=head2 sage_xor_string(\%options)

Call this method and the encrypted XOR string will be returned 

=head3 \%options

=head4 strip_newlines

By default it's disabled but if you'd like new lines to be stripped set to 1 to enable e.g. 

my $enc_string = $obj->sage_xor_string({'strip_newlines' => 1});

=head1 DEPENDENCIES

MIME::Base64

=head1 SEE ALSO

SagePay documentation - http://www.sagepay.com/sites/default/files/pdf/user_guides/sagepayformprotocolandintegrationguidelines.pdf


=head1 AUTHOR

Cris Pini, E<lt>cris@perlconsulting.co.uk<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Cris Pini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
