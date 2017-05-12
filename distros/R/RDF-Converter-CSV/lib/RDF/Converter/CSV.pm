package RDF::Converter::CSV;

use warnings;
use strict;
use Text::CSV;
use IO::File;
use Carp;
use Class::Std::Utils;
use XML::Writer;

=head1 NAME

RDF::Converter::CSV - Converts comma separated CSV to RDF

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

   use RDF::Converter::CSV;
   use strict;
   use warnings;
   my $rdf =  RDF::Converter::CSV->new(
		    FILENAME 	=> 'books.csv', #MANDATORY
		    URI		=>'http://nothing.nul/', #MANDATORY
		    PREFIX 	=> 'lib', #MANDATORY
		    PRIMARY 	=> 'id', #OPTIONAL - will take one of the field as identifier, if not given 
		    OUTPUT	=> 'books.rdf',#OPTIONAL - will output on the terminal, if not given
		    COLUMNS	=> [ 	
				    qw/
					    id 
					    title
					    author
					    price
					/
				   	] #OPTIONAL - will take the first row as the field names, 
					#if COLUMNS not given or 
					#the number of elements in COLUMN  != the number of fields in the CSV file
	    );
   $rdf->write;

=head1 OTHER METHODS

	$rdf->get_file;
	returns the array ref of the file content

	$rdf->csv_process;
	returns the csv data as a array ref of hash refs

=cut

my %file_name;
my %uri;
my %prefix;
my %primary;
my %columns;
my %output;

sub new
{
	my ($class, %params) = @_;
	if(! exists $params{FILENAME} || ! exists $params{URI} || ! exists $params{PREFIX})
	{
		croak("One or more mandatory attributes are missing!!");
	}
	my $this 		= bless \do{my $ghost}, $class;
	$file_name{ident $this} = $params{FILENAME};
	$uri{ident $this} 	= $params{URI};
	$prefix{ident $this} 	= $params{PREFIX};
	$primary{ident $this} 	= $params{PRIMARY};
	$columns{ident $this} 	= $params{COLUMNS};
	$output{ident $this} 	= $params{OUTPUT};
	return $this;
}
#This retrieves the CSV data as an array ref
sub get_file
{
	my ($this) 	= shift;
	my $file_name 	= $file_name{ident $this};
	open my $io ,'<',$file_name  or die "$file_name: $!";
	my @data;
	while (<$io>)
	{
		push @data, $_;
	}
	close $io;
	return \@data;
}

#This converts the csv content as a data structure
sub csv_process
{
	my ($this) 	= shift;
	my $csv 	= Text::CSV->new({binary => 1,eol => $/});
	my $file_name 	= $file_name{ident $this};
	my $field_names	= $columns{ident $this};
	open my $io, "<", $file_name or die "$file_name: $!";
	
	my $row 		= $csv->getline ($io);
	$field_names 		= $row if !$field_names || scalar @$row != scalar @$field_names;
	$primary{ident $this}	= $$field_names[0] if !$primary{ident $this} || 
							($primary{ident $this} && 
							! grep(/^$primary{ident $this}$/, @$field_names)
							);
	$csv->column_names (@$field_names);
	my @perl_data;
	
	while (my $hr = $csv->getline_hr ($io)) 
	{
		push @perl_data, $hr if $hr;
	}
	close $io;
	return \@perl_data;
}

#Converts CSV to RDF
sub write
{
	my ($this) 	= shift;
	my $rdfns 	= "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
	my $uri 	= $uri{ident $this};
	my $prefix 	= $prefix{ident $this};
	my $data 	= $this->csv_process;
	my $primary 	= $primary{ident $this};
	my $out_file	= $output{ident $this};
	my $output 	= new IO::File(">$out_file");
	
	my $writer 	= new XML::Writer(
					OUTPUT		=> $output,
					NAMESPACES 	=> 1, 
					PREFIX_MAP 	=> { $rdfns => 'rdf', $uri => $prefix}, 
					DATA_INDENT 	=>1,
					DATA_MODE 	=>1
				);
	$writer->xmlDecl("UTF-8");
	$writer->forceNSDecl($uri);
	$writer->startTag([$rdfns => "RDF"]);
	
	for my $row(@$data)
	{
		$writer->startTag(
				[$rdfns => "Description"], 
				[$rdfns => 'about'] => $uri.$row->{$primary} 
			);
		for my $key (keys %$row)
		{
			$writer->startTag([$uri => $key]);
			$writer->characters($row->{$key});
			$writer->endTag([$uri => $key]);
		}
		$writer->endTag([$rdfns, "Description"]);
	}
	$writer->endTag([$rdfns, "RDF"]);
	$writer->end();
}

=head1 AUTHORS

Arshad Mohamed, Khader Shameer and R. Sowdhamini RDF::Converter Team C<< <arshad25 at gmail.com> >>, C<< <shameer at ncbs.res.in> >>, C<< <mini at ncbs.res.in> >>

=head1 ACKNOWLEDGEMENTS 
Funding : 


=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-converter-csv at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-Converter-CSV>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RDF-Converter-CSV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RDF-Converter-CSV>

=item * Search CPAN

L<http://search.cpan.org/dist/RDF-Converter-CSV/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Arshad Mohamed, Khader Shameer & R. Sowdhamini, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of RDF::Converter::CSV
