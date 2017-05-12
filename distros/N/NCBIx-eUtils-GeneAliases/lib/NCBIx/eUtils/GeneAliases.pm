package NCBIx::eUtils::GeneAliases;
use Class::Std;
use Class::Std::Utils;
use LWP::Simple;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.9.0');

our $utils    = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
our $retmax   = 500;
our @keywords = ('Official Symbol:', 'and Name:', 'Name:', 'Other Aliases:', 'Other Designations:', 'Chromosome:', 'Location:', 'Annotation:', 'MIM:', 'Genomic context:', 'Macronuclear:', 'GeneID:');
	
{
        my %utils_url_of  :ATTR( :get<utils_url>   :set<utils_url>   :default<''>      :init_arg<utils_url> );
        my %retmax_of     :ATTR( :get<retmax>      :set<retmax>      :default<'500'>   :init_arg<retmax>    );
                
        sub START {
                my ($self, $ident, $arg_ref) = @_;
		$self->set_utils_url( $utils );
                return;
        }

	sub get_aliases {
		my ( $self, $gene_id ) = @_;
		my $gene_names      = {};
		my $gene_data;
	
		# Get NCBI records for gene
		my $gene_alts = $self->_get_docsums( $gene_id );
	
		if ( $gene_alts ) {
			# Remove newlines
			$gene_alts =~ s/\n/ /g;
		
			# Break into lines before keywords
			foreach my $keyword ( @keywords ) { $gene_alts =~ s/$keyword/\n$keyword/g; }
			my @alt_lines = split( /\n/, $gene_alts );
		
			# Process lines
			foreach my $alt_line ( @alt_lines ) {
				if ( $alt_line =~ m/^Official Symbol:(.*)$/ ) { 
					my $match = $1; $match =~ s/[,;]/ /g;
					my @symbols = split( /\s+/, $match );
					foreach my $symbol ( @symbols ) { if ( $symbol && $symbol ne $gene_id ) { $gene_names->{$symbol}++; } }
				}
				elsif ( $alt_line =~ m/^Other Aliases:(.*)$/ ) { 
					my $match = $1; $match =~ s/[,;]/ /g;
					my @aliases = split( /\s+/, $match );
					foreach my $alias ( @aliases )  { if ( $alias ) { $gene_names->{$alias}++; } }
				}
		
			}
			return sort keys %$gene_names;
		} else {
			return ();
		}
	}
	
	
	sub _get_docsums {
		my ( $self, $gene_id ) = @_;
		my $gene_data          = '';
		my $retmax             = $self->get_retmax();
		my $utils_url          = $self->get_utils_url();
		my $retstart;
	
		# Get the query
		my $esearch = $utils_url . "/esearch.fcgi?" .  "db=gene&retmax=1&usehistory=y&term=$gene_id" . 
		   		                               '&tool=cpan_ncbix_eutils_genealiases&email=roger@iosea.com';
		my $esearch_result = get( $esearch );
		sleep(3);
		
		# Parse the count, query_key, and webenv
		$esearch_result =~ m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;
		my $Count    = $1 ? $1 : 0;
		my $QueryKey = $2;
		my $WebEnv   = $3;
		
		#print "  STATUS: Getting $Count results for $gene_id \n";

		for ( my $retstart = 0; $retstart < $Count; $retstart += $retmax ) {
			my $efetch = $utils_url . "/efetch.fcgi?" .
			             "rettype=docsum&retmode=text&retstart=$retstart&retmax=$retmax&" .
			             "db=gene&query_key=$QueryKey&WebEnv=$WebEnv" . 
		   		     '&tool=cpan_ncbix_eutils_genealiases&email=roger@iosea.com';
			
			$gene_data .= get($efetch);
			sleep(2);
		}
	
		#print "  STATUS: Done. \n";

		return $gene_data;
	}	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

NCBIx::eUtils::GeneAliases - Get Aliases from NCBI 'gene' using NCBI eUtils


=head1 VERSION

This document describes NCBIx::eUtils::GeneAliases version 0.9.0


=head1 SYNOPSIS

    use NCBIx::eUtils::GeneAliases;

    my $ga = NCBIx::eUtils::GeneAliases->new();
    
    my @aliases = $ga->get_aliases("CYP46A1");
    
    foreach my $alias ( @aliases ) { print " ALIAS: $alias \n"; }
    

=head1 DESCRIPTION


=head1 CONFIGURATION AND ENVIRONMENT

NCBIx::eUtils::GeneAliases requires no configuration files or environment variables.


=head1 DEPENDENCIES

 Class::Std;
 Class::Std::Utils;
 LWP::Simple;


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-biox-genealias@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Roger A Hall  C<< <rogerhall@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Roger A Hall C<< <rogerhall@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
