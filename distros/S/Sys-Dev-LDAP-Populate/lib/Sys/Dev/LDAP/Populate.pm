package Sys::Dev::LDAP::Populate;

use warnings;
use strict;
use Net::LDAP::AutoDNs;
use Net::LDAP::AutoServer;

=head1 NAME

Sys::Dev::LDAP::Populate - Populates various parts of /dev/ldap.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';


=head1 SYNOPSIS

    use Sys::Dev::LDAP::Populate;

    my $foo = Sys::Dev::LDAP::Populate->new();

    $foo->populate

    if($foo->{error}){
        print "Error!";
    }

For this Net::LDAP::AutoDNs and Net::LDAP::AutoServers is used, with
their methods set to the defaults, minus 'devldap'.

=head1 METHODS

=head2 new

Initiates the object.

    my $foo=Sys::Dev::LDAP::Populate->new;

=cut

sub new{
	my $self={
			  error=>undef,
			  errorString=>'',
			  module=>'Sys-Dev-LDAP-Populate',
			  };
	bless $self;

	return $self;
}

=head2 populate

This populates the entries under "/dev/ldap".

    $foo->populate;
    if($foo->{error}){
        print "Error!";
    }

=cut

sub populate{
	my $self=$_[0];
	my $method='populate';

	$self->errorblank;

	#makes sure that the ldap device exists
	if (! -e "/dev/ldap/server") {
			$self->{error}=1;
			$self->{errorString}='"/dev/ldap/server" does not exist';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return undef;
	}

	#creates the new AutoDNs object
	my $AutoDNs=Net::LDAP::AutoDNs->new({methods=>"env,hostname"});
	my $AutoServers=Net::LDAP::AutoServer->new({methods=>'hostname,dns,env'});
	
	#holds the file handle
	my $fh;

	#writes out the user base
	if (open($fh , '>', '/dev/ldap/userBase')) {
		if (defined($AutoDNs->{users})) {
			print $fh $AutoDNs->{users};
		}else {
			print $fh '';
		}
		
		close $fh;
	}

	#writes out the group scope
	if (open($fh , '>', '/dev/ldap/userScope')) {
		if (defined($AutoDNs->{usersScope})) {
			print $fh $AutoDNs->{usersScope};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the user base
	if (open($fh , '>', '/dev/ldap/groupBase')) {
		if (defined($AutoDNs->{groups})) {
			print $fh $AutoDNs->{groups};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the group scope
	if (open($fh , '>', '/dev/ldap/groupScope')) {
		if (defined($AutoDNs->{groupsScope})) {
			print $fh $AutoDNs->{groupsScope};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the home
	if (open($fh , '>', '/dev/ldap/homeBase')) {
		if (defined($AutoDNs->{home})) {
			print $fh $AutoDNs->{home};
		}else {
			print $fh '';
		}

		print $fh $AutoDNs->{home};
		close $fh;
	}

	#writes out the base
	if (open($fh , '>', '/dev/ldap/base')) {
		if (defined($AutoDNs->{base})) {
			print $fh $AutoDNs->{base};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the server
	if (open($fh , '>', '/dev/ldap/server')) {
		if (defined($AutoServers->{server})) {
			print $fh $AutoServers->{server};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the port
	if (open($fh , '>', '/dev/ldap/port')) {
		if (defined($AutoServers->{port})) {
			print $fh $AutoServers->{port};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the startTLS
	if (open($fh , '>', '/dev/ldap/startTLS')) {
		if (defined($AutoServers->{startTLS})) {
			print $fh $AutoServers->{startTLS};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the CAfile
	if (open($fh , '>', '/dev/ldap/CAfile')) {
		if (defined($AutoServers->{CAfile})) {
			print $fh $AutoServers->{CAfile};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the CApath
	if (open($fh , '>', '/dev/ldap/CApath')) {
		if (defined($AutoServers->{CApath})) {
			print $fh $AutoServers->{CApath};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the checkCRL
	if (open($fh , '>', '/dev/ldap/checkCRL')) {
		if (defined($AutoServers->{checkCRL})) {
			print $fh $AutoServers->{checkCRL};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the clientCert
	if (open($fh , '>', '/dev/ldap/clientCert')) {
		if (defined($AutoServers->{clientCert})) {
			print $fh $AutoServers->{clientCert};
		}else {
			print $fh '';
		}

		close $fh;
	}

	#writes out the clientKey
	if (open($fh , '>', '/dev/ldap/clientKey')) {
		if (defined($AutoServers->{clientKey})) {
			print $fh $AutoServers->{clientKey};
		}else {
			print $fh '';
		}

		close $fh;
	}

	return 1;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

        $zconf->{error}=undef;
        $zconf->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
};


=head1 ERROR CODES

This may be tested via checking if "$foo->{error}" is true. If it is
true, then a description can be found via checking "$foo->{errorString}".

=head2 1

LDAP kmod does not appear to be present.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sys-dev-ldap-populate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-Dev-LDAP-Populate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::Dev::LDAP::Populate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-Dev-LDAP-Populate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sys-Dev-LDAP-Populate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sys-Dev-LDAP-Populate>

=item * Search CPAN

L<http://search.cpan.org/dist/Sys-Dev-LDAP-Populate/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Sys::Dev::LDAP::Populate
