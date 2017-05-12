package Plugtools::Plugins::HomeOUremove;

use warnings;
use strict;

=head1 NAME

Plugtools::Plugins::HomeOUremove - Remove the home OU for a user.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

This creates the home OU a user has access to.

=cut

=head1 Functions

=head2 plugin

The function that will be called by Plugtools.

    use Plugtools::Plugins::HomeOUremove;
    %returned=Plugtools::Plugins::HomeOUremove->plugin(\%opts, \%args);
    
    if($returned{error}){
        print "Error!\n";
    }

=cut

sub plugin{
	my %opts;
	if(defined($_[1])){
		%opts= %{$_[1]};
	};
	my %args;
	if(defined($_[2])){
		%args= %{$_[2]};
	};

	my %returned;
	$returned{error}=undef;

	if (!defined( $opts{self}->{ini}->{HomeOU}->{homebase} )) {
		$returned{error}=1;
		$returned{errorString}='The variable "homebase" in the section "HomeOU" is undefined';
		warn('Plugtools-Plugins-HomeOUremove plugin:1: '.$returned{errorString}{errorString});
		return %returned;
	}

	if (!defined( $args{user} )) {
		$returned{error}=2;
		$returned{errorString}='$args{user} is noet defined';
		warn('Plugtools-Plugins-HomeOUremove plugin:2: '.$returned{errorString}{errorString});
		return %returned;
	}

	my $dn='ou='.$args{user}.','.$opts{self}->{ini}->{HomeOU}->{homebase};

	my $mesg=$opts{ldap}->search(
								 base=>$dn,
								 filter=>'(objectClass=*)',
								 scope=>'sub',
								 );
	if (!$mesg->{errorMessage} eq '') {
		$returned{error}=4;
		$returned{errorString}='$entry->update($ldap) failed. $mesg->{errorMessage}="'.
		                        $mesg->{errorMessage}.'"';
		warn('Plugtools-Plugins-HomeOUremove plugin:4: '.$returned{errorString});
		return %returned;
	}

	my $entry=$mesg->pop_entry;
	my %entries;
	while (defined($entry)) {
		my $dn2=$entry->dn;

		$entries{$dn}=$entry;

		$entry=$mesg->pop_entry;
	}

	my @DNs=keys(%entries);

	my @sortedDNs=sort(@DNs);

	my $int=$#sortedDNs;

	while (defined($sortedDNs[$int])) {
		my $dn3=$sortedDNs[$int];

		$entry=$entries{$dn};
		$entry->delete;

		my $mesg2=$entry->update($opts{ldap});
		if (!$mesg2->{errorMessage} eq '') {
			$returned{error}=3;
			$returned{errorString}='$entry->update($ldap) failed. $mesg2->{errorMessage}="'.
			                       $mesg2->{errorMessage}.'"';
			warn('Plugtools-Plugins-HomeOUremove plugin:3: '.$returned{errorString});
			return %returned;
		}

		$int--;
	}

	return %returned;
}

=head1 ERROR CODES

=head2 1

The variable "homebase" in the section "HomeOU" is undefined.

=head2 2

$args{user} is not defined

=head2 3

Failed to delete the entry.

=head2 4

The search to check if it exists failed.

=head1 PLUGTOOLS CONFIG

    pluginDeleteUser=Plugtools::Plugins::HomeOUremove
    [HomeOU]
    homebase=ou=home,dc=foo,dc=bar

=head2 homebase

This is the DB to create the home OU under.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plugtools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plugtools-Plugins-HomeOU>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plugtools::Plugins::HomeOU
    perldoc Plugtools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plugtools-Plugins-HomeOU>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plugtools-Plugins-HomeOU>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plugtools-Plugins-HomeOU>

=item * Search CPAN

L<http://search.cpan.org/dist/Plugtools-Plugins-HomeOU/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Plugtools
