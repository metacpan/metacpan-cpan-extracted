#request object
package PSGI::Hector::Request;

=pod

=head1 NAME

PSGI::Hector::Request - Form request class

=head1 SYNOPSIS

	my $r = $hector->getRequest();
	my $params = $r->getParameters();

=head1 DESCRIPTION

Class to deal with the current page request

=head1 METHODS

=cut

use strict;
use warnings;
use Data::Dumper;
use parent qw(Plack::Request);
#########################################################

=pod

=head2 getParameters()

	my $params = $r->getParameters();

Returns a hash reference of all the GET/POST values from the current request.

Parameters that have multiple values will be returned as an array reference.

=cut

##########################################
sub getParameters{	#get POST or GET data
	my $self = shift;
	return $self->parameters->mixed;
}
#########################################################

=pod

=head2 validate()

	my $rules = {
		'age' => {
			'rule' => '^\d+$',
			'friendly' => 'Your Age'
		}
	};	#the form validation rules
	my($result, $errors) = $r->validate($rules);

Validates all the current form fields against the provided hash reference.

The hash reference contains akey for every field you are concerned about,
which is a reference to another hash containing two elements. The first is the 
actaul matching rule. The second is the friendly name for the field used
in the error message, if a problem with the field is found.

The method returns two values, first being a 0 or a 1 indicating the success of the form.
The second is a reference to a list of errors if any.

=cut

##########################################
sub validate{	#checks %form againist the hash rules
	my($self, $rules) = @_;
	my %params = %{$self->getParameters()};
	my @errors;	#fields that have a problem
	my $result = 0;
	if($rules){
		foreach my $key (keys %{$rules}){	#check each field
			if(!$params{$key} || $params{$key} !~ m/$rules->{$key}->{'rule'}/){	#found an error
				push(@errors, $rules->{$key}->{'friendly'});
			}
		}
		if($#errors == -1){	#no errors
			$result = 1;
		}
	}
	else{
		die("No rules to validate form");
	}
	return($result, \@errors);
}
#########################################

=pod

=head2 getHeader($header)

	$request->getHeader($name)

Returns the value of the specified request header.

=cut

#########################################
sub getHeader{
	my($self, $name) = @_;
	my $value = undef;
	$name = uc($name);
	$name =~ s/\-/_/g;
	if(defined($ENV{"HTTP_" . $name})){
		$value = $ENV{'HTTP_' . $name};
	}
	return $value;
}
############################################################################################################
sub getCookie{	#returns the value of a cookie
	my($self, $name) = @_;
	my $cookies = $self->cookies();
	$cookies->{$name} || undef;
}
####################################################
sub __stringfy{
	my($self, $item) = @_;
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 0;
	return Dumper($item);
}
###########################################################

=pod

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 See Also

=head1 Copyright

Copyright (c) 2017 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

##########################################
return 1;