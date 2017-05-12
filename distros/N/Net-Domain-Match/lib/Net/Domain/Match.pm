package Net::Domain::Match;

use strict;

use version; our $VERSION = qv('0.2.3');

our $LOCAL = '/tmp/effective_tld_names.dat';
our $CACHE = '/tmp/effective_tld_names.dat.cache';
our $SOURCE = 'http://mxr.mozilla.org/mozilla-central/source/netwerk/dns/effective_tld_names.dat?raw=1';

use LWP::UserAgent;

sub import {
	if( grep { /:pdata/ } @_ ){
		$SOURCE = 'https://raw.github.com/petermblair/Perl-CPAN/master/Net-Domain-Regex/misc/tld.txt';
	}
}

sub new {
	my $class = shift;

	my $args = {
		local => $LOCAL,
		source => $SOURCE,
		cache => $CACHE,
		@_,
	};

	my $o = bless $args => $class;

	unless( -e $o->{local} ){
		$o->pull;
	}

	$o->refresh;

	return $o;
}

sub insert {
	my $self = shift;
	my $domain = shift;

	my @a = split( /\./, $domain );
	
	if( scalar @a == 2 ){
		$self->{tld}->{"$a[-1]"}++;
		$self->{sld}->{"$domain"}++;
	}
}

sub refresh {
	my $self = shift;

	use open qw(:std :utf8);
	open FD, "<$self->{local}";

	my $tlds = {};
	my $slds = {};

	while( <FD> ){
		chomp;

		if(/^(\S[^\.\s]+)$/){
			$tlds->{$1}++;
		}
		elsif ( /^\S[^\.\s]+\.(.+)$/ && exists $tlds->{$1} ) {
			$slds->{$_}++;
		}
	}

	$self->{tld} = $tlds;
	$self->{sld} = $slds;

	# any manual overrides - not all ccSLD are in the external file
	for( qw/ co.uk / ){
		$self->insert( $_ );
	}

}

sub pull {
	my $self = shift;

	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new( GET => $self->{source} );
	my $res = $ua->request( $req );

	if( $res->is_success ){
		open FD, ">$self->{local}";
		local $/;
		print FD $res->content;
	} else {
		die $res->status_line;
	}
}

sub generate_regex {
}

sub generate_map {
	my $self = shift;

	my $map = {};

	for( keys %{$self->{tld}} ){
		$map->{$_} = {};
	}

	for( keys %{$self->{sld}} ){
		my @a = split( /\./, $_ );
		my $t = $a[-1];

		if( defined $map->{$t} ){
			$map->{$t}->{$_}++;
		}
	}

	return $map;
}

sub match {
	my $self = shift;
	my $target = shift;

	$self->match_map( $target );
}

sub match_map {
	my $self = shift;
	my $target = shift;
	my $orig = $target;

	use Data::Dumper;

	my $map = $self->generate_map();

	my @tok = split /[^\w\.\-]/, $target;

	my @results;

	TARGET:for my $target ( @tok ){
		my ( $tld, $domain, $hostname ) = ( undef, undef, '' );

		my @tokens = split( /\./, $target );

		# Check 1: Is the TLD found
		if( defined $map->{"$tokens[-1]"} ){
			# Check if the SLD is found
			if( defined $map->{"$tokens[-1]"}->{"$tokens[-2].$tokens[-1]"} ){
				$tld = "$tokens[-2].$tokens[-1]";
			} else {
				$tld = $tokens[-1];
			}
		}

		# bail out, if we don't have the TLD defined
		next TARGET unless $tld;

		# Strip out the $tld from the target
		$target =~ s/^(.*?)\.$tld$/$1/;

		# Re-split it, to get the domain
		my @a = split( /\./, $target );

		next TARGET unless scalar @a > 0;

		$domain = $a[-1];

		pop( @a );

		$hostname = join( ".", @a )
			if scalar @a > 0;

		push( @results, { match => $orig, hostname => $hostname, domain => $domain, tld => $tld } );
	}

	return @results;
}

1;

__END__

=head1 NAME

Net::Domain::Match - Match DNS domain names and extract into TLD, Domain and hostname parts.

=head1 SYNOPSIS

    use Net::Domain::Match;
    use Data::Dumper;
    my $c = Net::Domain::Match->new;
    
    while( <> ){
            chomp;
            if( my @rc = $c->match( $_ ) ){
                    print Dumper( \@rc ),"\n";
            }
    
    }

=head1 DESCRIPTION

This module is used for finding and extracting domain names from a series of text.

=head2 OBJECT ORIENTED INTERFACE

This module is written with an object oriented interface.

=over 4

=item B<new>

This method instantiates the object.  It attempts to parse the TLD/SLD cache and load
the domains into its object store.

=item B<refresh>

Parse the local file, generating all TLDs and SLDs.

=item B<pull>

Pull the remote file for processing.  Requires C<LWP> for this.

=back

=head1 SEE ALSO
 
This module makes use of L<LWP::UserAgent> for the communications
with the external services.
 
Please submit all bugs via L<< https://github.com/petermblair/Perl-CPAN/issues >>
 
=head1 AUTHOR
 
Peter Blair, E<lt>cpan@petermblair.comE<gt>
 
=head1 COPYRIGHT AND LICENSE
 
Copyright (C) 2013 by Peter Blair
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


