package Net::Domain::Regex;

use strict;

use version; our $VERSION = qv('0.2.1');

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

	# any manual overrides
	for( qw/ co.uk / ){
		$tlds->{"$_"}++;
	}

	$self->{tld} = $tlds;
	$self->{sld} = $slds;
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
	my $self = shift;

	my @a;

	for( keys %{$self->{sld}} ){
		push( @a, $_ );
	}

	for( keys %{$self->{tld}} ){
		push( @a, $_ );
	}

	my @atld = sort { length $b cmp length $a } @a;

	my $tld = join( "|", @atld );
	$tld =~ s/\./\\./g;

	#my $regex = "((?:[a-zA-Z0-9]\\w+\\.)(($tld)|($sld)))";
	my $regex = "((?:[a-zA-Z0-9][\\w\\-]+\\.)+(com|net|org|edu|$tld))\$";

	return $regex;
}

sub match {
	my $self = shift;
	my $target = shift;
	my $orig = $target;

	my $regex = $self->generate_regex;
	
	#print "Regex: [$regex]\n";

	my @tokens = split /[^\w\.\-]/, $target;
	my @results;

	for my $target( @tokens ){
		if( $target =~ /$regex/g ){
			my $match = $orig = $1;
			# Extract the TLD
			my @atld = sort { length $b cmp length $a } keys %{$self->{tld}};
			#my $tld = join( "|", sort keys %{$self->{tld}} );
			my $tld = join( "|", @atld );
			$tld =~ s/\./\\./g;

			# Extract the TLD from the match
			my $t = $1 if $match =~ /^.*?\.($tld)$/;

			if( $t ){
				$match =~ s/\.$t$//;
			}

			# Extract the domain from the match
			my $d = $1 if $match =~ /([^\.]+)$/;
			$d =~ s/\.$//;

			if( $d ){
				$match =~ s/$d$//;
			}

			my $h = $match;
			$h =~ s/\.$//;

			push( @results, { match => $orig, hostname => $h, domain => $d, tld => $t } );
		}
	}
	return @results;
}

1;

__END__

=head1 NAME

Net::Domain::Regex - Match DNS domain names and extract into TLD, Domain and hostname parts.

=head1 SYNOPSIS

    use Net::Domain::Regex;
    use Data::Dumper;
    my $c = Net::Domain::Regex->new;
    
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

