package Mozilla::IntermediateCerts;

use strict;
use warnings;

use utf8;
use Moo;

use namespace::clean;

use LWP::UserAgent;
use Text::CSV;
use Mozilla::IntermediateCerts::Cert;

# ABSTRACT: Downloads and parses Mozilla intermediate certificates

our $VERSION = 'v0.0003';

=head1 NAME
 
Mozilla::IntermediateCerts
 
=head1 WARNING
 
This module is in early development and may change.
 
=head1 SYNOPSIS
 
		my $certs = Mozilla::IntermediateCerts->new;

		for my $cert ( $certs->certs )
		{
			...
		} 

	or
		my $certs = Mozilla::IntermediateCerts->new(
			tmp_path => '/my/tmp/dir'
			moz_int_cert_path => 'http://foo.com/certs.csv' 
		);
=cut
 
=head1 DESCRIPTION

This module downloads the latest Mozilla intermediate certificates list and parses it

https://wiki.mozilla.org/CA/Intermediate_Certificates 
 
This is a work in progress and contains incomplete test code, methods are likely to be refactored, you have been warned.
 
=head1 Args

=cut

=head2 tmp_path
	
Set the directory where files are downloded to

	Default /tmp
=cut
has tmp_path => ( 
	is => 'rw', 
	default => sub { '/tmp' } 
);


=head2 moz_int_cert_path

Set the URL for the the intermediate certificate file download

	Default https://ccadb-public.secure.force.com/mozilla/PublicAllIntermediateCertsWithPEMCSV
=cut
has moz_int_cert_path => (
	is => 'rw', 
	default => sub { 'https://ccadb-public.secure.force.com/mozilla/PublicAllIntermediateCertsWithPEMCSV' }
);


=head1 Methods
=cut


has csv => ( is => 'rw' );

=head2 certs

Returns an arrayref of Mozilla::IntermediateCert objects
=cut

has certs => ( is => 'rw' );


=head2 error

Returns error message if an error occurs
=cut
has error => ( is => 'rw' );

sub BUILD
{
	my $self = shift;

	if ( $self->_download )
	{
		if ( $self->_parse_csv )
		{
			return 1;
		}
	}	
	return 0;
}

=head2 _download

Internal method to handle downloading the csv file
=cut
sub _download
{
	my $self = shift;
	eval 
	{
		my $ua = LWP::UserAgent->new;
		$ua->agent("Perl - Mozilla::IntermediateCerts/$VERSION");
		$ua->cookie_jar({});

		my $req = HTTP::Request->new(GET => $self->moz_int_cert_path);
		my $res = $ua->request($req);

		my $file =  $self->tmp_path . '/' . time;
		open my $fh, '>', $file or die "Could not save output $!";
		print $fh $res->content;
		$self->csv( $file );
	};
	if ( $@ )
	{
		$self->{error} = "Unable to download certificate csv $@";
		return 0;
	}
	return 1;
}

=head2 _parse_csv

Internal method to parse csv into array of Mozilla::IntermediateCerts::Cert objects
=cut 
sub _parse_csv
{
	my $self = shift;
	my @certs;
	eval
	{
		my $csv = Text::CSV->new({ binary => 1, decode_utf8 => 1  } );
		open my $fh, '<:encoding(UTF-8)', $self->csv or die "Could not load CSV $!";
		
		$csv->column_names( $csv->getline( $fh ) );

		while ( my $row = $csv->getline_hr( $fh ) )
		{
			push @certs, Mozilla::IntermediateCerts::Cert->new( $row );
		}
	};
	if ( $@ )
	{
		die "Failed to parse certificate csv $@";
	}
	$self->certs( \@certs );
}


=head1 SOURCE CODE

The source code for this module is held in a public git repository on Gitlab https://gitlab.com/rnewsham/mozilla-intermediatecerts

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2019 Richard Newsham
 
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
 
=head1 BUGS AND LIMITATIONS
 
See rt.cpan.org for current bugs, if any.
 
=head1 INCOMPATIBILITIES
 
None known. 
 
=head1 DEPENDENCIES

Moo
LWP::UserAgent;
Text::CSV;
Mozilla::IntermediateCerts::Cert;
=cut

1;
