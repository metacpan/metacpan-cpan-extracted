package Sim::OPT;
# Copyright (C) 2008-2018 by Gian Luca Brunetti and Politecnico di Milano.
# This is Sim::OPT, a program managing building performance simulation programs for performing optimization by block coordinate search.
# This is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.
$VERSION = '0.419';
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
#$Data::Dumper::Terse  = 1;d
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
use Sim::OPT::Interlinear;

our @ISA = qw( Exporter ); # our @adamkISA = qw(Exporter);
#%EXPORT_TAGS = ( DEFAULT => [qw( &opt &prepare )]); # our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#@EXPORT   = qw(); # our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
opt takechance
odd even _mean_ flattenvariables count_variables fromopt_tosweep fromsweep_toopt convcaseseed
convchanceseed makeflatvarnsnum calcoverlaps calcmiditers definerootcases
callcase callblock deffiles makefilename extractcase setlaunch exe start
_clean_ getblocks getblockelts getrootname definerootcases populatewinners
getitem getline getlines getstepsvar tell wash flattenbox enrichbox filterbox givesize
$configfile $mypath $exeonfiles $generatechance $file $preventsim $fileconfig $outfile $tofile $report
$simnetwork @themereports %simtitles %reporttitles %retrievedata
@keepcolumns @weights @weightsaim @varthemes_report @varthemes_variations @varthemes_steps
@rankdata @rankcolumn @reporttempsdata @reportcomfortdata %reportdata
@report_loadsortemps @files_to_filter @filter_reports @base_columns @maketabledata @filter_columns
@files_to_filter @filter_reports @base_columns @maketabledata @filter_columns %vals
@sweeps @miditers @varnumbers @caseseed @chanceseed @chancedata $dimchance $tee @pars_tocheck retrieve
report newretrieve newreport washn
$target %dowhat readsweeps $max_processes $computype $calcprocedure %specularratios @totalcases @winneritems
toil genstar solvestar integratebox filterbox__ clean %dowhat
);

$ABSTRACT = 'Sim::OPT is an optimization and parametric exploration program encouraging problem decomposition. It can be used with simulation programs receiving text files as input and emitting text files as output. It allows a free mix of sequential and parallel block coordinate searches.';

#################################################################################
# Sim::OPT
#################################################################################


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

sub odd__
{
  my ( $number ) = @_;
  if ( $number % 2 == 1 )
  {
    return ( "odd" );
  }
  else
  {
    return ( "even" );
  }
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
	@bag = uniq( @bag );
	return scalar( @bag ); # TO BE CALLED WITH: countnetarray(@array)
}


sub addnear
{
  my ( $this_bulkref, $varnums_ref ) = @_;
	my $this = $this_bulkref->[0][0];
	my $pass = dclone($this_bulkref);
	my %varnums = %{ $varnums_ref };
	my @keys = ( keys %varnums );
	my @signs = ( "+", "-" );
	my %thiselts = split( "_|-", $this );

  my $that;
	my $done = "no";
	while ( $done eq "no" )
	{
		my @pars = shuffle( @keys );
		my @signs = shuffle( @signs );
		my $par = $pars[0];
		my $sign = $signs[0];
		my $maxlev = $varnums{$par};
		my $lev = $thiselts{$par};
		my $newlev;
		if ( $sign eq "+" )
		{
			$newlev = ( $lev + 1 );
		}
		elsif ( $sign eq "-" )
		{
			$newlev = ( $lev - 1 );
		}

		my $bit = $par . "-" . $newlev;
		unless( ( $newlev == $lev ) or ( $newlev == 0 ) or ( $newlev > $maxlev ) )
		{
			my $firstbit = $par . "-"; #say "\$firstbit $firstbit";
			$that = $this;
			$that =~ s/$firstbit(\d)/$bit/ ; #say "\$that $that";
			$done = "yes"; #say "\$done $done";
		}
	}
	$pass->[0][0] = $that;
	return( $pass );
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

sub present
{
	foreach (@_)
	{
		say "### $_ : " . dump($_);
		say TOFILE "### $_ : " . dump($_);
	}
}


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
		my @basket = sort { $a <=> $b } uniq( @basket );
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


sub fromsweep_toopt # IT CONVERTS THE ORIGINAL OPT BLOCKS SEARCH FORMAT IN A TREE BLOCK SEARCH FORMAT.
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
			my $blocksize = scalar( @block ); # THE ORIGINAL OPT BLOCKS SEARCH FORMAT IN A TREE BLOCK SEARCH FORMAT.
			my $lc = List::Compare->new( \@varns, \@block );
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
	@chanceseed = @bucket; # THE ORIGINAL OPT BLOCKS SEARCH FORMAT IN A TREE BLOCK SEARCH FORMAT.
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
	my @sweeps = @_;
	my ( @caseoverlaps );
	my $countcase = 0;
	foreach my $case ( @sweeps )
	{
		my @caseelts = @{ $case };
		my $countblock = 0;
		foreach my $block ( @caseelts )
		{
			my @pasttblock = @{ $block[ $countblock - 1 ]};
			my @presentblock = @{ $block[ $countblock ]};
			my $lc = List::Compare->new( \@pastblock, \@presentblock );
			my @intersection = $lc->get_intersection;
			push ( @caseoverlaps, [ @intersection ] );
			$countblock++;
		}
		$countcase++;
	}
	return( @caseoverlaps );
}


sub calcmiditers
{
	my @varnumbers = @_;
	my $countcase = 0;
	my @mediters;
	foreach ( @varnumbers )
	{
		my $countblock = 0;
		foreach ( keys %$_ )
		{
			unless ( defined $mediumters[$countcase]{$_} )
			{
				$mediters[$countcase]{$_} = ( ceil( $varnumbers[$countcase]{$_} / 2 ) );
			}
		}
		$countcase++;
	} # TO BE CALLED WITH: calcmiditers(@varnumbers)
	return ( @mediters );
}


sub getitersnum
{ # IT GETS THE NUMBER OF ITERATION. UNUSED. CUT
	my $countcase = shift;
	my $varnumber = shift;
	my @varnumbers = @_;
	my $itersnum = $varnumbers[$countcase]{$varnumber};

	return $itersnum;
	# IT HAS TO BE CALLED WITH getitersnum($countcase, $varnumber, @varnumbers);
}


sub clean
{
  my ( $line, $mypath, $file ) = @_;
	$line =~ s/^$mypath// ; #say $tee "IN CLEAN \$line $line";
	$line =~ s/^\/// ; #say $tee "IN CLEAN \$line $line";
	$line =~ s/^$file// ; #say $tee "IN CLEpAN \$line $line";
	$line =~ s/^_// ; #say $tee "IN CLEAN \$line $line";
  $line =~ /_(\D+)$/ ; #say $tee "IN CLEAN \$line $line";
  $line =~ s/_$1$// ; #say $tee "IN CLEAN \$line $line";
  #$line =~ s/^-// ;
  return( $line );
}


sub makefilename # IT DEFINES A FILE NAME GIVEN A %carrier.
{
	my ( $tempc_r, $mypath, $file, $instn, $inst_ref, $dowhat_ref ) = @_;
	my %tempc = %{ $tempc_r }; #say $tee "IN MAKEFILENAME \$tempc $tempc";
	my %inst = %{ $inst_ref };
	my %dowhat = %{ $dowhat_ref };
	my $cleanto;
	foreach my $key (sort {$a <=> $b} (keys %tempc) )
	{
		$cleanto = $cleanto . $key . "-" . $tempc{$key} . "_";
	}
	$cleanto =~ s/_$// ; #say $tee "IN MAKEFILENAME \$cleanto $cleanto";

	my $to = "$mypath/$file" . "_" . "$cleanto"; #say $tee "IN MAKEFILENAME \$to $to";
	my $cleancrypto = $instn . "__"; #say $tee "IN MAKEFILENAME \$cleancrypto $cleancrypto";
	#my $cleancrypto = $instn . "-";
	my $crypto = "$mypath/$file" . "_" . "$cleancrypto"; #say $tee "IN MAKEFILENAME \$crypto $crypto";
	my $it; #say "DOWHATNAMES: " . $dowhat{names}; #say "DOWHAT: " . dump ( \%dowhat ) ;
	if ( $dowhat{names} eq "short" )
	{
		$it{to} = $to;
		$it{cleanto} = $cleanto;
		$it{crypto} = $crypto;
		$it{cleancrypto} = $cleancrypto;
	}
	elsif ( ( $dowhat{names} eq "long" ) or ( $dowhat{names} eq "" ) )
	{
		$it{to} = $to;
		$it{cleanto} = $cleanto;
		$it{crypto} = $to;
		$it{cleancrypto} = $cleanto;
	}
	return ( \%it );
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
	my ( $sweeps_ref, $countcase, $countblock ) = @_; #say $tee "In getblockelts; \$countblock: " . dump( $countblock) ;
	my @sweeps = @{ $sweeps_ref }; #say $tee "In getblockelts; \@sweeps: " . dump( @sweeps) ;
	#my @blockelts = sort { $a <=> $b } @{ $sweeps[$countcase][$countblock] };
	my @blockelts = @{ $sweeps[$countcase][$countblock] }; #say $tee "In getblockelts; \@blockelts: " . dump( @blockelts) ;
	return ( \@blockelts );
}


sub getrootname
{
	my ( $rootnames_r, $countcase ) = @_;
	my @rootnames = @{ $rootnames_r };
	my $rootname = $rootnames[$countcase];
	return ($rootname);
}



sub extractcase #  UPDATES THE FILE NAME ON THE BASIS OF A %carrier
{
	my ( $dowhat_ref, $transfile, $carrier_r, $file, $blockelts_r, $mypath, $instn ) = @_;
	#say $tee "In extractcase; \$transfile: " . dump( $transfile) ;
	#say $tee "In extractcase; \$file: " . dump( $file) ;
	my %carrier = %{ $carrier_r }; #say $tee "In extractcase; \%carrier: " . dump( \%carrier) ;
	my @blockelts = @{ $blockelts_r }; #say $tee "In extractcase; \@blockelts: " . dump( @blockelts ) ;
	my $num = scalar( @blockelts ); #say $tee "In extractcase; \$num: " . dump( $num ) ;
	my %dowhat = %{ $dowhat_ref };
	#say $tee "In extractcase; \$mypath: " . dump( $mypath ) ;
	#say $tee "In extractcase; \$instn: " . dump( $instn ) ;

	my %provhash;
	$transfile =~ s/^mypath\///; #say $tee "In extractcase1; \$transfile: " . dump( $transfile) ;
	$transfile =~ s/^$file//; #say $tee "In extractcase1; \$transfile: " . dump( $transfile) ;
	$transfile =~ s/^_//; #say $tee "In extractcase2; \$transfile: " . dump( $transfile) ;
	foreach my $parnum ( keys %carrier )
	{
		$transfile =~ /^(\d+)-(\d+)/;

		if ( ($1) and ($2) )
		{
			if ( $1 ~~ @blockelts )
			{
				$provhash{$1} = $2; #say $tee "In extractcase3; \$transfile: " . dump( $transfile) ;
			}
		}

		$transfile =~ s/^$1-$2//; #say $tee "In extractcase4; \$transfile: " . dump( $transfile) ;
		$transfile =~ s/^_//; #say $tee "In extractcase5; \$transfile: " . dump( $transfile) ;
	}
	#say $tee "In extractcase; \%provhash: " . dump( \%provhash ) ;

	my %tempc = %{ dclone( \%carrier )};
	foreach my $key ( keys %provhash )
	{
		if ( scalar( @blockelts > 0 ) )
		{
			if ( $key ~~ @blockelts )
			{
				$tempc{$key} = $provhash{$key};
			}
		}
		else
		{
			$tempc{$key} = $provhash{$key};
		}
	}

	#say $tee "In extractcase, OBTAINED \%carrier: " . dump( \%carrier ) ;
	my %to = %{ makefilename( \%tempc, $mypath, $file, $instn, \%inst, \%dowhat ) }; #say $tee "In extractcase!, RESULT1:; \%to: " . dump( \%to ) ;
	return( \%to );
}


sub definerootcases #### DEFINES THE ROOT-CASE'S NAME.
{
	my @sweeps = @{ $_[0] }; #say $tee "\@sweeps IN DEFINEROOTCASES " . dump( @sweeps );
	my @miditers = @{ $_[1] }; #say $tee "\@miditers IN DEFINEROOTCASES " . dump( @miditers );
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
	return (@rootnames); # IT HAS TO BE CALLED WITH: definerootcase(@miditers).
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
	my $elt = $arr[-1];
	return ($elt);
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


sub washn
{
	my ( @arr ) = @_;
	if ( ref( @arr[0] ) eq "ARRAY" )
	{
		@arr = @{ $arr[0] }; #say $tee "335 getcase \$itemref " . dump( $itemref );
	}
	return( @arr );
}


sub getcase
{
	my ( $varn_r, $countcase ) = @_; #say $tee "333 getcase \$countcase " . dump( $countcase );
	my @varnumbers = @{ $varn_r }; #say $tee "333 getcase \@varnumbers " . dump( @varnumbers );
	my ( $itemref, %item);
	if ( ref( @varnumbers[0] ) eq "HASH" )
	{
		$itemref = $varnumbers[$countcase]; #say $tee "333 getcase \$itemref " . dump( $itemref );
		%item = %{ $itemref }; #say $tee "333 getcase \%item " . dump( %item );
	}
	else
	{
		@varnumbers = @{ $varnumbers[$countcase] }; #say $tee "335 getcase \$itemref " . dump( $itemref );
	  $itemref = $varnumbers[$countcase]; #say $tee "335 getcase \$itemref " . dump( $itemref );
	  my %item = %{ $itemref }; #say $tee "335 getcase \%item " . dump( %item );
	} #say $tee "333 getcase leaving \@varnumbers " . dump( @varnumbers );
	return ( %item );
}


sub getstepsvar
{ 	# IT EXTRACTS $stepsvar
	my ( $countvar, $countcase, $varnumbers_r ) = @_; #say $tee "555 getstepsvar \$countvar " . dump( $countvar );
	my @varnumbers = @{ $varnumbers_r }; #say $tee "555 getstepsvar \@varnumbers" . dump( @varnumbers );
	#say $tee "555 getstepsvar \$varnumbers[ \$countcase ]" . dump( $varnumbers[ $countcase ] );
	my %varnums = getcase( \@varnumbers, $countcase ); #say $tee "555 getstepsvar \%varnums" . dump( %varnums );
	my $stepsvar = $varnums{$countvar}; #say $tee "555 getstepsvar \$stepsvar" . dump( $stepsvar );
	return ( $stepsvar )
} #getstepsvar($countvar, $countcase, \@varnumbers);


sub givesize
{	# IT RETURNS THE SEARCH SIZE OF A BLOCK.
	my $sliceref = shift;
	my @slice = @$sliceref;
	my $countcase = shift;
	my $varnumberref = shift;
	my $product = 1;
	foreach my $elt (@slice)
	{
		my $stepsize = Sim::OPT::getstepsvar( $elt, $countcase, $varnumberref );
		$product = $product * $stepsize;
	}
	return ($product); # TO BE CALLED WITH: givesize(\@slice, $countcase, \@varnumbers);, WHERE SLICE MAY BE @blockelts in SIM::OPT OR @presentslice OR @pastslice IN Sim::OPT::Takechance
}


sub wash # UNUSED. CUT.
{
	my @instances = @_;
	my @bag;
	my @rightbag;
	foreach my $instanceref (@instances)
	{
		my %d = %{ $instanceref };
		my %to = %{ $d{$to} };
		push ( @bag, $to{cleanto} );
	}
	my $count = 0;
	foreach my $instanceref (@instances)
	{
		my %d = %{ $instanceref };
		my %to = %{ $d{$to} };
		if ( not ( $to{cleanto} ~~ @bag ) )
		{
			push ( @rightbag, $to{cleanto} );
		}
	}
	return ( @rightbag ); # TO BE CALLED WITH wash(@instances);
}


sub flattenbox
{
	my ( $eltss_r ) = @_;
	my @basket;
	foreach my $eltsref ( @{ $eltss_r } )
	{
		my @elts = @$eltsref;
		push (@basket, @elts );
	}
	return( \@basket );
}


sub integratebox
{
	my @arrelts = @{ $_[0] }; #say $tee "IN INTEGRATEBOX \@arrelts " . dump( @arrelts ) ;
	my %carrier = %{ $_[1] }; #say $tee "IN INTEGRATEBOX \%carrier " . dump( \%carrier ) ;
	my $file = $_[2]; #say $tee "IN INTEGRATEBOX \$file $file" ;
	my @blockelts = @{ $_[3] }; #say $tee "IN INTEGRATEBOX \@blockelts @blockelts" ;
	my $mypath = $_[4]; #say $tee "IN INTEGRATEBOX \$mypath $mypath" ;
	my %dowhat = %{ $_[5] };
	my @newbox;
	if ( ref( $arrelts[0] ) )
	{
		foreach my $eltref ( @arrelts )
		{
			my @elts = @{ $eltref }; #say $tee "IN INTEGRATEBOX \@elts @elts" ;
			my $target = $elts[0]; #say $tee "IN INTEGRATEBOX Target $target" ;
			#say $tee "PRE EXTRACTCASE IN INTEGRATEBOX \$target $target" ;
			my %righttarg = %{ extractcase( \%dowhat, $target, \%carrier, $file, \@blockelts, $mypath ) }; #say $tee "IN INTEGRATEBOX \%righttarg " . dump(  \%righttarg ) ;
			my $righttarget = $righttarg{cleanto}; #say $tee "IN INTEGRATEBOX \$righttarget $righttarget" ;
			my $origin = $elts[3]; #say $tee "IN INTEGRATEBOX \$origin $origin" ;
			#say $tee "PRE EXTRACTCASE IN INTEGRATEBOX \$origin $origin";
			my %rightorig = %{ extractcase( \%dowhat, $origin, \%carrier, $file, \@blockelts, $mypath ) }; #say $tee "IN INTEGRATEBOX \%rightorig " . dump(  \%rightorig ) ;
			my $rightorigin = $rightorig{cleanto}; #say $tee "IN INTEGRATEBOX \$rightorigin " . dump(  \$rightorigin ) ;
			push ( @newbox, [ $righttarget, $elts[1], $elts[2], $rightorigin, $elts[4] ] );
		} #say $tee "IN INTEGRATEBOX \@newbox " . dump( @newbox ) ;
		return ( \@newbox );
	}
}


sub filterbox
{
	my ( $arr_r ) = @_;
	@arr = @_;
	my @basket;
	my ( @box, @dish );
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
					push ( @bucket, $case, $case->[4] );
				}
			}
			my $parent = $bucket[0];
			push ( @basket, $parent );
			foreach ( @basket )
			{
				#my %varnums = %{ $varnumsref };
				push ( @box, $_->[0], $case->[4] );
			}
		}
	}
	#say $tee "IN FILTER BOX: " . dump( @box );
	#say $tee "IN FILTER BASKET: " . dump( @basket );
	#return( @box );
	return( @basket );
}



sub filterbox_delete
{
	my ( $arr_r ) = @_;
	@arr = @{ $arr_r };
	my @basket;
	foreach my $case ( @arr )
	{ $case->[0];
		push ( @basket, $case->[0] );
	}
	return( @basket );
}


sub tellstring
{
	my ( $mids_ref, $file ) = @_;
	my %mids = %{ $mids_ref };
	my $starstring;
	foreach my $key ( sort {$a <=> $b} ( keys %mids ) )
	{
		$starstring = "$starstring" . "$key" . "-" . $mids{$key} . "_";
	}
	if ( $starstring ne "" )
	{
		$starstring = $file . "_" . $starstring;
	}
	return( $starstring );
}


sub prunethis
{
	my $aref = shift;
	my @arr = @{ $aref };
	my @newarr = map
	{
		if ( ref( $_ ) )
		{ prunethis( $_ ); }
		elsif ( $_ =~ />/ )
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


sub cleansweeps
{
	my @struct = @{ $_[0] };
	my @sourcestruct = @{ dclone( \@struct ) };
	my @outbag;
	foreach my $e ( @struct )
	{
		my @midbag;
		foreach my $el ( @{ $e } )
		{
			my @inbag;
			foreach my $elt ( @{ $el } )
			{
				$elt =~ s/^(\d+)>// ;
				$elt =~ s/[A-za-z]+//g ;
				$elt =~ s/<//g ;
				$elt =~ s/£//g ;
				$elt =~ s/§//g ;
				$elt =~ s/\|//g ;
				push( @inbag, $elt );
			}
			push( @midbag, [ @inbag ] );
		}
		push( @outbag, [ @midbag ] );
	}
	return ( \@outbag, \@sourcestruct );
}


sub gencen
{
  my @varnums =  @{ $_[0] };
  my @newmids;
  foreach my $hs_ref ( @varnums )
  {
    my %newhs;
    my %hs = %{ $hs_ref };
    foreach my $key ( sort { $a <=> $b } ( keys %hs ) )
    {
      my $newval = ( int( $hs{$key} / 2 ) + 1 );
      $newhs{$key} = $newval;
    }
    push( @newmids, \%newhs );
  }
  return( \@newmids );
}


sub genextremes
{
  my @varnums =  @{ $_[0] };
  my @newmids;
  foreach my $hs_ref ( @varnums )
  {
    my %newhs;
    my %hs = %{ $hs_ref };
    foreach my $key ( sort { $a <=> $b } ( keys %hs ) )
    {
      my $newval = 1 ;
      $newhs{$key} = $newval;
    }
    push( @newmids, \%newhs );
    push( @newmids, \%hs );
  }
  return( \@newmids );
}


sub gencentres
{
  my ( $vars_ref ) =  @_;
  my @vars = @{ $vars_ref };
  my @varcopy = @vars;
  my $numelts = scalar( @vars );
  my $numcases = ( $numelts / 2 );
  my $c = 0;
  while ( $c < ( $numelts - 1 ) )
  {
    my %newhs;
    my @box;
    my %hsmin = %{ $vars[$c] };
    my %hsmax = %{ $vars[$c+1] };
    my $signal = 0;
    my $inv;
    foreach my $key ( sort { $a <=> $b } ( keys %hsmax ) )
    {
      my $newval = ( int( ( $hsmax{$key} - $hsmin{$key} ) / 2 ) + $hsmin{$key} ) ; #say "\$newval: " . dump ( $newval );
      if ( ( $newval == $hsmax{$key} ) or ( $newval == $hsmin{$key} ) )
      {
        my @newpair;
        my $answer = odd__( $signal ); #say "\$answer: " . dump ( $answer );
        if ( $answer eq "even" )
        {
          $value = $array[ int(rand( @array + 1 )) ];
          my @ar = ( $hsmax{$key}, $hsmin{$key} );
          $newval = $ar[ int( rand( @ar + 1 ) ) ]; #say "newpair1: " . dump ( @newpair );
          if ( $hsmax{$key} == $newval )
          {
            $inv = "no";
          }
          else
          {
            $inv = "yes";
          }
        }
        else
        {
          if ( $inv = "no" )
          {
            @newpair = ( $hsmin{$key}, $hsmax{$key} ); #say "newpair 2: " . dump ( @newpair );
          }
          else
          {
            @newpair = ( $hsmax{$key}, $hsmin{$key} ); #say "newpair 3: " . dump ( @newpair );
          }
          $newval = $newpair[0];
        }
        $signal++;
      }
      $newhs{$key} = $newval;
    }
    splice( @varcopy, ( ( $c * 2 ) + 1 ), 0, \%newhs );
    $c++;
  }
  return( \@varcopy );
}


sub starsweep
{
  my ( $varns_r, $sweeps_r ) = @_;
  my %firstvarn = %{ $varns_r->[0] }; #say $tee "IN STARSWEEP \%firstvarn: " . dump( \%firstvarn );
  my @firstsweep = @{ shift( @{ $sweeps_r } ) }; #say $tee "IN STARSWEEP \@firstsweep: " . dump( \@firstsweep );
	my @restsweeps = @{ $sweeps_r }; #say $tee "IN STARSWEEP \@restsweeps: " . dump( \@restsweeps );
	my ( @box );
  foreach $par ( sort { $a <=> $b } ( keys %firstvarn ) )
  {
		push( @box, [ $par ] ); #say "\$par: " . dump( \$par );
  } #say "\@box: " . dump( \@box );
  unshift( @restsweeps, ( [ @box ] ) ); #say "\@sweeps: " . dump( \@sweeps );
  return( \@restsweeps );  #say $tee "IN STARSWEEP \@restdirs: " . dump( \@restdirs );  say $tee "IN STARSWEEP \@restords: " . dump( \@restords );
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


sub stararrange
{
	my ( $sweeps_ref, $blockelts_ref, $varnumbers_ref, $countcase, $countblock, $file ) = @_;
	my @sweeps = @{ $sweeps_ref };
	my @blockelts = @{ $blockelts_ref };
	my @varnumbers = @{ $varnumbers_ref }; #say $tee "IN STARARRANGE \@varnumbers " . dump( @varnumbers );
	my %varnums = getcase( \@varnumbers, $countcase );
	my @vars = ( keys %varnums );
	my @diffs = Sim::OPT::Interlinear::diff( \@vars, \@blockelts ); #say $tee "IN STARARRANGE @diffs " . dump( @diffs );

	my @newhash;
	foreach my $var ( @blockelts )
	{
		push( @newhash, $var );
		push( @newhash, $varnums{$var} );
	}

	foreach my $diff ( @diffs )
	{
		push( @newhash, $diff );
		push( @newhash, 1 );
	} #say $tee "IN STARARRANGE \@newhash " . dump( @newhash );
	my %temp = @newhash; #say $tee "IN STARARRANGE \%temp " . dump( \%temp );
	$varnumbers[$countcase] = \%temp; #say $tee "IN STARARRANGE \$varnumbers[\$countcase] " . dump( $varnumbers[$countcase] );
	return( \@varnumbers );
}



sub star_act
{
	my ( $sweeps_r, $blockelts_r, $countcase, $countblock ) = @_;
	my @sweeps = @{ $sweeps_r }; #say $tee "IN star_act \@sweeps: " . dump( @sweeps );
	my @blockelts = @{ $blockelts_r }; #say $tee "IN star_act \@blockelts: " . dump( @blockelts );

	my @bag;
	foreach my $elt ( @blockelts )
	{
		push( @bag, [ $elt ] );
	} #say $tee "IN star_act \@bag: " . dump( @bag );

	my @basket;
	foreach my $sweepcase ( @sweeps )
	{ my @box;
		foreach my $sweep ( @{ $sweepcase } )
		{
			my @diff = Sim::OPT::Interlinear::diff( $sweep, \@blockelts );
			if ( not( scalar( @diff ) == 0 ) )
			{
				push( @box, $sweep )
			}
			else
			{
				push( @box, [ @bag ] );
			}
			push( @basket, [ @box ] );
		}
	} #say $tee "IN star_act \@basket: " . dump( @basket );
	return( \@basket, \@bag );
} ### END SUB star_act



sub solvestar
{
	my %d = %{ $_[0] };
	my %dirfiles = %{ $d{dirfiles} };
	my %dowhat = %{ $d{dowhat} };
	my @varnumbers = @{ $d{varnumbers} };
	my %carrier = %{ $d{carrier} };
	my @blockelts = @{ $d{blockelts} };

	$dirfiles{direction} = "star";
	$dirfiles{starorder} = $dowhat{starorder}->[countcase]->[0];

	my ( @gencetres, @genextremes, @genpoints, $genextremes_ref, $gencentres_ref,
		@starpositions, @dummysweeps );


	if ( $dirfiles{stardivisions} ne "" )
	{
		$dirfiles{starpositions} = genstar( \%dirfiles, \@varnumbers, \%carrier, \@blockelts );

		( $dirfiles{dummysweeps}, $dirfiles{dummyelt} ) = @{ star_act( \@sweeps, \@blockelts, $countcase, $countblock ) };
	} ### if ( not( scalar( @{ $dirfiles{starpositions} } ) == 0 ) )YOU CAN CUT THIS. THE OBTAINED VARIABLES ARE UNUSED
	#say $tee "IN SOLVESTAR!! \$dirfiles{starpositions}: " . dump( $dirfiles{starpositions} );
	#say $tee "IN SOLVESTAR \$dirfiles{dummysweeps}: " . dump( $dirfiles{dummysweeps} );

	$dirfiles{starnumber} = scalar( @{ $dirfiles{starpositions} } ); #say $tee "AFTER \$dirfiles{starnumber}: " . dump( $dirfiles{starnumber} );

	if ( not( scalar( @{ $dirfiles{starpositions} } ) == 0 ) )
	{
		$dirfiles{direction} => [ [ "star" ] ],
		$dirfiles{randomsweeps} => "no", # to randomize the order specified in @sweeps.
		$dirfiles{randominit} => "no", # to randomize the init levels specified in @miditers.
		$dirfiles{randomdirs} => "no", # to randomize the directions of descent.
	}
	return( \%dirfiles )
} ### END SUB solvestar


sub takewinning
{
	my ( $toitem ) = @_;

	my %carrier = split( "_|-", $toitem ); #say $tee "IN takewinning ( \%carrier) " . dump( \%carrier );
	return( \%carrier );
}


sub sense
{
	#say $tee "WORKING.";
	my ( $addr, $mypath, $objcolumn, $stopcondition ) = @_;
	#say $tee "IN SENSE \$addr: " . dump( $addr );
	#say $tee "IN SENSE \$mypath: " . dump( $mypath );
	#say $tee "IN SENSE \$objcolumn: " . dump( $objcolumn );
	#say $tee "IN SENSE \$stopcondition: " . dump( $stopcondition );

	my $newaddr = "$mypath/$addr" . "_variances.csv"; #say $tee "IN SENSE \$newaddr: " . dump( $newaddr );

	open( ADDR, "$addr" ) or die;
	my @lines = <ADDR>;
	close ADDR;

	my @purelines;
	foreach my $line ( @lines )
	{
		chomp $line;
		push( @purelines, $line );
	}

	#say $tee "IN SENSE \@lines: " . dump( @lines );

	my @values = map { ( split( ',', $_ ))[ $objcolumn ] } @purelines; #say $tee "IN SENSE \@values: " . dump( @values );
	my $totvariance = variance( @values ); #say $tee "IN SENSE \$totvariance: $totvariance" ;

	my @cases = map { ( split( ',', $_ ))[0] } @purelines; #say $tee "IN SENSE \@cases: " . dump( @cases );

	my @sack;
	foreach my $case ( @cases )
	{
		my @row = split( "_", $case );
		push( @sack, [ @row ] );
	} #say $tee "IN SENSE \@sack: " . dump( @sack );

	my %whole;
	my $count = 0;
	foreach my $case ( @sack )
	{
		my @temp;
		foreach my $pair ( @{ $case } )
		{
			my ( $key, $value ) = split( "-", $pair );
			push( @{ $whole{$key}{$value} }, $values[$count] );
		}
		$count++;
	} #say $tee "IN SENSE \%whole: " . dump( \%whole );

	my ( %sensfs, %avgsensfs );
	#say $tee "IN SENSE keys \%whole: " . dump( keys %whole );
	foreach my $factor ( keys %whole )
	{
		#say $tee "IN SENSE \$factor: " . dump( $factor );
		my @avgvar; #say $tee "IN SENSE keys %{ \$whole{\$factor} }: " . dump( keys %{ $whole{$factor} } );
		foreach my $level ( keys %{ $whole{$factor} } )
		{
			#say $tee "IN SENSE \$level: " . dump( $level );
			my $variance = variance( @{ $whole{$factor}{$level} } ); #say $tee "IN SENSE \$variance: $variance" ;
			my $variancerat = ( $variance / $totvariance ); #say $tee "IN SENSE \$variancerat: $variancerat" ;
			$sensfs{$factor}{$level} = $variancerat;
			push( @avgsensf, $variancerat );
		}
		my $mean = mean( @avgsensf );
		$avgsensfs{$factor} = $mean; #say $tee "IN SENSE \$mean: " . dump( $mean );
	} #say $tee "IN SENSE \%sensfs: " . dump( \%sensfs ); say $tee "IN SENSE \%avgsensfs: " . dump( \%avgsensfs );

	open( NEWADDR, ">$newaddr" ) or die;
	foreach my $fact ( sort{ $a <=> $b }( keys %avgsensfs ) )
	{
		say NEWADDR "$fact: $avgsensfs{$fact}";
	}
	close NEWADDR;
	if ( $stopcondition eq "stop" )
	{
		exit;
	}
}


sub prepfactl
{
  my @arr = @{ $_[0] }; #say $tee "IN prepfactl \@arr:" . dump( @arr ) ;
  my ( %hash, %hs );

  foreach my $el ( @arr )
  {
		my %hash = split( "-|_", $el ); #say $tee "IN prepfactl \%hash:" . dump( \%hash ) ;
		foreach my $key ( keys %hash )
		{
			$hs{$key}{$hash{$key}} = "";
		}
  }
	#say $tee "IN prepfactl \%hs:" . dump( \%hs ) ;

	my %ohs;
	my $num = 0;
	#say $tee "IN prepfactl keys \%hs:" . dump( keys %hs ) ;
	foreach my $key ( keys %hs )
	{
		foreach my $item ( sort { $a <=> $b }( keys %{ $hs{$key} } ) )
		{
			push( @{ $ohs{$key} }, $item );
			$num++;
		}
		$ohs{$key} = [ uniq( @{ $ohs{$key} } ) ];
	} #say $tee "IN prepfactl \$num:" . dump( $num ) ; say $tee "IN prepfactl \%ohs:" . dump( \%ohs ) ;
  return( $num, \%ohs );
}


sub callblock # IT CALLS THE SEARCH ON BLOCKS.
{
	my %d = %{ $_[0] };
	my $countcase = $d{countcase}; #say $tee "IN callblock ( \$countcase) " . dump($countcase);
	my $countblock = $d{countblock}; #say $tee "IN callblock ( \$countblock) " . dump($countblock);
	my @sweeps = @{ $d{sweeps} }; #say $tee "IN callblock \@sweeps " . dump(@sweeps);
	my @sourcesweeps = @{ $d{sourcesweeps} }; #say $tee"IN callblock \@sourcesweeps " . dump(@sourcesweeps);
	my @miditers = @{ $d{miditers} };
	@miditers = Sim::OPT::washn( @miditers ); #say $tee "IN callblock \@miditers " . dump( @miditers );
	my @winneritems = @{ $d{winneritems} }; #say $tee "IN callblock \@winneritems " . dump( @winneritems );
	my %dirfiles = %{ $d{dirfiles} }; #say $tee "IN callblock \%dirfiles " . dump( %dirfiles );
	my %datastruc = %{ $d{datastruc} };
	my %dowhat = %{ $d{dowhat} }; #say $tee "IN callblock \%dowhat" . dump( %dowhat );
	my @varnumbers = @{ $d{varnumbers} };
	my $instn = $d{instn}; #say $tee "IN callblock \$instn" . dump( $instn );
	my %inst = %{ $d{inst} }; #say $tee "IN callblock \%inst " . dump( \%inst );
	@varnumbers = Sim::OPT::washn( @varnumbers ); #say $tee"IN callblock ( \@varnumbers) " . dump( @varnumbers );

	if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
  {
		if ( $dirfiles{checksensitivity} eq "yes" )
		{
			Sim::OPT::sense( $dirfiles{ordtot}, $mypath, $dirfiles{objectivecolumn} );
		}
    exit(say $tee "#END RUN.");
  }

	say $tee "#Beginning a search on case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

	my @blockelts = @{ getblockelts( \@sweeps, $countcase, $countblock ) }; #say $tee "IN callblock \@blockelts " . dump( @blockelts );

	my @sourceblockelts = @{ getblockelts( \@sourcesweeps, $countcase, $countblock ) }; #say $tee "IN callblock \@sourceblockelts " . dump( @sourceblockelts );


	my $entryname;
	if ( $sourceblockelts[0] =~ /^([A-Za-z]+)/ )
	{
		$entryname = $1;
		$dirfiles{entryname} = $entryname;
	}
	else
	{
		$dirfiles{entryname} = "";
	} #say $tee "IN callblock 2 \$entryname " . dump( $entryname );


	my $exitname;
	if ( $sourceblockelts[-1] =~ /([A-Za-z]+)$/ )
	{
		$exitname = $1;
		$dirfiles{exitname} = $exitname;
	}
	else
	{
		$dirfiles{exitname} = "";
	} #say $tee "IN callblock 3 \$exitname " . dump( $exitname );


	#say $tee "IN callblock6: \$sourceblockelts[0] " . dump( $sourceblockelts[0] );
	if ( $sourceblockelts[0] =~ />/ )
	{ #say $tee "IN callblock IN: \$sourceblockelts[0] " . dump( $sourceblockelts[0] );
		$dirfiles{starsign} = "yes"; #say $tee "SETTING IN callblock: \$dirfiles{starsign} " . dump( $dirfiles{starsign} );
		$sourceblockelts[0] =~ /^(\d+)>/ ;
		$dirfiles{stardivisions} = $1;
	}
	else
	{
		$dirfiles{starsign} = "no";
		$dirfiles{stardivisions} = "";
	}
	#say $tee "IN callblock 3 \$dirfiles{starsign} " . dump( $dirfiles{starsign} );
	#say $tee "IN callblock 3 \$dirfiles{stardivisions} " . dump( $dirfiles{stardivisions} );


	if ( $sourceblockelts[0] =~ /\|/ )
	{
		$dirfiles{random} = "yes";
	}
	else
	{
		$dirfiles{random} = "no";
	}

	if ( $sourceblockelts[0] =~ /§/ )
	{
		$dirfiles{latinhypercube} = "yes";
	}
	else
	{
		$dirfiles{latinhypercube} = "no";
	}

	if ( $sourceblockelts[0] =~ /</ )
	{
		$dirfiles{factorial} = "yes";
	}
	else
	{
		$dirfiles{factorial} = "no";
	}


	if ( $sourceblockelts[0] =~ /£/ )
	{
		$dirfiles{facecentered} = "yes";
		$dirfiles{factorial} = "yes";
		$dirfiles{random} = "yes";
		$dirfiles{starsign} = "yes"; #say $tee "SETTING IN callblock: \$dirfiles{starsign} " . dump( $dirfiles{starsign} );
		$dowhat{starpositions} = "";
		$dirfiles{starpositions} = "";
		$dowhat{stardivisions} = 1;
		$dirfiles{stardivisions} = 1;
	}
	else
	{
		$dirfiles{facecentered} = "no";
	}


	my @blocks = getblocks( \@sweeps, $countcase );

	my $toitem = getitem( \@winneritems, $countcase, $countblock ); #say $tee "IN12 callblock \$toitem" . dump( $toitem ); #say $tee "IN12 callblock \$mypath" . dump( $mypath ); say $tee "IN12 callblock \$file" . dump( $file ); ###
	$toitem = clean( $toitem, $mypath, $file ); #say $tee "IN12 callblock \$toitem " . dump( $toitem );
	#say $tee "IN12 callblock \@winneritems " . dump( @winneritems );
	#say $tee "IN12 callblock \$countcase " . dump( $countcase );
	#say $tee "IN12 callblock \$countblock " . dump( $countblock );

	my $from = getline($toitem);
	$from = clean( $from, $mypath, $file ); #say $tee "IN12 callblock \$from " . dump( $from );

	my $file = $dowhat{file};

	#my %intermids = getcase( \@miditers, $countcase ); say $tee "IN callblock \%intermids" . dump( \%intermids ); # UNUSED. CUT,
	#say $tee "IN callblock \$toitem" . dump( \$toitem ); ###
	my %carrier = %{ takewinning( $toitem ) }; #say $tee "FROM TAKEWINNING IN callblock \%carrier " . dump( \%carrier ); ###


	#say $tee "IN callblock  \$dirfiles{starsign} " . dump( $dirfiles{starsign} );
	my @tempvarnumbers;
	if ( $dirfiles{starsign} eq "yes" )
	{
		my @newvarnumbers = @{ stararrange( \@sweeps, \@blockelts, \@varnumbers, $countcase, $countblock, $file ) }; #say $tee "IN2 callblock \@newvarnumbers " . dump( @newvarnumbers );
		$dirfiles{varnumbershold} = dclone( \@varnumbers ); #say $tee "IN2 BEFORE callblock  \$dirfiles{varnumbershold} " . dump( $dirfiles{varnumbershold} );
		@varnumbers = @{ dclone( \@newvarnumbers ) };
		@varnumbers = Sim::OPT::washn( @varnumbers ); #say $tee "IN2 AFTER callblock dcloned \@varnumbers " . dump( @varnumbers );

		%dirfiles = %{ solvestar( { dirfiles => \%dirfiles, dowhat => \%dowhat, varnumbers => \@varnumbers, blockelts => \@blockelts, carrier => \%carrier } ) };

		my @newmiditers = @{ $dirfiles{starpositions} }; #say $tee "IN2 callblock \@newmiditers " . dump( @newmiditers );
		# IT CORRECTS THE PART OF @miditers OUTSIDE THE BLOCKS

		$dirfiles{miditershold} = dclone( \@miditers ); #say $tee "IN2 BEFORE callblock  \$dirfiles{miditershold} " . dump( $dirfiles{miditershold} );

		#sub checkmids
		#{
		#	my ( $newmiditers_r, $miditershold ) = @_;
		#	my @newmiditers = @{ $newmiditers_r };
		#	my @oldmiditers = @{ $miditershold };
		#	my $oldmids_r = $oldmiditers[0];
		#	my %oldmids = %{ $oldmids_r };
		#	my @news;
		#	foreach my $mids_r ( @newmiditers )
		#	{
		#		my %mids = %{ $mids_r };
		#		foreach my $key ( keys %mids )
		#		{
		#			if ( not ( $key ~~ @blockelts ) )
		#			{
		#				$mids{$key} = $oldmids{$key};
		#			}
		#		}
		#		push( @news, \%mids );
		#	}
		#	return( \@news );
		#}
		#
		#@newmiditers = @{ checkmids( \@newmiditers, $dirfiles{miditershold} ) }; #say $tee "IN2 callblock POST-PROCESSED \@newmiditers " . dump( @newmiditers );

		@miditers = @{ dclone( \@newmiditers ) }; #say $tee "IN2 AFTER callblock dcloned \@miditers " . dump( @miditers );
	  #@miditers = Sim::OPT::washn( @miditers ); say $tee "IN2 AFTER callblock dcloned \@miditers " . dump( @miditers );
		#say $tee "IN2 callblock  \$dirfiles{starpositions} " . dump( $dirfiles{starpositions} );
	}

	my %mids = getcase( \@miditers, $countcase ); #say $tee "IN callblock \%mids " . dump( \%mids );
	my %varnums = getcase( \@varnumbers, $countcase ); #say $tee "IN callblock \%varnums " . dump( \%varnums );

  ###########################################################

	$dirfiles{simlist} = "$mypath/$file-simlist--$countcase";
	$dirfiles{morphlist} = "$mypath/$file-morphlist--$countcase";
	$dirfiles{retlist} = "$mypath/$file-retlist$sweeps_ref--$countcase";
	$dirfiles{replist} = "$mypath/$file-replist--$countcase"; # # FOR RETRIEVAL
	$dirfiles{descendlist} = "$mypath/$file-descendlist--$countcase"; # UNUSED FOR NOW
	$dirfiles{simblock} = "$mypath/$file-simblock--$countcase-$countblock";
	$dirfiles{morphblock} = "$mypath/$file-morphblock--$countcase-$countblock";
	$dirfiles{retblock} = "$mypath/$file-retblock--$countcase-$countblock";
	$dirfiles{repblock} = "$mypath/$file-repblock--$countcase-$countblock"; # # FOR RETRIEVAL
	$dirfiles{repfile} = "$mypath/$file-report-$countcase-$countblock.csv"; #say "IN CALLBLOCK REPFILE:" . ( $dirfiles{repfile} ) . " .";
	$dirfiles{sortmixed} = "$dirfiles{repfile}" . "_sortm.csv"; #say "IN CALLBLOCK sortmixed:" . ( $dirfiles{sortmixed} ) . " .";
	$dirfiles{totres} = "$mypath/$file-$countcase" . "_totres.csv"; #say "IN CALLBLOCK totres:" . ( $dirfiles{totres} ) . " .";
	$dirfiles{ordres} = "$mypath/$file-$countcase" . "_ordres.csv"; #say "IN CALLBLOCK ordres:" . ( $dirfiles{ordres} ) . " .";
	#$dirfiles{metafile} = "$dirfiles{repfile}" . "_meta.csv"; say "IN CALLBLOCK \$dirfiles{metafile}:" . ( $dirfiles{metafile} ) . " .";
	#$dirfiles{ordmeta} = "$dirfiles{repfile}" . "_ordmeta.csv"; say "IN CALLBLOCK \$dirfiles{ordmeta}:" . ( $dirfiles{ordmeta} ) . " .";say "IN CALLBLOCK sortmixed:" . ( $dirfiles{sortmixed} ) . " .";


	#say $tee "IN CALLBLOditersCK \@{ \$dirfiles{starpositions} } " . dump( @{ $dirfiles{starpositions} } ); ##VOID!

	deffiles( {	countcase => $countcase, countblock => $countblock,
		miditers => \@miditers,  winneritems => \@winneritems,
		dirfiles => \%dirfiles, toitem => $toitem, from => $from,
		sweeps => \@sweeps, sourcesweeps => \@sourcesweeps, datastruc => \%datastruc,
		dowhat => \%dowhat, varnumbers => \@varnumbers,
		mids => \%mids, varnums => \%varnums, carrier => \%carrier,
		carrier => \%carrier, sourceblockelts => \@sourceblockelts,
		blocks => \@blocks, blockelts => \@blockelts, instn => $instn, inst => \%inst } );
}


sub deffiles # IT DEFINED THE FILES TO BE PROCESSED
{
	my %d = %{ $_[0] };
	#say $tee "IN DEFFILES \$dummyelt " . dump( $dummyelt );
	#say $tee "SO, \$c : " . dump( $c );

	my $countcase = $d{countcase}; #say $tee "IN DEFFILES \$countcase : " . dump( $countcase );
  my $countblock = $d{countblock}; #say $tee "IN DEFFILES \$countblock : " . dump( $countblock );
	my @sweeps = @{ $d{sweeps} }; #say $tee "IN DEFFILES \@sweeps : " . dump( @sweeps );
	my @sourcesweeps = @{ $d{sourcesweeps} }; #say $tee "IN DEFFILES \@sourcesweeps : " . dump( @sourcesweeps );
	my @miditers = @{ $d{miditers} }; #say $tee "IN DEFFILES \@miditers : " . dump( @miditers );
	my @winneritems = @{ $d{winneritems} }; #say $tee "\@winneritems : " . dump( @winneritems );
	my %dirfiles = %{ $d{dirfiles} }; #say $tee "IN deffiles \%dirfiles " . dump( %dirfiles );
	#say $tee "IN DEFFILES \$dirfiles{starsign} " . dump( $dirfiles{starsign} );
	my %datastruc = %{ $d{datastruc} }; #say $tee "\%datastruc : " . dump( %datastruc );
	my @varnumbers = @{ $d{varnumbers} }; #say $tee "IN DEFFILES \@varnumbers" . dump( @varnumbers );
	my %dowhat = %{ $d{dowhat} }; #say $tee "IN DEFFILES \%dowhat" . dump( %dowhat );

	my @blockelts = @{ $d{blockelts} }; #say $tee "IN DEFFILES \@blockelts : " . dump( @blockelts );
	my @sourceblockelts = @{ $d{blockelts} }; #say $tee "IN DEFFILES \@sourceblockelts : " . dump( @blockelts );
	my @blocks = @{ $d{blocks} }; #say $tee "IN DEFFILES \@blocks : " . dump( @blocks );
	my $toitem = $d{toitem}; #say $tee "IN12 DEFFILES12 \$toitem : " . dump( $toitem );
	my $from = $d{from}; #say $tee "IN DEFFILES \$from " . dump( $from );
	my %varnums = %{ $d{varnums} }; #say $tee "IN DEFFILES \%varnums " . dump( \%varnums );
	my %mids = %{ $d{mids} }; #say $tee "IN DEFFILES \%mids " . dump( \%mids );
	my %carrier = %{ $d{carrier} }; #say $tee "IN DEFFILES \%carrier " . dump( \%carrier );
	my $instn = $d{instn};
	my %inst = %{ $d{inst} };

	#say $tee "IN IN DEFFILES  \$dirfiles{starsign} " . dump( $dirfiles{starsign} );
	my $file = $dowhat{file}; #say $tee "IN DEFFILES \$file " . dump( $file );
	my $mypath = $dowhat{mypath};

	my $starstring = tellstring( \%mids, $file ); #say $tee "IN2 DEFFILES1 \$starstring " . dump( $starstring );
	$dirfiles{starstring} = $starstring; # FOR THE OUTTER STAR SEARCH

	my $rootitem = "$file" . "_"; #say $tee "IN DEFFILES \$rootitem : " . dump( $rootitem );
	my (@basket, @box);
	push (@basket, [ $rootitem ] ); #say $tee "IN DEFFILES \@basket : " . dump( @basket );



	sub toil
	{
		my ( $blockelts_r, $varnums_r, $basket_r, $c, $mypath, $file ) = @_;
		my @blockelts = @{ $blockelts_r }; #say $tee "IN TOIL \@blockelts : " . dump( @blockelts );
		my %varnums = %{ $varnums_r }; #say $tee "IN TOIL \%varnums : " . dump( %varnums );

		my @basket = @{ $basket_r }; #say $tee "IN TOIL \@basket : " . dump( @basket );
		if ( ( $c eq "" ) or ( $c == 0 ) )
		{
			@box = ();
		}

		foreach my $var ( @blockelts )
		{
			my ( @bucket );
			my $maxvalue	= $varnums{$var}; #say $tee "IN TOIL \$maxvalue : " . dump( $maxvalue );

			foreach my $elt ( @basket )
			{
				my $root = $elt->[0]; #say $tee "IN TOIL \$root : " . dump( $root );
				my @bag;
				my $item;
				my $cnstep = 1;
				while ( $cnstep <= $maxvalue)
				{	#say $tee "IN TOIL \$countblock : " . duvernummp( $countblock );
					my $olditem = $root; #say $tee "IN TOIL \$olditem : " . dump( $olditem );
					$item = "$root" . "$var" . "-" . "$cnstep" . "_" ;  #say $tee "IN TOIL \$item : " . dump( $item );
					push ( @bag, [ $item, $var, $cnstep, $olditem, $c ] ); #say $tee "IN TOIL \@bucket: " . dump( @bucket );
					$cnstep++; #say $tee "IN TOIL \$cnstep : " . dump( $cnstep );
				}
				push ( @bucket, @bag );
				#push ( @bucket, [ $item, $var, $cnstep, $olditem, $c ] ); #say $tee "IN TOIL \@bucket: " . dump( @bucket );
			}
			@basket = ();
			@basket = @bucket;

			if ( $c eq "" )
			{
				push ( @box, [ @bucket ] );
			}
			else
			{
				@box = [ @bucket ];
			}
		} #say $tee "IN TOIL \@box : " . dump( @box );
		return( \@box );
	}


	my ( @bux, @buux );
	if ( ( $dirfiles{starsign} eq "yes" ) or
			( ( $dirfiles{random} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
			( ( $dirfiles{latinhypercube} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
			( ( $dirfiles{factorial} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
			( ( $dirfiles{facecentered} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) )
	{


		if ( $dirfiles{starsign} eq "yes" )
		{
			my $c = 0;
			foreach my $elt ( @blockelts )
			{
				my @dummys = ( $elt );
				my @bix = @{ toil( \@dummys, \%varnums, \@basket, $c, $mypath, $file ) }; #say $tee "IN DEFFILES2 \@bix BEFORE: " . dump( @bix );
				@bix = @{ $bix[0] };
				#say $tee "IN DEFFILES2 \@bix AFTER: " . dump( @bix );
				#my @bark = @{ flattenbox( @bix ) };
				push( @bux, @bix );
				$c++;
			}
		}


		my ( $tmpblankfile, $bit );
		my ( @bag, @fills, @fulls );
		if ( ( ( $dirfiles{random} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) )
		 	or ( ( $dirfiles{latinhypercube} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) )
			or ( ( $dirfiles{factorial} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) )
			or ( ( $dirfiles{facecentered} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) )	)
		{
			$tmpblankfile = "$mypath/$file" . "_tmp_gen_blank.csv"; #say $tee "IN LATINHYPERCUBE \$tmpblankfile: " . dump( $tmpblankfile );
			$bit = $file . "_";
			@bag =( $bit );
			@fills = @{ Sim::OPT::Descend::prepareblank( \%varnums, $tmpblankfile, \@blockelts, \@bag, $file, \%carrier ) };
			@fulls = uniq( map { $_->[0] } @fills ); #say $tee "IN RANDOM \@fulls: " . dump( @fulls );
		}


		if ( ( $dirfiles{random} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) )
		{
			my ( $standard ) = prepfactl( \@fulls ); #say $tee "IN RANDOM \$standard: " . dump( $standard );
			#say $tee "IN RANDOM \$dowhat{randomfraction}: " . dump( $dowhat{randomfraction} );

			my $numitems = int( $standard * $dowhat{randomfraction} ); #say $tee "IN RANDOM \$numitems: " . dump( $numitems );
			my @newfulls = shuffle( @fulls );
			my @forebunch = @newfulls[ 0 .. $numitems ]; #say $tee "IN RANDOM \@forebunch: " . dump( @forebunch );

			foreach $el ( @forebunch )
			{
				push( @buux, [ [ $el, "", "", "", "" ] ] );
			}
		}
		elsif ( ( $dirfiles{random} eq "yes" ) and ( $dowhat{metamodel} ne "yes" ) )
		{
			say $tee "UNABLE TO PERFORM THE MORPHING TRANSFORMATION IN THE RANDOM GENERATION SCHEME";
		}


		if ( ( $dirfiles{latinhypercube} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) )
		{
			my ( $standard ) = prepfactl( \@fulls ); #say $tee "IN LATINHYPERCUBE \$standard: " . dump( $standard );
			#say $tee "IN LATINHYPERCUBE \$dowhat{randomfraction}: " . dump( $dowhat{randomfraction} );

			my $numitems = int( $standard * $dowhat{hypercubefraction} ); #say $tee "IN LATINHYPERCUBE \$numitems: " . dump( $numitems );

			my $totnum = scalar( @fulls );
			my $numeach = int( $totnum / $numitems );

			my @newfulls;
			my $c1 = 0;
			my $c2 = 1;
			foreach $elt ( @fulls )
			{
				push( @{ $newfulls[$c1] }, $elt );
				if ( $c2 == $numeach )
				{
					$c1++;
					$c2 = 0;
				}
				$c2++
			}

			my @forebunch;
			foreach $ref ( @newfulls )
			{
				my @temp = shuffle( @{ $ref } );
				push( @forebunch, $temp[0] );
			} #say $tee "IN LATINHYPERCUBE \@forebunch: " . dump( @forebunch );

			foreach $el ( @forebunch )
			{
				push( @buux, [ [ $el, "", "", "", "" ] ] );
			}
		}
		elsif ( ( $dirfiles{latinhypercube} eq "yes" ) and ( $dowhat{metamodel} ne "yes" ) )
		{
			say $tee "UNABLE TO PERFORM THE MORPHING TRANSFORMATION IN THE LATIN HYPERCUBE GENERATION SCHEME";
		}


		if ( ( $dirfiles{factorial} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) )
		{
			my ( $standard, $ohs_r ) = prepfactl( \@fulls ); #say $tee "IN FACTORIAL \$ohs_r: " . dump( $ohs_r );
			my %ohs = %{ $ohs_r }; #say $tee "IN FACTORIAL \%ohs: " . dump( \%ohs );

			my %nhs;
			foreach my $key ( keys %ohs )
			{
				my @elts = @{ $ohs{$key} };
				my @prov;
				push( @prov, $elts[0], $elts[-1] );
				@prov = uniq( @prov );
				if ( scalar( @prov ) > 1 )
				{
					$nhs{$key} = [ @prov ];
				}
			} #say $tee "IN FACTORIAL \%nhs: " . dump( \%nhs );

			my @sack;
			foreach my $key ( sort{ $a <=> $b }( keys %nhs ) )
			{
				my @pairs = @{ $nhs{$key} };
				my $el;
				foreach my $single ( @pairs )
				{
					$el = join( "-", ( $key, $single ) );
					push( @sack, $el );
				}
			} #say $tee "IN FACTORIAL \@sack: " . dump( @sack );

			my $numelts = scalar( keys %nhs );
			foreach my $series ( @fulls )
			{
				my $count = 0;
				my @divs = split( "_", $series );
				foreach my $bit ( @divs )
				{
					if ( $bit ~~ @sack )
					{
						$count++;
					}
					if ( $count == $numelts )
					{
						push( @buux, [ [ $series, "", "", "", "" ] ] );
					}
				}
			}
			#say $tee "IN FACTORIAL \@bux: " . dump( @bux );
		}
		elsif ( ( $dirfiles{factorial} eq "yes" ) and ( $dowhat{metamodel} ne "yes" ) )
		{
			say $tee "UNABLE TO PERFORM THE MORPHING TRANSFORMATION IN THE FACTORIAL GENERATION SCHEME";
		}
		#say $tee "RESULTING: \@bux: " . dump( @bux );
		#say $tee "RESULTING: \@buux: " . dump( @buux );
	}
	else
	{
		#say $tee "IN DEFFFILES RIGHT \$dirfiles{starsign} : " . dump( $dirfiles{starsign} );
		@bux = @{ toil( \@blockelts, \%varnums, \@basket, "", $mypath, $file ) };
	} #say $tee "IN DEFFILES2 \@bux: " . dump( @bux );
	#say $tee "IN DEFFILES2 \$countblock : " . dump( $countblock );
	#say $tee "IN DEFFILES \@blockelts : " . dump( @blockelts );

	#############my $flattened_r = flattenbox( \@bux ); 	say $tee "IN DEFFILES2 \$flattened_r: " . dump( $flattened_r );
	#say $tee "In DEFFILES5 \%mids!: " . dump ( %mids );

	sub cleanduplicates
	{
		my ( $elts_ref, $dowhat_ref ) = @_; #say $tee "In cleanduplicates \@elts!: " . dump ( @elts );
		my @elts = @{ $elts_ref };
		my %dowhat = %{ $dowhat_ref };

		#my @sack;
		#foreach my $el ( @elts )
		#{
		#	push( @sack, $el->[0] );
		#}

		my @sack = map { $_[0] } @elts ;

		my @finals;
		foreach my $elt ( @sack )
		{
			foreach my $e ( @elts )
			{
				if ( $elt eq $e->[0] )
				{
					push( @finals, $e );
					last;
				}
			}
		} #say $tee "In cleanduplicates \@finals!: " . dump ( @finals );
		return( @finals );
	}

	if ( $dowhat{pairpoints} eq "yes" )
	{
		my @boox;
		foreach my $el ( @buux )
		{
			my $newel = addnear( $el, \%varnums );
			push( @boox, $el, $newel );
		}
		@buux = @boox;
	}

	my ( @finalbox );
	if ( $dirfiles{starsign} eq "yes" )
	{
		my @newbuux;
		foreach my $el ( @buux )
		{
			my $elt = $el->[0];
			push( @newbuux, $elt );
		}
		push( @bux, @newbuux );

		my @bag;
		foreach my $midsurrs_r ( @miditers )
		{
			#say $tee "MIDITERS FOR MIDSURRS!: " . dump ( @miditers );
			my %midsurrs = %{ $midsurrs_r }; #say $tee "IN DEFFILES \%midsurrs" . dump( \%midsurrs );
	 		@bag = uniq( @{ integratebox( \@bux, \%midsurrs, $file, \@blockelts, $mypath, \%inst, \%dowhat ) } );
			push( @finalbox, @bag );
		} #say $tee "IN DEFFILES BEFORE WASH \@finalbox" . dump( @finalbox );
		my @finalbox = cleanduplicates( \@finalbox, \%dowhat ); #say $tee "IN DEFFILES AFTER WASH \@finalbox" . dump( @finalbox );
	}
	else
	{
		#say $tee "IN DEFFILES RIGHT AFTER " ;
		my @bark = @{ flattenbox( \@bux ) }; #say $tee "In DEFFILES5-DESCENT \@bark!: " . dump ( @bark );
		@finalbox = uniq( @{ integratebox( \@bark, \%carrier, $file, \@blockelts, $mypath, \%inst, \%dowhat ) } );
		#say $tee "In DEFFILES5-DESCENT \@finalbox!: " . dump ( @finalbox );
	}

	@finalbox = sort { $a->[0] <=> $b->[0] } @finalbox; #say $tee "In DEFFILES5 \@finalbox!: " . dump ( @finalbox );


	setlaunch( {
		countcase => $countcase, countblock => $countblock,
		miditers => \@miditers,  winneritems => \@winneritems,
		dirfiles => \%dirfiles, basket => \@finalbox,
		toitem => $toitem, from => $from,
		sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
		datastruc => \%datastruc, dowhat => \%dowhat,
		varnumbers => \@varnumbers,
		mids => \%mids, varnums => \%varnums,
		carrier => \%carrier, instn => $instn, inst => \%inst
	} );
}

sub setlaunch # IT SETS THE DATA FOR THE SEARCH ON THE ACTIVE BLOCK.
{
	my %d = %{ $_[0] };
	my $countcase = $d{countcase}; #say $tee "IN SETLAUNCH \$countcase " . dump( $countcase );
	my $countblock = $d{countblock}; #say $tee "IN SETLAUNCH \$countblock " . dump( $countblock );
	my @sweeps = @{ $d{sweeps} };
	my @sourcesweeps = @{ $d{sourcesweeps} }; #say $tee "IN SETLAUNCH \@sourcesweeps " . dump( @sourcesweeps );
	my @miditers = @{ $d{miditers} }; #say $tee "IN SETLAUNCH \@miditers " . dump( @miditers );
	my @winneritems = @{ $d{winneritems} };
	my %dirfiles = %{ $d{dirfiles} }; #say $tee "IN SETLAUNCH \%dirfiles " . dump( %dirfiles );
	my @basket = @{ $d{basket} }; #say $tee "IN SETLAUNCH \@basket " . dump( @basket );
	my %datastruc = %{ $d{datastruc} };
	my @varnumbers = @{ $d{varnumbers} }; #say $tee "IN SETLAUNCH \@varnumbers " . dump( @varnumbers );
	my %dowhat = %{ $d{dowhat} }; #say $tee "IN SETLAUNCH \%dowhat" . dump( %dowhat );
	my $toitem = $d{toitem} ; #say $tee "IN12 SETLAUNCH \$toitem : " . dump( $toitem );
	my $from = $d{from}; #say $tee "IN12 SETLAUNCH \$from : " . dump( $from );
	my $instn = $d{instn}; #say $tee "IN12 SETLAUNCH \$instn : " . dump( $instn );
	my %inst = %{ $d{inst} }; #say $tee "IN12 SETLAUNCH \%inst : " . dump( \%inst );

	#sub cleaninst
	#{
	#	my %inst = %{ $_[0] };
	#	my %newinst;
	#	my @cleans;
	#	foreach my $in ( keys %inst )
	#	{
	#		push( @cleans, $in{cleanto} );
	#	}
	#	uniq( @cleans );
	#
	#	foreach my $el (  @cleans )
	#	{
	#		foreach my $in ( keys %inst )
	#		{
	#			if( $in{cleanto} eq $el )
	#			{
	#				$newinst{$in}{cleanto} = $in{cleanto};
	#				$newinst{$in}{to} = $in{to};
	#				$newinst{$in}{crypto} = $in{crypto};
	#				$newinst{$in}{cleancrypto} = $in{cleancrypto};
	#				next;
	#			}
	#		}
	#	}
	#	return( \%newinst )
	#}
	#
	#%inst = %{ cleaninst( \%inst ) }; say $tee "AFTER CLEANINST IN SETLAUNCH \%inst : " . dump( \%inst );

	my @blockelts = @{ getblockelts( \@sweeps, $countcase, $countblock ) };
	my @blocks = getblocks( \@sweeps, $countcase ); #say $tee "IN SETcountstep => $countstep,LAUNCH \@blocks " . dump( @blocks );

	my %varnums = %{ $d{varnums} }; #say $tee "IN SETLAUNCH \%varnums " . dump( %varnums );
	my %mids = %{ $d{mids} }; #say $tee "IN SETLAUNCH \%mids" . dump( \%mids ); ### DDD
	my %carrier = %{ $d{carrier} }; #say $tee "IN SETLAUNCH \%carrier" . dump( \%carrier ); ### DDD
	#say $tee "IN IN SETLAUNCH  \$dirfiles{starsign} " . dump( $dirfiles{starsign} );

	my ( @instances );
	#say $tee "PRE EXTRACTCASE IN SETLAUNCH - NOTHING" . dump(  );
	my %starters = %{ extractcase( \%dowhat, "", \%carrier, $file, \@blockelts, $mypath, "" ) };

	$dirfiles{starter} = $starters{cleanto}; #say $tee "IN SETLAUNCH \$dirfiles{starter}" . dump( $dirfiles{starter} );

	my $count = 0;
	foreach my $elt ( @basket )
	{

		my $newpars = $$elt[0]; #say $tee "IN SETLAUNCH \$newpars! " . dump( $newpars );
		my $countvar = $$elt[1]; #say $tee "IN SETLAUNCH \$countvar! " . dump( $countvar );
		my $countstep = $$elt[2]; #say $tee "IN SETLAUNCH \$countstep! " . dump( $countstep );
		my $oldpars = $$elt[3]; #say $tee "IN SETLAUNCH \$oldpars " . dump( $oldpars );
		#say $tee "PRE EXTRACTCASE IN SETLAUNCH \$newpars" . dump( \$newpars );
		my %to = %{ extractcase( \%dowhat, $newpars, \%carrier, $file, \@blockelts, $mypath, $instn ) };
		#say $tee "IN SETLAUNCH FROM EXTRATCASE \%to" . dump( \%to );
		#say $tee "IN SETLAUNCH FROM EXTRATCASE \$to{cleanto}" . dump( $to{cleanto} );
		#say $tee "IN SETLAUNCH \$inst{\$to{cleanto}}" . dump( $inst{$to{cleanto}} );
		#say $tee "IN SETLAUNCH \%inst" . dump( \%inst );


		unless( ( $to{cleanto} ~~ @{ $dirfiles{dones} } ) and ( $dirfiles{precomputed} eq "" ) )
		{
			push( @{ $dirfiles{dones} }, $to{cleanto} );
			$inst{$to{cleanto}} = $to{crypto};
			$inst{$to{crypto}} = $to{cleanto};
			$inst{$to{to}} = $to{cleanto};

			#say $tee "PRE EXTRACTCASE IN SETLAUNCH \$oldpars" . dump( \$oldpars );
			my %orig = %{ extractcase( \%dowhat, $oldpars, \%carrier, $file, \@blockelts, $mypath ) };
			my $origin = $orig{cleanto};
			#say $tee "IN SETLAUNCH! \$origin" . dump( \$origin ) . "\n\n";
			my $c = $$elt[4];
			#say $tee "IN SETLAUNCH INSTANCE!: $instn";
			push ( @instances,
			{
				countcase => $countcase, countblock => $countblock,
				miditers => \@miditers,  winneritems => \@winneritems,
				dirfiles => \%dirfiles, c => $c, toitem => $toitem, from => $from,
				to => \%to, countvar => $countvar, countstep => $countstep,
				sweeps => \@sweeps, dowhat => \%dowhat,
				sourcesweeps => \@sourcesweeps, datastruc => \%datastruc,
				varnumbers => \@varnumbers, blocks => \@blocks,
				blockelts => \@blockelts, mids => \%mids, varnums => \%varnums,
				countinstance => $count, carrier => \%carrier, origin => $origin,
				instn => $instn, inst => \%inst
			} );
			$instn++;
		}
		$count++;
	} #say $tee "IN SETLAUNCH \@instances " . dump( @instances );
	exe( { instances => \@instances, dirfiles => \%dirfiles } );
}

sub exe
{
	my %dat = %{ $_[0] };
	my @instances = @{ $dat{instances} }; #say $tee "IN EXE \@instances " . dump( @instances );
	my %dirfiles = %{ $dat{dirfiles} }; #say $tee "IN EXE \%dirfiles " . dump( %dfromirfiles );

	my %d = %{ $instances[0] }; #say $tee "IN EXE \%d!!! " . dump( \%d );
	my $countcase = $d{countcase}; #say $tee "IN EXE \$countcase " . dump( $countcase );
	my $countblock = $d{countblock}; #say $tee "IN EXE \$countblock " . dump( $countblock );
	my @varnumbers = @{ $d{varnumbers} }; #say $tee "IN EXE \@varnumbers " . dump( @varnumbers );
	my @miditers = $d{miditers}; #say $tee "IN EXE \@miditers " . dump( @miditers );
	my @sweeps = @{ $d{sweeps} }; #say $tee "IN EXE \@sweeps " . dump( @sweeps );
	my @sourcesweeps = @{ $d{sourcesweeps} }; #say $tee "IN EXE \@sourcesweeps " . dump( @sourcesweeps );
	my @winneritems =  @{ $d{winneritems} }; #say $tee "IN EXE \@winneritems " . dump( @winneritems );

	my %datastruc = %{ $d{datastruc} }; #say $tee "IN EXE \%datastruc " . dump( %datastruc );
	my %dowhat = %{ $d{dowhat} }; #say $tee "IN EXE \%dowhat " . dump( %dowhat );
	my $toitem = $d{toitem}; #say $tee "IN12 EXE \%toitem : " . dump( \%toitem );
	my $from = $d{from}; #say $tee "IN12 EXE \%from : " . dump( %from );
	my %to = %{ $d{to} }; #say $tee "IN12 EXE \%to : " . dump( %to );
	my $countvar = $d{countvar}; #say $tee "IN12 EXE \$countvar : " . dump( $countvar );
	my $countstep = $d{countstep}; #say $tee "IN12 EXE \$countstep : " . dump( $countstep );
	my $instn = $d{instn};
	#say $tee "IN EXE  \$dirfiles{starsign} " . dump( $dirfiles{starsign} );
	my %inst = %{ $d{inst} };

	my $precomputed = $dowhat{precomputed}; #say $tee "IN EXE \$precomputed " . dump( $precomputed ); #NEW
  my @takecolumns = @{ $dowhat{takecolumns} }; #say $tee "IN EXE \@takecolumns " . dump( @takecolumns ); #NEW
	my ( @simcases, @simstruct );
	say $tee "#Performing a search on case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

	my $cryptolinks = "$mypath/$file" . "_" . "$countcase" . "_cryptolinks.pl";
	open ( CRYPTOLINKS, ">$cryptolinks" ) or die;
	say CRYPTOLINKS "" . dump( \%inst );
	close CRYPTOLINKS;

	if ( $dowhat{morph} eq "y" )
	{
		say $tee "#Calling morphing operations for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

		my @result = Sim::OPT::Morph::morph( $configfile, \@instances, \%dirfiles, \%dowhat );
		$dirfiles{morphcases} = $result[0];
		$dirfiles{morphstruct} = $result[1];
	}

	if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
	{

		say $tee "#Calling simulations, reporting and retrieving for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
		my ( $simcases_ref, $simstruct_ref, $repcases_ref, $repstruct_ref,
	    $mergestruct_ref, $mergecases_ref, $c ) = Sim::OPT::Sim::sim(
				{ instances => \@instances, dirfiles => \%dirfiles } );
		$dirfiles{simcases} = $simcases_ref;
		$dirfiles{simstruct} = $simstruct_ref;
		$dirfiles{repcases} = $repcases_ref;
		$dirfiles{repstruct} = $repstruct_ref;
		$dirfiles{mergestruct} = $mergestruct_ref;
		$dirfiles{mergecases} = $mergecases_ref;
	}
  elsif ( $dowhat{simulate} eq "y" )
	{
		say $tee "#Calling simulations for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
		my ( $simcases_ref, $simstruct_ref, $repcases_ref, $repstruct_ref,
		    $mergestruct_ref, $mergecases_ref, $c )  = Sim::OPT::Sim::sim(
					{ instances => \@instances, dirfiles => \%dirfiles } );
		$dirfiles{simcases} = $simcases_ref;
		$dirfiles{simstruct} = $simstruct_ref;
		$dirfiles{repcases} = $repcases_ref;
		$dirfiles{repstruct} = $repstruct_ref;
		$dirfiles{mergestruct} = $mergestruct_ref;
		$dirfiles{mergecases} = $mergecases_ref;
	}

	if ( $dowhat{descend} eq "y" )
	{
		say $tee "#Calling descent for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ".";
		#say $tee "\@sourcesweeps: " . dump( @sourcesweeps );
		Sim::OPT::Descend::descend(	{ instances => \@instances, dirfiles => \%dirfiles } );
	}

	if ( $dowhat{substitutenames} eq "y" )
	{
		 Sim::OPT::Report::filter_reports( { instances => \@instances, dirfiles => \%dirfiles } );
	}

	if ( $dowhat{filterconverted} eq "y" )
	{
		 Sim::OPT::Report::convert_filtered_reports(
		{
			  instances => \@instances, dirfiles => \%dirfiles } );
	}

	if ( $dowhat{make3dtable} eq "y" )
	{
		 Sim::OPT::Report::maketable(
		{
			  instances => \@instances, dirfiles => \%dirfiles } );
	}
} # END SUB exe


sub genstar
{
	my ( $dowhat_ref, $varnumbers_ref, $carrier_ref, $blockelts_ref ) = @_;
	my %dowhat = %{ $dowhat_ref };
	my %carrier = %{ $carrier_ref }; #say $tee "IN GENSTAR1 \%carrier: " . dump( %carrier );
	my @blockelts = @{ $blockelts_ref }; #say $tee "IN GENSTAR1 \@blockelts: " . dump( @blockelts );
	#say $tee "IN GENSTAR1 \$dowhat{starpositions}: " . dump( $dowhat{starpositions} );

	my @varnumbers = @{ $varnumbers_ref };

	my (  @genextremes, @gencentres, @starpositions );
	if ( $dowhat{stardivisions} == 1 )
	{
		$gencentres_ref = gencen( \@varnumbers); #say $tee "\$dowhat{starpositions}: " . dump( $dowhat{starpositions} );
		@gencentres = @{ $gencentres_ref };
		push( @starpositions, @gencentres );
	}
	elsif ( $dowhat{stardivisions} > 1 )
	{
		$genextremes_ref = genextremes( \@varnumbers );
		my $i = 1;
		while ( $i < $dowhat{stardivisions} )
		{
			$genextremes_ref = gencentres( $genextremes_ref );
			@genpoints = @{ $genextremes_ref }; #say $tee "GENCENTRES \@gencentres: " . dump( @gencentres );
			$i++;
		}
		push( @starpositions, @genpoints );
	}
	#say $tee "IN genstar STARPOSITIONS BEFORE: " . dump( @starpositions );

	my @bag;
	if ( scalar( @blockelts > 0) )
	{
		foreach my $el ( @starpositions )
		{
			my %hs = %{ $el };
			foreach my $key ( sort( keys( %hs ) ) )
			{
				if ( not ( $key ~~ @blockelts ) )
				{
					$hs{$key} = $carrier{$key};
				}
			}
			push( @bag, \%hs );
		}
		@starpositions = @bag;
	}
	#say $tee "IN genstar STARPOSITIONS AFTER: " . dump( @starpositions );

	return( \@starpositions );
}


sub start
{
###########################################
say "\nThis is Sim::OPT, version $VERSION.
Please insert the name of a configuration file (Unix path).\n";
###########################################
	$configfile = <STDIN>;
	chomp $configfile;
	if (-e $configfile )
	{
		return( $configfile );
	}
	else { start; }
}



###########################################################################################

sub opt
{
	my $configfile = start;
	#eval `cat $configfile`; # The file where the program data are
	my ( @miditers, @varnumbers );
	require $configfile;

	my $instn = 1;
	my %inst;

	if ( $dowhat{mypath} eq "" )
	{
		$dowhat{mypath} = $mypath;
	}

	if ( scalar( @miditers == 0 ) )
	{
		@miditers = @mediumiters;
	}

	if ( scalar( @varnumbers == 0 ) )
	{
		@varnumbers = @varinumbers;
	}


	#if ( not ( $outfile ) ) { $outfile = "$mypath/$file-$fileconfig-feedback.txt"; }
	if ( not ( $tofile ) )
	{
		$tofile = "$mypath/$file-tofile.txt";
	}

	if ( $dowhat{tofile} eq "" )
	{
		$dowhat{tofile} = $tofile;
	}

	if ( $dowhat{randomfraction} eq "" )
	{
		$dowhat{randomfraction} = 1;
	}

	if ( $dowhat{hypercubefraction} eq "" )
	{
		$dowhat{hypercubefraction} = 1;
	}

	$tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL ZZZ

#	if ($casefile) { eval `cat $casefile` or die( "$!" ); }
#	if ($chancefile) { eval `cat $chancefile` or die( "$!" ); }

	say $tee "\nNow in Sim::OPT. \n";
	$dowhat{file} = $file;
	#say $tee "IN OPT \%vals " . dump( %vals );

	if ( $dowhat{justchecksensitivity} ne "" )
	{
		say "RECEIVED.";
		Sim::OPT::sense( $dowhat{justchecksensitivity}, $mypath, $dowhat{objectivecolumn}, "stop" );
	}

  if ( $dowhat{randomsweeps} eq "yes" ) #IT SHUFFLES  @sweeps UNDER REQUESTED SETTING.
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
      #print "NEW SWEEPS: " . dump( @sweeps ) . "\n";
  }

  my $i = 0;
  my @newarr;
  if ( $dowhat{randomdirs} eq "yes" )
  { #IT SHUFFLES  $dowhat{direction} UNDER REQUESTED SETTINGS.
    foreach my $directionref ( @{ $dowhat{direction} } )
    {
      my @varnumber = %{ $varnumbers[$i] };
      my $numcases = ( scalar( @varnumber ) / 2 ) ;
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
    #say "NEW RANDOMIZED DIRECTIONS: " . dump( $dowhat{direction} );
  }


  { #IT FILLS THE MISSING $dowhat{direction} UNDER REQUESTED SETTINGS.
    my $i = 0;
    my @newarr;
    foreach my $dirref ( @{ $dowhat{direction} } )
    {
			#say "112 \$dirref: " . dump( $dirref );
      my @thesesweeps = @{ $sweeps[$i] }; #say "112 \@thesesweeps: " . dump( @thesesweeps );
      my $numcases =  scalar( @thesesweeps )  ; #say "112 \$numcases: " . dump( $numcases );

      my @directions;
      my $itemsnum = scalar( @{ $dirref } ); #say "112 \$itemsnum: " . dump( $itemsnum );
      my $c = 0;
      while ( ( $itemsnum + $c ) <= $numcases )
      {
        push ( @directions, ${ $dirref }[0] );
        $c++;
      }
			#say "112-0 \@directions: " . dump( @directions );
      push ( @newarr, [ @directions ] );
      $i++;
    }
		#say "112-0 \@newarr: " . dump( @newarr );
    $dowhat{direction} = [ @newarr ];
    #say "NEW FILLED DIRECTIONS: " . dump( $dowhat{direction} );
  }
	#say "112-0 \$dowhat{direction}: " . dump( $dowhat{direction} );

	{ #IT FILLS THE MISSING $dowhat{starorder} UNDER APPROPRIATE SETTINGS.
    my $i = 0;
    my @newarr;
    foreach my $dirref ( @{ $dowhat{starorder} } )
    {
			#say "112 \$dirref: " . dump( $dirref );
      my @thesesweeps = @{ $sweeps[$i] }; #say "112 \@thesesweeps: " . dump( @thesesweeps );
      my $numcases =  scalar( @thesesweeps )  ; #say "112 \$numcases: " . dump( $numcases );

      my @directions;
      my $itemsnum = scalar( @{ $dirref } ); #say "112 \$itemsnum: " . dump( $itemsnum );
      my $c = 0;
      while ( ( $itemsnum + $c ) <= $numcases )
      {
        push ( @directions, ${ $dirref }[0] );
        $c++;
      }
			#say "112-0 \@directions: " . dump( @directions );
      push ( @newarr, [ @directions ] );
      $i++;
    }
		#say "112-0 \@newarr: " . dump( @newarr );
    $dowhat{starorder} = [ @newarr ];
    #say "NEW FILLED STAR ORDERING: " . dump( $dowhat{starorder} );
  }
	#say "112-0 \$dowhat{starorder}: " . dump( $dowhat{starorder} );

  if ( $dowhat{randominit} eq "yes" )
  {
    my %i = 0;
    foreach $arr ( @varnumbers )
    {
      my %hash = %{ $arr };
      foreach my $elt ( sort {$a <=> $b} ( keys %hash ) )
      {
        my $num = $hash{$elt};
        my $newnum = ( 1+ int( rand( $num ) ) );
        ${ $miditers[i] }{$elt} = $newnum;
      }
      $i++;
    }
    #say "NEW INIT LEVELS: " . dump( @miditers );
  }

	#open( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!";
#	open( TOFILE, ">>$tofile" ) or die "Can't ING: " . dump( $starstring );open $tofile: $!";

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

		if ( scalar( @miditers ) == 0 ) { calcmiditers( @varnumbers ); }
		#$itersnum = getitersnum($countcase, $varnumber, @varnumbers);

		@rootnames = definerootcases( \@sweeps, \@miditers );
		#say $tee "PRE CALLCASE \@rootnames: " . dump( @rootnames );

		my $countcase = 0;
		my $countblock = 0;
		my %datastruc;

		my @winneritems = populatewinners( \@rootnames, $countcase, $countblock );
		#say $tee "PRE CALLCASE \@winneritems: " . dump( @winneritems );

		my $count = 0;
		my @arr;
		foreach ( @varnumbers )
		{
			my $elt = getitem( \@winneritems, $count, 0 );
			push ( @arr, $elt );
			$count++;
		}
		$datastruc{pinwinneritem} = [ @arr ];

		#say $tee "\$dowhat{stardivisions}_: " . dump( $dowhat{stardivisions} );
		my ( @gencetres, @genextremes, @genpoints, $genextremes_ref, $gencentres_ref );

		if ( $dowhat{outstarmode} eq "yes" )
		{
			if ( ( $dowhat{stardivisions} ne "" ) and ( $dowhat{starpositions} eq "" ) )
			{
				$dowhat{starpositions} = genstar( \%dowhat, \@varnumbers, $miditers[$countcase] );
			}
			#say $tee "OUTSTARMODE AFTER \$dowhat{starpositions}: " . dump( \@{ $dowhat{starpositions} } );

			$dowhat{starnumber} = scalar( @{ $dowhat{starpositions} } ); #say $tee "AFTER \$dowhat{starnumber}: " . dump( $dowhat{starnumber} );

			if ( not( scalar( @{ $dowhat{starpositions} } ) == 0 ) )
			{
				$dowhat{direction} => [ [ "star" ] ];
				$dowhat{randomsweeps} => "no"; # to randomize the order specified in @sweeps.
				$dowhat{randominit} => "no"; # to randomize the init levels specified in @miditers.
				$dowhat{randomdirs} => "no"; # to randomize the directions of descent.

				my @sweeps = @{ starsweep( \@varnumbers, \@sweeps ) }; #say $tee "AFTER0 \@sweeps: " . dump( @sweeps );

				my $number = scalar( @varnumbers ); #say $tee "AFTER0 \$number: " . dump( $number );

				my ( @addition, @addition2, @addition3, @sweepaddition );
				my $cn = 0;
				while ( $cn < $dowhat{starnumber} )
				{
					push( @addition, $varnumbers[0] );
					push( @addition2, $dowhat{direction}[0] );
					push( @addition3, $dowhat{starorder}[0] );
					push( @sweepaddition, $sweeps[0] );
					$cn++;
				} #say $tee "AFTER0 \@addition: " . dump( @addition );

				@varnumbers = @addition;
				$dowhat{direction} = \@addition2;
				$dowhat{starorder} = \@addition3;
				my @sweeps = @sweepaddition;

				my @bag; #say $tee "AFTER0 \@miditers: " . dump( @miditers );
				my @miditers = @miditers[1 ... $#miditers]; #say $tee "AFTER1 \@miditers: " . dump( @miditers );
				push( @bag, @{ $dowhat{starpositions} }, @miditers );
				my @miditers = @bag; #say $tee "AFTER3 \@miditers: " . dump( @miditers );

				$countstring = 1;

				my ( $sweepz_ref, $sourcesweeps_ref ) = readsweeps( @sweeps );
				my @sweepz = @$sweepz_ref;
				my @sourcesweeps = @$sourcesweeps_ref;
				if ( @sweepz )
				{
					@sweeps = @sweepz;
				}

				@calcoverlaps = calcoverlaps( @sweeps );

		    #@miditers = @pinmiditers;
				#my %mids = getcase( \@miditers, $countcase ); #say $tee "IN CALLCASE \%mids" . dump( %mids );
				$dirfiles{countstring} = $countstring;
				#my $totres_read = "$mypath/$file-totres-$countcase-$countblock.csv";
				#$dirfiles{totres_read} = $totres_read;
				#my $totres_write = "$mypath/$file-totres-$countcase-$countblock.csv";
				#$dirfiles{totres_write} = $totres_write;

				#say $tee "PRE CALLCASE \@sweeps: " . dump( @sweeps );
				#say $tee "PRE CALLCASE \@varnumbers: " . dump( @varnumbers );
				#say $tee "PRE CALLCASE \@miditers: " . dump ( @miditers );
				#say $tee "PRE CALLCASE \$dowhat{direction}" . dump( $dowhat{direction} );
				#say $tee "PRE CALLCASE \$dowhat{starorder}" . dump( $dowhat{starorder} );

				$dirfiles{tottot} = "$mypath/$file-$countcase" . "-tottot.csv"; #say "IN CALLBLOCK tottot:" . ( $dirfiles{tottot} ) . " .";
				$dirfiles{ordtot} = "$mypath/$file-$countcase" . "-ordtot.csv"; #say "IN CALLBLOCK ordtot:" . ( $dirfiles{ordtot} ) . " .";


				callblock( { countcase => $countcase, countblock => $countblock,
					miditers => \@miditers, varnumbers => \@varnumbers, winneritems => \@winneritems, sweeps => \@sweeps,
					sourcesweeps => \@sourcesweeps, datastruc => \%datastruc, dirfiles => \%dirfiles,
					dowhat => \%dowhat, instn => $instn, inst => \%inst } );
					$countstring++;
					$dirfiles{countstring} = $countstring;
			}
		}
		else
		{
			my ( $sweepz_ref, $sourcesweeps_ref ) = cleansweeps( \@sweeps );
			my @sweepz = @{ $sweepz_ref }; #say $tee "AFTER CLEANSWEEPS \@sweepz: " . dump ( @sweepz );
			my @sourcesweeps = @{ $sourcesweeps_ref }; #say $tee "AFTER CLEANSWEEPS \@sourcesweeps: " . dump ( @sourcesweeps );
			if ( @sweepz )
			{
				@sweeps = @sweepz;
			}

			#@calcoverlaps = calcoverlaps( @sweeps );
			$dirfiles{tottot} = "$mypath/$file-$countcase" . "-tottot.csv"; #say "IN CALLBLOCK tottot:" . ( $dirfiles{tottot} ) . " .";
			$dirfiles{ordtot} = "$mypath/$file-$countcase" . "-ordtot.csv"; #say "IN CALLBLOCK ordtot:" . ( $dirfiles{ordtot} ) . " .";
			#@miditers = @pinmiditers;
			#say $tee "miditers: " . dump ( @miditers );

			if ( scalar( @miditers ) == 0 ) { calcmiditers( @varnumbers ); }
			#$itersnum = getitersnum( $countcase, $varnumber, @varnumbers );

			@rootnames = definerootcases( \@sweeps, \@miditers ); #say $tee "\@rootnames: " . dump ( @rootnames );

			my $countcase = 0;
			my $countblock = 0;
			my %datastruc;

			my @winneritems = populatewinners( \@rootnames, $countcase, $countblock ); #say $tee "\@winneritems: " . dump ( @winneritems );

			my $count = 0;
			my @arr;
			foreach ( @varnumbers )
			{
				my $elt = getitem(\@winneritems, $count, 0);
				push ( @arr, $elt );
				$count++;
			}
			$datastruc = [ @arr ];
			#say $tee "PRE CALLCASE \%dowhat" . dump( %dowhat );
			callblock
			(	{ countcase => $countcase, countblock => $countblock,
					miditers => \@miditers, varnumbers => \@varnumbers, winneritems => \@winneritems,
					sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
					datastruc => \%datastruc, dowhat => \%dowhat,
					dirfiles => \%dirfiles, instn => $instn, inst => \%inst } );
		}
	}
	elsif ( ( $target eq "parcoord3d" ) and (@chancedata) and ( $dimchance ) )
	{
		Sim::OPT::Parcoord3d::parcoord3d;
	}

	close(OUTFILE);
	close(TOFILE);
	exit;
} # ENDsub opt

#############################################################################

1;

__END__

=head1 NAME

Sim::OPT.

=head1 SYNOPSIS

  use Sim::OPT;
  opt;

=head1 DESCRIPTION

Sim::OPT is an optimization and parametric exploration program favouring problem decomposition. It can be used with simulation programs receiving text files as input and emitting text files as output. Sim::OPT's optimization modules (Sim::OPT, Sim::OPT::Descent) pursue optimization through block search, allowing blocks (subspaces) to overlap, and allowing a free intermix of sequential searches (inexact Gauss-Seidel method) and parallell ones (inexact Jacobi method). The Sim::OPT::Takechange module can seek for the least explored search paths when exploring new search spaces sequentially (following rules presented in: http://dx.doi.org/10.1016/j.autcon.2016.08.014). Sim::OPT::Morph, the morphing module, can manipulate parameters of simulation models.
Other modules under the Sim::OPT namespace are Sim::OPT::Parcoord3d, a module which can convert 2D parallel coordinates plots into Autolisp instructions for obtaining 3D plots as Autocad drawings; and Sim::OPT::Interlinear, which can build metamodels from sparse multidimensional data, and the module Sim::OPT::Modish, capable of altering the shading values calculated with the ESP-r buildjng performance simulation platform (http://www.esru.strath.ac.uk/Programs/ESP-r.htm).
The Sim::OPT's morphing and reporting modules contain several additional functions specifically targeting the ESP-r building performance simulation platform.

To install Sim::OPT, the command <cpanm Sim::OPT> has to be issued as a superuser. Sim::OPT can then be loaded through the command <use Sim::OPT> in a Perl repl. But to ease the launch, the batch file "opt" (which can be found packed in the "optw.tar.gz" file in "examples" folder in this distribution) can be copied in a work directory and the command <opt> may be issued. That command will launch Sim::OPT with the settings specified in the configuration file. When launched, OPT will ask the path to that file, which has to contain a suitable description of the operations to be accomplished and point to an existing simulation model.

The "$mypath" variable in the configuration file must be set to the work directory where the base model reside.

Besides an OPT configuration file, separate configuration files for propagation of constraints may be created. Those files can give the morphing operations greater flexibility. Propagation of constraints can regard the geometry of a model, solar shadings, mass/flow network, controls, and generic text files descripting a simulation model.

The simulation model folders and the result files that will be created in a parametric search will assigned a unique name base on a sequence, but within the program each instance will be assigned a name consituted by numbers describing the position of the instance in the multidimensional matrix (tensor). For example, within the program, the instance produced in the first iteration for a root model named "model" in a search constituted by 3 morphing phases and 5 iteration steps each would be named "model_1-1_2-1_3-1"; and the last one, "model_1-5_2-5_3-5"; while the file may be named "model_1__" and "model_128__". After each program's run, the correspondence between the file names and the instance names is recorded in a file ending with "_cryptolinks.pl"; and there is also an option to keep the file names unencrypted (which can be done if they are not too long).

The structure of the block searches in the configuration file is described through the variable "@sweeps". Each case is listed inside square brackets; and each search subspace (block) in each case is listed inside square brakets. For example: a sequence constituted by two sequential full-factorial force searches, one regarding parameters 1, 2, 3 and the other regarding parameters 1, 4, 5, 7, would be described with: @sweeps = ( [ [ 1, 2, 3 ] ] , [ [ 1, 4, 5, 7 ] ] ) . And a sequential block search with the first subspace regarding parameters 1, 2, 3 and the second regarding parameters 3, 4, 5, 6 would be described with: @sweeps = ( [ [ 1, 2, 3 ] , [ 3, 4, 5, 6 ] ] ).

The number of iterations to be taken into account for each parameter for each case is specified in the "@varnumbers" variable. To specifiy that the parameters of the last example are to be tried for three values (iterations) each, @varnumbers has to be set to ( { 1 => 3, 2 => 3, 3 => 3, 4 => 3, 5 => 3, 6 => 3 } ).

The instance number that has to trated as the basic instance, corresponding to the root case, is specified by the variable "@miditers". "@miditers" for the last example may be for instance set to ( { 1 => 2, 2 => 2, 3 => 2, 4 => 2, 5 => 2, 6 => 2 } ).

OPT can work on a given set of pre-simulated results without launching new simulations, and it can randomize both the sequence of the  search and the initialization level of the parameters (see the included examples).

By default the behaviour of the program is sequential. To make it parallel locally, subspaces have to be named with a name not containing numbers, so as to work as a collector cells. If the name "name", for example, has to be given to a block, the letters "name" must be joined at the beginning of the first number describing an iteration number in a block. If that number is 1, for example, the first element of that block should be named "name1". As an effect, that block will receive values from all the blocks "pointing" to the name "name". To point the search outcome of a block to another block, the name of the block pointed to has to be appended to the last number describing an iteration number in a block. If, for example, that number is 3 and the name of the block pointed to is "surname", the last element of that block should be named "3surname". A block of in which both the mentioned situations took place could be named [ "name1", 2, "3surname" ].

If the search is to start from more than one block in parallel, the first block should be named and all the other starting blocks should be named like it.

The capability of articulating a mix of parallel and sequential searches is of absolute importance, because it makes possible to design search structures with a "depth", embodying precedence, and therefore procedural time, in them. This toolset is needed to describe directed graphs.

OPT can perform star searches (Jacoby method of course, but also Gauss-Seidel) within blocks in place of multilevel full-factorial searches. To ask for that in a configuration file, the first number in a block has to be preceded by a ">" sign, which in its turn has to be preceded by a number specifying how many star points there have to be in the block. A block, in that case, should be declared with something like this: ( "2>1", 2, 3). When operating with pre-simulated dataseries or metamodels, OPT can also perform: factorial searches (to ask for that, the first number in that block has to be preceded by a "<" sign); face-centered composite design searches of the DOE type (in that case, the first number in the block has to be preceded by a "£"); random searches (the first number has to be preceded by a "|"); latin hypercube searches (the first number has to be preceded by a "§").

For specifying in a Sim::OPT configuration file that a certain block has to be searched by the means of a metamodel derived from star searches or other "positions" instead of a multilevel full-factorial search, it is necessary to assign the value "yes" to the variable $dowhat{metamodel}.

OPT can perform both variance-based sensitivity analyses on the basis of simulated dataseries and variance-based preliminary sensitivity analyses on the basis of metamodels.

OPT works under Linux.

=head2 EXPORT

"opt".

=head1 SEE ALSO

Annotated examples (which include "esp.pl" for ESP-r, "ep.pl" for EnergyPlus - the two perform the same morphing operations on models describing the same building -, "des.pl" about block search, and "f.pl" about a search in a pre-simulated dataset, and other) can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution. They constitute all the available documentation besides these pages and the source code.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2018 by Gian Luca Brunetti and Politecnico di Milano. This is free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
