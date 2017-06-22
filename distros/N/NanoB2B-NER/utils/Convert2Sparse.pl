#!/bin/perl

use File::Path qw(make_path);			#makes sub directories	

my $fileDir;
my $features;
my $buckets;
my @bucketList;
my @types = qw( train test );

sub main{
	#get the inputs
	print "Directory: ";
	chomp($fileDir = <STDIN>);
	print "Index or File: ";
	chomp(my $fileIndex = <STDIN>);
	print "Features [abbreviation]: ";
	chomp($features = <STDIN>);
	print "Buckets: ";
	chomp($buckets = <STDIN>);
	@bucketList = (1..$buckets);

	#open the directory	 
	opendir (DIR, $fileDir) or die $!;							
	my @tags = grep { $_ ne '.' and $_ ne '..' and substr($_, 0, 1) ne '_'} readdir DIR;	#get each file from the directory

	#ner the files
	my $totalTags = @tags;
	if($fileIndex =~/\b[0-9]+\b/){		#is a number
		for(my $a = $fileIndex; $a < $totalTags; $a++){
			my $b = $a+1;
			printColorDebug("on_blue", "FILE #$b / $totalTags");
			my $tag = $tags[$a];
			sparseMaker($tag);
			printColorDebug("on_blue", "##         FINISHED #$b - $tag!        ##");
		}
	}else{
		sparseMaker($fileIndex);
	}
	
}

#create a new sparse matrix arff file
sub sparseMaker{
	my $file = shift;

	#get the name of the file
	my @n = split '/', $file;
	my $l = @n;
	my $filename = $n[$l - 1];
	$filename = lc($filename);

	#iterate through each arff file based on feature, type, and bucket #
	my $abbrev = "_";
	for(my $a=0;$a<length($features);$a++){
		$abbrev .= substr($features, $a, 1);
		foreach my $type (@types){
			foreach my $b(@bucketList){
				#import the lines
				my $name = "$fileDir/_ARFF/$filename" . "_ARFF/$abbrev/_$type/$filename_$type-$b.arff";
				open (my $FILE, $name) || die ("Cannot find $name\n");
				my @lines = <$FILE>;
				foreach my $line(@lines){chomp($line)};
				my $len = @lines;
				$uniSub->printColorDebug("on_red", "$filename");

				#get everything around @DATA
				my $dataIndex = getIndexofLine("\@DATA", \@lines);
				my @dataSet = @lines[$dataIndex..$len];
				my @attrSet = @lines[0..$dataIndex];

				#convert the set
				my @sparseSet = ();
				foreach my $vec(@dataSet){
					push(@sparseSet, convert2Sparse($vec));
				}

				#create a new file
				my $sparsePath = "$filename" . "_ARFF/$abbrev/_$type/";
				make_path("$fileDir/_SPARSE_ARFF/$sparsePath/");
				open(my $SPARSE_FILE, "$fileDir/_SPARSE_ARFF/$sparsePath/$filename_$type-$b.arff")  || die "lol no way";
				
				#print the contents
				foreach my $a(@attrSet){
					print $SPARSE_FILE "$a\n";
				}
				foreach my $d(@sparseSet){
					print $SPARSE_FILE "$d\n";
				}

				#close everything
				close $FILE;
				close $SPARSE_FILE;
			}
		}
	}

	
}


#converts a binary vector to a sparse vector
sub convert2Sparse{
	my $bin_vec = shift;
	my @vals = split(",", $bin_vec);
	my $numVals = @vals;

	my $sparse_vec = "{";
	for(my $c=0;$c<$numVals-1;$c++){
		my $curVal = $vals[$c];
		if($curVal eq "1"){
			$sparse_vec .= "$c" . "$curVal, ";
		}
	}
	$sparse_vec .= "$numVals, ";
	$sparse_vec .= $vals[$numVals-1];
	$sparse_vec .= "}";

	return $sparse_vec;
}

#gets the line's index
# input  : $keyword <-- the regex to use to search for the specific line
#		   @lines   <-- the set of lines to look through
# output : $a  		<-- return the index of the line based on the regex; returns -1 if not found
sub getIndexofLine{
	my $keyword = shift;
	my $lines_ref = shift;
	my @lines = @$lines_ref;

	my $len = @lines;
	for(my $a = 0; $a < $len; $a++){
		my $line = $lines[$a];
		if ($line =~ /($keyword)/){
			return $a;
		}
	}	
	return -1;
}