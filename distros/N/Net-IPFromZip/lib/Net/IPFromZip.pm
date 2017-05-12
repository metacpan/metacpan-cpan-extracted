package Net::IPFromZip;

use 5.018002;
use strict;
use warnings;

require Exporter;
require Text::CSV_XS;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	reverse
);

our $VERSION = '0.02';


# Preloaded methods go here.
sub reverse {
	my $csvFile;
	my $postalCode;
	
	my @output;

	if ($_[0] =~ /^[\d-]+$/) { #if only zip code
		$postalCode = $_[0];

		#looking for csv file if only zip code

		#seeing if passed in args
		if (defined($_[1]) && $_[1] =~ /csv/ig) { #if $_[1] is a csv file, or has some mention of anything csv, we should at least try to open it

			$csvFile = $_[1];
		}

		#checking current dir and /usr/local/share/GeoIP
		else {

			chomp(my $pwd =`pwd`);
			opendir (my $cwd, $pwd) or die "Couldn't open $pwd : $! line 46 \n";
			while (readdir $cwd) {
				if (/Blocks/ig && /csv/ig) {
					$csvFile = $_;
				}
			}
			closedir ($cwd);
				
		
			if (-d "/usr/local/share/GeoIP") {	
				opendir(my $geoipDir, "/usr/local/share/GeoIP"); #if directory doesn't exist, then next
				if ($geoipDir) {
					while (readdir $geoipDir) {
						if (/Blocks/ig && /csv/ig) {
							$csvFile = $_;
						}
					}
					closedir ($geoipDir);
				}
			}

			if (!(defined($csvFile))) {
				die ("No CSV found in /usr/local/share/GeoIP or current dir\n");
			}

		}

	}

	else { #then argv[1]
		$csvFile = $_[0]; #THIS SHOULD BE THE BLOCK FILE
		$postalCode = $_[1];
	}

	

	#straight from meta cpan

	my $csv = Text::CSV_XS->new ( { binary => 1 } )  # should set binary attribute.
			or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

	open my $fh, "<$csvFile" or die $!;

	#printing ip array if matching postalCode


	my $resultCount = 0;
	while ( my $row = $csv->getline( $fh ) ) {
		$row->[6] =~ /$postalCode/ or next; # 3rd field should match
		push ( @output, $row->[0] );
		$resultCount++;
	}
	$csv->eof or $csv->error_diag();
	close $fh;
	return \@output;
}

1;
__END__

=head1 NAME

Net::IPFromZip- find all ip addresses associated with a specific zip code

=head1 SYNOPSIS

  use Net::IPFromZip qw/reverse/;

  #assuming that the .csv file is either in the local directory or in /usr/local/share/GeoIP
  my @ips = @{ reverse("59715") }; 

  #if not
  my @ips = @{ reverse("/path/to/file.csv", "59715") }; 


=head1 DESCRIPTION

This module uses the GeoIP2 database in the form of CSV files. It takes in a zip code, being that a zip code is more accurate than an area code or city name, and that a zip code is the most accurate input the free GeoIP2 databases take.

=head2 EXPORT

reverse - the main function

Being that the only meat of this module is the main reverse function, only one function is exported


=head1 SEE ALSO

http://github.com/jk33/reverse-geo-ip - repository containing compressed csv databases, the originaly reverseFromCSV.pl file, and various misc scripts

http://github.com/jk33/net-ipfromzip - repository with all the perl module source

=head1 AUTHOR

John Kennedy, E<lt>jgk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by John Kennedy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
