package String::Validator::Phone::NANP;

use 5.006;
use strict;
use warnings;
use String::Validator::Common ;
use Number::Phone ;

=head1 NAME

String::Validator::Phone::NANP - Check a Phone Number (North American Numbering Plan)!

=head1 VERSION

Version 0.96

=cut

our $VERSION = '0.96';

sub new {
    my $class = shift ;
    my $self = { @_ } ;
    use base ( 'String::Validator::Common' ) ;
    unless ( defined $self->{ alphanum } ) { $self->{ alphanum } = 0 } ;
    # disable length checking.
    $self->{ min_len } = 0 ; $self->{ max_len } = 0 ;    
    bless $self, $class ;
    return $self ;
}

# Private method to change to area-exchange-num format.

sub _clean {
    my $num = uc( shift @_ ) ;
    my $alphanum = shift @_ ;
    if ( $alphanum ) {
        $num =~ s/\W//g ;
        $num =~ tr/ABCDEFGHIJKLMNOPQRSTUVWXYZ/22233344455566677778889999/ ;
        }
    else { $num =~ s/\D//g ; }
    $num =~ s/^1// ;
    my $area = substr( $num, 0, 3, '' ) ;
    my $exch = substr( $num, 0, 3, '' ) ;
    return qq /$area-$exch-$num/ ;
}

# North American Numbers have a length of 10.
# Returns 1 if this is true 0 and increases err if not.
sub _must_be10 {
    my $self = shift ;
    my $num = shift ;
    my $num2 = $num ;
    $num2 =~ s/\W//g ;
    my $l = length $num2 ;
    if ( 10 == $l ) { return 1 }
    else { $self->IncreaseErr(
        "Not a 10 digit Area-Number $num .. $num2 = $l." ) }
    return 0 ;
}

sub _Init  {
    my $self = shift ;
	$self->{ error } = 0 ;
	for ( qw / string original international errstring areacode exchange local /) {
		$self->{ $_ } = '' ; }
    } ;

sub Check {
    my ( $self, $string1, $string2 ) = @_ ;
    if ( $self->Start( $string1, $string2 ) ) {
        return $self->{ error } }
    $self->{ string } = &_clean( $string1, $self->{alphanum} ) ;
    unless( $self->_must_be10( $self->{ string } ) ) {
        $self->{ string } = '' ; return $self->{ error } }
    $self->{ original } = $string1 ;
    #Number::Phone requires a leading 1.;
    ( $self->{ areacode }, $self->{ exchange }, $self->{ local } ) =
            split /\-/, $self->{ string };
    $self->{ international } = '1-' . $self->{ string } ;
    my $Phone = Number::Phone->new( $self->{ international } ) ;
    unless ( $Phone ) {
        $self->IncreaseErr( 'Invalid Number, perhaps non-existent Area Code' ) }
	else {
		unless ( $Phone->is_valid ) {
			$self->IncreaseErr( 'Invalid Number, perhaps non-existent Area Code' ) }
		}
return $self->{ error } ;
}

# sub String # is inherited from String::Validator::Common.

sub Original { my $self = shift ; return $self->{ original } ; } ;

sub Areacode {
	my $self = shift ;
	return ( $self->{ areacode } ) ;
	}
	
sub Exchange {
	my $self = shift ;
	return ( $self->{ exchange } ) ;
	}	

sub Local {
	my $self = shift ;
	return ( $self->{ local } ) ;
	}

sub International { my $self = shift ; return $self->{ international } }

sub Parens {
	my $self = shift ;
	my $area = $self->Areacode() ;
	my $exchange = $self->Exchange() ;
	my $local = $self->Local() ;
	return "($area) $exchange-$local" ;
	}

sub Number_Phone {
	my $self = shift ;
	unless( $self->{ international } ) { return 0 } ;
	return Number::Phone->new( $self->{ international } ) ;
	}

=head1 SYNOPSIS

String::Validator::Phone::NANP is part of the String Validator Collection. It checks a string
against validation rules for phone numbers from countries participating in the North American
Numbering Plan, which includes the United States and Canada.

=head1 String::Validator Methods and Usage

Provides and conforms to the standard String::Validator methods,
please see String::Validator for general documentation, and
String::Validator::Common for information on the base String::Validator Class.

=head1 Methods Specific to String::Validator::Phone::NANP

=head2 Parameters to New with (default) behaviour.

 alphanum    (OFF) : Allow Alphanumeric formats. 

=head2 Original, String, International, Areacode, Parens, Local

Returns:

Original: the Orignial string provided, 

String: the internal representations of the phone number, which
is in the format of AREA-EXCHANGE-NUMBER, (the most commonly used representation in the United 
States).

International: Prepends 1- in front of the string.

Areacode, Exchange, Local: Returns each of the 3 components of a number

Parens: Formats the number (AREA) EXCHANGE-LOCAL.

=head2 Number_Phone

Returns a Number::Phone::NANP object based on the current phone number, if the last
number evaluated was not valid it returns 0.

=head1 Example

 use String::Validator::Phone::NANP ;
 my $Validator = String::Validator::Phone::NANP->new( alphanum => 1 ) ;
 
 if ( $Validator->IsNot_Valid( '6464') { say $Validator->Errstr() }
 # IsNot_Valid returns Errstr on failure. 
 # So the preceding and following are the same.
 my $badone = $Validator->IsNot_Valid( '999') ;
 if ( $badone ) { say "$badone' } ; 
 
 if ( $Validator->Is_Valid( '646-SG7-6464' ) { say "good" }
 say $Validator->Areacode ; # print the Areacode.
 my $PhoneNum = $Validator->Number_Phone ; # Get a Number Phone object.
 say $PhoneNum->country; # Prints the two letter country code of the number.

=head1 ToDo

The major TO DO items are to provide String::Validator::Phone modules for other numbering 
schemes and to fully encapsulate Number::Phone.

=head1 AUTHOR

John Karr, C<< <brainbuz at brainbuz.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-validator-phone at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Validator-Phone>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Validator::Phone


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Validator-Phone>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Validator-Phone>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Validator-Phone>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Validator-Phone/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Karr.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1; # End of String::Validator::Phone::NANP
