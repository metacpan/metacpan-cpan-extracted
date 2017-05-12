package TAIR::GeneDescriptions;

use warnings;
use strict;

use LWP::UserAgent;
use HTTP::Request::Common;

=head1 NAME

TAIR::GeneDescriptions - Automatically download gene descriptions using locus identifiers (AGI codes) or gene names.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

Automatically download gene descriptions using locus identifiers (AGI codes) or gene names. 
(http://www.arabidopsis.org/tools/bulk/genes/index.jsp)


    	use TAIR::GeneDescriptions;
	my $TB = TAIR::GeneDescriptions->new();
	my $verbose = "1";
	my $input_file = "input_file.txt";
	my $output_file = "output_file.txt";
	my ($input_file_hn);
	
	open($input_file_hn, "<", $input_file) or die("Cannot open $input_file for reading: $!");
	while (<$input_file_hn>)
		{
			chomp;
			my $query = $_;
			$TB->connect($query,$verbose);	
		}
	
	$TB->write($output_file);

=head1 SUBROUTINES/METHODS

=head2 new

Object-oriented master-hash!

=cut

sub new
  {
    my %master_hash;
    return(bless(\%master_hash, __PACKAGE__));
  }

=head2 connect

Parameters, do not mess with them unless you know what you are doing.

=cut

sub connect
 {
	my $tair_master = shift;
	my $query = shift;
	my $verbose = shift;
				
	my $URLtoPostTo = "http://www.arabidopsis.org/cgi-bin/bulk/genes/gene_descriptions";
	my %Fields = (
   "search_for" => $query,
   "search_against" => "rep_gene",
   "output_type" => "text",
   "textbox" => "seq"
	);

	my $BrowserName = "TAIR";

	my $Browser = new LWP::UserAgent;

	if($BrowserName) { $Browser->agent($BrowserName); }

	my $Page = $Browser->request(POST $URLtoPostTo,\%Fields);

	if ($Page->is_success) {	
	my $output_raw = $Page->content;
	my @output_array = split("\n", $output_raw);
	my $header = $output_array[0];
	shift @output_array;
	my @output_itemized;
	my $i = 1;	
		foreach (@output_array){
			my @details = split("\t",$_);
				if (defined($details[1])) {
					my %details = (
					"i" => $i,
					"locus_identifier" => $details[0],
					"gene_model_name" => $details[1],
					"gene_model_description" => $details[2],
					"gene_model_type" => $details[3],
					"primary_gene_symbol" => $details[4],
					"all_gene_symbols" => $details[5]
					);
					shift(@details);
					push (@output_itemized, \%details);	
					$i++;
				}
		}
 	$tair_master->{'output'}->{$query}=\@output_itemized;
	if ($verbose == 1){
		print $query, " is done!\n";	
	}
 	}	
	else { print $Page->message; }
	
 }
 
=head2 write

This subroutine handles output of the program, it writes the results into a specified file name.

=cut

sub write 
	{
		my $tair_master = shift;
		my $output_file = shift;
		my ($output_file_hn);
		my $output_hash = $tair_master->{'output'};
		open($output_file_hn, ">", $output_file) or die("Cannot open $output_file for writing: $!");
		print $output_file_hn "Locus Identifier \t Gene Model Name \t Gene Model Description \t Gene Model Type \t Primary Gene Symbol \t All Gene Symbols \n";	
			foreach (keys %$output_hash){		
			my $next_query = $_; 
				foreach(@{$output_hash->{$_}}){
				print $output_file_hn
						$_->{'locus_identifier'},"\t",
						$_->{'gene_model_name'},"\t",
						$_->{'gene_model_description'},"\t",
						$_->{'gene_model_type'},"\t",
						$_->{'primary_gene_symbol'},"\t",
						$_->{'all_gene_symbols'},"\n";				
				}
			}
	}

=head1 AUTHOR

Haktan Suren, C<< <hsuren at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tair-genedescriptions at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TAIR-GeneDescriptions>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TAIR::GeneDescriptions


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TAIR-GeneDescriptions>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TAIR-GeneDescriptions>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TAIR-GeneDescriptions>

=item * Search CPAN

L<http://search.cpan.org/dist/TAIR-GeneDescriptions/>

=back

=head1 DEPENDENCIES

	LWP::UserAgent
	HTTP::Request::Common

=head1 ACKNOWLEDGEMENTS

Special thanks to LC :)

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Haktan Suren.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TAIR::GeneDescriptions
