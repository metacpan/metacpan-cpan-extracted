#!/usr/bin/perl
# NanoB2B-NER::NER::Arffman
#
# Creates ARFF files from annotated files
# Version 1.5
#
# Program by Milk

package NanoB2B::NER::Arffman;

use NanoB2B::UniversalRoutines;
use MetaMap::DataStructures;
use File::Path qw(make_path);			#makes sub directories	
use List::MoreUtils qw(uniq);

use strict;
use warnings;

#option variables
my $debug = 1;
my $program_dir = "";
my $fileIndex = 0;
my $stopwords_file;
my $prefix = 3;
my $suffix = 3;
my $bucketsNum = 10;
my $is_cui = 0;
my $sparse_matrix = 0;
my $wcs = "";

#datastructure object
my %params = ();
my $dataStructures = MetaMap::DataStructures->new(\%params); 

#universal subroutines object
my %uniParams = ();
my $uniSub;

#other general global variables
my @allBuckets;
my %fileHash;
my %metamapHash;
my %tokenHash;
my %conceptHash;
my %posHash;
my %semHash;
my %cuiHash;
my %orthoHash;
my @features;
my $selfId = "_self";
my $entId = "_e";
my $morphID = "_m";

my $stopRegex;

####      A HERO IS BORN     ####

# construction method to create a new Arffman object
# input  : $directory     <-- the name of the directory for the files
#		   $name 		  <-- name of the file to examine
#		   $features      <-- the list of features to use [e.g. "ortho morph text pos cui sem"]
#		   $bucketsNum    <-- the number of buckets to use for k-fold cross validation
#		   \$debug         <-- run the program with debug print statements
#		   \$prefix        <-- the number of letters to look at the beginning of each word
#		   \$suffix        <-- the number of letters to look at the end of each word
#		   \$index         <-- the index to start metamapping from in the set of files
#		   \$no_stopwords  <-- exclude examining stop words [imported from the stop word list]
# output : $self          <-- an instance of the Arffman object
sub new {
    #grab class and parameters
    my $self = {};
    my $class = shift;
    return undef if(ref $class);
    my $params = shift;

    #reset all arrays and hashes
    @allBuckets = ();
	%fileHash = ();
	%metamapHash = ();
	%tokenHash = ();
	%conceptHash = ();
	%posHash = ();
	%semHash = ();
	%cuiHash = ();
	%orthoHash = ();
	@features = ();

    #bless this object
    bless $self, $class;
    $self->_init($params);
    @allBuckets = (1..$bucketsNum);

    #retrieve parameters for universal-routines
    $uniParams{'debug'} = $debug;
	$uniSub = NanoB2B::UniversalRoutines->new(\%uniParams);

	#return the object
    return $self;
}

#  method to initialize the NanoB2B::NER::Arffman object.
#  input : $parameters <- reference to a hash
#  output: 
sub _init {
    my $self = shift;
    my $params = shift;

    $params = {} if(!defined $params);

    #  get some of the parameters
    my $diroption = $params->{'directory'};
	my $ftsoption = $params->{'features'};
	my $bucketsNumoption = $params->{'bucketsNum'};
    my $debugoption = $params->{'debug'};
	my $prefixoption = $params->{'prefix'};
	my $suffixoption = $params->{'suffix'};
    my $indexoption = $params->{'index'};
    my $stopwordoption = $params->{'stopwords'};
    my $iscuioption = $params->{'is_cui'};
    my $sparsematrixoption = $params->{'sparse_matrix'};
    my $wcsoption = $params->{'wcs'};

    #set the global variables
    if(defined $debugoption){$debug = $debugoption;}
    if(defined $diroption){$program_dir = $diroption;}
    if(defined $indexoption){$fileIndex = $indexoption;}
    if(defined $stopwordoption){$stopwords_file = $stopwordoption;}
    if(defined $iscuioption){$is_cui = $iscuioption;}
    if(defined $sparsematrixoption){$sparse_matrix = $sparsematrixoption;}
    if(defined $prefixoption){$prefix = $prefixoption;}
    if(defined $suffixoption){$suffix = $suffixoption;}
    if(defined $wcsoption){$wcs = $wcsoption;}
    if(defined $bucketsNumoption){$bucketsNum = $bucketsNumoption;}
    if(defined $ftsoption){@features = split(' ', $ftsoption);}
}


#######		ARFFMAN AND THE METHODS OF MADNESS		#####


# opens a single file and runs it through the process of creating buckets
# extracting tokens and concepts, and creating arff files based on the features given
# input  : $file <-- the name of the file to make into arff files
# output : a set of arff files
sub arff_file{
	my $self = shift;
	my $file = shift;

	#define and reset temp var
	my $indexer = 0;
	%fileHash = ();
	%metamapHash = ();
	%tokenHash = ();
	%conceptHash = ();
	%posHash = ();
	%semHash = ();
	%cuiHash = ();

	#get the name of the file
	my @n = split '/', $file;
	my $l = @n;
	my $filename = $n[$l - 1];
	$filename = lc($filename);

	my $FILE;
	open ($FILE, "$program_dir/$file") || die ("what is this '$program_dir/$filename' you speak of?\n");
	my @fileLines = <$FILE>;
	my @orthoLines = @fileLines;
	#my @orthoLines = ["Hi! I'm Milk", "I have a hamster named Scott", "I like pizza"];
	foreach my $l(@fileLines){
		$l = lc($l);
	}
	$uniSub->printColorDebug("on_red", "$filename");
	#$uniSub->printColorDebug("on_cyan", "*** $wcs ***");

	#get the total num of lines
	my $totalLines = 0;
	$totalLines = @fileLines;
	$uniSub->printColorDebug("red", "Lines: $totalLines\n");

	#clean it up for two separate sets
	my @tagSet = retagSet($filename, \@fileLines);
	my @cleanLines = untagSet($filename, \@fileLines);

	#get the orthographic based lines
	#my @orthoLines = <FILE>;
	@orthoLines = retagSetOrtho(\@orthoLines);

	#$uniSub->printColorDebug("red", "TAG SET: ");
	#$uniSub->printArr(", ", \@tagSet);

	#######     ASSIGN THE VALUES TO HASHTABLES O KEEP TRACK OF THEM    #######

	#put all the lines in a file hash
	$uniSub->printColorDebug("blue", "*Putting all the file lines into a hashtable....\n");
	$indexer = 0;
	foreach my $line (@tagSet){
		$fileHash{$indexer} = $line;
		$indexer++;
	}

	#put the orthographic lines in a hash
	$indexer = 0;
	foreach my $line (@orthoLines){
		#$uniSub->printColorDebug("red", "$line\n");
		$orthoHash{$indexer} = $line;
		$indexer++;
	}

	#import the hashtables from saved data
	importMetaData($filename);

	#tokenize all the lines --> tokenhash
	$uniSub->printColorDebug("blue", "*Tokenizing the lines into a hashtable....\n");
	$indexer = 0;
	my $totalTokens = 0;
	my $totalConcepts = 0;
	foreach my $line (@cleanLines){
		#acquire the necessary variables
		my $special_ID = "$indexer.ti.1";
		my $meta = $metamapHash{$indexer};

		#create citation first
		$dataStructures->createFromTextWithId($meta, $special_ID);
		my $citation = $dataStructures->getCitationWithId($special_ID);

		#get tokens
		my @tokensOut = $citation->getOrderedTokens();
		#double array - extract the inner one
		my @tokens = ();
		foreach my $tt (@tokensOut){
			my @newSet = @$tt;
			push (@tokens, @newSet);
		}
		my $tnum = @tokens;
		$totalTokens += $tnum;
		push (@{$tokenHash{$indexer}}, @tokens);

		#get concepts
		my @conceptsOut = $citation->getOrderedConcepts();
		#double array - extract the inner one
		my @concepts = ();
		foreach my $cc (@conceptsOut){
			my @newSet = @$cc;
			push (@concepts, @newSet);
		}
		my $cnum = @concepts;
		$totalConcepts += $cnum;
		push (@{$conceptHash{$indexer}}, @concepts);

		#create the ordered POS lines
		my @posOrder = orderedTokenPOS($cleanLines[$indexer], \@tokens);
		my $posOrderLine = join " ", @posOrder;
		$posHash{$indexer} = $posOrderLine;

		#create the ordered semantic type lines
		my @semantics = getConceptSets("sem", $line, \@concepts);
		my $semanticsLine = join " ", @semantics;
		$semHash{$indexer} = $semanticsLine;
		
		#create the ordered cui lines
		my @cuis = getConceptSets("cui", $line, \@concepts);
		my $cuiLine = join " ", @cuis;
		$cuiHash{$indexer} = $cuiLine;


		#increment to the next set
		$indexer++;
	}
	$uniSub->printColorDebug("red", "TOKENS: $totalTokens\n");
	$uniSub->printColorDebug("red", "CONCEPTS: $totalConcepts\n");

	
	#######           BUCKET SORTING - TRAIN AND TEST DATA            #######

	#sort the lines to buckets
	$uniSub->printColorDebug("blue", "*Making buckets....\n");
	my %buckets = ();
	%buckets = sort2Buckets($totalLines, $bucketsNum);

	$uniSub->printColorDebug("blue", "*Making train and test files....\n");

	zhu_li($filename, \%buckets);

	$uniSub->printDebug("\n");

}



######################              LINE MANIPULATION               #####################

######    RETAGS THE LINE    ######

# turns the tagged entity words into special words with <> for the context words
# input  : $input <-- the line to retag
#		   $id    <-- the id within the tag to look for
# output : (.arff files)
sub retag{
	my $input = shift;
	my $id = shift;

	$id = lc($id);
	my $line = lc($input);

	#get rid of any tags
	my @words = split (" ", $line);
	my @newSet = ();
	my $charact = 0;
	foreach my $word (@words){
		if($charact){
			if($word eq "<end>"){
				$charact = 0;
			}else{
				my $charWord = "$word"."$entId"; 
				push @newSet, $charWord;
			}
		}else{
			if($word eq "<start:$id>"){
				$charact = 1;
			}else{
				push @newSet, $word;
			}
		}
	}

	#clean up the new line
	my $new_line = join " ", @newSet;
	$new_line =~s/\b$entId\b//g;
	$new_line = $uniSub->cleanWords($new_line);
	return $new_line;
}

# turns the tagged entity words in the entire file into special words with <> for the context words
# input  : $name  <-- the name of the file to use as the id tag
#		   @lines   <-- the set of lines to retag
# output : @tagSet <-- set of retagged lines
sub retagSet{
	my $name = shift;
	my $lines_ref = shift;
	my @lines = @$lines_ref;

	my @tagSet = ();
	foreach my $line (@lines){
		#retag the line
		chomp($line);
		my $tag_line = retag($line, $name);

		#add it to the set
		push @tagSet, $tag_line;
	}
	return @tagSet;
}

#returns clean line with no tags or retaggings
# input  : $line <-- the line to untag
# 	     : $id   <-- the id label to look for
# output : $input <-- untagged input line
sub untag{
	my $line = shift;
	my $id = shift;

	my $input = lc($line);
	$id = lc($id);
	$input =~ s/ <start:$id>//g;
	$input =~ s/ <end>//g;
	$input = $uniSub->cleanWords($input);
	return $input;
}
#returns a clean set of lines
# input  : $filename <-- the name of the file for use in the id tag
#		 : @lines    <-- the set of lines to untag
# output : @clean_set  <-- untagged set of lines
sub untagSet{
	my $filename = shift;
	my $lines_ref = shift;
	my @lines = @$lines_ref;

	my @clean_set = ();
	foreach my $line(@lines){
		my $cl = untag($line, $filename);
		push @clean_set, $cl;
	}
	return @clean_set;
}


#import metamap hashtable data
# input  : $name  <-- the name of the file to import from
# output : (hashmap of metamap lines)
sub importMetaData{
	my $name = shift;

	#create a directory to save hashtable data
	my $META;
	my $subdir = "_METAMAPS";
	open($META, "<", ("$program_dir/$subdir/" . $name . "_meta")) || die ("HAHA No such thing!");
	

	#import metamap data from the file
	my @metaLines = <$META>;
	my $metaCombo = join("", @metaLines);
	my @newMetaLines = split("\n\n", $metaCombo);
	my $t = @newMetaLines;
	$uniSub->printColorDebug("red", "META LINES: $t\n");
	my $key = 0;
	foreach my $mm (@newMetaLines){
		$metamapHash{$key} = $mm;
		$key++;
	}
	close $META;
}

#####     FOR THE ORTHO SET     #####

#turns the tagged entity words into special words with <> for the context words
# input  : $input  <-- the line to retag 
# output : $new_line <-- the retagged line
sub retagOrtho{
	my $input = shift;
	my $line = $input;

	#get rid of any tags
	my @words = split (" ", $line);
	my @newSet = ();
	my $charact = 0;
	foreach my $word (@words){
		if($charact){
			if($word =~/<END>/){
				$charact = 0;
			}else{
				my $charWord = "$word"."$entId"; 
				push @newSet, $charWord;
			}
		}else{
			if($word =~/<START:[a-zA-Z-_]*>/g){
				$charact = 1;
			}else{
				push @newSet, $word;
			}
		}
	}

	#clean up the new line
	my $new_line = join " ", @newSet;
	$new_line =~s/\b$entId\b//g;
	$new_line = noASCIIOrtho($new_line);
	return $new_line;
}
#turns the tagged entity words in the entire file into special words with <> for the context words
# input  : @lines  <-- the set of lines to retag
# output : @tagSet <-- the retagged line
sub retagSetOrtho{
	my $lines_ref = shift;
	my @lines = @$lines_ref;

	my @tagSet = ();
	foreach my $line (@lines){
		#retag the line
		chomp($line);
		my $tag_line = retagOrtho($line);

		#add it to the set
		push @tagSet, $tag_line;
	}
	return @tagSet;
}

#cleans the line without getting rid of tags
# input  : $line     <-- line to clean up
# output : $new_in   <-- the cleaned line
sub noASCIIOrtho{
	my $line = shift;

	my $new_in = $line;
	$new_in =~ s/[^[:ascii:]]//g;
	return $new_in
}


#######################      TOKENS AND CONCEPT MANIPULATION       #######################   


#gets rid of any special tokens
# input  : $text     <-- the token text to fix
# output : $tokenText <-- a cleaned up token
sub cleanToken{
	my $text = shift;

	my $tokenText = $text;

	#fix "# . #" tokens
	if($tokenText =~ /\d+\s\.\s\d+/){
		$tokenText =~s/\s\.\s/\./g;
	}

	#fix "__ \' __" tokens
	if($tokenText =~ /\w+\s\\\'\s\w+/){
		$tokenText =~s/\s\\\'\s//g;
	}

	if($tokenText =~ /[^a-zA-Z0-9]/){
		$tokenText = "";
	}

	return $tokenText;
}

#grabs the part-of-speech part of the token that's matched up with the bucket tokens
# input  : @buktTokens     <-- the set of tokens from the specific bucket[s]
# output : @posTokens 	   <-- the part-of-speech tokens for the bucket
sub getTokensPOS{
	my $bucketTokens_ref = shift;
	my @buktTokens = @$bucketTokens_ref;

	#finds the part of speech tokens
	my @posTokens = ();
	foreach my $token (@buktTokens){
		my $pos = $token->{posTag};
		push(@posTokens, $pos);
	}
	return @posTokens;
}

#gets the positions of the POS words from a line
# input  : $cleanLine     <-- the line to pinpoint the POS tokens to
#		 : @tokens        <-- the set of tokens to use are reference
# output : @orderPOS 	   <-- the part-of-speech tokens for the bucket
sub orderedTokenPOS{
	my $cleanLine = shift;
	my $tokens_ref = shift;
	my @tokens = @$tokens_ref;

	#$uniSub->printColorDebug("on_red", "TAG : $tagLine\n");
	my @lineWords = split " ", $cleanLine;
	my @orderPOS = ();

	#make the connection between the word and the pos
	my %text2Pos = ();
	my @txtTokens = ();
	foreach my $token (@tokens){
		my $txt = $token->{text};
		$txt = cleanToken($txt);
		#$uniSub->printColorDebug("on_green", $txt);
		push @txtTokens, $txt;
		my $pos = $token->{posTag};
		$text2Pos{$txt} = $pos;
	}

	#associate each tagged word with it
	foreach my $word (@lineWords){
		if($uniSub->inArr($word, \@txtTokens)){
			my $newPos = $text2Pos{$word};
			push @orderPOS, $newPos;
		}else{
			push @orderPOS, "undef";
		}
	}

	return @orderPOS;
}

#gets the tagged parts of the concepts
# input  : $type     	<-- what kind of concepts you want to extract [e.g. "sem", "cui"]
#		 : $line        <-- the line to pinpoint the concepts to
#		 : @concepts    <-- the total set of concepts to use
# output : @conceptSet 	   <-- the set of concepts used within the line
sub getConceptSets{
	my $type = shift;
	my $line = shift;
	my $concepts_ref = shift;
	my @concepts = @$concepts_ref;

	$line = lc($line);

	#assign each concept by their text name
	my @conceptsTxt = ();
	foreach my $concept (@concepts){
		my $ohboi = @$concept[0];
		my $name = lc($ohboi->{text});
		push (@conceptsTxt, $name);
	}

	#make a clean set of text words
	my @txtIn = split / /, $line;
	my @clean_txt = ();
	foreach my $word (@txtIn){
		push @clean_txt, $word;
	}

	my $totCon = @conceptsTxt;
	#get the set needed
	my @conceptSet = ();
	for(my $f = 0; $f < $totCon; $f++){
		my @concept = @{$concepts[$f]};
		my $txtCon = $conceptsTxt[$f];

		
		foreach my $cc (@concept){

			#get the right items
			my @items = ();
			if($type eq "sem"){
				my $s = $cc->{semanticTypes};
				@items = split /,/, $s;
			}elsif($type eq "cui"){
				my $c = $cc->{cui};
				@items = split /,/, $c;
			}elsif($type eq "text"){
				my $t = $cc->{text};
				@items = split /,/, $t;
			}
			
			#add to the concept set
			push @conceptSet, @items;
		}
	}
	return @conceptSet;
}


#retrieves the feature for a single word
# input  : $word     	<-- the word to extract the features from
#		 : $type        <-- what type of feature to extract [e.g. "pos", "sem", "cui"]
# output : if "pos"		<-- a scalar part-of-speech value
#		 : else			<-- an array of semantic or cui values (a single text value can have more than one of these)
sub getFeature{
	my $word = shift;
	my $type = shift;

	#if retrieving pos tag
	if($type eq "pos"){
		#get the token and it's pos tag
		foreach my $key (sort keys %tokenHash){
			my @tokens = @{$tokenHash{$key}};
			foreach my $token(@tokens){
				my $tokenTxt = $token->{text};
				if($tokenTxt eq $word){
					return $token->{posTag};
				}
			}
		}
		return "";
	}elsif($type eq "sem" or $type eq "cui"){
		#get the concept and it's cui or sem tag
		foreach my $key (sort keys %conceptHash){
			my @concepts = @{$conceptHash{$key}};
			foreach my $concept (@concepts){
				my $ohboi = @$concept[0];
				my $name = lc($ohboi->{text});
				if($name eq $word){
					if($type eq "sem"){
						my @semArr = ();
						foreach my $cc (@$concept){push(@semArr, $cc->{semanticTypes});}
						return @semArr;
					}elsif($type eq "cui"){
						my @cuiArr = ();
						foreach my $cc (@$concept){push(@cuiArr, $cc->{cui});}
						return @cuiArr;
					}
				}
			}
		}
		return "";
	}
	return "";
}

######################      BUCKETS - TRAIN AND TEST ARFF FILES     #####################


#sorts the keys from the hashmaps into buckets so that certain values can be accessed
# input  : $keyAmt     	    <-- the number of lines or "keys" to divvy up into the buckets
#		 : $bucketNum       <-- how many buckets to use
# output : %bucketList		<-- the set of buckets with keys in them
sub sort2Buckets{
	my $keyAmt = shift;
	my $bucketNum = shift;

	#create sets 	
	my @keySet = (0..$keyAmt - 1);						#set of keys
	my %bucketList = ();							#all of the buckets

	#add some buckets to the bucket list
	 for(my $a = 1; $a <= $bucketNum; $a++){
	 	$bucketList{$a} = [];
	 }

	 #sort the lines into buckets
	 my $bucketId = 1;
	 foreach my $key (@keySet){
	 	push (@{$bucketList{$bucketId}}, $key);	#add the line to the bucket

	 	#reset the id if at the max value
	 	if($bucketId == $bucketNum){
	 		$bucketId = 1;
	 	}else{
	 		$bucketId++;
	 	}
	 }

	 #return the list of buckets
	 return %bucketList;
}

######################               ARFF STUFF              #####################
	 #makes arff files for ortho, morpho, text, pos, cui, and sem attributes

#zhu li!! Do the thing!!
# input  : $name     	    <-- the name of the file
#		 : %bucketList       <-- the set of buckets with keys in them
# output : (n arff files; n = # of buckets x (train and test) x # of features being used)
sub zhu_li{
	my $name = shift;
	my $bucketList_ref = shift;
	my %buckets = %$bucketList_ref;

	#grab the attributes
	my %attrSets = ();
	$uniSub->printColorDebug("bold green", "Retrieving attributes...\n");
	foreach my $item(@features){
		$uniSub->printColorDebug("bright_green", "\t$item attr\n");
		my %setOfAttr = grabAttr($name, $item, \%buckets);
		$attrSets{$item} = \%setOfAttr;						#gets both the vector and arff based attributes
	}

	if(defined $stopwords_file){
		$stopRegex = stop($stopwords_file);
	}

	#let's make some vectors!
	$uniSub->printColorDebug("bold yellow", "Making Vectors...\n-------------------\n");
	my @curFeatSet = ();
	my $abbrev = "";

	#run based on wcs
	my $wcs_bucket;
	my $wcs_feature;
	my $wcs_found = 0;
	if($wcs){
		my @wcs_parts = split("-", $wcs);
		$wcs_feature = $wcs_parts[1];
		$wcs_bucket = $wcs_parts[0];
	}


	#iteratively add on the features [e.g. o, om, omt, omtp, omtpc, omtpcs]
	foreach my $feature (@features){
		$uniSub->printColorDebug("yellow", "** $feature ** \n");
		push(@curFeatSet, $feature);
		$abbrev .= substr($feature, 0, 1);		#add to abbreviations for the name

		#$uniSub->printColorDebug("on_red", "$wcs - $wcs_found - $abbrev vs. $wcs_feature");
		if(($wcs) && (!$wcs_found) && ($abbrev ne $wcs_feature)){
			print("**SKIP** \n");
			next;
		}

		#go through each bucket
		foreach my $bucket (sort keys %buckets){
			if(($wcs) && (!$wcs_found) && ($bucket != $wcs_bucket)){
				print("\t**SKIP**\n");
				next;
			}else{
				$wcs_found = 1;
			}

			my @range = $uniSub->bully($bucketsNum, $bucket);

			$uniSub->printColorDebug("on_green", "BUCKET #$bucket");
			#retrieve the vector attributes to use
			my %vecAttrSet = ();
			foreach my $curItem(@curFeatSet){
				if($curItem eq "ortho"){
					$vecAttrSet{$curItem} = ();
				}else{
					#get outer layer (tpcs)
					my $a_ref = $attrSets{$curItem};
					my %a = %$a_ref;

					#get inner layer (vector)
					my $b_ref = $a{vector};
					my %b = %$b_ref;

					#foreach my $key (sort keys %b){print "$key\n";}

					#finally get the bucket layer (1..$bucketNum) based on range
					my $c_ref = $b{$bucket};
					my @c = @$c_ref;
					$vecAttrSet{$curItem} = \@c;
				}
			}

			### TRAIN ###
			$uniSub->printColorDebug("bold blue", "\ttraining...\n");
			#retrieve the lines to use
			my @lineSetTrain = ();
			my @bucketSetTrain = ();
			foreach my $num (@range){push(@bucketSetTrain, @{$buckets{$num}});}
			foreach my $key (@bucketSetTrain){push(@lineSetTrain, $orthoHash{$key});}

			#make the vector
			my @vectorSetTrain = vectorMaker(\@lineSetTrain, \@curFeatSet, \%vecAttrSet);
			$uniSub->printDebug("\n");

			### TEST ###
			$uniSub->printColorDebug("bold magenta", "\ttesting...\n");
			#retrieve the lines to use
			my @lineSetTest = ();
			my @bucketSetTest = ();
			push(@bucketSetTest, @{$buckets{$bucket}});
			foreach my $key (@bucketSetTest){push(@lineSetTest, $orthoHash{$key});}

			#make the vector
			my @vectorSetTest = vectorMaker(\@lineSetTest, \@curFeatSet, \%vecAttrSet);
			$uniSub->printDebug("\n");

			### ARFF ###
			#retrieve the arff attributes to use
			my @arffAttrSet = ();
			foreach my $curItem(@curFeatSet){
				if($curItem eq "ortho"){
					#get outer layer (ortho)
					my $a_ref = $attrSets{$curItem};
					my %a = %$a_ref;
					#get the values from ortho
					push(@arffAttrSet, @{$a{arff}});
				}else{
					#get outer layer (mtpcs)
					my $a_ref = $attrSets{$curItem};
					my %a = %$a_ref;

					#get inner layer (arff)
					my $b_ref = $a{arff};
					my %b = %$b_ref;

					#finally get the bucket layer (1..$bucketNum) based on range
					my $c_ref = $b{$bucket};
					my @c = @$c_ref;
					push(@arffAttrSet, @c);
				}
			}


			$uniSub->printColorDebug("bright_yellow", "\tmaking arff files...\n");
			$uniSub->printColorDebug("bright_red", "\t\tARFF TRAIN\n");
			createARFF($name, $bucket, $abbrev, "train", \@arffAttrSet, \@vectorSetTrain);
			$uniSub->printColorDebug("bright_red", "\t\tARFF TEST\n");
			createARFF($name, $bucket, $abbrev, "test", \@arffAttrSet, \@vectorSetTest);
		}
	}

}

#create the arff file
# input  : $name     	    <-- the name of the file
#		 : $bucket   		<-- the index of the bucket you're testing [e.g. bucket #1]
#        : $abbrev          <-- the abbreviation label for the set of features
#        : $type            <-- train or test ARFF?
#        : @attrARFFSet     <-- the set of attributes exclusively for printing to the arff file
#		 : @vecSec          <-- the set of vectors created
# output : (an arff file)
sub createARFF{
	my $name = shift;
	my $bucket = shift;
	my $abbrev = shift;
	my $type = shift;
	my $attr_ref = shift;
	my $vec_ref = shift;

	my $typeDir = "_$type";
	my $ARFF;
	#print to files
	$uniSub->printColorDebug("bold cyan", "\t\tcreating $name/$abbrev - BUCKET #$bucket $type ARFF...\n");
	if($program_dir ne ""){
		my $subdir = "_ARFF";
		my $arffdir = $name . "_ARFF";
		my $featdir = "_$abbrev";
		make_path("$program_dir/$subdir/$arffdir/$featdir/$typeDir");
		open($ARFF, ">", ("$program_dir/$subdir/$arffdir/$featdir/$typeDir/" . $name . "_$type-" . $bucket .".arff")) || die ("OMG?!?!");
	}else{
		my $arffdir = $name . "_ARFF";
		my $featdir = "_$abbrev";
		make_path("$arffdir/$featdir/$typeDir");
		open($ARFF, ">", ("$arffdir/$featdir/$typeDir/" . $name . "_$type-" . $bucket .".arff")) || die ("What?!?!");
	}

	#get the attr and vector set
	my @attrARFFSet = @$attr_ref;
	my @vecSet = @$vec_ref;
	
	#get format for the file
	my $relation = "\@RELATION $name";	
	my @printAttr = makeAttrData(\@attrARFFSet);	
	my $entity = "\@ATTRIBUTE Entity {Yes, No}";	#set if the entity word or not
	my $data = "\@DATA";

	#print everything to the file
	$uniSub->printDebug("\t\tprinting to file...\n");
	$uniSub->print2File($ARFF, $relation);
	foreach my $a(@printAttr){$uniSub->print2File($ARFF, $a);}
	$uniSub->print2File($ARFF, $entity);
	$uniSub->print2File($ARFF, $data);
	foreach my $d(@vecSet){$uniSub->print2File($ARFF, $d);}
	close $ARFF;
}

######################               VECTOR THINGIES              #####################


#makes vectors from a set
# input  : @txtLineSet 		<-- the retagged text lines to make vectors out of
#		 : @featureList		<-- the list of features to make the vectors out of [e.g. (ortho, morph, text)]
#		 : @attrs  			<-- the attributes to use to make the vectors
# output : @setVectors		<-- the vectors for each word in all of the lines
sub vectorMaker{
	my $set_ref = shift;
	my $feat_ref = shift;
	my $attrib_ref = shift;
	my @txtLineSet = @$set_ref;
	my @featureList = @$feat_ref;
	my %attrs = %$attrib_ref;

	my @setVectors = ();
	#go through each line of the set
	my $setLen = @txtLineSet;

	for(my $l = 0; $l < $setLen; $l++){
		my $line = $txtLineSet[$l];
		my @words = split(' ', $line);
		#$uniSub->printArr(", ", \@words);
		#print "\n";
		my $wordLen = @words;
		#go through each word
		for(my $a = 0; $a < $wordLen; $a++){

			$| = 1;

			#make the words for comparison
			my $word = $words[$a];
			my $prevWord = "";
			my $nextWord = "";

			#show progress
			my $l2 = $l + 1; 
			my $a2 = $a + 1;
			$uniSub->printDebug("\r" . "\t\tLine - $l2/$setLen ------ Word - $a2/$wordLen  ----  ");
			
			my $smlword = substr($word, 0, 8);
			if(length($word) > 8){
				$smlword .= "...";
			}
			
			if($word =~/$entId/){
				$uniSub->printColorDebug("red", "$smlword!                ");
			}else{
				$uniSub->printDebug("$smlword!                    ")
			}

			my @word_cuis = getFeature($word, "cui");
			my $ncui = $word_cuis[0];
			#$uniSub->printColorDebug("red", "\n\t\t$word - $ncui\n");

			#check if it's a stopword
			if(($stopwords_file and $word=~/$stopRegex/o) || ($is_cui and $word_cuis[0] eq "") || ($word eq "." || $word eq ",")){
				#$uniSub->printColorDebug("on_red", "\t\tSKIP!");
				next;
			}

			if($a > 0){$prevWord = $words[$a - 1];}
			if($a < ($wordLen - 1)){$nextWord = $words[$a + 1];}

			

			#get rid of tag if necessary
			$prevWord =~s/$entId//g;
			$nextWord =~s/$entId//g;
			$word =~s/$entId//g;

			my $vec = "";
			#use each set of attributes
			foreach my $item(@featureList){
				my $addVec = "";
				if($item eq "ortho"){$addVec = orthoVec($word);}
				elsif($item eq "morph"){$addVec = morphVec($word, \@{$attrs{"morph"}});}
				elsif($item eq "text"){$addVec = textVec($word, $prevWord, $nextWord, \@{$attrs{"text"}});}
				elsif($item eq "pos"){$addVec = posVec($word, $prevWord, $nextWord, \@{$attrs{"pos"}});}
				elsif($item eq "cui"){$addVec = cuiVec($word, $prevWord, $nextWord, \@{$attrs{"cui"}});}
				elsif($item eq "sem"){$addVec = semVec($word, $prevWord, $nextWord, \@{$attrs{"sem"}});}
				

				$vec .= $addVec;

			}

			#convert binary to sparse if specified
			if($sparse_matrix){
				$vec = convert2Sparse($vec);
			}

			#check if the word is an entity or not
			my $wordOrig = $words[$a];	
			$vec .= (($wordOrig =~/([\s\S]*($entId)$)/) ? "Yes " : "No ");

			#close it if using sparse matrix
			if($sparse_matrix){
				$vec .= "}";
			}

			#finally add the word back and add the entire vector to the set
			$vec .= "\%$word";

			if($word ne ""){
				push(@setVectors, $vec);
			}
		}
	}

	return @setVectors;
}

#makes the orthographic based part of the vector
# input  : $word     	    <-- the word to analyze
# output : $strVec			<-- the orthographic vector string
sub orthoVec{
	my $word = shift;

	##  CHECKS  ##
	my $strVec = "";
	my $addon = "";

	#check if first letter capital
	$addon = ($word =~ /\b([A-Z])\w+\b/g ? 1 : 0);
	$strVec .= "$addon, ";

	#check if a single letter word
	$addon = (length($word) == 1 ? 1 : 0);
	$strVec .= "$addon, ";

	#check if all capital letters
	$addon = ($word =~ /\b[A-Z]+\b/g ? 1 : 0);
	$strVec .= "$addon, ";

	#check if contains a digit
	$addon = ($word =~ /[0-9]+/g ? 1 : 0);
	$strVec .= "$addon, ";

	#check if all digits
	$addon = ($word =~ /\b[0-9]+\b/g ? 1 : 0);
	$strVec .= "$addon, ";

	#check if contains a hyphen
	$addon = ($word =~ /-/g ? 1 : 0);
	$strVec .= "$addon, ";

	#check if contains punctuation
	$addon = ($word =~ /[^a-zA-Z0-9\s]/g ? 1 : 0);
	$strVec .= "$addon, ";

	return $strVec;
}

#makes the morphological based part of the vector
# input  : $word     	    <-- the word to analyze
#		 : @attrs 			<-- the set of morphological attributes to use
# output : $strVec			<-- the morphological vector string
sub morphVec{
	my $word = shift;
	my $attrs_ref = shift;
	my @attrs = @$attrs_ref;

	my $strVec = "";

	my $preWord = substr($word, 0, $prefix);
	my $sufWord = substr($word, -$suffix);

	foreach my $a (@attrs){
		if($a eq $preWord){
			$strVec .= "1, ";
		}elsif($a eq $sufWord){
			$strVec .= "1, ";
		}else{
			$strVec .= "0, ";
		}
	}

	return $strVec;

}

#makes the text based part of the vector
# input  : $w     	    	<-- the word to analyze
#        : $pw     	    	<-- the previous word
#        : $nw     	    	<-- the next word
#		 : @attrbts 		<-- the set of text attributes to use
# output : $strVec			<-- the text vector string
sub textVec{
	my $w = shift;
	my $pw = shift;
	my $nw = shift;
	my $at_ref = shift;
	my @attrbts = @$at_ref;

	my $strVec = "";

	#clean the words
	$w = $uniSub->cleanWords($w);
	$pw = $uniSub->cleanWords($pw);
	$nw = $uniSub->cleanWords($nw);

	#check if the word is the attribute or the words adjacent it are the attribute
	foreach my $a(@attrbts){
		
		my $pair = "";
		$pair .= ($w eq $a ? "1, " : "0, ");	
		$pair .= (($pw eq $a or $nw eq $a) ? "1, " : "0, ");
		$strVec .= $pair;
	}

	return $strVec;
}

#makes the part of speech based part of the vector
# input  : $w     	    	<-- the word to analyze
#        : $pw     	    	<-- the previous word
#        : $nw     	    	<-- the next word
#		 : @attrbts 		<-- the set of pos attributes to use
# output : $strVec			<-- the pos vector string
sub posVec{
	my $w = shift;
	my $pw = shift;
	my $nw = shift;
	my $at_ref = shift;
	my @attrbts = @$at_ref;

	#clean the words
	$w = $uniSub->cleanWords($w);
	$pw = $uniSub->cleanWords($pw);
	$nw = $uniSub->cleanWords($nw);

	#alter the words to make them pos types
	$w = getFeature($w, "pos");
	$pw = getFeature($pw, "pos");
	$nw = getFeature($nw, "pos");

	my $strVec = "";

	#check if the word is the attribute or the words adjacent it are the attribute
	foreach my $a(@attrbts){
		my $pair = "";
		$pair .= ($w eq $a ? "1, " : "0, ");		
		$pair .= (($pw eq $a or $nw eq $a) ? "1, " : "0, ");
		$strVec .= $pair;
	}

	return $strVec;
}

#makes the cui based part of the vector
# input  : $w     	    	<-- the word to analyze
#        : $pw     	    	<-- the previous word
#        : $nw     	    	<-- the next word
#		 : @attrbts 		<-- the set of cui attributes to use
# output : $strVec			<-- the cui vector string
sub cuiVec{
	my $w = shift;
	my $pw = shift;
	my $nw = shift;
	my $at_ref = shift;
	my @attrbts = @$at_ref;

	#clean the words
	$w = $uniSub->cleanWords($w);
	$pw = $uniSub->cleanWords($pw);
	$nw = $uniSub->cleanWords($nw);

	#alter the words to make them cui types
	my @wArr = getFeature($w, "cui");
	my @pwArr = getFeature($pw, "cui");
	my @nwArr = getFeature($nw, "cui");

	my $strVec = "";
	#check if the word is the attribute or the words adjacent it are the attribute
	foreach my $a(@attrbts){
		my $pair = "";
		$pair .= ($uniSub->inArr($a, \@wArr) ? "1, " : "0, ");		
		$pair .= (($uniSub->inArr($a, \@pwArr) or $uniSub->inArr($a, \@nwArr)) ? "1, " : "0, ");
		$strVec .= $pair;
	}

	return $strVec;
}

#makes the semantic based part of the vector
# input  : $w     	    	<-- the word to analyze
#        : $pw     	    	<-- the previous word
#        : $nw     	    	<-- the next word
#		 : @attrbts 		<-- the set of sem attributes to use
# output : $strVec			<-- the sem vector string
sub semVec{
	my $w = shift;
	my $pw = shift;
	my $nw = shift;
	my $at_ref = shift;
	my @attrbts = @$at_ref;

	#clean the words
	$w = $uniSub->cleanWords($w);
	$pw = $uniSub->cleanWords($pw);
	$nw = $uniSub->cleanWords($nw);

	#alter the words to make them sem types
	my @wArr = getFeature($w, "sem");
	my @pwArr = getFeature($pw, "sem");
	my @nwArr = getFeature($nw, "sem");

	my $strVec = "";

	#check if the word is the attribute or the words adjacent it are the attribute
	foreach my $a(@attrbts){
		#remove "sem" label
		$a = lc($a);

		my $pair = "";
		$pair .= ($uniSub->inArr($a, \@wArr) ? "1, " : "0, ");		
		$pair .= (($uniSub->inArr($a, \@pwArr) or $uniSub->inArr($a, \@nwArr)) ? "1, " : "0, ");
		$strVec .= $pair;
	}
	return $strVec;
}

#converts a binary vector to a sparse vector
sub convert2Sparse{
	my $bin_vec = shift;
	my @vals = split(",", $bin_vec);
	my $numVals = @vals;

	my $sparse_vec = "{";
	for(my $c=0;$c<$numVals;$c++){
		my $curVal = $vals[$c];
		if($curVal eq "1"){
			$sparse_vec .= "$c" . "$curVal, ";
		}
	}
	$sparse_vec .= "$numVals, ";

	return $sparse_vec;
}


######################               ATTRIBUTE BASED METHODS              #####################

#gets the attributes based on the item
# input  : $feature     	<-- the feature type [e.g. ortho, morph, text]
#		 : %buckets 		<-- the bucket key set
# output : %vecARFFattr		<-- the vector set of attributes and arff set of attributes
sub grabAttr{
	my $name = shift;
	my $feature = shift;
	my $buckets_ref = shift;
	my %buckets = %$buckets_ref;

	my %vecARFFattr = ();
	if($feature eq "ortho"){
		my @vecSet = ();
		my @arffSet = ("first_letter_capital", 
						"single_character",
						"all_capital",
						"has_digit",
						"all_digit",
						"has_hyphen",
						"has_punctuation");
		$vecARFFattr{vector} = \@vecSet;
		$vecARFFattr{arff} = \@arffSet;
		return %vecARFFattr;
	}elsif($feature eq "morph"){	
		my %bucketAttr = ();
		my %bucketAttrARFF = ();

		#get the attributes for each bucket
		foreach my $testBucket (@allBuckets){
			my @range = $uniSub->bully($bucketsNum, $testBucket);
			$uniSub->printDebug("\t\t$name BUCKET #$testBucket/$feature MORPHO attributes...\n");
			
			#get attributes [ unique and deluxe ]
			my @attr = getMorphoAttributes(\@range, \%buckets);
			@attr = uniq(@attr);						#make unique forms
			$bucketAttr{$testBucket} = \@attr;

			my @attrARFF = @attr;
			foreach my $a(@attrARFF){$a .= $morphID;}
			$bucketAttrARFF{$testBucket} = \@attrARFF;
		}

		#add to overall
		$vecARFFattr{vector} = \%bucketAttr;
		$vecARFFattr{arff} = \%bucketAttrARFF;

		return %vecARFFattr;
	}else{
		my %bucketAttr = ();
		my %bucketAttrARFF = ();

		#get the attributes for each bucket
		foreach my $testBucket (@allBuckets){
			my @range = $uniSub->bully($bucketsNum, $testBucket);
			$uniSub->printDebug("\t\t$name BUCKET #$testBucket/$feature attributes...\n");
			
			#get attributes [ unique and deluxe ]
			my @attr = getRangeAttributes($feature, \@range, \%buckets);
			@attr = uniq(@attr);						#make unique forms
			$bucketAttr{$testBucket} = \@attr;

			my @attrARFF = getAttrDelux($feature, \@attr);
			$bucketAttrARFF{$testBucket} = \@attrARFF;
		}

		#add to overall
		$vecARFFattr{vector} = \%bucketAttr;
		$vecARFFattr{arff} = \%bucketAttrARFF;

		return %vecARFFattr;
	}
}



#makes an array with unique elements
# input  : @orig_arr <-- the original array w/ repeats
# output : @new_arr  <-- same array but w/o repeats
sub makeUniq{
	my $orig_arr_ref = shift;
	my @orig_arr = @$orig_arr_ref;

	my @new_arr = ();
	foreach my $t (@orig_arr){
		unless($uniSub->inArr($t, \@new_arr) or $t =~/\s+/ or $t =~/\b$entId\b/ or length($t) == 0){
			push @new_arr, $t;
		}
	}
	@new_arr = grep { $_ ne '' } @new_arr;
	return @new_arr;
}


#returns the attribute values of a range of buckets
# input  : $type     	    <-- the feature type [e.g. ortho, morph, text]
#		 : @bucketRange     <-- the range of the buckets to use [e.g.(1-8,10) out of 10 buckets; use "$uniSub->bully" subroutine in UniversalRoutines.pm]
#		 : %buckets 		<-- the bucket key set
# output : @attributes		<-- the set of attributes for the specific type and range
sub getRangeAttributes{
	my $type = shift;
	my $bucketRange_ref = shift;
	my $buckets_ref = shift;
	my @bucketRange = @$bucketRange_ref;
	my %buckets = %$buckets_ref;

	#collect all the necessary keys
	my @keyRing = ();
	foreach my $bucket (sort { $a <=> $b } keys %buckets){
		if($uniSub->inArr($bucket, \@bucketRange)){
			my @keys = @{$buckets{$bucket}};
			push @keyRing, @keys;
		}
	}

	#get the tokens for each associated key
	my @bucketTokens = ();
	foreach my $key (@keyRing){
		push @bucketTokens, @{$tokenHash{$key}};
	}

	#get the concepts for each associated key
	my @bucketConcepts = ();
	if($type eq "sem"){
		foreach my $key (@keyRing){
			push @bucketConcepts, $semHash{$key};
		}
	}elsif($type eq "cui"){
		foreach my $key (@keyRing){
			push @bucketConcepts, $cuiHash{$key};
		}
	}


	#get particular value from the tokens and concepts
	my @attributes = ();
	if($type eq "text" or $type eq "pos"){					#get the text attributes
		my @tokenWords = ();
		foreach my $token(@bucketTokens){
			my $tokenText = $token->{text};

			#add to the tokens
			if($tokenText =~ /\w+\s\w+/){
				my @tokenText2 = split(" ", $tokenText);
				push @tokenWords, @tokenText2;
			}elsif($tokenText ne "." and $tokenText ne "-" and !($tokenText =~ /[^a-zA-Z0-9]/)){
				push @tokenWords, $tokenText;
			}

			#clean up the text
			foreach my $toky(@tokenWords){
				$toky = cleanToken($toky);
			}

		}
		#gets the tokens for the attributes and vector analysis
		if($type eq "text"){
			@attributes = @tokenWords;
		}elsif($type eq "pos"){
			@attributes = getTokensPOS(\@bucketTokens, \@tokenWords, \@keyRing);
		}
		
	}
	#get the concept-based attributes
	elsif($type eq "sem" or $type eq "cui"){					
		my @conWords = ();
		foreach my $conFeat(@bucketConcepts){
			my @conLine = split / /, $conFeat;
			push @conWords, @conLine;
		}
		@attributes = uniq (@conWords);

		#add a semantic label for differentiation
		if($type eq "sem"){
			foreach my $a (@attributes){$a = uc($a);}
		}

	}
	#my $a = @attributes;
	#$uniSub->printColorDebug("red", "$type ATTR: #$a\n");
	#printArr("\n", @attributes);

	return @attributes;
}

#makes the arff version attributes - makes a copy of each attribute but with "_self" at the end
# input  : $f     			<-- the feature type (used for special features like POS and morph)
#		 : @attrs 		    <-- the attributes to ready for arff output
# output : @attrDelux		<-- the delux-arff attribute set
sub getAttrDelux{
	my $f = shift;
	my $attr_ref = shift;
	my @attr = @$attr_ref;

	#add the _self copy
	my @attrDelux = ();
	foreach my $word (@attr){
		#check if certain type of feature
		if($f eq "pos"){
			$word = ($word . "_POS");
		}
		$word =~s/$entId//g;

		#add the copy and then the original
		my $copy = "$word" . "$selfId";
		if(!$uniSub->inArr($word, \@attrDelux)){
			push (@attrDelux, $copy);
			push(@attrDelux, $word);
		}
	}
	return @attrDelux;
}

#returns the lines from a range of buckets
# input  : $type     	    <-- the feature type [e.g. ortho, morph, text]
#		 : @bucketRange     <-- the range of the buckets to use [e.g.(1-8,10) out of 10 buckets; use "$uniSub->bully" subroutine in UniversalRoutines.pm]
#		 : %buckets 		<-- the bucket key set
# output : @bucketLines		<-- the lines for the specific type and bucket keys based on the range
sub getRangeLines{
	my $type = shift;
	my $bucketRange_ref = shift;
	my $buckets_ref = shift;
	my @bucketRange = @$bucketRange_ref;
	my %buckets = %$buckets_ref;

	#collect all the necessary keys
	my @keyRing = ();
	foreach my $bucket (sort { $a <=> $b } keys %buckets){
		my @bucKeys = @{$buckets{$bucket}};
		if($uniSub->inArr($bucket, \@bucketRange)){
			push @keyRing, @bucKeys;
		}
	}

	my @bucketLines = ();
	#get the lines for each associated key
	if($type eq "text"){
		#[line based]
		foreach my $key (@keyRing){
			my $line = $fileHash{$key};
			push @bucketLines, $line;
		}
	}
	elsif($type eq "pos"){
		foreach my $key (@keyRing){
			my $line = $posHash{$key};
			push @bucketLines, $line;
		}
	}
	elsif($type eq "sem"){
		foreach my $key (@keyRing){
			my $line = $semHash{$key};
			push @bucketLines, $line;
		}
	}
	elsif($type eq "cui"){
		foreach my $key (@keyRing){
			my $line = $cuiHash{$key};
			push @bucketLines, $line;
		}
	}

	return @bucketLines;
}
#looks at the prefix # and suffix # and returns a substring of each word found in the bucket text set
# input  : @bucketRange     <-- the range of the buckets to use [e.g.(1-8,10) out of 10 buckets; use "$uniSub->bully" subroutine in UniversalRoutines.pm]
#		 : %buckets 		<-- the bucket key set
# output : @attributes		<-- the morphological attribute set
sub getMorphoAttributes{
	my $bucketRange_ref = shift;
	my $buckets_ref = shift;
	my @bucketRange = @$bucketRange_ref;
	my %buckets = %$buckets_ref;

	#collect all the necessary keys
	my @keyRing = ();
	foreach my $bucket (sort { $a <=> $b } keys %buckets){
		if($uniSub->inArr($bucket, \@bucketRange)){
			my @keys = @{$buckets{$bucket}};
			push @keyRing, @keys;
		}
	}

	my @bucketLines = ();
	#get the lines for each associated key
	foreach my $key (@keyRing){
		my $line = $fileHash{$key};
		push @bucketLines, $line;
	}

	#get each word from each line
	my @wordSet = ();
	foreach my $line (@bucketLines){
		my @words = split(" ", $line);
		push(@wordSet, @words);
	}

	#get the prefix and suffix from each word
	my @attributes = ();
	foreach my $word (@wordSet){
		$word =~s/$entId//g;
		push(@attributes, substr($word, 0, $prefix));									#add the word's prefix
		push(@attributes, substr($word, -$suffix));		#add the word's suffix
	}

	#my $a = @attributes;
	#$uniSub->printColorDebug("red", "$type ATTR: #$a\n");
	#printArr("\n", @attributes);

	return @attributes;
}

#formats attributes for the ARFF file
# input  : @set    		    <-- the attribute set
# output : @attributes  	<-- the arff formatted attributes
sub makeAttrData{
	my $set_ref = shift;
	my @set = @$set_ref;

	my @attributes = ();
	foreach my $attr (@set){
		push (@attributes, "\@ATTRIBUTE $attr NUMERIC");
	}

	return @attributes;
}

##new stoplist function
sub stop { 
 
    my $stopfile = shift; 

    my $stop_regex = "";
    my $stop_mode = "AND";

    open ( STP, $stopfile ) ||
        die ("Couldn't open the stoplist file $stopfile\n");
    
    while ( <STP> ) {
	chomp; 
	
	if(/\@stop.mode\s*=\s*(\w+)\s*$/) {
	   $stop_mode=$1;
	   if(!($stop_mode=~/^(AND|and|OR|or)$/)) {
		print STDERR "Requested Stop Mode $1 is not supported.\n";
		exit;
	   }
	   next;
	} 
	
	# accepting Perl Regexs from Stopfile
	s/^\s+//;
	s/\s+$//;
	
	#handling a blank lines
	if(/^\s*$/) { next; }
	
	#check if a valid Perl Regex
        if(!(/^\//)) {
	   print STDERR "Stop token regular expression <$_> should start with '/'\n";
	   exit;
        }
        if(!(/\/$/)) {
	   print STDERR "Stop token regular expression <$_> should end with '/'\n";
	   exit;
        }

        #remove the / s from beginning and end
        s/^\///;
        s/\/$//;
        
	#form a single big regex
        $stop_regex.="(".$_.")|";
    }

    if(length($stop_regex)<=0) {
	print STDERR "No valid Perl Regular Experssion found in Stop file $stopfile";
	exit;
    }
    
    chop $stop_regex;
    
    # making AND a default stop mode
    if(!defined $stop_mode) {
	$stop_mode="AND";
    }
    
    close STP;
    
    return $stop_regex; 
}

1;