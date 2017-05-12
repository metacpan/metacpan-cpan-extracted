use Config;

( $infile, $outfile ) = ( $0, $ARGV[0] );
$infile =~ s/\.PL$/.pl/;

open IN, "<$infile"  or die "Can't read $infile: $!";
open OUT,">$outfile" or die "Can't create $outfile: $!";

print "Extracting $outfile (with variable substitutions)\n";
print OUT ( "$Config{startperl}\n", <IN> );

close IN;
close OUT;

chmod(0755, $outfile);

#
# $Id: mkscript.PL,v 1.1 2002/11/15 04:01:53 bozzio Exp $
#
