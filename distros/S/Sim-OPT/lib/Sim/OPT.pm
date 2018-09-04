package Sim::OPT;
# Copyright (C) 2008-2017 by Gian Luca Brunetti and Politecnico di Milano.
# This is Sim::OPT, a program managing building performance simulation programs for performing optimization by block coordinate search.
# This is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

use v5.14;
# use v5.20;
use Exporter;
use parent 'Exporter'; # imports and subclasses Exporter

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Math::Trig;
use Math::Round;
use List::Util qw[ min max reduce shuffle];
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Statistics::Basic qw(:all);
use Storable qw(lock_store lock_nstore lock_retrieve dclone);
use IO::Tee;
use File::Copy qw( move copy );
use Set::Intersection;
use List::Compare;
use Data::Dumper;
use POSIX;
#use Parallel::ForkManager;
#$Data::Dumper::Indent = 0;
#$Data::Dumper::Useqq  = 1;
#$Data::Dumper::Terse  = 1;
use Data::Dump qw(dump);
use feature 'say';
#use feature qw(postderef);
#no warnings qw(experimental::postderef);
#use Sub::Signatures;
#no warnings qw(Sub::Signatures);
#no strict 'refs';
no strict;
no warnings;
use warnings::unused;
use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;
use Sim::OPT::Descend;
use Sim::OPT::Takechance;
use Sim::OPT::Parcoord3d;
use Sim::OPT::Modish;
use Sim::OPT::Interlinear;

our @ISA = qw( Exporter ); # our @adamkISA = qw(Exporter);
#%EXPORT_TAGS = ( DEFAULT => [qw( &opt &prepare )]); # our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#@EXPORT   = qw(); # our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
opt takechance
odd even _mean_ flattenvariables count_variables fromopt_tosweep fromsweep_toopt convcaseseed
convchanceseed makeflatvarnsnum calcoverlaps calcmediumiters getitersnum definerootcases
callcase callblocks deffiles makefilename extractcase setlaunch exe start
_clean_ getblocks getblockelts getrootname definerootcases populatewinners
getitem getline getlines getcase getstepsvar tell wash flattenbox enrichbox filterbox givesize
$configfile $mypath $exeonfiles $generatechance $file $preventsim $fileconfig $outfile $tofile $report
$simnetwork @themereports %simtitles %reporttitles %retrievedata
@keepcolumns @weights @weightsaim @varthemes_report @varthemes_variations @varthemes_steps
@rankdata @rankcolumn @reporttempsdata @reportcomfortdata %reportdata
@report_loadsortemps @files_to_filter @filter_reports @base_columns @maketabledata @filter_columns
@files_to_filter @filter_reports @base_columns @maketabledata @filter_columns %vals
@sweeps @mediumiters @varinumbers @caseseed @chanceseed @chancedata $dimchance $tee @pars_tocheck retrieve
report newretrieve newreport
$target %dowhat readsweeps modish $max_processes $computype $calcprocedure %specularratios @totalcases @pinwinneritems
);

$VERSION = '0.75.41';
$ABSTRACT = 'Sim::OPT is an optimization and parametric exploration program oriented to problem decomposition. It can be used with simulation programs receiving text files as input and emitting text files as output. It allows a free mix of sequential and parallel block coordinate searches.';

#################################################################################
# Sim::OPT
#################################################################################

# FUNCTIONS' SPACE
###########################################################
###########################################################


sub checkdone
{
	my $term = shift;
	my @arr = @{ shift( @_ ) };
	foreach my $elm ( @arr )
	{
		if ( $elm =~ /$term/ )
		{
			return( "yes" );
		}
	}
}

sub odd
{
    my $number = shift;
    return !even ($number);
}

sub even
{
    my $number = abs shift;
    return 1 if $number == 0;
    return odd ($number - 1);
}

sub _mean_ { return @_ ? sum(@_) / @_ : 0 }

sub rotate2d
{ # SELF-EXPLAINING. IT IS HERE TO BE CALLABLE READILY FROM THE OUTSIDE
    my ( $x, $y, $angle ) = @_;

    sub deg2rad
    {
	my $degrees = shift;
	return ( ( $degrees / 180 ) * 3.14159265358979 );
    }

    sub rad2deg
    {
	my $radians = shift;
	return ( ( $radians / 3.14159265358979 ) * 180 ) ;
    }

    $angle = deg2rad( $angle );
    my $x_new = cos($angle)*$x - sin($angle)*$y;
    my $y_new = sin($angle)*$x + cos($angle)*$y;
  return ( $x_new, $y_new);
}

sub countarray
{
	my $c = 1;
	foreach (@_)
	{
		foreach (@$_)
		{
			$c++;
		}
	}
	return ($c); # TO BE CALLED WITH: countarray(@array)
}

sub countnetarray
{
	my @bag;
	foreach (@_)
	{
		foreach (@$_)
		{
			push (@bag, $_);
		}
	}
	@bag = uniq(@bag);
	return scalar(@bag); # TO BE CALLED WITH: countnetarray(@array)
}

sub sorttable # TO SORT A TABLE ON THE BASIS OF A COLUMN
{
	my $num = $_[0];
	my @table = @{ $_[1] };
	my @rows;
	foreach my $line (@table)
	{
	    chomp $line;
	    $sth->execute(line);

	    my @row = $sth->fetchrow_array;
	    unshift (@row, $line);
	    push @rows, \@row;
	}

	@rows = sort { $a->[$num] cmp $b->[$num] } @rows;

	foreach my $row (@rows) {
	    foreach (@$row) {
		print "$_";
	    }
	    print "\n";
	} #TO BE CALLED WITH: sorttable( $number_of column, \@table);
	return (@table);
}

sub _clean_
{ # IT CLEANS A BASKET FROM CASES LIKE "-", "1-", "-1", "".
	my $swap = shift;
	my @arraytoclean = @$swap;
	my @storeinfo;
	foreach (@arraytoclean)
	{
		$_ =~ s/ //;
		unless ( !( defined $_) or ($_ =~ /^-/) or ($_ =~ /-$/) or ($_ =~ /^-$/) or ($_ eq "") or ($_ eq "-") )
		{
			push(@storeinfo, $_)
		}
	}
	return  @storeinfo; # HOW TO CALL THIS FUNCTION: clean(\@arraytoclean). IT IS DESTRUCTIVE.
}

#sub present
#{
#	foreach (@_)
#	{
#		say "### $_ : " . dump($_);
#		say TOFILE "### $_ : " . dump($_);
#	}
#}


sub flattenvariables # THIS LISTS THE NUMBER OF VARIABLES PLAY IN A LIST OF BLOCK SEARCHES. ONE COUNT FOR EACH LIST ELEMENT.
{
	my @array = @_;
	foreach my $case (@array)
	{
		@casederef = @$case;
		my @basket;
		foreach my $block (@casederef)
		{
			@blockelts = @$block;
			push (@basket, @blockelts);
		}
		my @basket = sort { $a <=> $b} uniq(@basket);
		push ( @flatvarns, \@basket ); ###
		# IT HAS TO BE CALLED WITH: flatten_variables(@treeseed);
	}
}

sub count_variables # IT COUNTS THE FLATTENED VARIABLES
{
	my @flatvarns = @_;
	foreach my $group (@flatvarns)
	{
		my @array = @$group;
		push ( @flatvarnsnum, scalar(@array) );
		# IT HAS TO BE CALLED WITH: count_variables(@flatvarns);
	}
}

# flatten_variables ( [ [1, 2, 3] , [2, 3, 4] , [3, 4, 5] ], [ [1, 2], [2, 3] ] );
#count_variables ([1, 2, 3, 4, 5], [1, 2, 3]);


sub fromopt_tosweep # IT CONVERTS A TREE BLOCK SEARCH FORMAT IN THE ORIGINAL OPT'S BLOCKS SEARCH FORMAT.
{
	my %thishash = %{ $_[0] };
	my @casegroup = @{ $thishash{casegroup} } ;
	my @chancegroup = @{ $thishash{chancegroup} };
	my @sweeps;
	my $countcase = 0;
	foreach my $case (@casegroup)
	{
		my @blockrefs = @$case;
		my @chancerefs = @{ $chancegroup[$countcase] };
		my @sweepblocks;
		my $countblock = 0;
		foreach my $elt (@blockrefs)
		{
			my @blockelts = @$elt;
			my $attachpoint = $blockelts[0];
			my $blocklength = $blockelts[1];
			my @chances = @{ $chancerefs[$countblock] };
			my @sweepblock = @chances[ $attachpoint .. ($attachpoint + $blocklength - 1) ];
			push (@sweepblocks, [@sweepblock]);
			$countblock++;
		}
		push (@sweeps, [ @sweepblocks ] );
		$countcase++;
	}
	# IT HAS TO BE CALLED THIS WAY: fromopt_tosweep( { casegroup => \@caseseed, chancegroup => \@chanceseed } );
	return (@sweeps);
}

sub fromopt_tosweep_simple # IT CONVERTS A TREE BLOCK SEARCH FORMAT IN THE ORIGINAL OPT'S BLOCKS SEARCH FORMAT.
{
	my %thishash = @_;
	my $casegroupref = $thishash{casegroup};
	my @blocks = @$casegroupref;
	my $chancegroupref = $thishash{chancegroup};
	my @chances = @$chancegroupref;
	my $countblock = 0;
	foreach my $elt (@blocks)
	{
		my @blockelts = @$elt;
		my $attachpoint = $blockelts[0];
		my $blocklength = $blockelts[1];
		my $chancesref = $chances[$countblock];
		my @chances = @$chancesref;
		my @sweepblock = @chances[ $attachpoint .. ($attachpoint + $blocklength - 1) ];
		push (@sweepblocks, [@sweepblock]);
		$countblock++;
	}
	# IT HAS TO BE CALLED THIS WAY: fromopt_tosweep( casegroup => [@caserefs_alias], chancegroup => [@chancerefs_alias] ); # IT IS NOT RELATIVE TO CASE: JUST ONE CASE, THE CURRENT.
	return (@sweepblocks);
}

sub checkduplicates
{
	my %hash = %{$_[0]};
	my @slice = @{$hash{slice}};
	my @sweepblocks = @{$hash{sweepblocks}};
	my $signal = 0;
	foreach my $blockref (@sweepblocks)
	{
		@block = @$blockref;
		if ( @slice ~~ @block )
		{
			$signal++;
		}
	}
	if ($signal == 0) { return "no"; }
	else { return "yes" };
}

sub fromsweep_toopt # IT CONVERTS THE ORIGINAL OPT'S BLOCKS SEARCH FORMAT IN A TREE BLOCK SEARCH FORMAT.
{
	my ( @bucket, @secondbucket );
	my $countcase = 0;
	foreach (@_) # CASES
	{
		my ( @blocks, @chances );
		my $countblock = 0;
		foreach(@$_) # BLOCKS
		{

			my $swap = $flatvarns[$countcase];
			my @varns = @$swap;
			my @block = @$_;
			my $blocksize = scalar(@block);
			my $lc = List::Compare->new(\@varns, \@block);
			my @intersection = $lc->get_intersection;
			my @nonbelonging;
			foreach (@varns)
			{
				my @parlist;
				unless ($_ ~~ @intersection)
				{
					push (@nonbelonging, $_);
				}
			}

			push (@blocks, [@intersection, @nonbelonging] );
			push (@chances, [0, $blocksize] );
			$countblock++;
		}
		push (@bucket, [ @blocks ] );
		push (@secondbucket, [@chances]);
		$countcase++;
	}
	@chanceseed = @bucket;
	@caseseed = @secondbucket;
	return (\@caseseed, \@chanceseed);
	# IT HAS TO BE CALLED THIS WAY: fromsweep_toopt(@sweep);
}

sub convcaseseed # IT ADEQUATES THE POINT OF ATTACHMENT OF EACH BLOCK TO THE FACT THAT THE LISTS CONSTITUTING THEM ARE THREE, JOINED.
{
	my $ref = shift;
	my %hash = %{$ref};
	my @chanceseed = @{ $hash{ chanceseed } };
	my @caseseed = @{ $hash{ caseseed } };
	my $countcase = 0;
	foreach my $case (@caseseed)
	{
		my $chance = $chanceseed[$countcase];
		my $countblock = 0;
		my @blockrefs = @$case;
		my @chancerefs = @$chance;
		foreach (@blockrefs)
		{
			my $chancelt = scalar ( @{ $chancerefs[$countblock] } );
			my $numofelts = ( $chancelt / 3 );
			${$_}[0] = ${$_}[0] + $numofelts;
			$countblock++;
		}
		$countcase++;
	} # TO BE CALLED WITH: convcaseseed(\@caseseed, \@chanceseed). @caseseed IS globsAL. TO BE CALLED WITH: convcaseseed(@caseseed);
	return(@caseseed);
}


sub convchanceseed # IT COUNTS HOW MANY PARAMETERS THERE ARE IN A SEARCH STRUCTURE,
{
	foreach (@_)
	{
		foreach (@$_)
		{
			push (@$_, @$_, @$_);
		}
	} # IT HAS TO BE CALLED WITH convchanceseed(@chanceseed). IT ACTS ON @chanceseed, WHICH IS globsAL.
	return(@_);
}

sub tellnum
{
	@arr = @_;
	my $response = (scalar(@_)/2);
	return($response); # TO BE CALLED WITH tellnum(%varnums);
}

sub calcoverlaps
{
	my $countcase = 0;
	foreach my $case(@sweeps)
	{
		my @caseelts = @{$case};
		my $contblock = 0;
		my @overlaps;
		foreach my $block (@caseelts)
		{
			my @pasttblock = @{$block[ $contblock - 1 ]};
			my @presentblock = @{$block[ $contblock ]};
			my $lc = List::Compare->new(\@pasttblock, \@presentblock);
			my @intersection = $lc->get_intersection;
			push (@caseoverlaps, [ @intersection ] );
			$countblock++;
		}
		push (@casesoverlaps, [@overlaps]); # globsAL!
		$countcase++;
	}
}

sub calcmediumiters
{
	my @varinumbers = @_;
	my $countcase = 0;
	my @mediters;
	foreach ( @varinumbers )
	{
		my $countblock = 0;
		foreach ( keys %$_ )
		{


			unless ( defined $mediumters[$countcase]{$_} )
			{
				$mediters[$countcase]{$_} = ( ceil( $varinumbers[$countcase]{$_} / 2 ) );
			}
		}
		$countcase++;
	} # TO BE CALLED WITH: calcmediumiters(@varinumbers)
	return ( @mediters );
}

#sub getitersnum
#{ # IT GETS THE NUMBER OF ITERATION. UNUSED. CUT
#	my $countcase = shift;
#	my $varinumber = shift;
#	my @varinumbers = @_;
#	my $itersnum = $varinumbers[$countcase]{$varinumber};
#
#	return $itersnum;
#	# IT HAS TO BE CALLED WITH getitersnum($countcase, $varinumber, @varinumbers);
#}

sub makefilename # IT DEFINES A FILE NAME GIVEN A %carrier.
{
	my %carrier = @_;
	my $filename = "$mypath/$file" . "_";
	my $countcase = 0;
	foreach my $key (sort {$a <=> $b} (keys %carrier) )
	{
		$filename = $filename . $key . "-" . $carrier{$key} . "_";
	}
	return ($filename); # IT HAS TO BE CALLED WITH: makefilename(%carrier);
}

sub getblocks
{ # IT GETS @blocks. TO BE CALLED WITH getblocks(\@sweeps, $countcase)
	my $swap = shift;
	my @sweeps = @$swap;
	my $countcase = shift;
	my @blocks = @{ $sweeps[$countcase]};
	return (@blocks);
}

#@blocks = getblocks(\@sweeps, 0);  say "dumpA( \@blocks) " . dump(@blocks);

sub getblockelts
{ # IT GETS @blockelts. TO BE CALLED WITH getblockelts(\@sweeps, $countcase, $countblock)
	my $swap = shift;
	my @sweeps = @$swap;
	my $countcase = shift;
	my $countblock = shift;
	my @blockelts = sort { $a <=> $b } @{ $sweeps[$countcase][$countblock] };
	return (@blockelts);
}

sub getrootname
{
	my $swap = shift;
	my @rootnames = @$swap;
	my $countcase = shift;
	my $rootname = $rootnames[$countcase];
	return ($rootname);
}

sub extractcase # IT EXTRACTS THE ITEMS TO BE CHANCED FROM A  %carrier, UPDATES THE FILE NAME AND CREATES THE NEW ITEM'S CARRIER
{
	my $file = shift;
	my $carrierref = shift;
	my @carrierarray = %$carrierref;
	my %carrier = %$carrierref;
	my $num = ( scalar(@carrierarray) / 2 );
	my $transfile = $file;
	$transfile = "_" . "$transfile";
	my $counter = 0;
	my %provhash;
	while ($counter < $num)
	{
		$transfile =~ /_(\d+)-(\d+)_/;
		if ( ($1) and ($2) )
		{
			$provhash{$1} = "$2";
		}
		$transfile =~ s/$1-$2//;
		$counter++;
	}
	foreach my $key (keys %provhash)
	{
		$carrier{$key} = $provhash{$key};
	}
	my $to = makefilename(%carrier);
	return($to, \%carrier); # IT HAS TO BE CALLED WITH: extractcase("$string", \%carrier), WHERE STRING IS A PIECE OF FILENAME WITH PARAMETERS.
}

sub definerootcases #### DEFINES THE ROOT-CASE'S NAME.
{
	my @sweeps = @{ $_[0] };
	my @miditers = @{ $_[1] };
	my @rootnames;
	my $countcase = 0;
	foreach my $sweep (@sweeps)
	{
		my $case = $miditers[$countcase];
		my %casetopass;
		my $rootname;
		foreach my $key (sort {$a <=> $b} (keys %$case) )
		{
			$casetopass{$key} = $miditers[$countcase]{$key};
		}
		foreach $key (sort {$a <=> $b} (keys %$case) )
		{
			$rootname = $rootname . $key . "-" . $miditers[$countcase]{$key} . "_";
		}
		$rootname = "$file" . "_" . "$rootname";
		$casetopass{rootname} = $rootname;
		chomp $rootname;
		push ( @rootnames, $rootname);
		$countcase++;
	}
	return (@rootnames); # IT HAS TO BE CALLED WITH: definerootcase(@mediumiters).
}

sub populatewinners
{
	my @rootnames = @{ $_[0] };
	my $countcase = $_[1];
	my $countblock = $_[2];
	my @winneritems;
	foreach my $case ( @rootnames )
	{
		push ( @{ $winneritems[$countcase][$countblock] }, $case );
		$countcase++;
	}
	return( @winneritems );
}


sub getitem
{ # IT GETS THE WINNER OR LOSER LINE. To be called with getitems(\@winner_or_loser_lines, $countcase, $countblock)
	my $swap = shift;
	my @items = @$swap;
	my $countcase = shift;
	my $countblock = shift;
	my $item = $items[$countcase][$countblock];
	my @arr = @$item;
	my $elt = $arr[0];
	return ($elt);
}

sub getline
{
	my $item = shift;
	my $file = "$mypath/" . "$item";
	return ($file);
}

sub getlines
{
	my $swap = shift;
	my @items = @$swap;
	my @arr;
	my $countcase = 0;
	foreach (@items)
	{
		foreach ( @{ $_ } )
		{
			push ( @{ $arr[$countcase] } , getline($_) );
		}
		$countcase++;
	}
	return (@arr);
}


sub getcase
{
	my $swap = shift;
	my @items = @$swap;
	my $countcase = shift;
	my $itemref = $items[$countcase];
	my %item = %{ $itemref };
	return ( %item );
}

sub getstepsvar
{ 	# IT EXTRACTS $stepsvar
	my $countvar = shift;
	my $countcase = shift;
	my $swap = shift;
	my @varinumbers = @$swap;
	my $varnumsref = $varinumbers[ $countcase ];
	my %varnums = %{ $varnumsref };
	my $stepsvar = $varnums{$countvar};
	return ($stepsvar)
} #getstepsvar($countvar, $countcase, \@varinumbers);

sub givesize
{	# IT RETURNS THE SEARCH SIZE OF A BLOCK.
	my $sliceref = shift;
	my @slice = @$sliceref;
	my $countcase = shift;
	my $varinumberref = shift;
	my $product = 1;
	foreach my $elt (@slice)
	{
		my $stepsize = Sim::OPT::getstepsvar($elt, $countcase, $varinumberref);
		$product = $product * $stepsize;
	}
	return ($product); # TO BE CALLED WITH: givesize(\@slice, $countcase, \@varinumbers);, WHERE SLICE MAY BE @blockelts in SIM::OPT OR @presentslice OR @pastslice IN Sim::OPT::Takechance
}

sub wash # UNUSED. CUT.
{
	my @instances = @_;
	my @bag;
	my @rightbag;
	foreach my $instanceref (@instances)
	{
		my %d = %{ $instanceref };
		my $to = $d{to};
		push (@bag, $to);
	}
	my $count = 0;
	foreach my $instanceref (@instances)
	{
		my %d = %{ $instanceref };
		my $to = $d{to};
		if ( not ( $to ~~ @bag ) )
		{
			push ( @rightbag, \%d );
		}
	}
	return (@rightbag); # TO BE CALLED WITH wash(@instances);
}

sub flattenbox
{
	my @basket;
	foreach my $eltsref (@_)
	{
		my @elts = @$eltsref;
		push (@basket, @elts);
	}
	return(@basket);
}


sub integratebox
{
	my @arrelts = @{ $_[0] };
	my %carrier = %{ $_[1] };
	my $file = $_[2];
	my @newbox;
	foreach my $eltref ( @arrelts )
	{
		my @elts = @{ $eltref };
		my $target = $elts[0];
		my $origin = $elts[3];
		my @result = extractcase( $target, \%carrier );
		my $righttarget = $result[0];
		my @result = extractcase( $origin, \%carrier );
		my $rightorigin = $result[0];
		push (@newbox, [ $righttarget, $elts[1], $elts[2], $rightorigin ] );
	}
	return (@newbox); # TO BE CALLED WITH: integratebox(\@flattened, \%mids), $file); # %mids is %carrier. $file is the blank root folder.
}


sub filterbox
{
	@arr = @_;
	my @basket;
	my @box;
	foreach my $case ( @arr )
	{
		my $elt = $case->[0];
		if ( not ( $elt ~~ @box ) )
		{
			my @bucket;
			foreach my $caseagain ( @arr )
			{
				my $el = $caseagain->[0];
				if ( $elt ~~ $el )
				{
					push ( @bucket, $case );
				}
			}
			my $parent = $bucket[0];
			push ( @basket, $parent );
			foreach ( @basket )
			{
				push ( @box, $_->[0] );
			}
		}
	}
	return( @basket );
}

sub callcase # IT PROCESSES THE CASES.
{
	my $swap = shift;
	my %dat = %{$swap};
	my $countcase = $dat{countcase};
	my $countblock = $dat{countblock};
	my @miditers = @{ $dat{miditers} };
	my @sweeps = @{ $dat{sweeps} };
	my @sourcesweeps = @{ $dat{sourcesweeps} };
	my @winneritems = @{ $dat{winneritems} };
	my %dirfiles = %{ $dat{dirfiles} };
	my @uplift = @{ $dat{uplift} };
	my %datastruc = %{ $dat{datastruc} };
	my @rescontainer = @{ $dat{uplift} };
	my @backvalues = @{ $dat{backvalues} };
	#eval($getparshere);

	my $rootname = getrootname(\@rootnames, $countcase);
	my @blockelts = getblockelts(\@sweeps, $countcase, $countblock);
	my @blocks = getblocks(\@sweeps, $countcase);
	my $toitem = getitem(\@winneritems, $countcase, $countblock);
	my $from = getline($toitem);
	#my @winnerlines = getlines( \@winneritems ); say "dump(\@winnerlines): " . dump(@winnerlines);
	my %varnums = getcase(\@varinumbers, $countcase);
	my %mids = getcase(\@miditers, $countcase);
	#eval($getfly);

	if ($countblock == 0 ) { my %dirfiles; }
	$dirfiles{simlist} = "$mypath/$file-simlist--$countcase";
	$dirfiles{morphlist} = "$mypath/$file-morphlist--$countcase";
	$dirfiles{retlist} = "$mypath/$file-retlist--$countcase";
	$dirfiles{replist} = "$mypath/$file-replist--$countcase"; # # FOR RETRIEVAL
	$dirfiles{descendlist} = "$mypath/$file-descendlist--$countcase"; # UNUSED FOR NOW
	$dirfiles{simblock} = "$mypath/$file-simblock--$countcase-$countblock";
	$dirfiles{morphblock} = "$mypath/$file-morphblock--$countcase-$countblock";
	$dirfiles{retblock} = "$mypath/$file-retblock--$countcase-$countblock";
	$dirfiles{repblock} = "$mypath/$file-repblock--$countcase-$countblock"; # # FOR RETRIEVAL
	$dirfiles{descendblock} = "$mypath/$file-descendblock--$countcase-$countblock"; # UNUSED FOR NOW

	#if ($countblock == 0 )
	#{
	#	( $dirfiles{morphcases}, $dirfiles{morphstruct}, $dirfiles{simcases}, $dirfiles{simstruct}, $dirfiles{retcases},
	#	$dirfiles{retstruct}, $dirfiles{repcases}, $dirfiles{repstruct}, $dirfiles{mergecases}, $dirfiles{mergestruct},
	#	$dirfiles{descendcases}, $dirfiles{descendstruct} );
	#}
	#say "OUTFILE: $outfile";
	#open( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!";
#	open( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!";

	#if ( ($countcase > 0) or ($countblock > 0) )
	#{

	#}

	#my @taken = extractcase("$toitem", \%mids);
	#my $to = $taken[0];
	#my %carrier = %{$taken[1]};

	my $casedata = {
				countcase => $countcase, countblock => $countblock,
				miditers => \@miditers,  winneritems => \@winneritems,
				dirfiles => \%dirfiles, uplift => \@uplift,
				backvalues => \@backvalues,
				sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
				datastruc => \%datastruc, rescontainer => \@rescontainer,
			};

	callblocks( $casedata );
	if ( $countblock != 0 ) { return($casedata); }
}

sub callblocks # IT CALLS THE SEARCH ON BLOCKS.
{
	my $swap = shift;
	my %dat = %{$swap};
	my $countcase = $dat{countcase};
	my $countblock = $dat{countblock};
	my @sweeps = @{ $dat{sweeps} };
	my @sourcesweeps = @{ $dat{sourcesweeps} }; #say $tee"dumpIN( \@sourcesweeps) " . dump(@sourcesweeps);
	my @miditers = @{ $dat{miditers} };
	my @winneritems = @{ $dat{winneritems} };
	my %dirfiles = %{ $dat{dirfiles} };
	my @uplift = @{ $dat{uplift} };
	my @backvalues = @{ $dat{backvalues} };
	my %datastruc = %{ $dat{datastruc} };
	my @rescontainer = @{ $dat{rescontainer} };

	my $rootname = getrootname(\@rootnames, $countcase);
	my @blockelts = getblockelts(\@sweeps, $countcase, $countblock);
	my @blocks = getblocks(\@sweeps, $countcase);
	my $toitem = getitem(\@winneritems, $countcase, $countblock);
	my $from = getline($toitem);
	my %varnums = getcase(\@varinumbers, $countcase);
	my %mids = getcase(\@miditers, $countcase);

	##my $word = join( ", ", @blockelts );

	my $openingelt;
	if ( $sourcesweeps[ $countcase ][ $countblock ][0] =~ />/ )
	{
		$sourcesweeps[ $countcase ][ $countblock ][0] =~ s/>//;
		$openingelt = $sourcesweeps[ $countcase ][ $countblock ][0];
	};

	if ( defined( $openingelt ) )
	{
		if ( not ( $openingelt =~ /^0/ ) )
		{
			my @contained = @{ $datastruc{$openingelt} };
			my @sorted = sort { ( split( /,/, $a ) )[ $#contained ] <=> (split( /,/, $b ) )[ $#contained ] } @contained ;
			my $winnerentry = $sorted[0]; #say TOFILE "dump( IN SUB CALLBKOCKS CHANGING \$winnerentry): " . dump($winnerentry);
			my @winnerelms = split(/\s+|,/, $winnerentry);
			my $winnerline = $winnerelms[0];
			my $copy = $winnerline;
			$copy =~ s/$mypath\/$file//;
			my @taken = Sim::OPT::extractcase( "$copy", \%mids ); #say $tee "CALLBKOCKS CHANGING >taken: " . dump(@taken);
			my $newtarget = $taken[0]; #say $tee "CALLBKOCKS CHANGING \$newtarget>: $newtarget";
			$newtarget =~ s/$mypath\///;
			my %newcarrier = %{ $taken[1] }; #say $tee "CALLBKOCKS CHANGING \%newcarrier>" . dump( %newcarrier );
			#say $tee "CALLBKOCKS CHANGING \@miditers: " . dump(@miditers);
			%{ $miditers[$countcase] } = %newcarrier;
		}
		else
		{
			my $word = "0";
			my @taken = Sim::OPT::extractcase( $datastruc{$word}, $datastruc{mids0} );
			my $newtarget = $taken[0]; #say $tee "CALLBKOCKS CHANGING \$newtarget>: $newtarget";
			$newtarget =~ s/$mypath\///;
			my %newcarrier = %{ $taken[1] }; #say $tee "CALLBKOCKS CHANGING \%newcarrier>" . dump( %newcarrier );
			#say $tee "CALLBKOCKS CHANGING \@miditers: " . dump(@miditers);
			%{ $miditers[$countcase] } = %newcarrier;
		}
	}
	else
	{
		if ( ( $countcase == 0 ) and ( $blockelts == 0 ) )
		{
			my $word = "0";
			my $copy = $from;
			$copy =~ s/$mypath\/$file//;
			$datastruc{$word} = $copy;
			$datastruc{mids0} = \%mids;
		}
	}

	my $blockdata =
	{
		countcase => $countcase, countblock => $countblock,
		miditers => \@miditers,  winneritems => \@winneritems,
		dirfiles => \%dirfiles, uplift => \@uplift,
		backvalues => \@backvalues,
		sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
		datastruc => \%datastruc, rescontainer => \@rescontainer,
	};

	deffiles( $blockdata );
}

sub deffiles # IT DEFINED THE FILES TO BE PROCESSED
{
	my $swap = shift;
	my %dat = %{$swap};
	my $countcase = $dat{countcase}; #say $tee "\$countcase : " . dump( $countcase );
  	my $countblock = $dat{countblock};
	my @sweeps = @{ $dat{sweeps} };
	my @sourcesweeps = @{ $dat{sourcesweeps} };
	my @miditers = @{ $dat{miditers} };
	my @winneritems = @{ $dat{winneritems} };
	my %dirfiles = %{ $dat{dirfiles} };
	my @uplift = @{ $dat{uplift} };
	my @backvalues = @{ $dat{backvalues} };
	my %datastruc = %{ $dat{datastruc} }; #say $tee "\%datastruc : " . dump( %datastruc );
	my @rescontainer = @{ $dat{rescontainer} }; #say $tee "\@rescontainer : " . dump( @rescontainer );

	my $rootname = getrootname(\@rootnames, $countcase); #say $tee "\$rootname : " . dump( $rootname );
	my @blockelts = getblockelts(\@sweeps, $countcase, $countblock); #say $tee "\@blockelts : " . dump( @blockelts );
	my @blocks = getblocks(\@sweeps, $countcase);  #say $tee "\@blocks : " . dump( @blocks );
	my $toitem = getitem(\@winneritems, $countcase, $countblock); #say $tee "\$toitem : " . dump( $toitem );
	my $from = getline($toitem); #say $tee "\$from : " . dump( $from );
	my %varnums = getcase(\@varinumbers, $countcase); #say $tee "\%varnums : " . dump( %varnums );
	my %mids = getcase(\@miditers, $countcase); #say $tee "\%mids : " . dump( %mids );

	my $rootitem = "$file" . "_"; #say $tee "\$rootitem : " . dump( $rootitem );
	my (@basket, @box);
	push (@basket, [ $rootitem ] ); #say $tee "\@basket : " . dump( @basket );
	foreach my $var ( @blockelts )
	{
		my @bucket;
		my $maxvalue = $varnums{$var}; #say $tee "\$maxvalue : " . dump( $maxvalue );
		foreach my $elt (@basket)
		{
			my $root = $elt->[0]; #say $tee "\$root : " . dump( $root );
			my $cnstep = 1;
			while ( $cnstep <= $maxvalue)
			{	#say $tee "\$countblock : " . dump( $countblock );
				my $olditem = $root; #say $tee "\$olditem : " . dump( $olditem );
				my $item = "$root" . "$var" . "-" . "$cnstep" . "_" ;  #say $tee "\$item : " . dump( $item );
				push ( @bucket, [$item, $var, $cnstep, $olditem] ); #say $tee "\@bucket: " . dump( @bucket );
				$cnstep++; #say $tee "\$cnstep : " . dump( $cnstep );
			}
		}
		@basket = ();
		@basket = @bucket;
		push ( @box, [ @bucket ] );

	}

	#say $tee "\@box: " . dump( @box );
	my @flattened = flattenbox(@box); #say $tee "\@flattened: " . dump( @flattened );
	my @integrated = integratebox(\@flattened, \%mids, $file); #say $tee "\@integrated: " . dump( @integrated );
	my @finalbox = filterbox(@integrated); #say $tee "\@finalbox: " . dump( @finalbox );


	my $datatowork =
	{
		countcase => $countcase, countblock => $countblock,
		miditers => \@miditers,  winneritems => \@winneritems,
		dirfiles => \%dirfiles, uplift => \@uplift,
		basket => \@finalbox,
		backvalues => \@backvalues,
		sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
		datastruc => \%datastruc, rescontainer => \@rescontainer,
	} ;

	setlaunch( $datatowork );
}

sub setlaunch # IT SETS THE DATA FOR THE SEARCH ON THE ACTIVE BLOCK.
{
	my $swap = shift;
	my %dat = %{$swap};
	my $countcase = $dat{countcase};
	my $countblock = $dat{countblock};
	my @sweeps = @{ $dat{sweeps} };
	my @sourcesweeps = @{ $dat{sourcesweeps} };
	my @miditers = @{ $dat{miditers} };
	my @winneritems = @{ $dat{winneritems} };
	my %dirfiles = %{ $dat{dirfiles} };
	my @uplift = @{ $dat{uplift} };
	my @basket = @{ $dat{basket} };
	my @backvalues = @{ $dat{backvalues} };
	my %datastruc = %{ $dat{datastruc} };
	my @rescontainer = @{ $dat{rescontainer} };

	my $rootname = getrootname(\@rootnames, $countcase);
	my @blockelts = getblockelts(\@sweeps, $countcase, $countblock);
	my @blocks = getblocks(\@sweeps, $countcase);
	my $toitem = getitem(\@winneritems, $countcase, $countblock);
	my $from = getline($toitem);
	my %varnums = getcase(\@varinumbers, $countcase);
	my %mids = getcase(\@miditers, $countcase);

	my ( @instances, %carrier);
	#if ($countblock == 0)
	#{
	#	%carrier = %mids;
	#}
	#else
	#{
	#	my $prov = "_" . "$winnerline";
	#	%carrier = extractcase( $prov , \%carrier );
	#}

	foreach my $elt ( @basket )
	{

		my $newpars = $$elt[0];
		my $countvar = $$elt[1];
		my $countstep = $$elt[2];
		my $oldpars = $$elt[3];
		my @taken = extractcase("$newpars", \%mids);
		my $to = $taken[0];
		#my %instancecarrier = %{$taken[1]};
		my @olds = extractcase("$oldpars", \%mids);
		my $origin = $olds[0];
		push (@instances,
		{
			countcase => $countcase, countblock => $countblock,
			miditers => \@miditers,  winneritems => \@winneritems,
			dirfiles => \%dirfiles, uplift => \@uplift,
			to => $to, countvar => $countvar, countstep => $countstep,
			origin => $origin,
			backvalues => \@backvalues,
			sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
			datastruc => \%datastruc, rescontainer => \@rescontainer,
		} );
	}



	exe( @instances ); # IT HAS TO BE CALLED WITH: setlaunch(@datatowork). @datatowork ARE CONSTITUTED BY AN ARRAY OF: ( [ \@blocks, \%varnums, \%bases, $name, $countcase, \@blockelts, $countblock ], ... )
}

sub exe
{
	my @instances = @_;

	my $firstinst = $instances[0];
	my %d = %{ $firstinst };
	my $countcase = $d{countcase};
	my $countblock = $d{countblock};
	my %dirfiles = %{ $d{ dirfiles } };
	my %datastruc = %{ $d{datastruc} };
	my @rescontainer = @{ $d{rescontainer} };

        my $direction = ${$dowhat{direction}}[$countcase][$countblock]; #NEW
        my $precomputed = $dowhat{precomputed}; #NEW
        my @takecolumns = @{ $dowhat{takecolumns} }; #NEW

	say $tee "#Executing new searches for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

	if ( $dowhat{morph} eq "y" )
	{
		say $tee "#Calling morphing operations for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

		my @result = Sim::OPT::Morph::morph(
		{
			configfile => $configfile, instances => \@instances, countcase => $countcase, countblock => $countblock,
			dirfiles => \%dirfiles, datastruc => \%datastruc, rescontainer => \@rescontainer,
		} );
		$dirfiles{morphcases} = $result[0];
		$dirfiles{morphstruct} = $result[1];
	}

	if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
	{

		say $tee "#Calling simulations, reporting and retrieving for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
		my @result = Sim::OPT::Sim::sim(
		{
			instances => \@instances, countcase => $countcase, countblock => $countblock,
			dirfiles => \%dirfiles, datastruc => \%datastruc, rescontainer => \@rescontainers
		} );
		$dirfiles{simcases} = $result[0];
		$dirfiles{simstruct} = $result[1];
		$dirfiles{retcases} = $result[2];
		$dirfiles{retstruct} = $result[3];
		$dirfiles{notecases} = $result[4];
		$dirfiles{repcases} = $result[5];
		$dirfiles{repstruct} = $result[6];
		$dirfiles{mergestruct} = $result[7];
		$dirfiles{mergecases} = $result[8];
		$dirfiles{repfilebackup} = $result[9];
	}
        elsif ( $dowhat{simulate} eq "y" )
	{
			say $tee "#Calling simulations for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
		my @result = Sim::OPT::Sim::sim(
		{
			instances => \@instances, countcase => $countcase, countblock => $countblock,
			dirfiles => \%dirfiles, datastruc => \%datastruc, rescontainer => \@rescontainers
		} );
		$dirfiles{simcases} = $result[0];
		$dirfiles{simstruct} = $result[1];
	}

	if ( $dowhat{descend} eq "y" )
	{
		say $tee "#Calling descent in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
		my @result = Sim::OPT::Descend::descend(
		{
			instances => \@instances, countcase => $countcase, countblock => $countblock,
			dirfiles => \%dirfiles, repfile => $repfile, datastruc => \%datastruc, rescontainer => \@rescontainer,
		} );
		$dirfiles{descendcases} = $result[0];
		$dirfiles{descendstruct} = $result[1];
	}

	if ( $dowhat{substitutenames} eq "y" )
	{
		 Sim::OPT::Report::filter_reports(
		{
			instances => \@instances, countcase => $countcase, countblock => $countblock,
			dirfiles => \%dirfiles
		} );
	}

	if ( $dowhat{filterconverted} eq "y" )
	{
		 Sim::OPT::Report::convert_filtered_reports(
		{
			instances => \@instances, countcase => $countcase, countblock => $countblock,
			dirfiles => \%dirfiles
		} );
	}

	if ( $dowhat{make3dtable} eq "y" )
	{
		 Sim::OPT::Report::maketable(
		{
			instances => \@instances, countcase => $countcase, countblock => $countblock,
			dirfiles => \%dirfiles
		} );
	}
} # END SUB exe

sub start
{
###########################################
say "\nHi. This is Sim::OPT, version $VERSION.
Please insert the name of a configuration file (Unix path).\n";
###########################################
	$configfile = <STDIN>;
	chomp $configfile;
	if (-e $configfile ) { ; }
	else { &start; }
}


sub prunethis
{
	my $aref = shift;
	my @arr = @{ $aref };
	my @newarr = map
	{
		if ( ref( $_ ) )
		{ prunethis( $_ ); }
		elsif ( $_ =~/>/ )
		{
			();
		}
		else
		{
			$_;
		}
	} @arr;
	return ( \@newarr );
}


sub readsweeps
{
	my @struct = @_;
	my @sourcestruct = @{ dclone( \@struct ) };
	foreach ( @struct )
	{
		foreach ( @$_ )
		{
			#prunethis( $_ );
			;
		}
	}
	return ( \@struct, \@sourcestruct );
}

###########################################################################################

sub opt
{
	&start;
	#eval `cat $configfile`; # The file where the program data are

	require $configfile;

	#if ( not ( $outfile ) ) { $outfile = "$mypath/$file-$fileconfig-feedback.txt"; }
	if ( not ( $tofile ) ) {
		unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) )
		{
			$tofile = "$mypath/$file-tofile.txt";
		}
		else
		{
			$tofile = "$mypath\\$file-tofile.txt";
		}
	}

	$tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL ZZZ

#	if ($casefile) { eval `cat $casefile` or die( "$!" ); }
#	if ($chancefile) { eval `cat $chancefile` or die( "$!" ); }

	print "\nNow in Sim::OPT. \n";

  if ( $dowhat{randomsweeps} eq "yes" ) #IT SHUFFLES  @sweeps UNDER REQUEST SETTING.
  {
    my @newsweeps;
    foreach my $arrayref ( @sweeps )
    {
        my @newarr;
        my @array = @{ $arrayref };
        @array = shuffle( @array );
        foreach my $arefref ( @array )
        {
          my @arrayy = @{ $arefref };
          @arrayy = shuffle( @arrayy );
          push ( @newarr, [ @arrayy ] );
        }
        push ( @newsweeps, [ @newarr ] );
      }
      @sweeps = @newsweeps;
      print "NEW SWEEPS: " . dump( @sweeps ) . "\n";
  }

  my $i = 0;
  my @newarr;
  if ( $dowhat{randomdirs} eq "yes" )
  { #IT SHUFFLES  $dowhat{direction} UNDER APPROPRIATE SETTINGS.
    foreach my $directionref ( @{ $dowhat{direction} } )
    {
      my @varinumber = %{ $varinumbers[i] };
      my $numcases = ( scalar( @varinumber ) / 2 ) ;
      my @directions;
      my $x = 0;
      foreach ( @{ $directionref } )
      {
        while ( $x < $numcases )
        {
          my @bag = ( ">", "<", "=" );
          @bag = shuffle( @bag );
          push ( @directions, $bag[0] );
          $x++;
        }
      }
      push ( @newarr, [ @directions ] );
      $i++;
    }
    $dowhat{direction} = [ @newarr ];
    say "NEW RANDOMIZED DIRECTIONS: " . dump( $dowhat{direction} );
  }

  { #IT FILLS THE MISSING $dowhat{direction} UNDER APPROPRIATE SETTINGS.
    my $i = 0;
    my @newarr;
    foreach my $dirref ( @{ $dowhat{direction} } )
    {
      my @varinumber = %{ $varinumbers[i] };
      my $numcases = ( scalar( @varinumber ) / 2 ) ;

      my @directions;
      my $itemsnum = scalar( @{ $dirref } );
      my $c = 0;
      while ( ( $itemsnum + $c ) <= $numcases )
      {
        push ( @directions, ${ $dirref }[0] );
        $c++;
      }
      push ( @newarr, [ @directions ] );
      $i++;
    }
    $dowhat{direction} = [ @newarr ];
    say "NEW FILLED DIRECTIONS: " . dump( $dowhat{direction} );
  }

  if ( $dowhat{randominit} eq "yes" )
  {
    my %i = 0;
    foreach $arr ( @varinumbers )
    {
      my %hash = %{ $arr };
      foreach my $elt ( sort {$a <=> $b} ( keys %hash ) )
      {
        my $num = $hash{$elt};
        my $newnum = ( 1+ int( rand( $num ) ) );
        ${ $mediumiters[i] }{$elt} = $newnum;
      }
      $i++;
    }
    say "NEW INIT LEVELS: " . dump( @mediumiters );
  }

	#open( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!";
#	open( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!";

	#unless (-e "$mypath")
	#{
	#	if ($exeonfiles eq "y")
	#	{
	#		`mkdir $mypath`;
	#	}
	#}
	#unless (-e "$mypath")
	#{
	#	print TOFILE "mkdir $mypath\n\n";
	#}

	if ( not ( $target ) ) { $target = "opt"; }

	#####################################################################################
	# INSTRUCTIONS THAT LAUNCH OPT AT EACH SWEEP (SUBSPACE SEARCH) CYCLE

	if ( not ( ( @chanceseed ) and ( @caseseed ) and ( @chancedata ) ) )
	{
		if ( ( @sweepseed ) and ( @chancedata ) ) # IF THIS VALUE IS DEFINED. TO BE FIXED. ZZZ
		{
			my $yield = fromsweep_toopt( @sweeps );
			@caseseed = @{ $yield[0] };
			@chanceseed = @{ $yield[1] };
		}
	}



	@chanceseed = convchanceseed(@chanceseed);
	@caseseed = convcaseseed( { caseseed => \@caseseed, chanceseed => \@chanceseed } );


	my (@sweeps_);

	if ( ( $target eq "takechance" ) and (@chancedata) and ( $dimchance ) )
	{
		my @obt = Sim::OPT::Takechance::takechance( \@caseseed, \@chanceseed, \@chancedata, $dimchance );              #say $tee "PASSED: \@sweeps: " . dump(@sweeps);
		@sweeps_ = @{ $obt[0] };
		@caseseed_ = @{ $obt[1] };
		@chanceseed_ = @{ $obt[2] };
		open( MESSAGE, ">./search_structure_that_may_be_adopted.txt" );
		say MESSAGE "\@sweeps_ " . Dumper(@sweeps_);
		say MESSAGE "\THESE VALUES OF \@sweeps IS EQUIVALENT TO THE FOLLOWING VALUES OF \@caseseed AND \@chanceseed: ";
		say MESSAGE "\n\@caseseed " . Dumper(@caseseed_);
		say MESSAGE "\n\@chanceseed_ " . Dumper(@chanceseed_);
		close MESSAGE;

		if ( not (@sweeps) ) # CONSERVATIVE CONDITION. IT MAY BE CHANCED. ZZZ
		{
			@sweeps = @sweeps_ ;
		}
	}
	elsif ( $target eq "opt" )
	{
		#my  $itersnum = $varinumbers[$countcase]{$varinumber}; say "\$itersnum: $itersnum";

		my ( $sweepz_ref, $sourcesweeps_ref ) = readsweeps( @sweeps );
		my @sweepz = @$sweepz_ref;
		my @sourcesweeps = @$sourcesweeps_ref;
		if ( @sweepz )
		{
			@sweeps = @sweepz;
		}

		calcoverlaps( @sweeps ); # PRODUCES @calcoverlaps WHICH IS global. ZZZ

                #@mediumiters = @pinmediumiters; say $tee "###############MEDIUMITERS: " . dump ( @mediumiters );
		
                if ( scalar( @mediumiters ) == 0 ) { calcmediumiters( @varinumbers ); }
		#$itersnum = getitersnum($countcase, $varinumber, @varinumbers);

		@rootnames = definerootcases( \@sweeps, \@mediumiters );

		my $countcase = 0;
		my $countblock = 0;
		my %datastruc;
		my @rescontainer;

		my @winneritems = populatewinners( \@rootnames, $countcase, $countblock );
                
                my $count = 0;
                my @arr;
                foreach ( @varinumbers )
                {
                  my $elt = getitem(\@winneritems, $count, 0); 
                  push ( @arr, $elt );
                  $count++;
                }
                $datastruc{pinwinneritem} = [ @arr ];
                

		callcase( { countcase => $countcase, rootnames => \@rootnames, countblock => $countblock,
		miditers => \@mediumiters, winneritems => \@winneritems, sweeps => \@sweeps, sourcesweeps => \@sourcesweeps, datastruc => \%datastruc, rescontainer => \@rescontainer } ); #EVERYTHING HAS TO BEGIN IN SOME WAY
	}
	elsif ( ( $target eq "parcoord3d" ) and (@chancedata) and ( $dimchance ) )
	{
		Sim::OPT::Parcoord3d::parcoord3d;
	}

	close(OUTFILE);
	close(TOFILE);
	exit;
} # END

#############################################################################

1;

__END__

=head1 NAME

Sim::OPT.

=head1 SYNOPSIS

  use Sim::OPT;
  opt;

=head1 DESCRIPTION

Sim::OPT is an optimization and parametric exploration program oriented to problem decomposition. It can be used with simulation programs receiving text files as input and emitting text files as output. Some of Sim::OPT's optimization modules (Sim::OPT, Sim::OPT::Descent) pursue optimization through block search, allowing blocks (subspaces) to overlap, and allowing a free intermix of sequential searches (inexact Gauss-Seidel method) and parallell ones (inexact Jacobi method). The Sim::OPT::Takechange module seeks for the least explored search paths when exploring new search spaces sequentially (following rules presented in: http://dx.doi.org/10.1016/j.autcon.2016.08.014). Sim::OPT::Morph, the morphingchange module, manipulates chosen parameters in the configuration files (constituted by text files) describing models for simulation programs, recognizing variables by position. The Sim::OPT::Parcoord3d module converts 2D parallel coordinates plots in Autolisp instructions for obtaining 3D plots as Autocad drawings. The Sim::OPT::Modish module, which alters the shading values calculated with the ESP-r simulation platform in order to take into account the solar reflections from obstructions, is no more included in this distribution, because a modificed version of it has been included in the ESP-r distribution, available at the address http://www.esru.strath.ac.uk/Programs/ESP-r.htm.

The Sim::OPT's morphing and reporting modules contain several additional functions specifically targeting the ESP-r building performance simulation platform. A working knowledge of ESP-r is necessary to use those functionalities.

To install Sim::OPT, the command <cpanm Sim::OPT> has to be issued as a superuser. Sim::OPT can then be loaded through the command <use Sim::OPT> in a Perl repl. But to ease the launch, the batch file "opt" (which can be found packed in the "optw.tar.gz" file in "examples" folder in this distribution) may be copied in a work directory and the command <opt> may be issued. That command will call OPT with the settings specified in the configuration file. When launched, Sim::OPT will ask the path to that file, which must contain a suitable description of the operations to be accomplished and point to an existing simulation model.

The "$mypath" variable in the configuration file must be set to the work directory where the base model reside.

To run the morphing functions of OPT without making OPT launch the simulation program, the setting <$exeonfiles = "n";> should be specified in the configuration file. That way, the commands will only be printed to a file. This can be aimed to inspect the commands that OPT would give the simulation program, and for debugging.

Besides an OPT configuration file, separate configuration files for propagation of constraints may be created. Those can be useful to give the morphing operations greater flexibility. Propagation of constraints can regard the geometry of a model, solar shadings, mass/flow network, controls, and generic text files descripting a simulation model.

The simulation model folders and the result files that will be created in a parametric search will be named as the base model, plus numbers and other characters  naming model instances. For example, the instance produced in the first iteration for a root model named "model" in a search constituted by 3 morphing phases and 5 iteration steps each will be named "model_1-1_2-1_3-1"; and the last one "model_1-5_2-5_3-5".

The structure of the block searches is described through the variable "@sweeps" in the configuration file. Each case is listed inside square brackets. And each search subspace (block) in each case is listed inside square brakets. For example: a sequence constituted by two sequential brute force searches, one regarding parameters 1, 2, 3 and the other regarding parameters 1, 4, 5, 7 would be described with: @sweeps = ( [ [ 1, 2, 3 ] ] , [ [ 1, 4, 5, 7 ] ] )   (1). And a sequential block search with the first subspace regarding parameters 1, 2, 3 and the second regarding parameters 3, 4, 5, 6 would be described with: @sweeps = ( [ [ 1, 2, 3 ] , [ 3, 4, 5, 6 ] ] ).

The number of iterations to be taken into account for each parameter for each case is specified in the "@varinumbers" variable. To specifiy that the parameters of the last example are to be tried for three values (iterations) each, @varinumbers has to be set to ( { 1 => 3, 2 => 3, 3 => 3, 4 => 3, 5 => 3, 6 => 3 } ).

The instance number that has to considered the basic one, corresponding to the root case, is specified by the variable "@miditers". "@miditers" for the last example may be for instance set to ( { 1 => 2, 2 => 2, 3 => 2, 4 => 2, 5 => 2, 6 => 2 } ).

OPT can work on a given set of pre-simulated results without launching new simulations, and it can randomize the sequence of the parameter search and the initialization level of the parameters (see the included examples).

By default the behaviour of the program is sequential. To make it parallel locally, subspaces may be named, so as to work as collector cells. A name named "name" must be written ">name" and placed at the end of the block from which it is receiving the value produced by the block. Clearly, one named block (cell) can receive inputs by more than one block. The name named "name" should instead be written "name>" and placed at the beginning of the block in the case that it brings into it the values it contains.

An example:
@sweeps = ( [ [ "0>", 1, 2, 3, ">a" ] , [ "0>", 3, 4, 5, 6, ">a" ] , [ "a>" 6, 7, 8, 9 ] , [ 11, 12, 13, ">b" ] , [ ">b", 14, 15, 16, ">c" ], [ ">b", 15, 16, 17, ">c" ], [">c"] ] );
The ">"s signalling the named blocks can be seen as a visual aid for a sort of markup language for blocks which allows to nest parts of a search. But they can be omitted.

Numerical blocks, for example [ 1, 2, 3 ], are automatically named, in the sense that they can also be used as container cells. The name of the block in question, for example, is "1, 2, 3", so there is no need to create new containers and names esplicitly. For this reason, there is also no need of specifying a container block at the beginning of a block or at the end of a block for describing directed graphs. Only specifying collectors at the entry or at the exit of some blocks is necessary when there is parallelism involved. For example, the last cited search could also have been written in the following manner:
@sweeps = ( [ [ 1, 2, 3, ">6, 7, 8, 9" ] , [ "0>", 3, 4, 5, 6, ">6, 7, 8, 9" ] , [ 6, 7, 8, 9 ] , [ 11, 12, 13, ">14, 15, 16" ] , [ 14, 15, 16, ">c" ], [ 11, 12, 13, ">15, 16, 17" ] ,[ 15, 16, 17, ">c" ] ] ). But sometimes it may be worth adding extra containers for the sake of clarity.

The collector-like block "0>" is a particular case: it is the base case. The beginning of a search always begins with a "0>", explicitly or implicitly. Other "0>"s can be present along the search graph as inner starting points. But it is cleaner not to alter the block "0", not to use it as a collector cell.

Any groups of parameters can be renamed in the configuration file (before the variable @sweeps is specified), and that name can be used in place of the parameters. For example:
$group1 = (1, 2, 3); $group2 = (2, 3, 4);
In that case, writing   ( [ [ 1, 2, 3 ] , [ 2, 3, 4 ] ] )   is equivalent to  ([["$group1"]], [["$group2"]]).

What counts in describing a search is the fact that the blocks are named (i.e. they are strings - even if they contain numbers) or not, i.e. they are constituted by sequences of numbers (parameters, variables) or they are aliases directing to them. If they are named, they are just containers which generate no action. If they are constituted by numbers, block search takes place in them, and they also can work as containers. In the case the blocks are named, they get spliced (pasted) into other blocks, and they can only be placed at the beginning and/or at the end of them, but not in the middle.

The consequence of all this is that there is more than one way for describing a search. For example, the search written in the two versions above can also be described in the further manners, using named containers at the end of each block (a) or at the beginning (b):
(a): @sweeps = ( [ [ "0", "1, 2, 3" ], [ 1, 2, 3, "6, 7, 8, 9" ] , [ "0", "3, 4, 5, 6" ], [ 3, 4, 5, 6, "6, 7, 8, 9" ] , [ 6, 7, 8, 9 , "11, 12, 13" ] , [ 11, 12, 13, "14, 15, 16" ] , [ 14, 15, 16, "c" ], [ 11, 12, 13, "15, 16, 17" ] ,[ 15, 16, 17, "c" ] ] );
(b): @sweeps = ( [ [ "0", 1, 2, 3 ], [ "1, 2, 3", 6, 7, 8, 9 ] , [ "0", 3, 4, 5, 6 ], [ "3, 4, 5, 6 ", 6, 7, 8, 9 ] , [ "6, 7, 8, 9", 11, 12, 13 ], [ "11, 12, 13 ", 14, 15, 16 ], [ "14, 15, 16", "c" ], [ "11, 12, 13", 15, 16, 17 ] ,[ "15, 16, 17", "c" ] ] ).

The possibility of articulating a mix of parallel and sequential searches is more fundamental that can be expressed with words, because it makes possible to design search structures with a depth, embodying precedence, and therefore procedural time, in them. Deriving from this, there is the fact that the representation tools in question are sufficient for describing directed graphs.

Where Sim::OPT may be fit for a task? Where a certain exploration is complex and/or when it is to be confronted through decomposition, by dividing a problem in overlapping subproblems; when there aren't slick tools suitable to decomposition-based, simulation-based optimization; when spending a day, or two, or three setting up a model may spare months of work.

Where it may not be suitable for the task? Due to the investment which is necessary for getting acquainted with its raw interface, for quick shots at small explorations.

The program works under Linux.

=head2 EXPORT

"opt".

=head1 SEE ALSO

Annotated examples ("esp.pl" for ESP-r, "ep.pl" for EnergyPlus - the two perform the same morphing operations on models describing the same building -, "des.pl" about block search, and "f.pl" about a search in a pre-simulated dataset) can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution. They constitute the available documentation. For more information, reference to the source code should be made.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2017 by Gian Luca Brunetti and Politecnico di Milano. This is free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
