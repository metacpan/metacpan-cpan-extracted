package String::Validator::Email;

use 5.006;
use strict;
use warnings;
use String::Validator::Common ;
use Regexp::Common qw /net/;
use Net::DNS;
use Email::Valid;
use Email::Address;

our $VERSION = '0.98';

=head1 VERSION

Version 0.98

=cut

sub new {
    my $class = shift ;
    my $self = { @_ } ;
    use base ( 'String::Validator::Common' ) ;
    unless ( defined $self->{ min_len } )
                { $self->{ min_len } = 6 ; }
    unless ( defined $self->{ max_len } )
                { $self->{ max_len } = 64 ; }
	# allow_ip wont work with fqdn or tldcheck
	if ( $self->{ allow_ip } ) {
	    $self->{ mxcheck } = 0 ; 
		$self->{ fqdn } = 0 ;
		$self->{ tldcheck } = 0 ;
		}
    # Converts String::Validator Switches to Email::Valid Switches.
	my %switchhash = () ;
    for  ( qw / tldcheck fqdn allow_ip /) {
		my $dashstr = '-' . $_ ;
        if ( defined $self->{ $_ } )
             { $switchhash{ $dashstr } = $self->{ $_ } }
        }
	unless( defined $self->{ tldcheck } ) {
        $switchhash{ '-tldcheck' } = 1 }
    $self->{ switchhash } = \%switchhash ;
    if( $self->{ mxcheck } ) {
        $self->{ fqdn } = 1 ; #before mx, must pass fqdn.
        $self->{ NetDNS } = Net::DNS::Resolver->new;
        }
        
    bless $self, $class ;
    return $self ;
}

# Email::Valid has very terse error codes.
# Not an OO method must use &
sub _expound {
    my $errors = shift || '';
    my $string = shift ;
    my $expounded = '' ;
    if ( $errors =~ m/fqdn/ ) {
        $expounded .= 'Does not appear to contain a Fully Qualified Domain Name.' }
    if ( $errors =~ m/rfc822/ ) {
        unless ( $string =~ /\@/ ) { $expounded .= 'Missing @ symbol' }
        else {
        $expounded .= 'Does not look like an email address.' }
        }
    if ( $errors =~ m/tld/ ) {
        $expounded .=
        'The TLD (Top Level Domain) is not recognized.' ;
        }
    if ( $errors =~ m/mx/ ) {
    	$expounded .= "Mail Exchanger for $string " .
            "is missing from Public DNS. Mail cannot be delivered." ;
    	}
    return $expounded ;
}

sub _rejectip {
	my $self = shift ;
	if  ( $self->{ string } =~ /$RE{net}{IPv4}/ ) {
		$self->IncreaseErr(
			"$self->{ string } Looks like it contains an IP Address." ) }
}

sub Check{
    my ( $self, $string1, $string2 ) = @_ ;
    #not standard hashvar so not inited by inherited method in CheckCommon.
    $self->{ expounded } = '' ;
    if ( $self->CheckCommon( $string1, $string2 ) ) {
        return $self->{ error } }
    my %switchhash = %{ $self->{switchhash} } ;
    $switchhash{ -address  } = $self->{ string } ;
    my $addr = Email::Valid->address( %switchhash );
    unless ( $addr ) {
        $self->IncreaseErr( $Email::Valid::Details ) ;
        $self->{ expounded } = &_expound(
            $Email::Valid::Details, $self->{ string } ) ;
        }
	else {
		unless ( $self->{ allow_ip } ) {
			$self->_rejectip() }
		}
	# Need maildomain for mxcheck.
	( my $discard, $self->{maildomain} ) = split( /\@/, $self->{ string } );
    $self->{maildomain} =~ tr/\>//d ; #clean out unwanted chars.
    if ( $self->{ mxcheck } ) {
		if ( $self->{ error } == 0 ) {
		    my $res = $self->{ NetDNS };
		    unless ( mx( $res, $self->{ maildomain } ) ) {
                $self->IncreaseErr( "MX" ) ;
                $self->{ expounded } = 
                    &_expound( 'mx', $self->{ maildomain} ) ;
		    }    
		}
    }
return $self->{ error } ;
}

sub Expound {
    my $self = shift ;
    return $self->{ expounded } ;
    }

=pod

=head1 NAME

String::Validator::Email - Check if a string is an email address.

=head1 SYNOPSIS

String::Validator::Email is part of the String Validator Collection. It will
check a string against any number of email validation rules, and optionally
against a second string (as in a confirmation box on a webform).

=head1 String::Validator Methods and Usage

Provides and conforms to all of the standard String::Validator methods,
please see String::Validator for general documentation, and
String::Validator::Common for information on the base String::Validator Class.

=head1 Methods Specific to String::Validator::Email

=head2 Parameters to New with (default) behaviour.

 mxcheck     (OFF) : Perform MX Lookup for Domain Given.
 tldcheck    (ON ) : Validate TLD against a List.
 fqdn        (ON ) : Require a Fully Qualified Domain Name.
 allow_ip    (OFF) : Allow @[ip] (forces tld & fqdn off.)
 min_len     (OFF)
 max_len     (OFF)

Important notes -- SVE uses Email::Valid, however, tldcheck is defaulted to on.
The choice to turn tldcheck should be obvious. The fudge and local_rules
options are specific to aol and compuserve, and are not supported.
Finally mxcheck is not tried if there is already an error, since Email::Valid's 
DNS check does not work, that is performed directly through Net::DNS.

=head2 Expound

Email::Valid provides very terse errors, Expound provides errors more appropriate
for returning to an end user.

=head1 Example

 use String::Validator::Email ;
 my $Validator = String::Validator::Email->new() ;
 if ( $Validator->Is_Valid( 'real@address.com' ) { say "good" }
 if ( $Validator->IsNot_Valid( 'bad@address=com') { say $Validator->Errstr() }

=head1 ToDo

The major TO DO items are to replace Email::Valid methods, return an Email::Address object and to use it to create methods for returning information
from an extended mail string like: Jane Brown <jane.brown@domain.com>.

=head1 AUTHOR

John Karr, C<< <brainbuz at brainbuz.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-validator-email at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Validator-Email>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Validator::Email


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Validator-Email>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Validator-Email>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Validator-Email>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Validator-Email/>

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

1; # End of String::Validator::Email
