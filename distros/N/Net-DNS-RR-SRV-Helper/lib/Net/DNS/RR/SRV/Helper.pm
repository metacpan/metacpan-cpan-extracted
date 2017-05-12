package Net::DNS::RR::SRV::Helper;

use warnings;
use strict;
use Exporter;
use Sort::Naturally;

our @ISA         = qw(Exporter);
our @EXPORT      = qw(SRVorder);
our @EXPORT_OK   = qw(SRVorder);
our %EXPORT_TAGS = (DEFAULT => [qw(SRVorder)]);

=head1 NAME

Net::DNS::RR::SRV::Helper - Orders SRV records by priority and weight for Net::DNS.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::DNS;
    use Net::DNS::RR::SRV::Helper;
    use Data::Dumper;
    
    my $query=$res->search("_ldap._tcp.foo.bar", SRV);
    my @answers=$query->answer;

    my @ordered=SRVorder(\@answers);
    if(!defined( $ordered[0] )){
        print "No usable records were found.\n";
    }else{
        print Dumper(\@ordered);
    }

=head1 EXPORT

SRVorder

=head1 FUNCTIONS

=head2 SRVorder

This takes the returned answer array containing Net::DNS::RR::SRV
objects and processes them into a new easy to use array of hashes
ordered by priority and weight.

One item is taken and that is the array returned from the answers method.

Upon a error or no records being present, undef is returned.

=cut

sub SRVorder{
	my @records=@{$_[0]};

	if (!defined($records[0])) {
		return undef;
	}

	#used for assemblying this
	my %holder;

	#process each entry
	my $int=0;
	while (defined($records[$int])) {
		my $r=$records[$int];
		
		#gets the various fields for the record
		my $priority=$r->priority;
		my $weight=$r->weight;
		my $port=$r->port;
		my $server=$r->target;

		#makes sure they are all defined, if not skip processing it
		if (
			defined($priority) &&
			defined($weight) &&
			defined($port) &&
			defined($server)
			) {
			
			#makes sure the priority hash exists
			if (!defined($holder{$priority})) {
				$holder{$priority}={};
			}

			#makes sure the weight hash exists
			if (!defined( $holder{$priority}{$weight} )) {
				$holder{$priority}{$weight}={};
			}
			
			#makes sure that server hash exists
			if (!defined( $holder{$priority}{$weight}{$server} )) {
				$holder{$priority}{$weight}{$server}={}
			}

			$holder{$priority}{$weight}{$server}{$port}=1;
		}

		$int++;
	}

	#the array to return
	my @toreturn;
	
	#processes it all
	my $priInt=0;
	my @priorities=nsort(keys(%holder));
	while ( defined($priorities[$priInt]) ) {
		my $priority=$priorities[$priInt];
		
		#process the weights for the current priority
		my @weights=reverse(nsort(keys( %{$holder{$priority}}  )));
		my $wInt=0;
		while ( defined($weights[$wInt]) ) {
			my $weight=$weights[$wInt];
			
			#process the servers
			my @servers=keys( %{ $holder{$priority}{$weight} });
			my $sInt=0;
			while (defined( $servers[$sInt] )) {
				my $server=$servers[$sInt];
				
				#processes the ports and put the new entry onto the return array
				my @ports=keys( %{ $holder{$priority}{$weight}{$server} });
				my $portInt=0;
				while (defined($ports[$portInt])) {
					my $port=$ports[$portInt];
					
					my %serverentry;
					$serverentry{server}=$server;
					$serverentry{port}=$port;
					$serverentry{priority}=$priority;
					$serverentry{weight}=$weight;
					
					#push the server entry onto to the return array
					push(@toreturn, \%serverentry);
					
					$portInt++;
				}
				
				$sInt++;
			}
			
			$wInt++;
		}
	
		$priInt++;
	}

	return @toreturn;
}

=head1 RETURN VALUE

The returned value is a array.

Each item of the array is a hash.

The keys listed below are used for the hash.

=head2 server

This is the server to use.

=head2 port

This is the port to use for this server.

=head2 priority

This is the priority of this server.

=head2 weight

This is the weight of this server.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-dns-rr-srv-helper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DNS-RR-SRV-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DNS::RR::SRV::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-DNS-RR-SRV-Helper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-DNS-RR-SRV-Helper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-DNS-RR-SRV-Helper>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-DNS-RR-SRV-Helper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::DNS::RR::SRV::Helper
