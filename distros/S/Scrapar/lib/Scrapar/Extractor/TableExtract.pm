package Scrapar::Extractor::TableExtract;

use strict;
use warnings;
use HTML::TableExtract;
use base qw(Scrapar::Extractor::_base);

sub extract {
    my $self = shift;
    my $content = shift;
    my $params_ref = shift;

    my $te = HTML::TableExtract->new($self->{keep_html} ? (keep_html => 1) : ());
    $te->parse($content);

    my $tables;
    my $output;

    foreach my $ts ($te->tables) {
        my ($x, $y) = $ts->coords;
	if ($x == $params_ref->{x} && $y == $params_ref->{y}) {
#	    print "($x, $y)\n";
	    my @rows = $ts->rows;

	    for my $i (0..$#rows) {
		my @cols = @{$rows[$i]};
		for my $j (0..$#cols) {
		    if ($cols[$j]) {
			$cols[$j] =~ s[\A\s+][]o;
			$cols[$j] =~ s[\s+\z][]o;
			$cols[$j] =~ s[\r][]sgo;
			$cols[$j] =~ s[^\s*\r?\n$][\n]msgo;
			$cols[$j] =~ s[\n+][\n]sgo;
 		        $output .= $cols[$j];
			$tables->[$x][$y][$i][$j] = $cols[$j];
		    }
		}
		$output .= "\n\n";
	    }
	    return $output;
	}
    }
}

1;

__END__

=pod

=head1 NAME

Scrapar::Extractor::TableExtract - Table extractor

=head1 COPYRIGHT

Copyright 2009-2010 by Yung-chung Lin 

All right reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
