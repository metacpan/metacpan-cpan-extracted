#!/usr/local/bin/perl

=pod

=head1 NAME

pagedump.pl - prints more or less useful information about pags in a PDF-file

=head1 SYNOPSIS

  pagedump.pl file page ...

=head1 DESCRIPTION

This program dumps some data about pages in a PDF. It was written as a
test-bed for the PDF library and comes quite handy for dumping
objects. The practical use of this program is quite low.

The information printed by this program is not very useful, but it
demontrates well some more complex aspects of the PDF library. Check
the function B<doprint> in this program on how to handle all possible
data occuring in a PDF.

=head1 Copyright

Copyright 2000, by Johannes Blach (dw235@yahoo.com)

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 Availability

It may or may not be included in the latest version of the PDF library,
which is likely to be available from:

http://www.geocities.com/CapeCanaveral/Hangar/4794/

and at any CPAN mirror

=cut

use strict;
use PDF;

#
# This function prints whatever PDF::GetObject returns recursively
#
sub doprint ($@)
	{
	my $indent = shift;
	while (defined (my $param = shift))
		{
		if (UNIVERSAL::isa ($param, "HASH"))
			{
			print "Dictionary\n", "    " x $indent, "<<\n";
			foreach my $i ( sort keys %{$param} )
				{
				print "    " x $indent;
				if ($i =~ m/^\//)
					{
					print "Name: ", $i, " => ";
					}
				else
					{
					print "Other: ", $i, " => ";
					}
				doprint ($indent + 1, $param->{$i});
				}
			print "    " x $indent, ">>\n";
			}
		elsif (UNIVERSAL::isa ($param, "ARRAY"))
			{
			print "Array\n", "    " x $indent, "[\n";
			foreach my $i ( @{$param} )
				{
				print "    " x $indent;
				doprint ($indent + 1, $i);
				}
			print "    " x $indent, "]\n";
			}
		elsif ($param =~ m/^\//) {print "Name: ", $param, "\n";}
		elsif ($param =~ m/^\d+ \d+ R$/) {print "Object: ", $param, "\n";}
		elsif ($param =~ m/^[\d.\+\-]+$/) {print "Number: ", $param, "\n";}
		elsif ($param =~ m/^<.*>$/)
			{
			print "Hex String\n", "    " x $indent, "Raw:\t", $param, "\n",
			"    " x $indent, "Cooked:\t", PDF::Core::UnQuoteString ($param),
			"\n";
			}
		elsif ($param =~ m/^\(.*\)$/)
			{
			print "Text String\n", "    " x $indent, "Raw:\t", $param, "\n",
			"    " x $indent, "Cooked:\t", PDF::Core::UnQuoteString ($param),
			"\n";
			}
		else
			{
			print "Unknown: ", $param, "\n";
			}
		}
	}

if (my $file = shift)
	{
	my $PDFfile = PDF->new($file);

	if ($PDFfile->{"Header"})
		{
		$PDFfile->LoadPageInfo;

		while (defined (my $pn = shift))
			{
			print "Page ", $pn, "\n    ";
			$pn--;
			next if ($pn < 0 || $pn > $#{$PDFfile->{"Page"}});

			doprint (2, $PDFfile->{"Page"}[$pn]);

			my @dl;
			print "\nReferenced objects\n\n";
			foreach my $i (keys %{$PDFfile->{"Page"}[$pn]})
				{
				#Skip obvious ones
				next if ($i eq "/Parent");
				
				if (UNIVERSAL::isa ($PDFfile->{"Page"}[$pn]{$i}, "ARRAY"))
					{
					foreach my $j (@{$PDFfile->{"Page"}[$pn]{$i}})
						{
						push @dl, $j if ($j =~ m/^\d+ \d+ R$/);
						}
					}
				else
					{
					push @dl, $PDFfile->{"Page"}[$pn]{$i}
					if ($PDFfile->{"Page"}[$pn]{$i} =~ m/^\d+ \d+ R$/);
					}
				}

			foreach my $j (@dl)
				{
				my ($ind) = $j =~ m/^(\d+)/;
				my $res =  $PDFfile->GetObject ($j);
				print "Object: ", $j, 
				"\toffset: ", $PDFfile->{"Objects"}[$ind],
				"\tsize: ", $PDFfile->{"Object_Length"}[$ind], "\n    ";
				doprint (2, $res);
				print "\n";
				}
			}
		}
	else
		{
		print $file, " is not a PDF\n";
		}
	}
else
	{
	print "Usage: pagedump.pl filename page1 ...\n";
	}
