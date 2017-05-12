package String::Validator::Password;

use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized) ;
use String::Validator::Common ;

our $VERSION = '0.94';

=pod

=head1 NAME

String::Validator::Password - Check a string against a number of common password rules.

=head1 VERSION

Version 0.94

=head1 SYNOPSIS

String::Validator::Password is part of the String Validator Collection. It will
check a string against any number of password validation rules, and optionally
against a second string (as in password confirmation box on a webform). The
primary Negative method returns 0 if the password passes all tests, or a string
describing the errors if it fails. The Positive Method returns 1 if the string
passes and 0 if it fails. The ErrString method returns the errors from the last
string processed.

=head1 String::Validator Methods and Usage

Provides and conforms to all of the standard String::Validator methods, please see
String::Validator for general documentation.

=head1 Methods Specific to String::Validator::Password

=head2 Parameters to New

=head3 Require or Deny Classes of Character

SVP knows about four classes of character -- B<uc> (Upper Case), B<lc> (Lower Case),
B<num> (Digits), and B<punct> (Everything Else). Types can be required or denied.
Thus these 8 arguments
B<require_lc>, B<require_uc>, B<require_nums>, B<require_punct>, B<deny_punct>,
B<deny_lc>, B<deny_uc>, B<deny_nums>, all of which take a numeric argument, and all of
which default to 0 if omitted.

When requiring and denying classes of characters the values of 0 and 1 work as expected,
where 0 means not to check this condition at all and 1 means to accept or reject based on
the presence of just 1 instance of the type. However, when used to set an amount, require
is interpreted as require at least X of this type, while deny is deny if X or more
are encountered. require_lc => 2 will result in a string with 2 or more lowercase characters
passing the test. deny_lc => 2 will result in a string with 2 lowercase characters being
rejected, but would pass a string with 1 lowercase character.

=head3 Minimum number of Classes of Character

B<min_types> is used to specify the number of different character types required,
default is 2.

=head3 Minimum and Maximum Length

B<min_len> and B<max_len> determine the respective minimum and maximum length
password to accept. Defaults are 6 and 64.

=head1 Examples

To create a new instance, with all of the default values:

 my $Validator = String::Validator::Password->new() ;

Specify all of the default values:

 my $Validator = String::Validator::Password->new(
	require_lc => 0,
	require_uc => 0,
	require_punct => 0,
	require_num => 0,
	deny_lc => 0,
	deny_uc => 0,
	deny_punct => 0,
	deny_num => 0,
	min_types => 2,
	min_len => 6,
	max_len => 64,
	) ;
 ) ;

Normally you would only specify values that were not the default.

 my $Validator = String::Validator::Password->new(
	require_lc => 2,
	require_uc => 2,
	min_types => 3,
	min_len => 8,
	max_len => 18,
	) ;

Then to check a password you might write something like this:

 if( $Validator->IsNot_Valid( $password1, $passwordconfirm ) ) {
  die $Validator->errstr() ; }

=cut

sub new {
    my $class = shift ;
    my $self = { @_ } ;
    use base ( 'String::Validator::Common' ) ;
    unless ( defined $self->{ require_lc } )     { $self->{ require_lc } = 0 };
    unless ( defined $self->{ require_uc } )     { $self->{ require_uc } = 0 };
    unless ( defined $self->{ require_nums } )   { $self->{ require_nums } = 0 };
    unless ( defined $self->{ require_punct } )  { $self->{ require_punct } = 0 };
    unless ( defined $self->{ deny_punct } ) 	 { $self->{ deny_punct } = 0 };
    unless ( defined $self->{ deny_lc } )        { $self->{ deny_lc } = 0 };
    unless ( defined $self->{ deny_uc } )        { $self->{ deny_uc } = 0 };
    unless ( defined $self->{ deny_nums } )      { $self->{ deny_nums } = 0 };
    unless ( defined $self->{ min_types } )	 	 { $self->{ min_types } = 2 };
    unless ( defined $self->{ min_len } )        { $self->{ min_len } = 6 };
    unless ( defined $self->{ max_len } )        { $self->{ max_len } = 64 };
# Not implemented right now.
#    unless ( defined $self->{ dictionary } )     { $self->{ dictionary } = [ 'default' ] }
#    unless ( defined $self->{ custom_allow } )   { $self->{ custom_allow } = 0 }
#    unless ( defined $self->{ custom_deny } )    { $self->{ custom_deny } = 0 }
    $self->{ string } = '' ;
    $self->{ error } = 0 ;
    $self->{errstring} = '' ;
    bless $self, $class ;
    return $self ;
}

# Does all the checks and returns the
# number of errors found. Used by the
# Is/IsNot_Valid. May be invoked directly.
sub Check{
    my ( $self, $string1, $string2 ) = @_ ;
    if ( $self->CheckCommon( $string1, $string2 ) == 99 ) {
        return $self->{ error } }
# The match operator cannot be directly used to count matches.
# substitution does count replacements, and by removing all other
# other character classes what is left over is "punct".
	$string2 = $string1 ; # make sure string is in string2.
    $self->{num_lc} = $string2 =~ s/[a-z]//g || 0;
    $self->{num_uc} = $string2 =~ s/[A-Z]//g || 0 ;
    $self->{num_num} = $string2 =~ s/\d//g || 0;
    $self->{num_punct} = length $string2; #What is left is punct.
	$self->{ types_found } = 0;
    for ( qw / num_lc num_uc num_num num_punct / ) {
        if ( $self->{ $_ } ) { $self->{ types_found }++ }  }
    if ( $self->{types_found} < $self->{ min_types } ) {
	$self->IncreaseErr(
	    "$self->{types_found} types were found, $self->{min_types} required.") ; }
    foreach my $type ( qw /lc num uc punct/ ) {
		my $required = 'require_' . $type ;
		my $denied = 'deny_' . $type ;
		my $num = 'num_' . $type ;
		unless ( $self->{ $required } <= $self->{ $num } ) {
			$self->IncreaseErr(
			"At least $self->{ $required } of $type is required.") }
# If denied is 0, all strings are >= 0 not just those where
# type is present. So don't check if denied is false (0).
		if ( $self->{ $denied } == 1 ) {
			if ( $self->{ $num } )
				{ $self->IncreaseErr( "$type is prohibited.") } }
		elsif ( $self->{ $denied } > 1 ) {
			if ( $self->{ $denied } <= $self->{ $num } ) {
				$self->IncreaseErr( "$type is limited to fewer than " . $self->{ $denied } )
			}	}
	} #foreach ( lc num uc punct ).

#     if ( length($string1) < $self->{min_len} ) {
# 		$self->IncreaseErr( "Password Length of " . length( $string1 ) .
# 		" Does not meet requirement: Min Length " . $self->{min_len} . "." ) ;
# 		}
# 	if ( length($string1) > $self->{max_len} ) {
# 		$self->IncreaseErr( "Password Length of " . length( $string1 ) .
# 		" Does not meet requirement: Max Length " . $self->{max_len} . "." ) ;
# 		}
return $self->{ error } ;
}

=head1 TO DO

Provide support for custom regexes, custom allow/deny lists, and checking against weak
password dictionaries.

=head1 AUTHOR

John Karr, C<< <brainbuz at brainbuz.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-validator-password at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Validator-Password>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Validator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Validator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Validator>

=item * Search CPAN

L<http://search.cpan.org/dist/Validator/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Karr.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1; # End of Validator
