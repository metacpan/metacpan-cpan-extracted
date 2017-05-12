#!/usr/bin/perl
use strict;
use warnings;
use 5.008;

use File::Spec;

our $VERSION = '0.04';

setup_examples();


sub setup_examples {
	
	my $dir = File::Spec->catdir('lib', 'Perl6', 'Cookbook');
	mkdir $dir;

	opendir my $chapters, 'eg' or die $!;
	while (my $chapter = readdir $chapters) {
		next if $chapter eq '.' or $chapter eq '..';
		opendir(my $eg, File::Spec->catdir('eg', $chapter)) or die $!;
		my @entries;
		while (my $entry = readdir $eg) {
			next if $entry eq '.' or $entry eq '..';
			my $file = File::Spec->catfile('eg', $chapter, $entry);
			#print "processing $file\n";
			my @data = slurp($file);
			push @entries, {file => $entry, data => \@data};
			
		}
		my $content = build_content($chapter, @entries);
		my $file = File::Spec->catfile($dir, ucfirst($chapter) . '.pod');
		#print "Saving $file\n";
		open my $out, '>', $file or die;
		print {$out} $content;
	}
}

sub slurp {
	my $file = shift;
	open my $fh, '<', $file or die "Could not open $file $!";
	#local $/ = undef;
	return <$fh>;
}

sub build_content {
	my ($chapter, @entries) = @_;

	my $p = ucfirst substr($chapter, 3);
	my $content = <<"END_CONTENT";
package Perl6::Cookbook::$p;

END_CONTENT

	foreach my $e (sort {$a->{file} cmp $b->{file} } @entries) {
		my $head = substr($e->{file}, 0, -3);
		$head =~ s/_/ /g;
		$content .= "\n=head1 $head\n\n";
		foreach my $line ( @{ $e->{data} } ) {
			if ($line =~ /=begin pod/ .. $line =~ /=end pod/) {
			    if ($line =~ /=begin pod/) {
					$content .= "\n=head2 Description\n";
				} elsif ($line =~ /=end pod/) {
				} else {
					$content .= $line;
				}
			} else {
				$content .= "   $line";
			}
		}
		$content .= "\n\n=cut\n\n";
	}

	$content .= "\n1;\n\n";

	return $content;
}


