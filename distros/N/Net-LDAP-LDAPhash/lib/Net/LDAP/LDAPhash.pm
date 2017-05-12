package Net::LDAP::LDAPhash;

use warnings;
use strict;
use Net::LDAP;
use Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

our @ISA         = qw(Exporter);
our @EXPORT      = qw(LDAPhash);
our @EXPORT_OK   = qw(LDAPhash);
our %EXPORT_TAGS = (DEFAULT => [qw(LDAPhash)]);

=head1 NAME

Net::LDAP::LDAPhash - Takes from a search and turns it into a hash.

=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

    	use Net::LDAP::LDAPhash;

	my $ldapconnection = Net::LDAP->new( "127.0.0.1" )

	my $bindMessage->bind( "cn=admin,dc=someBase", password=>"password", version=>3 );

	my $mesg = $ldapconnection->search(scope=>"sub","dc=someBase", filter=>"(objectClass=*)");

    	my %foo = LDAPhash($mesg);
    	...

=head1 EXPORT

LDAPhash

=head1 FUNCTIONS

=head2 LDAPhash ( mesg )

This takes from a search and turns it into a hash.

The returned has is in the following format.

	{DN}{ldap}{attribute}[array of values for this attribute]
	
The reason for the {ldap} is to allow for other values and the like to be tagged
onto a hash for a DN that are unrelated to LDAP.

This function does not make any attempt to check if the search succedded or not.

=cut

sub  LDAPhash {
	my $mesg = $_[0]; #the object returned from a LDAP search

	#used for holding the data, before returning it
	my %data;

	#builds it
	my $entryinter=0;
	my $max = $mesg->count;
	for ( $entryinter = 0 ; $entryinter < $max ; $entryinter++ ){
		my $entry = $mesg->entry ( $entryinter );
		$data{$entry->dn}={ldap=>{dn=>$entry->dn},internal=>{changed=>0}};
		#builds a hash of attributes
		foreach my $attr ( $entry->attributes ) {
			$data{$entry->dn}{ldap}{$attr}=[];

			#builds the array of values for the attribute
			my $valueinter=0;
			my @attributes=$entry->get_value($attr);
			while (defined($attributes[$valueinter])){
				$data{$entry->dn}{ldap}{$attr}[$valueinter]=$attributes[$valueinter];
				$valueinter++;
			};
        };
	};

	return %data;
};



=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or the like to vvelox@vvelox.net.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::LDAPhash


=head1 COPYRIGHT & LICENSE

Copyright 2011 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

WIML, #43892, pointed out out that 't/pod-coverage.t' does not exist, but does in the MANIFEST

=cut

1; # End of Net::LDAP::LDAPhash
