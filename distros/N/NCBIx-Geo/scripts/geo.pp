#!/usr/bin/perl

use NCBIx::Geo;
use Getopt::Long;

# Get switches
my $accn = ''; my $dir = ''; my $verbose = ''; my $help = ''; my $compare = '';
my $switches = GetOptions ('verbose' => \$verbose, 'accn=s'  => \$accn, 'dir=s'   => \$dir, 'help' => \$help, 'compare=s' => \$compare );

# Check for help or missing accn
if ( $help || !$accn ) { usage(); }

my $params = { data => 1 };
if ( $accn )    { $params->{accn}     = $accn; }
if ( $dir )     { $params->{data_dir} = $dir; }
if ( $verbose ) { $params->{debug}    = 1; }
my $geo = NCBIx::Geo->new( $params );

if ( $compare ) { 
	print $geo->diff({ list => [ $accn, $compare ] });
} else {
	print $geo->desc();
}

exit;

sub usage {
	print "\n";
	print "  ######################################################################\n";
	print "  #  \n";
	print "  #  Note: Data is only downloaded on GDS, GSE, or GSM search resulting\n";
	print "  #        in only one GDS. Using GPL accessions only downloads meta-\n";
	print "  #        data. Use your own directory or collaborate with others \n";
	print "  #        using /tmp/geo/.\n";
	print "  #  \n";
	print "  #  Note: The compare switch produces a text file with a list of \n";
	print "  #        transcript_ids only 'Present' in either the 'left' or the \n";
	print "  #        'right' GSM. The output is similar to linux 'diff', using \n";
	print "  #        arrows and labels to note which transcript_ids belong to \n";
	print "  #        which GSM. Both GSM must have the same GPL.\n";
	print "  #        \n";
	print "  ######################################################################\n";
	print "  #  Switch            Description         Notes \n";
	print "  ######################################################################\n";
	print "  #  -a <accn>         Accession           required \n";
	print "  #  --accn <accn>                         -a long form\n";
	print "  #  -d <data_dir>     Data directory      optional, default '/tmp/geo/' \n";
	print "  #  -data <data_dir>                      -d long form \n";
	print "  #  -c                Transcript Diff     optional, two -a GSM only\n";
	print "  #  --compare                             -c long form \n";
	print "  #  -h                Help                optional, this message \n";
	print "  #  --help                                -h long form \n";
	print "  #  -v                Verbose             optional \n";
	print "  #  --verbose                             -v long form \n";
	print "  ######################################################################\n";
	print "\n";
	print "  NCBIx::Geo geo Copyleft (C) 2010 Roger Hall\n";
	print "  Usage: geo -a <accn> -d <data_dir>     # Download related samples\n";
	print "         geo -v -a <accn> -d <data_dir>  # Print progress (verbose)\n";
	print "         geo -a <accn> -c <accn>         # Compare transcript_ids \n";
	print "         geo -h                          # Help message\n";
	print "\n";
}

