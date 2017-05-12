package Net::LDAP::Makepath;

use warnings;
use strict;
use Net::LDAP::Entry;
use Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

our @ISA         = qw(Exporter);
our @EXPORT      = qw(LDAPmakepathSimple);
our @EXPORT_OK   = qw(LDAPmakepathSimple);
our %EXPORT_TAGS = (DEFAULT => [qw(LDAPmakepathSimple)]);


=head1 NAME

Net::LDAP::Makepath - Provides a methode for creating paths in LDAP simply.

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';


=head1 SYNOPSIS

    use Net::LDAP::Makepath;

	#Uses $ldap to create the new entries.
	#The objectClasses used are top and organizationalUnit.
	#The attribute used for the DNs is ou.
	#The path to be created is "some/path".
	#The base is "dc=foo,dc=bar".
	#
	#The resulting entries are...
	#dn: ou=some,dc=foo,dc=bar
	#objectClass: top
	#objectClass: orginationalUnit
	#ou: some
	#
	#dn: ou=path,ou=some,dc=foo,dc=ath
	#objectClass: top
	#objectClass: orginationalUnit
	#ou: path
	my $returned=LDAPmakepathSimple($ldap, ["top", "organizationalUnit"], "ou",
						"some,path", "dc=foo,dc=bar")
    if(!returned){
    	print "LDAPmakepathSimple failed.";
    };
    

=head1 EXPORT

LDAPmakepathSimple

=head1 FUNCTIONS

=head2 LDAPmakepathSimple

This creates a path from a comma seperated path.  Five arguements are required.

The first arguement is a Net::LDAP connection object.

The second arguement is a array of objectClasses.

The third the attribute to use for creating the DNs.

The fourth is the path to use. It is broken apart at each ,.

The firth is the base DN to use.

The returned object is a perl boolean value.

=cut

sub LDAPmakepathSimple {
	my $ldap=$_[0]; #this contains the LDAP connection
	my @objectClasses=$_[1]; #a array holding the attributes 
	my $attribute=$_[2]; # the attribute to use for each path part
	my $path=$_[3]; # a path using , as the delimiter
	my $start=$_[4]; # this is where it starts at
	
	#splits $path at each ,
	my @pathA=split(/,/, $path);
	
	my $pathAint=0;#used for intering through @pathA
	#sets the previous DN as it will be used in the construction in the loop
	my $previousDN=$start;
	#go through @pathA and add each one
	while(defined($pathA[$pathAint])){
		my $dn=$attribute."=".$pathA[$pathAint].",".$previousDN;
		$previousDN=$dn; #sets the previous DN for use on the next path

		#creates the new entry
		my $entry = Net::LDAP::Entry->new;
		
		#sets the DN
		$entry->dn($dn);
		
		#adds the attributes
		$entry->add(objectClass=>@objectClasses, $attribute=>$pathA[$pathAint]);
		
		#sets the change type on this entry to add as it is being added
		$entry->changetype("add");
		
		#update it and warn if it fails.
		my $mesg=$entry->update($ldap);
		if($mesg->is_error){
			if($pathAint == $#pathA){
				warn("Adding '".$dn."' failed. Path creation failed.");
				return undef;
			};
		};
		
		$pathAint++;
	};

	return 1;
}


=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ldap-makepath at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-Makepath>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::Makepath


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Makepath>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-Makepath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-Makepath>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-Makepath>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::LDAP::Makepath
