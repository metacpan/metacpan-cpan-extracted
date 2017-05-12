=head1 NAME

Telephone::Mnemonic::Phone - US Telephone Object

=cut
package Telephone::Mnemonic::US::Phone;
use strict;
use warnings;
use 5.010000;
#use MooseX::FollowPBP;
use Data::Dumper;
use Telephone::Mnemonic::US::Number qw/ well_formed_p to_tel_digits/;
use namespace::autoclean;

our $VERSION   = '0.07';

use Moose;
extends 'Telephone::Mnemonic::Phone';
with    'Telephone::Mnemonic::US::Roles::Words';

use Moose::Util::TypeConstraints;
subtype 'Tel_Number_US'
	=> as 'Str'
	=> where {
		well_formed_p($_);
};

coerce 'Tel_Number_US'
	=> from 'Str'
	=> via {
		#Telephone::Mnemonic::US::Number::to_tel_digits($_) ;
		to_tel_digits($_) ;
};
			

has '+num'      => (is =>'rw' , 
					isa=>'Tel_Number_US', 
					required=>1, 
					lazy=>0, 
					coerce=>1, 
);

around BUILDARGS => sub{
	my ($func, $self, @args) = @_ ;
	(1==@args and !ref $_)  ?  $self->$func(num=>@args) : $self->$func(@args);
};

sub BUILD {
	my $self=shift;
	my $num = $self->num or warn "num should have been defined";

	# mass initializationss
	my $fun = 'Telephone::Mnemonic::US::Number::';
    no strict 'refs';
	$self->$_( &{$fun.$_}($num)||'')  for qw/ without_area_code area_code 
                                              station_code house_code beautify/;
	#chek state -- most attrs have been directly set above
}



has [qw/ area_code station_code without_area_code house_code beautify/] =>(is=>'rw',isa=>'Str');

no Moose;
__PACKAGE__->meta->make_immutable;
1;
=pod

=head1 SYNOPSIS

 use Telephone::Mnemonic::US::Phone;
 
 $tel = new Telephone::Mnemonic::US::Phone num=>'703 111 2222';
 $tel1->area_code;          => '703'
 $tell->beautify;           => '(703) 111 2222'

=head1 DESCRIPTION

=head2  Implements a US telephone object


=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Tie::Dict>

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ioannis Tambouras E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
