package Sim::OPT;
# Copyright (C) 2008-2022 by Gian Luca Brunetti and Politecnico di Milano.
# This is Sim::OPT, a program managing building performance simulation programs for performing optimization by overlapping block coordinate descent.
# This is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

use v5.14;
# use v5.20;

use Exporter;
use parent 'Exporter';

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Math::Trig;
use Math::Round;
use List::Util qw[ min max reduce shuffle];
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Statistics::Basic qw(:all);
use Storable qw(store retrieve lock_store lock_nstore lock_retrieve dclone);
use IO::Tee;
use File::Copy qw( move copy );
use Set::Intersection;
use List::Compare;
use Data::Dumper;
use POSIX;
use Data::Dump qw(dump);
use feature 'say';

#use Sub::Signatures;
#no warnings qw(Sub::Signatures);
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

our @ISA = qw( Exporter );
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
toil genstar solvestar integratebox filterbox__ clean %dowhat @weighttransforms
);

$VERSION = '0.645';
$ABSTRACT = 'Sim::OPT is an optimization and parametric exploration program oriented to problem decomposition. It can be used with simulation programs receiving text files as input and emitting text files as output. It allows a free mix of sequential and parallel block coordinate searches.';

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

sub cleanbag
{
	my @instances = @_;
	my ( @bagnames, @baginst );
	foreach my $inst_r ( @instances )
	{
		my %d = %{ $inst_r };
		my $is = $d{is};

		unless ( $is ~~ @bagnames )
		{
			push( @bagnames, $is );
			push( @baginst, $inst_r );
		}
	}
	return( @baginst );
}

sub washduplicates
{
	my ( $filename ) = @_;
	open( FILENAME, "$filename" ) or die;
	my @lines = <FILENAME>;
	close FILENAME;

	@lines = uniq( @lines );
	open( FILENAME, ">$filename" ) or die;
  foreach my $line ( @lines )
	{
		print FILENAME $line;
	}
	close FILENAME;
}

sub washhash
{
	my %hash = %{ $_[0] };
	my ( @bagnames, %newhash );
	foreach my $key ( keys %hash )
	{
		unless ( $key ~~ @bagnames )
		{
			push( @bagnames, $key );
			$newhash{$key} = $hash{$key};
		}
	}
  return( \%newhash );
}


sub filterinsts_winsts
{
	my ( $fewerinsts_r, $inst_r ) = @_ ;
	my @fewerinsts = @{ $fewerinsts_r };
	my %inst = %{ $inst_r };
	my @fewerinstnames;
	foreach my $instance ( @fewerinsts )
	{
		my %d = %{ $instance };
		unless ( $d{is} ~~ @fewerinstnames )
		{
			push( @fewerinstnames, $d{is} );
		}
	}
	say $tee "FEWERINSTNAMES" . dump( @fewerinstnames );

	my %newinst ;
	foreach my $key ( keys %inst )
	{
		foreach $name ( @fewerinstnames )
		{
			if ( $key =~ /$name/ )
			{
				$newinst{$key} = $inst{$key};
			}
		}
	} #say $tee "NEWINST1" . dump( \%newinst );

	foreach my $value ( values %newinst )
	{
		if ( $value ~~ ( keys %newinst ) )
		{
			$newinst{$value} = $value{$value};
		}
	} #say $tee "NEWINST2" . dump( \%newinst );

	return( \@fewerinstnames, \%newinst );
}


sub filterinsts_wnames
{
	my ( $names_r, $inst_r ) = @_ ;
	my @names = @{ $names_r };
	my %inst = %{ $inst_r };
	my %newinst;
	foreach my $key ( keys %inst )
	{
		foreach $name ( @names )
		{
			if ( $key =~ /$name/ )
			{
				$newinst{$key} = $inst{$key};
			}
		}
		#say $tee "NEWINST3" . dump( \%newinst );
	}

	foreach my $value ( values %newinst )
	{
		if ( $value ~~ ( keys %newinst ) )
		{
			$newinst{$value} = $value{$value};
		}
	} #say $tee "NEWINST4" . dump( \%newinst );

	return( \%newinst );
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
{
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
	return ($c);
}

sub cleaninst
{
	my %inst = @_;
	my %pure;
	foreach my $key ( keys %inst )
	{
		unless ( ( $key eq "" ) or ( $inst{$key} eq " ") )
		{
      $pure{$key} = $inst{$key};
		}
	}
	return ( %pure );
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
	return scalar( @bag );
}


sub distr
{
  my ( $elts_res, $num ) = @_;
  my @elts = @{ $elts_res };

  if ( ( $num eq "" ) or ( $num == 0 ) )
  {
    $num = 100;
  }

  my $min = min( @elts );
  my $max = max( @elts );
  my $ext = ( $max - $min );
  my $incr = ( $ext / $num ); say $tee "INCR $incr";

  my $count = 0;
  my $low = $min;
  my $newlow;
  my ( @vals, @ranks, @alls, @allnums, @percnums );
  while ( $count < $num  )
  { say $tee "COUNT $count";
    $newlow = ( $low + $incr );
    my $middle = ( ( $low + $newlow ) / 2 );
    push( @vals, $middle );
    push( @ranks, ( $count + 1 ) );

    foreach my $elt ( @elts )
    {
      if ( ( $elt < $max ) and ( ( $elt >= $low ) and ( $elt < $newlow ) ) )
      {
        push ( @{ $alls[$count] }, $elt );
      }
      elsif ( ( $elt == $max ) and ( ( $elt >= $low ) and ( $elt <= $newlow ) ) )
      {
        push ( @{ $alls[$count] }, $elt );
      }
    }



    $low = ( $low + $incr );
    $count++;
  }
  say $tee "ALLS: " . dump( @alls );
  #die;


  my $scalaralls = scalar( @alls );
  my $co = 0;
  while ( $co < $scalaralls )
  {
    push( @allnums, scalar( @{ $alls[$co] } ) );
    $co++
  }

  my $total = 0;
  foreach my $allnum ( @allnums )
  {
    $total = $total + $allnum;
  }

  my $reduction = ( 100 / $total );

  foreach my $allnum ( @allnums )
  {
    my $scalednum = ( $allnum * $reduction );
    push ( @percnums, $scalednum );
  }

  return( \@percnums, \@vals, \@ranks)
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
			my $firstbit = $par . "-";
			$that = $this;
			$that =~ s/$firstbit(\d)/$bit/ ;
			$done = "yes";
		}
	}
	$pass->[0][0] = $that;
	return( $pass );
}


sub sorttable
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
		#print $tee "$_";
	    }
	    #print $tee "\n";
	}
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
	return  @storeinfo; # IT IS DESTRUCTIVE.
}

sub encrypt1
{
  my ( $thing ) = @_;
  $thing =~ s/.-//g ;
  $thing =~ s/_//g ;
  return( $thing );
}

sub present
{
	foreach (@_)
	{
		say $tee "### $_ : " . dump($_);
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


sub fromopt_tosweep
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

sub fromopt_tosweep_simple
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


sub fromsweep_toopt
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
	} # TO BE CALLED WITH: convcaseseed(\@caseseed, \@chanceseed). @caseseed IS global.
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
	} # IT HAS TO BE CALLED WITH convchanceseed(@chanceseed). IT ACTS ON @chanceseed
	return(@_);
}


sub tellnum
{
	@arr = @_;
	my $response = (scalar(@_)/2);
	return($response);
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
	}
	return ( @mediters );
}


sub getitersnum
{ # IT GETS THE NUMBER OF ITERATION. UNUSED. CUT
	my $countcase = shift;
	my $varnumber = shift;
	my @varnumbers = @_;
	my $itersnum = $varnumbers[$countcase]{$varnumber};
	return $itersnum;
}


sub clean
{
  my ( $line, $mypath, $file ) = @_;
	$line =~ s/$mypath// ;
	$line =~ s/$file// ;
	$line =~ s/^(\/+)//g ;
	$line =~ s/^$file//g ;
	$line =~ s/^_//g ;
  $line =~ s/(\D+)$//g ;
	$line =~ s/(\D+)$//g ;
	#$line = "$mypath/$file" . "_" . "$line";
  #$line =~ s/^-// ;
  return( $line );
}


sub makefilename # IT DEFINES A FILE NAME GIVEN A %carrier.
{
	my ( $tempc_r, $mypath, $file, $instn, $inst_ref, $dowhat_ref ) = @_;
	my %tempc = %{ $tempc_r };
	my %inst = %{ $inst_ref };
	my %dowhat = %{ $dowhat_ref };
	my $cleanto;
	foreach my $key (sort {$a <=> $b} (keys %tempc) )
	{
		$cleanto = $cleanto . $key . "-" . $tempc{$key} . "_";
	}
	$cleanto =~ s/_$// ;

	my $fullto = "$mypath/$file" . "_" . "$cleanto";

	###my $cleancrypto = $instn . "__"; ###!!!OLD!!!
	my $cleancrypto = encrypt1( $cleanto );
	my $crypto = "$mypath/$file" . "_" . "$cleancrypto";

	my $it;
	if ( $dowhat{names} eq "short" )
	{
		$it{to} = $fullto;
		$it{cleanto} = $cleanto;
		$it{crypto} = $crypto;
		$it{cleancrypto} = $cleancrypto;
	}
	elsif ( ( $dowhat{names} eq "long" ) or ( $dowhat{names} eq "" ) )
	{
		$it{to} = $fullto;
		$it{cleanto} = $cleanto;
		$it{crypto} = $fullto;
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


sub getblockelts
{ # IT GETS @blockelts. TO BE CALLED WITH getblockelts(\@sweeps, $countcase, $countblock)
	my ( $sweeps_ref, $countcase, $countblock ) = @_;
	my @sweeps = @{ $sweeps_ref };
	my @blockelts = @{ $sweeps[$countcase][$countblock] };
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
	my ( $inst_r, $dowhat_ref, $transfile, $carrier_r, $file, $blockelts_r, $mypath, $instn ) = @_;
	my %carrier = %{ $carrier_r };
	my @blockelts = @{ $blockelts_r };
	my $num = scalar( @blockelts );
	my %dowhat = %{ $dowhat_ref };
	my %inst = %{ $inst_r };
	my %provhash;
	$transfile =~ s/^mypath\///;
	$transfile =~ s/^$file//;
	$transfile =~ s/^_//;
	foreach my $parnum ( keys %carrier )
	{
		$transfile =~ /^(\d+)-(\d+)/;

		if ( ($1) and ($2) )
		{
			if ( $1 ~~ @blockelts )
			{
				$provhash{$1} = $2;
			}
		}

		$transfile =~ s/^$1-$2//;
		$transfile =~ s/^_//;
	}
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
	my %to = %{ makefilename( \%tempc, $mypath, $file, $instn, \%inst, \%dowhat ) };
	return( \%to );
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
	return (@rootnames);
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
{ # IT GETS THE WINNER OR LOSER LINE.
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
		@arr = @{ $arr[0] };
	}
	return( @arr );
}


sub getcase
{
	my ( $varn_r, $countcase ) = @_;
	my @varnumbers = @{ $varn_r };
	my ( $itemref, %item);
	if ( ref( @varnumbers[0] ) eq "HASH" )
	{
		$itemref = $varnumbers[$countcase];
		%item = %{ $itemref };
	}
	else
	{
		@varnumbers = @{ $varnumbers[$countcase] };
	  $itemref = $varnumbers[$countcase];
	  my %item = %{ $itemref };
	}
	return ( %item );
}


sub getstepsvar
{
	my ( $countvar, $countcase, $varnumbers_r ) = @_;
	my @varnumbers = @{ $varnumbers_r };
	my %varnums = getcase( \@varnumbers, $countcase );
	my $stepsvar = $varnums{$countvar};
	return ( $stepsvar )
}


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
	my @arrelts = @{ $_[0] };
	my %carrier = %{ $_[1] };
	my $file = $_[2];
	my @blockelts = @{ $_[3] };
	my $mypath = $_[4];
	my %inst = %{ $_[5] };
	my %dowhat  = %{ $_[6] };
	my $instn = $_[7];
	my @newbox;
	if ( ref( $arrelts[0] ) )
	{
		foreach my $eltref ( @arrelts )
		{
			my @elts = @{ $eltref };
			my $target = $elts[0];
			my %righttarg = %{ extractcase( \%inst, \%dowhat, $target, \%carrier, $file, \@blockelts, $mypath ) };
			my $righttarget = $righttarg{cleanto};
			my $origin = $elts[3];
			my %rightorig = %{ extractcase( \%inst, \%dowhat, $origin, \%carrier, $file, \@blockelts, $mypath ) };
			my $rightorigin = $rightorig{cleanto};
			push ( @newbox, [ $righttarget, $elts[1], $elts[2], $rightorigin, $elts[4] ] );
		}
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
				push ( @box, $_->[0], $case->[4] );
			}
		}
	}
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
				$elt =~ s/^(\d*)>// ; #
				$elt =~ s/^(\d*)°// ;
				$elt =~ s/^(\d*)<// ;
				$elt =~ s/^(\d*)£// ;
				$elt =~ s/^(\d*)§// ;
				$elt =~ s/^(\d*)\|// ;
				$elt =~ s/^(\d*)ù// ;
				$elt =~ s/[A-za-z]*//g ;
				$elt =~ s/^(\d*)ç// ; # ç: push supercycle
				$elt =~ s/^ç// ; # ç: push supercycle
				$elt =~ s/^(\d*)é// ; # é: pop supercycle
				$elt =~ s/^é// ; # é: pop supercycle
				push( @inbag, $elt );
			}
			push( @midbag, [ @inbag ] );
		}
		push( @outbag, [ @midbag ] );
	}
	say $tee "CLEANED \@outbag: " . dump( @outbag );
	say $tee "CLEANED \@sourcestruct: " . dump( @sourcestruct );
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
      my $newval = ( int( ( $hsmax{$key} - $hsmin{$key} ) / 2 ) + $hsmin{$key} ) ;
      if ( ( $newval == $hsmax{$key} ) or ( $newval == $hsmin{$key} ) )
      {
        my @newpair;
        my $answer = odd__( $signal );
        if ( $answer eq "even" )
        {
          $value = $array[ int(rand( @array + 1 )) ];
          my @ar = ( $hsmax{$key}, $hsmin{$key} );
          $newval = $ar[ int( rand( @ar + 1 ) ) ];
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
          if ( $inv == "no" )
          {
            @newpair = ( $hsmin{$key}, $hsmax{$key} ); #say $tee "newpair 2: " . dump ( @newpair );
          }
          else
          {
            @newpair = ( $hsmax{$key}, $hsmin{$key} ); #say $tee "newpair 3: " . dump ( @newpair );
          }
					if ( ( $newpair[0] eq "undef" ) or ( $newpair[0] eq "" ) or ( $newpair[1] eq "undef" ) or ( $newpair[1] eq "" ) )
					{
						next;
					}
          $newval = $newpair[0];
					say $tee "newpair: " . dump ( @newpair );
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
  my %firstvarn = %{ $varns_r->[0] };
  my @firstsweep = @{ shift( @{ $sweeps_r } ) };
	my @restsweeps = @{ $sweeps_r };
	my ( @box );
  foreach $par ( sort { $a <=> $b } ( keys %firstvarn ) )
  {
		push( @box, [ $par ] );
  }
  unshift( @restsweeps, ( [ @box ] ) );
  return( \@restsweeps );
}


sub readsweeps
{
	my @struct = @_;
	my @sourcestruct = @{ dclone( \@struct ) };
	foreach ( @struct )
	{
		foreach ( @$_ )
		{	#prunethis( $_ );
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
	my @varnumbers = @{ $varnumbers_ref };
	my %varnums = getcase( \@varnumbers, $countcase );
	my @vars = ( keys %varnums );
	my @diffs = Sim::OPT::Interlinear::diff( \@vars, \@blockelts );

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
	}
	my %temp = @newhash;
	$varnumbers[$countcase] = \%temp;
	return( \@varnumbers );
}



sub star_act
{
	my ( $sweeps_r, $blockelts_r, $countcase, $countblock ) = @_;
	my @sweeps = @{ $sweeps_r };
	my @blockelts = @{ $blockelts_r };

	my @bag;
	foreach my $elt ( @blockelts )
	{
		push( @bag, [ $elt ] );
	}

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
	}
	return( \@basket, \@bag );
}


sub solvestar
{
	my %d = %{ $_[0] };
	my %dirfiles = %{ $d{dirfiles} };
	my %dowhat = %{ $d{dowhat} };
	my @varnumbers = @{ $d{varnumbers} };
	my %carrier = %{ $d{carrier} };
	my @blockelts = @{ $d{blockelts} };

	$dirfiles{direction} = "star";
	$dirfiles{starorder} = $dowhat{starorder}->[$countcase]->[0];

	my ( @gencetres, @genextremes, @genpoints, $genextremes_ref, $gencentres_ref,
		@starpositions, @dummysweeps );


	if ( $dirfiles{stardivisions} ne "" )
	{
		$dirfiles{starpositions} = genstar( \%dirfiles, \@varnumbers, \%carrier, \@blockelts );

		( $dirfiles{dummysweeps}, $dirfiles{dummyelt} ) = @{ star_act( \@sweeps, \@blockelts, $countcase, $countblock ) };
	}


	$dirfiles{starnumber} = scalar( @{ $dirfiles{starpositions} } );

	if ( not( scalar( @{ $dirfiles{starpositions} } ) == 0 ) )
	{
		$dirfiles{direction} => [ [ "star" ] ],
		$dirfiles{randomsweeps} => "no", # to randomize the order specified in @sweeps.
		$dirfiles{randominit} => "no", # to randomize the init levels specified in @miditers.
		$dirfiles{randomdirs} => "no", # to randomize the directions of descent.
	}
	return( \%dirfiles )
}


sub takewinning
{
	my ( $toitem ) = @_;

	my %carrier = split( "_|-", $toitem );
	return( \%carrier );
}


sub sense
{
	my ( $addr, $mypath, $objcolumn, $stopcondition ) = @_;
	my $newaddr = "$mypath/$addr" . "_variances.csv";

	open( ADDR, "$addr" ) or die;
	my @lines = <ADDR>;
	close ADDR;

	my @purelines;
	foreach my $line ( @lines )
	{
		chomp $line;
		push( @purelines, $line );
	}

	my @values = map { ( split( ',', $_ ))[ $objcolumn ] } @purelines;
	my $totvariance = variance( @values );

	my @cases = map { ( split( ',', $_ ))[0] } @purelines;

	my @sack;
	foreach my $case ( @cases )
	{
		my @row = split( "_", $case );
		push( @sack, [ @row ] );
	}

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
	}

	my ( %sensfs, %avgsensfs );
	foreach my $factor ( keys %whole )
	{
		my @avgvar;
		foreach my $level ( keys %{ $whole{$factor} } )
		{
			my $variance = variance( @{ $whole{$factor}{$level} } );
			my $variancerat = ( $variance / $totvariance );
			$sensfs{$factor}{$level} = $variancerat;
			push( @avgsensf, $variancerat );
		}
		my $mean = mean( @avgsensf );
		$avgsensfs{$factor} = $mean;
	}

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
  my @arr = @{ $_[0] };
  my ( %hash, %hs );

  foreach my $el ( @arr )
  {
		my %hash = split( "-|_", $el );
		foreach my $key ( keys %hash )
		{
			$hs{$key}{$hash{$key}} = "";
		}
  }

	my %ohs;
	my $num = 0;
	foreach my $key ( keys %hs )
	{
		foreach my $item ( sort { $a <=> $b }( keys %{ $hs{$key} } ) )
		{
			push( @{ $ohs{$key} }, $item );
			$num++;
		}
		$ohs{$key} = [ uniq( @{ $ohs{$key} } ) ];
	}
  return( $num, \%ohs );
}


sub callblock # IT CALLS THE SEARCH ON BLOCKS.
{
	my %d = %{ $_[0] };
	my $countcase = $d{countcase};
	my $countblock = $d{countblock};
	my @sweeps = @{ $d{sweeps} };
	my @sourcesweeps = @{ $d{sourcesweeps} };
	my @miditers = @{ $d{miditers} };
	@miditers = Sim::OPT::washn( @miditers );
	my @winneritems = @{ $d{winneritems} };
	my %dirfiles = %{ $d{dirfiles} };
	my %datastruc = %{ $d{datastruc} };
	my %dowhat = %{ $d{dowhat} };
	my @varnumbers = @{ $d{varnumbers} };
	my %inst = %{ $d{inst} };
	my %vehicles = %{ $d{vehicles} };
	@varnumbers = Sim::OPT::washn( @varnumbers );


	if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
  {
		if ( $dirfiles{checksensitivity} eq "yes" )
		{
			Sim::OPT::sense( $dirfiles{ordtot}, $mypath, $dirfiles{objectivecolumn} );
		}
    exit(
		say  $tee  "#END RUN."
		);
  }

	say $tee "#Beginning a search on case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

	my @blockelts = @{ getblockelts( \@sweeps, $countcase, $countblock ) };

	my @sourceblockelts = @{ getblockelts( \@sourcesweeps, $countcase, $countblock ) };


	my $entryname;
	if ( $sourceblockelts[0] =~ /^([A-Za-z]+)/ )
	{
		$entryname = $1;
		$dirfiles{entryname} = $entryname;
		if ( $sourceblockelts[0] =~ /ç/ )
		{
			$sourceblockelts[0] =~ /^([A-Za-z]+)(\d+)ç/ ;
			$dirfiles{slicenum} = $2;
			$dirfiles{pushsupercycle} = "yes";
			$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
			push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
		}
	}
	else
	{
		$dirfiles{entryname} = "";
	}

	my $exitname;
	if ( $sourceblockelts[-1] =~ /([A-Za-z]+)$/ )
	{
		$exitname = $1;
		$dirfiles{exitname} = $exitname;

		if ( $sourceblockelts[0] =~ /ç/ )
		{
			$sourceblockelts[0] =~ /(\d+)ç/ ;
			$dirfiles{slicenum} = $1;
			$dirfiles{pushsupercycle} = "yes";
			$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
			push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
		}

	}
	else
	{
		$dirfiles{exitname} = "";
	}

	if ( $sourceblockelts[0] =~ />/ )
	{
		$dirfiles{starsign} = "yes";
		$sourceblockelts[0] =~ /^(\d+)>/ ;
		$dirfiles{stardivisions} = $1;

		if ( $sourceblockelts[0] =~ /ç/ )
		{
			$sourceblockelts[0] =~ /^(\d+)>(\d+)ç/ ;
			$dirfiles{slicenum} = $2;
			$dirfiles{pushsupercycle} = "yes";
			$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
			push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
		}
	}
	else
	{
		$dirfiles{starsign} = "no";
		$dirfiles{stardivisions} = "";
	}

	if ( $sourceblockelts[0] =~ /\|/ )
	{
		$dirfiles{random} = "yes";
		$sourceblockelts[0] =~ /^(\d+)\|/ ;
		$dirfiles{randomnum} = $1;

		if ( $sourceblockelts[0] =~ /ç/ )
		{
			$sourceblockelts[0] =~ /^(\d+)\|(\d+)ç/ ;
			$dirfiles{slicenum} = $2;
			$dirfiles{pushsupercycle} = "yes";
			$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
			push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
		}
	}
	else
	{
		$dirfiles{random} = "no";
		$dirfiles{randomnum} = "";
	}

	if ( $sourceblockelts[0] =~ /§/ )
	{
		$dirfiles{latinhypercube} = "yes";
		$sourceblockelts[0] =~ /^(\d+)§/ ;
		$dirfiles{latinhypercubenum} = $1;

		if ( $sourceblockelts[0] =~ /ç/ )
		{
			$sourceblockelts[0] =~ /^(\d+)§(\d+)ç/ ;
			$dirfiles{slicenum} = $2;
			$dirfiles{pushsupercycle} = "yes";
			$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
			push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
		}
	}
	else
	{
		$dirfiles{latinhypercube} = "no";
		$dirfiles{latinhypercubenum} = "";
	}

	if ( $sourceblockelts[0] =~ /°/ )
	{
		$dirfiles{randompick} = "yes";
		$sourceblockelts[0] =~ /^(\d+)°/ ;
		$dirfiles{randompicknum} = $1;

		if ( $sourceblockelts[0] =~ /ç/ )
		{
			$sourceblockelts[0] =~ /^(\d+)°(\d+)ç/ ;
			$dirfiles{slicenum} = $2;
			$dirfiles{pushsupercycle} = "yes";
			$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
			push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
		}
	}
	else
	{
		$dirfiles{randompick} = "no";
		$dirfiles{randompicknum} = "";
	}


	if ( $sourceblockelts[0] =~ /ù/ )
	{
		$dirfiles{ga} = "yes";
		$sourceblockelts[0] =~ /^(\d+)ù/ ;
		$dirfiles{ganum} = $1;

		if ( $sourceblockelts[0] =~ /ç/ )
		{
			$sourceblockelts[0] =~ /^(\d+)ù(\d+)ç/ ;
			$dirfiles{slicenum} = $2;
			$dirfiles{pushsupercycle} = "yes";
			$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
			push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
		}
	}
	else
	{
		$dirfiles{ga} = "no";
		$dirfiles{ganum} = "";
	}


	if ( $sourceblockelts[0] =~ /</ )
	{
		$dirfiles{factorial} = "yes";

		if ( $sourceblockelts[0] =~ /ç/ )
		{
			$sourceblockelts[0] =~ /^(\d+)<(\d+)ç/ ;
			$dirfiles{slicenum} = $2;
			$dirfiles{pushsupercycle} = "yes";
			$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
			push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
		}
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
		$dirfiles{starsign} = "yes";
		$sourceblockelts[0] =~ /^(\d+)£/ ;
		$dirfiles{facecenterednum} = $1;
		$dowhat{starpositions} = "";
		$dirfiles{starpositions} = "";
		$dowhat{stardivisions} = 1;
		$dirfiles{stardivisions} = 1;

		if ( $sourceblockelts[0] =~ /ç/ )
		{
			$sourceblockelts[0] =~ /^(\d+)£(\d+)ç/ ;
			$dirfiles{slicenum} = $2;
			$dirfiles{pushsupercycle} = "yes";
			$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
			push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
		}
	}
	else
	{
		$dirfiles{facecentered} = "no";
	}

	if ( $sourceblockelts[0] =~ /ç/ )
	{
		$sourceblockelts[0] =~ /^(\d+)(>|<|£|§|°|§|ù)(\d+)ç/ ;
		$dirfiles{slicenum} = $3;
		if ( $3 eq "" )
		{
			$sourceblockelts[0] =~ /^(\d+)ç/ ;
			$dirfiles{slicenum} = $1;
		}
		say $tee "SLICENUM! " . dump( $dirfiles{slicenum} );
		say $tee "\$countcase $countcase \$countblock $countblock";
		$dirfiles{pushsupercycle} = "yes";
		$dirfiles{nestclock} = $dirfiles{nestclock} + 1;
		push( @{ $vehicles{nesting}{$dirfiles{nestclock}} }, $countblock );
	}

	if ( $sourceblockelts[0] =~ /é/ )
	{
		$sourceblockelts[0] =~ /^(\d+)(>|<|£|§|°|§|ù)(\d+)é/ ;
		$dirfiles{revealnum} = $3;
		say $tee "REVEALNUM! " . dump( $dirfiles{revealnum} );
		$dirfiles{popsupercycle} = "yes";
	}
	else
	{
		$dirfiles{popsupercycle} = "";
	}

	my @blocks = getblocks( \@sweeps, $countcase );

	my $toitem = getitem( \@winneritems, $countcase, $countblock );
	$toitem = clean( $toitem, $mypath, $file );

	my $from = getline($toitem);
	$from = clean( $from, $mypath, $file );

	my $file = $dowhat{file};

	my %carrier = %{ takewinning( $toitem ) };

	my @tempvarnumbers;
	if ( $dirfiles{starsign} eq "yes" )
	{
		my @newvarnumbers = @{ stararrange( \@sweeps, \@blockelts, \@varnumbers, $countcase, $countblock, $file ) };
		$dirfiles{varnumbershold} = dclone( \@varnumbers );
		@varnumbers = @{ dclone( \@newvarnumbers ) };
		@varnumbers = Sim::OPT::washn( @varnumbers );

		%dirfiles = %{ solvestar( { dirfiles => \%dirfiles, dowhat => \%dowhat, varnumbers => \@varnumbers, blockelts => \@blockelts, carrier => \%carrier } ) };

		my @newmiditers = @{ $dirfiles{starpositions} }; # IT CORRECTS THE PART OF @miditers OUTSIDE THE BLOCKS

		$dirfiles{miditershold} = dclone( \@miditers );

		@miditers = @{ dclone( \@newmiditers ) };
	}

	my %mids = getcase( \@miditers, $countcase );
	my %varnums = getcase( \@varnumbers, $countcase );

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
	$dirfiles{repfile} = "$mypath/$file-report-$countcase-$countblock.csv";
	$dirfiles{sortmixed} = "$dirfiles{repfile}" . "_sortm.csv";
	$dirfiles{totres} = "$mypath/$file-$countcase" . "_totres.csv";
	$dirfiles{ordres} = "$mypath/$file-$countcase" . "_ordres.csv";

	deffiles( {	countcase => $countcase, countblock => $countblock,
		miditers => \@miditers,  winneritems => \@winneritems,
		dirfiles => \%dirfiles, from => $from,
		sweeps => \@sweeps, sourcesweeps => \@sourcesweeps, datastruc => \%datastruc,
		dowhat => \%dowhat, varnumbers => \@varnumbers,
		mids => \%mids, varnums => \%varnums, carrier => \%carrier,
		carrier => \%carrier, sourceblockelts => \@sourceblockelts,
		blocks => \@blocks, blockelts => \@blockelts, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
}


sub deffiles # IT DEFINED THE FILES TO BE PROCESSED
{
	my %d = %{ $_[0] };

	my $countcase = $d{countcase};
  my $countblock = $d{countblock};
	my @sweeps = @{ $d{sweeps} };
	my @sourcesweeps = @{ $d{sourcesweeps} };
	my @miditers = @{ $d{miditers} };
	my @winneritems = @{ $d{winneritems} };
	my %dirfiles = %{ $d{dirfiles} };
	my %datastruc = %{ $d{datastruc} };
	my @varnumbers = @{ $d{varnumbers} };
	my %dowhat = %{ $d{dowhat} };

	my @blockelts = @{ $d{blockelts} };
	my @sourceblockelts = @{ $d{blockelts} };
	my @blocks = @{ $d{blocks} };
	my $from = $d{from};
	my %varnums = %{ $d{varnums} };
	my %mids = %{ $d{mids} };
	my %carrier = %{ $d{carrier} };
	my $instn = $d{instn};
	my %inst = %{ $d{inst} };
	my %vehicles = %{ $d{vehicles} };

	my $file = $dowhat{file};
	my $mypath = $dowhat{mypath};

	my $starstring = tellstring( \%mids, $file );
	$dirfiles{starstring} = $starstring; # FOR THE OUTTER STAR SEARCH

	my $rootitem = "$file" . "_";
	my (@basket, @box);
	push (@basket, [ $rootitem ] );

	sub toil
	{
		my ( $blockelts_r, $varnums_r, $basket_r, $c, $mypath, $file ) = @_;
		my @blockelts = @{ $blockelts_r };
		my %varnums = %{ $varnums_r };

		my @basket = @{ $basket_r };
		if ( ( $c eq "" ) or ( $c == 0 ) )
		{
			@box = ();
		}

		foreach my $var ( @blockelts )
		{
			my ( @bucket );
			my $maxvalue	= $varnums{$var};

			foreach my $elt ( @basket )
			{
				my $root = $elt->[0];
				my @bag;
				my $item;
				my $cnstep = 1;
				while ( $cnstep <= $maxvalue)
				{
					my $olditem = $root;
					$item = "$root" . "$var" . "-" . "$cnstep" . "_" ;
					push ( @bag, [ $item, $var, $cnstep, $olditem, $c ] );
					$cnstep++;
				}
				push ( @bucket, @bag );
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
		}
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
				my @bix = @{ toil( \@dummys, \%varnums, \@basket, $c, $mypath, $file ) };
				@bix = @{ $bix[0] };
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
			$tmpblankfile = "$mypath/$file" . "_tmp_gen_blank.csv";
			$bit = $file . "_";
			@bag =( $bit );
			@fills = @{ Sim::OPT::Descend::prepareblank( \%varnums, $tmpblankfile, \@blockelts, \@bag, $file, \%carrier ) };
			@fulls = uniq( map { $_->[0] } @fills );
		}

		if ( $dirfiles{random} eq "yes" )
		{
			my ( $standard ) = prepfactl( \@fulls );

			my $numitems = $dirfiles{randomnum};
			my @newfulls = shuffle( @fulls );
			my @forebunch = @newfulls[ 0 .. $numitems ];

			foreach $el ( @forebunch )
			{
				push( @buux, [ [ $el, "", "", "", "" ] ] );
			}
		}

		if ( $dirfiles{latinhypercube} eq "yes" )
		{
			my ( $standard ) = prepfactl( \@fulls );
			my $numitems = $dirfiles{latinhypercubenum};

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
			}

			foreach $el ( @forebunch )
			{
				push( @buux, [ [ $el, "", "", "", "" ] ] );
			}
		}

		if ( $dirfiles{factorial} eq "yes" )
		{
			my ( $standard, $ohs_r ) = prepfactl( \@fulls );
			my %ohs = %{ $ohs_r };

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
			}

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
			}

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
		}
	}
	else
	{
		unless ( $dirfiles{ga} eq "yes" )
	  {
	    @bux = @{ toil( \@blockelts, \%varnums, \@basket, "", $mypath, $file ) };
	  }
	  else
	  {
	    my @subst = (1);
	    @bux = @{ toil( \@subst, \%carrier, \@basket, "", $mypath, $file ) };
	  }
	}


	sub cleanduplicates
	{
		my ( $elts_ref, $dowhat_ref ) = @_;
		my @elts = @{ $elts_ref };
		my %dowhat = %{ $dowhat_ref };

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
		}
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
			my %midsurrs = %{ $midsurrs_r };
	 		@bag = uniq( @{ integratebox( \@bux, \%midsurrs, $file, \@blockelts, $mypath, \%inst, \%dowhat, $instn ) } );
			push( @finalbox, @bag );
		}
		my @finalbox = cleanduplicates( \@finalbox, \%dowhat );
	}
	else
	{
		my @bark = @{ flattenbox( \@bux ) };
		@finalbox = uniq( @{ integratebox( \@bark, \%carrier, $file, \@blockelts, $mypath, \%inst, \%dowhat, $instn ) } );
	}

	@finalbox = sort { $a->[0] <=> $b->[0] } @finalbox;

	setlaunch( {
		countcase => $countcase, countblock => $countblock,
		miditers => \@miditers,  winneritems => \@winneritems,
		dirfiles => \%dirfiles, basket => \@finalbox,
		sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
		datastruc => \%datastruc, dowhat => \%dowhat,
		varnumbers => \@varnumbers,
		mids => \%mids, varnums => \%varnums,
		carrier => \%carrier, instn => $instn, inst => \%inst, vehicles => \%vehicles
	} );
}

sub setlaunch # IT SETS THE DATA FOR THE SEARCH ON THE ACTIVE BLOCK.
{
	my %d = %{ $_[0] };
	my $countcase = $d{countcase};
	my $countblock = $d{countblock};
	my @sweeps = @{ $d{sweeps} };
	my @sourcesweeps = @{ $d{sourcesweeps} };
	my @miditers = @{ $d{miditers} };
	my @winneritems = @{ $d{winneritems} };
	my %dirfiles = %{ $d{dirfiles} };
	my @basket = @{ $d{basket} };
	my %datastruc = %{ $d{datastruc} };
	my @varnumbers = @{ $d{varnumbers} };
	my %dowhat = %{ $d{dowhat} };
	my $instn = $d{instn};
	my %inst = %{ $d{inst} };
	my %vehicles = %{ $d{vehicles} };

	my @blockelts = @{ getblockelts( \@sweeps, $countcase, $countblock ) };
	my @blocks = getblocks( \@sweeps, $countcase );

	my %varnums = %{ $d{varnums} };
	my %mids = %{ $d{mids} };
	my %carrier = %{ $d{carrier} };

	my ( @instances, @precedents );
	my %starters = %{ extractcase( \%inst, \%dowhat, "", \%carrier, $file, \@blockelts, $mypath, "" ) };

	$dirfiles{starter}{cleanto} = $starters{cleanto};
	$dirfiles{starter}{cleancrypto} = $starters{cleancrypto};

	my $count = 0;
	foreach my $elt ( @basket )
	{
		my $newpars = $$elt[0];
		my $countvar = $$elt[1];
		my $countstep = $$elt[2];
		my $oldpars = $$elt[3];

		my %to = %{ extractcase( \%inst, \%dowhat, $newpars, \%carrier, $file, \@blockelts, $mypath, $instn ) };

		{
			my %orig = %{ extractcase( \%inst, \%dowhat, $oldpars, \%carrier, $file, \@blockelts, $mypath ) }; #say $tee "obtained \$instn: $instn, countinstance: $count, from: $from, \$to: $to, \%orig: " . dump( \%orig ) . ", \%carrier: " . dump( \%carrier );
			my $origin = $orig{cleanto};
			my $from = $origin;
	  	my $c = $$elt[4];

			$inst{$to{cleanto}} = $to{cleancrypto};
		  $inst{$to{crypto}} = $to{to};
		  $inst{$to{cleancrypto}} = $to{cleanto};
		  $inst{$to{to}} = $to{crypto};
		  $inst{$orig{cleanto}} = $orig{cleancrypto};
		  $inst{$orig{crypto}} = $orig{to};
		  $inst{$orig{cleancrypto}} = $orig{cleanto};
		  $inst{$orig{to}} = $orig{crypto};

			%inst = cleaninst( %inst );
			#unless ( $dirfiles{ga} eq "yes" )
			#{
				#
        if ( not ( $to{cleanto} ~~ @{ $dirfiles{dones} } ) )
				{
					unless ( $dirfiles{randompick} eq "yes" )
					{
						push( @{ $dirfiles{dones} }, $to{cleanto} );
					}

					push( @instances,
					{
						countcase => $countcase, countblock => $countblock,
						miditers => \@miditers,  winneritems => \@winneritems, c => $c, from => $from,
						to => \%to, countvar => $countvar, countstep => $countstep, orig => \%orig,
						sweeps => \@sweeps, dowhat => \%dowhat,
						sourcesweeps => \@sourcesweeps, datastruc => \%datastruc,
						varnumbers => \@varnumbers, blocks => \@blocks,
						blockelts => \@blockelts, mids => \%mids, varnums => \%varnums,
						countinstance => $count, carrier => \%carrier, origin => $origin,
						instn => $instn, is => $to{cleanto}, vehicles => \%vehicles,
					} );
				}
        else
				{
					push( @precedents,
					{
						countcase => $countcase, countblock => $countblock,
						miditers => \@miditers,  winneritems => \@winneritems, c => $c, from => $from,
						to => \%to, countvar => $countvar, countstep => $countstep, orig => \%orig,
						sweeps => \@sweeps, dowhat => \%dowhat,
						sourcesweeps => \@sourcesweeps, datastruc => \%datastruc,
						varnumbers => \@varnumbers, blocks => \@blocks,
						blockelts => \@blockelts, mids => \%mids, varnums => \%varnums,
						countinstance => $count, carrier => \%carrier, origin => $origin,
						instn => $instn, is => $to{cleanto}, vehicles => \%vehicles,
					} );
				}
			#}
			$instn++;
		}
		$count++;
	}
	exe( { instances => \@instances, dirfiles => \%dirfiles, inst => \%inst, precedents => \@precedents, mypath => $mypath, file => $file,
         countcase => $countcase, countblock => $countblock, varnumbers => \@varnumbers, miditers => \@miditers, sweeps => \@sweeps,
				 sourcesweeps => \@sourcesweeps, winneritems => \@winneritems, dowhat => \%dowhat, mids => \%mids,
			   carrier => \%carriers, varnums => \%varnums,  } );
}

sub exe
{
	my %dat = %{ $_[0] };
	my @instances = @{ $dat{instances} };
	my %dirfiles = %{ $dat{dirfiles} };
	my %inst = %{ $dat{inst} };
	my @precedents = @{ $dat{precedents} };
	my $mypath = $dat{mypath};
	my $file = $dat{file};
	my $countcase = $dat{countcase};
	my $countblock = $dat{countblock};
	my @varnumbers = @{ $dat{varnumbers} };
	my @miditers = $dat{miditers};
	my @sweeps = @{ $dat{sweeps} };
	my @sourcesweeps = @{ $dat{sourcesweeps} };
	my @winneritems =  @{ $dat{winneritems} };
  my %dowhat = %{ $dat{dowhat} };
	my %mids = %{ $dat{mids} }; ##say "MIDS " . dump( \%mids );
	my %carrier = %{ $dat{carrier} };
	my %varnums = %{ $dat{varnums} };

	my %d = %{ $instances[0] };
	my %datastruc = %{ $d{datastruc} };
	my $from = $d{from};
	my %to = %{ $d{to} };
	my %orig = %{ $d{orig} };
	my $countvar = $d{countvar};
	my $countstep = $d{countstep};



	my @blockelts = @{ $d{blockelts} };
	my @sourceblockelts = @{ $d{blockelts} };
	my @blocks = @{ $d{blocks} };
	my $instn = $d{instn};
	my %vehicles = %{ $d{vehicles} };

	my $precomputed = $dowhat{precomputed};
  my @takecolumns = @{ $dowhat{takecolumns} };
	my ( @simcases, @simstruct );
	say $tee "#Performing a search on case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

	my $cryptolinks;
	#unless ( $dirfiles{ga} eq "yes" )
	#{
		$cryptolinks = "$mypath/$file" . "_" . "$countcase" . "_cryptolinks.pl"; say $tee "CRYPTOLINKS $cryptolinks";
		open ( CRYPTOLINKS, ">$cryptolinks" ) or die;
		say CRYPTOLINKS "" . dump( \%inst );
		close CRYPTOLINKS;
	#}

	my ( @reds, %winning, $csim );

	if ( $dirfiles{nestclock} > 0 )
	{
		push( @{ $vehicles{cumulateall} }, @instances );
	}

	say $tee "BEFORE PROCESSING, INSTANCES: " . dump ( @instances );

	if ( $dirfiles{ga} eq "yes" )
	{
		say $tee "SHOW \@instances: " . dump ( @instances ); # use Storable;
		say $tee "#Calling GAs on morphing operations for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

		my $basestore = "./basestore-$countcase-$countblock";
		my $dowhatstore = "./dowhat-$countcase-$countblock";
    my $dirfilesstore = "./dirfiles-$countcase-$countblock";

		my %carrier = Sim::OPT::Morph::reconstruct( $origin );
		my $starttarget = Sim::OPT::Morph::giveback( \%mids ); ##say "STARTTARGET $starttarget";

		my $startcrypt = encrypt1( $starttarget );

    #%obtained = map { $_{is} = $starttarget } %{ $instances[$#instances] };
		#%obtained = map { $_{origin} = $starttarget } %{ $instances[$#instances] };
		#%obtained = map { $_{from} = $starttarget } %{ $instances[$#instances] };
		#%obtained = map { $_{to}{cleanto} = $starttarget } %{ $instances[$#instances] };
		#%obtained = map { $_{orig} = $starttarget } %{ $instances[$#instances] };
		#%obtained = map { $_{orig}{cleanto} = $starttarget } %{ $instances[$#instances] };
		#%obtained = map { $_{to}{to} = $starttarget } %{ $instances[$#instances] };
		#%obtained = map { $_{orig}{to} = $starttarget } %{ $instances[$#instances] };

    my $crypto = encrypt1( $starttarget );
		my $cryptor = encrypt1( $starttarget );

		my $count = 0;
		foreach $i ( @instances )
		{
			my %in = %{ $i };
			if ( $count == 0 )
			{
				$in{is} = $starttarget;
				$in{origin} = $starttarget;
				$in{from} = $starttarget;
				$to{cleanto} = $starttarget;
				$orig{cleanto} = $starttarget;
			  $to{to} = "$mypath/$file" . "_" . "$starttarget";
				$orig{to} = "$mypath/$file" . "_" . "$starttarget";

				if ( $dowhat{names} eq "long" )
			  {
			    $to{crypto} = "$mypath/$file" . "_" . "$crypto";  ###DDD!!! FINISH THIS.
			    $to{cleancrypto} = $crypto;  ###DDD!!! FINISH THIS.
			    $orig{crypto} = "$mypath/$file" . "_" . "$cryptor";  ###DDD!!! FINISH THIS.
			    $orig{cleancrypto} = $cryptor; ###DDD!!! FINISH THIS.
			  }
			  elsif ( $dowhat{names} eq "short" )
			  {
			    $to{crypto} = "$mypath/$file" . "_" . "$starttarget";  ### TAKE CARE!!! REASSIGNIMENT!!!
			    $to{cleancrypto} = $starttarget; ### TAKE CARE!!! REASSIGNIMENT!!!
			    $orig{crypto} = "$mypath/$file" . "_" . "$starttarget"; ### TAKE CARE!!! REASSIGNIMENT!!!
			    $orig{cleancrypto} = $starttarget; ### TAKE CARE!!! REASSIGNIMENT!!!
			  }

				$inst{$to{cleanto}} = $to{cleancrypto};
			  $inst{$to{crypto}} = $to{to};
			  $inst{$to{cleancrypto}} = $to{cleanto};
			  $inst{$to{to}} = $to{crypto};
			  $inst{$orig{cleanto}} = $orig{cleancrypto};
			  $inst{$orig{crypto}} = $orig{to};
			  $inst{$orig{cleancrypto}} = $orig{cleanto};
			  $inst{$orig{to}} = $orig{crypto};
				%inst = cleaninst( %inst );

			}

			$count++;
		}


		my @juggle;
		my @prov = @instances; say $tee "BEFORE, INSTANCES: " . dump ( @instances );
		my $pop = pop( @prov );
		my %instance = %{ $pop };

		say $tee `rm -f $basestore`;
		say $tee `rm -f $dowhatstore`;
		say $tee `rm -f $dirfilesstore`;
		say $tee `rm -f $basestore-return`;
		say $tee `rm -f ./$relate.txt`;
		say $tee `rm -f ./$report.txt`;


		store \%instance, "$basestore";
		store \%dowhat, "$dowhatstore"; # ATTENTION. use Storable;
		store \%dirfiles, "$dirfilesstore"; # ATTENTION. use Storable;


		say $tee "python $dowhat{ga} $configfile $starttarget $countcase $basestore $dowhatstore $dirfilesstore $dirfiles{ganum}";
		my @returns = `python $dowhat{ga} $configfile $starttarget $countcase $basestore $dowhatstore $dirfilesstore $dirfiles{ganum}`; #HERE FLOWS THE ACTION
		say  "RETURNED!: " . dump ( @returns );


    my @selecteds;


    say  "\%mids!: " . dump ( \%mids ); say  "\$countcase!: " . dump ( $countcase );
		say  "\@juggle!: " . dump ( @juggle ); say  "\%dowhat!: " . dump ( \%dowhat );
		foreach my $name ( @returns )
		{
			chomp $name; say  "\$name!: " . dump ( $name );
			my $inss_r = Sim::OPT::Morph::setpickinst( $name, \%mids, $countcase, \@juggle, \%dowhat );
			my @inss = @{ $inss_r }; chomp $name; say  "\@inss!: " . dump ( @inss );
			my $pickedins = $inss[$#inss];
      push ( @selecteds, $pickedins );
		}
		#say  "SELECTEDS!: " . dump ( @selecteds );

		my @instances = @selecteds;

		foreach my $inst_r ( @instances )
		{
		  my %i = %{ $inst_r };
			my %inst = %{ $i{inst} };
			my %to = %{ $i{to} }; say RELATE "out of setpickinst \%to " .dump ( %to );
			my %orig = %{ $i{orig} }; say RELATE "out of \%orig \$crypto " .dump ( %orig );
			my $is = $i{is}; say RELATE "out of setpickinst \$is " .dump ( $is );
		  my $origin = $i{origin}; say RELATE "out of setpickinst \$origin " .dump ( $origin );

			#my $crypto = int( ( scalar( keys %inst ) ) / 5 * 6 );
			#my $cryptor = $crypto + 1;

			my $crypto = Sim::OPT::encrypt1( $is ); say RELATE "out of setpickinst \$crypto " .dump ( $crypto );
	    my $cryptor = Sim::OPT::encrypt1( $origin ); say RELATE "out of setpickinst \$cryptor " .dump ( $cryptor );

	    $to{to} = "$mypath/$file" . "_" . "$is";  ### TAKE CARE!!! REASSIGNIMENT!!!
	    $to{cleanto} = "$is"; ### TAKE CARE!!! REASSIGNIMENT!!!
	    $orig{to} = "$mypath/$file" . "_" . "$origin"; ### TAKE CARE!!! REASSIGNIMENT!!!
	    $orig{cleanto} = "$origin"; ### TAKE CARE!!! REASSIGNIMENT!!!

			if ( $dowhat{names} eq "long" )
		  {
		    $to{crypto} = "$mypath/$file" . "_" . "$crypto";  ###DDD!!! FINISH THIS.
		    $to{cleancrypto} = $crypto;  ###DDD!!! FINISH THIS.
		    $orig{crypto} = "$mypath/$file" . "_" . "$cryptor";  ###DDD!!! FINISH THIS.
		    $orig{cleancrypto} = $cryptor; ###DDD!!! FINISH THIS.
		  }
		  else
		  {
		    $to{crypto} = $to{to};  ### TAKE CARE!!! REASSIGNIMENT!!!
		    $to{cleancrypto} = $to{cleanto}; ### TAKE CARE!!! REASSIGNIMENT!!!
		    $orig{crypto} = $orig{to}; ### TAKE CARE!!! REASSIGNIMENT!!!
		    $orig{cleancrypto} = $orig{cleanto}; ### TAKE CARE!!! REASSIGNIMENT!!!
		  }

			$inst{$to{cleanto}} = $to{cleancrypto};
		  $inst{$to{crypto}} = $to{to};
		  $inst{$to{cleancrypto}} = $to{cleanto};
		  $inst{$to{to}} = $to{crypto};
		  $inst{$orig{cleanto}} = $orig{cleancrypto};
		  $inst{$orig{crypto}} = $orig{to};
		  $inst{$orig{cleancrypto}} = $orig{cleanto};
		  $inst{$orig{to}} = $orig{crypto};
			%inst = cleaninst( %inst );
		}

		say $tee "HAVE! INST " . dump( \%inst );

		my $cryptolinks = "$mypath/$file" . "_" . "$countcase" . "_cryptolinks.pl";
		open ( CRYPTOLINKS, ">$cryptolinks" ) or die;
		say CRYPTOLINKS "" . dump( \%inst );
		close CRYPTOLINKS;
    say $tee "ARRIVED 1 ";
		if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
		{
      say $tee "ARRIVED 2 ";
			say $tee "#Calling simulations, reporting and retrieving for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
			 ( my $simcases_ref, my $simstruct_ref, my $repcases_ref, my $repstruct_ref,
		    my $mergestruct_ref, my $mergecases_ref, $csim ) = Sim::OPT::Sim::sim(
					{ instances => \@instances, dirfiles => \%dirfiles, dowhat => \%dowhat, vehicles => \%vehicles,
					  inst => \%inst, precedents => \@precedents, postproc => "yes" } );
					$dirfiles{simcases} = $simcases_ref;
					$dirfiles{simstruct} = $simstruct_ref;
					$dirfiles{repcases} = $repcases_ref;
					$dirfiles{repstruct} = $repstruct_ref;
					$dirfiles{mergestruct} = $mergestruct_ref;
					$dirfiles{mergecases} = $mergecases_ref;
		}
    say $tee "ARRIVED 3 ";

		if ( $dowhat{metamodel} eq "yes" )
		{
			$tmpblankfile = "$mypath/$file" . "_tmp_gen_blank.csv"; say $tee "IN LATINHYPERCUBE \$tmpblankfile: " . dump( $tmpblankfile );
			$bit = $file . "_";
			@bag =( $bit );
			@fills = @{ Sim::OPT::Descend::prepareblank( \%varnums, $tmpblankfile, \@blockelts, \@bag, $file, \%carrier ) };
			@fulls = uniq( map { $_->[0] } @fills );
		}
	}
	elsif ( $dirfiles{randompick} eq "yes" )
	{############################################################

		my ( @sack, @collect );
    my $randnum = 0;
		while ( scalar( @sack ) <= $randompicknum )
		{
			my $newstring = genstring( \%mids, \%varnums );

			$instances_r = Sim::OPT::Morph::setpickinst( $newstring, \%mids, $countcase, \@baseinsts, \%dowhat );
			@shortinstances = @{ $instances_r }; say $tee "ALL-IMPORTANT ARRIVED INSTANCES TO GO " . dump ( @instances );

			foreach my $ir ( @shortinstances )
			{
			  my %i = %{ $ir };
			  my %to = %{ $i{to} }; say $tee "out of setpickinst \%to " .dump ( %to );
			  my %orig = %{ $i{orig} }; say $tee "out of \%orig \$crypto " .dump ( %orig );
			  my $is = $i{is}; say $tee "out of setpickinst \$is " .dump ( $is );
			  my $origin = $i{origin}; say $tee "out of setpickinst \$origin " .dump ( $origin );

			  $to{to} = "$mypath/$file" . "_" . "$is";  say $tee "A out of setpickinst \$to{to} " .dump ( $to{to} );
			  $to{cleanto} = "$is"; say $tee "B out of setpickinst \$to{cleanto} " .dump ( $to{cleanto} );
			  $orig{to} = "$mypath/$file" . "_" . "$origin"; say $tee "C out of setpickinst \$orig{to} " .dump ( $orig{to} );
			  $orig{cleanto} = "$origin"; say $tee "D out of setpickinst \$orig{cleanto} " .dump ( $orig{cleanto} );

			  if ( $dowhat{names} eq "long" )
			  {
			    my $crypto = Sim::OPT::encrypt1( $is ); say $tee "out of setpickinst \$crypto " .dump ( \$crypto );
			    my $cryptor = Sim::OPT::encrypt1( $origin ); say $tee "out of setpickinst \$cryptor " .dump ( \$cryptor );
			    $to{crypto} = "$mypath/$file" . "_" . "$crypto";  ###DDD!!! FINISH THIS.
			    $to{cleancrypto} = $crypto;  ###DDD!!! FINISH THIS.
			    $orig{crypto} = "$mypath/$file" . "_" . "$cryptor";  ###DDD!!! FINISH THIS.
			    $orig{cleancrypto} = $cryptor; ###DDD!!! FINISH THIS.
			  }
			  else
			  {
			    $to{crypto} = $to{to};  ### TAKE CARE!!! REASSIGNIMENT!!!
			    $to{cleancrypto} = $to{cleanto}; ### TAKE CARE!!! REASSIGNIMENT!!!
			    $orig{crypto} = $orig{to}; ### TAKE CARE!!! REASSIGNIMENT!!!
			    $orig{cleancrypto} = $orig{cleanto}; ### TAKE CARE!!! REASSIGNIMENT!!!
			  }

			  $inst{$to{cleanto}} = $to{cleancrypto};
			  $inst{$to{crypto}} = $to{to};
			  $inst{$to{cleancrypto}} = $to{cleanto};
			  $inst{$to{to}} = $to{crypto};
			  $inst{$orig{cleanto}} = $orig{cleancrypto};
			  $inst{$orig{crypto}} = $orig{to};
			  $inst{$orig{cleancrypto}} = $orig{cleanto};
			  $inst{$orig{to}} = $orig{crypto};
				%inst = cleaninst( %inst );

			}
			say $tee "FINALLY, \%inst" . dump( \%inst );

			my @pop = @shortinstances;
			my $leadinst_ref = pop( @pop );

			#my $exportinsts = "./exportinsts-$countblock.txt";
			#open( EXPORTINSTS, ">>$exportinsts" );
			#print EXPORTINSTS "$precious ";
			#close EXPORTINSTS;

			say $tee "16ARRIVED 3,LAUNCHING MORPHING WITH \$configfile $configfile, \@shortinstances, " . dump( @shortinstances ) . ", ...0000000000000000000000
			\$fire $fire, \%dirfiles,  " . dump( %dirfiles ) . ", \%dowhat, "  . dump( %dowhat ) . ", \%vehicles, " . dump( %vehicles ) . " \%inst " . dump( %inst ), ;
			Sim::OPT::Morph::morph( $configfile, \@shortinstances, \%dirfiles, \%dowhat, \%vehicles, \%inst );

			my @lastinstance = ();
			my $c = 0;
			foreach my $inst ( @shortinstances )
			{
				if ( $c == $#shortinstances )
				{

					push ( @lastinstance, $inst );
				}
				$c++;
			}

			say $tee "ARRIVED 4, WITH $precious";
			say $tee "LAUNCHING SIM WITH  \@lastinstance, " . dump( @lastinstance ) . ", \$fire $fire, \%dirfiles,  " . dump( %dirfiles ) .
			     ", \%vehicles, " . dump( %vehicles ) . ", \%dowhat, "  . dump( %dowhat ) . " \%inst " . dump( %inst ), ;
			Sim::OPT::Sim::sim( { instances => \@lastinstance, dowhat => \%dowhat, dirfiles => \%dirfiles, vehicles => \%vehicles, precious => $precious, inst => \%inst, fire => "yes"  } );

			say $tee "#Descending to catch performance " . ($countcase + 1) . ", block " . ($countblock + 1) . ".";
			Sim::OPT::Descend::descend(	{ instances => \@lastinstance, dowhat => \%dowhat, dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst, precedents => \@precedents, precious => "$precious" } );
			say $tee "#Moving on " . ($countcase + 1) . ", block " . ($countblock + 1) . ".";

			if ( not ( $is ~~ @sack ) )
			{
				push ( @sack, $is );
				push ( @collect, @lastinstance );
			}
			$randnumc++;
		}

		my @instances = @collect;

		#my $cryptolinks = "$mypath/$file" . "_" . "$countcase" . "_cryptolinks.pl";
		#open ( CRYPTOLINKS, ">$cryptolinks" ) or die;
		#say CRYPTOLINKS "" . dump( \%inst );
		#close CRYPTOLINKS;

		if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
		{

			say $tee "#Calling simulations, reporting and retrieving for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
			 ( my $simcases_ref, my $simstruct_ref, my $repcases_ref, my $repstruct_ref,
		    my $mergestruct_ref, my $mergecases_ref, $csim ) = Sim::OPT::Sim::sim(
					{ instances => \@instances, dirfiles => \%dirfiles, dowhat => \%dowhat, vehicles => \%vehicles,
					  inst => \%inst, precedents => \@precedents } );
					$dirfiles{simcases} = $simcases_ref;
					$dirfiles{simstruct} = $simstruct_ref;
					$dirfiles{repcases} = $repcases_ref;
					$dirfiles{repstruct} = $repstruct_ref;
					$dirfiles{mergestruct} = $mergestruct_ref;
					$dirfiles{mergecases} = $mergecases_ref;
		}


		if ( $dowhat{metamodel} eq "yes" )
		{
			$tmpblankfile = "$mypath/$file" . "_tmp_gen_blank.csv"; say $tee "IN LATINHYPERCUBE \$tmpblankfile: " . dump( $tmpblankfile );
			$bit = $file . "_";
			@bag =( $bit );
			@fills = @{ Sim::OPT::Descend::prepareblank( \%varnums, $tmpblankfile, \@blockelts, \@bag, $file, \%carrier ) };
			@fulls = uniq( map { $_->[0] } @fills );
		}



	}
  elsif ( $dirfiles{OLDrandompick} eq "yes" ) #DDD
	{
		say $tee "#Calling randomly picked morphing operations for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";

		my @pool = @instances ;
		say $tee "\pool: " . dump( @pool );
		@reds = shuffle( @pool );
		say $tee "REDS1: " . dump( @reds );
		@reds = @reds[0..($dirfiles{randompicknum}-1)];
		say $tee "REDS2: " . dump( @reds );

		@instances = @reds;


		if ( $dowhat{morph} eq "y" )
		{
			say $tee "#Calling morphing operations for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
			my @result = Sim::OPT::Morph::morph( $configfile, \@instances, \%dirfiles, \%dowhat, \%vehicles, \%inst, \@precedents );
			$dirfiles{morphcases} = $result[0];
			$dirfiles{morphstruct} = $result[1];
			#%inst = %{ $result[2] };
		}

		if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
		{

			say $tee "#Calling simulations, reporting and retrieving for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
			 ( my $simcases_ref, my $simstruct_ref, my $repcases_ref, my $repstruct_ref,
		    my $mergestruct_ref, my $mergecases_ref, $csim ) = Sim::OPT::Sim::sim(
					{ instances => \@instances, dirfiles => \%dirfiles, dowhat => \%dowhat, vehicles => \%vehicles,
					  inst => \%inst, precedents => \@precedents } );
					$dirfiles{simcases} = $simcases_ref;
					$dirfiles{simstruct} = $simstruct_ref;
					$dirfiles{repcases} = $repcases_ref;
					$dirfiles{repstruct} = $repstruct_ref;
					$dirfiles{mergestruct} = $mergestruct_ref;
					$dirfiles{mergecases} = $mergecases_ref;
		}
		if ( $dowhat{metamodel} eq "yes" )
		{
			$tmpblankfile = "$mypath/$file" . "_tmp_gen_blank.csv"; say $tee "IN LATINHYPERCUBE \$tmpblankfile: " . dump( $tmpblankfile );
			$bit = $file . "_";
			@bag =( $bit );
			@fills = @{ Sim::OPT::Descend::prepareblank( \%varnums, $tmpblankfile, \@blockelts, \@bag, $file, \%carrier ) };
			@fulls = uniq( map { $_->[0] } @fills );
		}
	}
	else
	{
		if ( $dowhat{morph} eq "y" )
		{
			say $tee "#Calling morphing operations for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
			my @result = Sim::OPT::Morph::morph( $configfile, \@instances, \%dirfiles, \%dowhat, \%vehicles, \%inst, \@precedents );
			$dirfiles{morphcases} = $result[0];
			$dirfiles{morphstruct} = $result[1];
			#%inst = %{ $result[2] };
		}

		if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
		{

			say $tee "#Calling simulations, reporting and retrieving for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
			( my $simcases_ref, my $simstruct_ref, my $repcases_ref, my $repstruct_ref,
			 my $mergestruct_ref, my $mergecases_ref, $csim ) = Sim::OPT::Sim::sim(
					{ instances => \@instances, dowhat => \%dowhat, dirfiles => \%dirfiles,
					  vehicles => \%vehicles, inst => \%inst, precedents => \@precedents, onlyrep => "yes" } );
			$dirfiles{simcases} = $simcases_ref;
			$dirfiles{simstruct} = $simstruct_ref;
			$dirfiles{repcases} = $repcases_ref;
			$dirfiles{repstruct} = $repstruct_ref;
			$dirfiles{mergestruct} = $mergestruct_ref;
			$dirfiles{mergecases} = $mergecases_ref;
			say $tee "#Performed simulations, reporting and retrieving for case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
		}
	}

	say $tee"NOW ON THE BRINK";
	say $tee "\$dowhat{descend} $dowhat{descend}";
	if ( $dowhat{descend} eq "y" )
	{
		say $tee "#Calling descent for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ".";
		Sim::OPT::Descend::descend(	{ instances => \@instances, dowhat => \%dowhat,
		 dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst, precedents => \@precedents } );
		say $tee "#Performed descent for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ".";
	}

	if ( $dowhat{substitutenames} eq "y" )
	{
		 Sim::OPT::Report::filter_reports( { instances => \@instances, dowhat => \%dowhat, dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst } );
	}

	if ( $dowhat{filterconverted} eq "y" )
	{
		 Sim::OPT::Report::convert_filtered_reports(
		{
			  instances => \@instances, dowhat => \%dowhat, dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst } );
	}

	if ( $dowhat{make3dtable} eq "y" )
	{
		 Sim::OPT::Report::maketable(
		{
			  instances => \@instances, dowhat => \%dowhat, dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst } );
	}
} # END SUB exe


sub genstar
{
	my ( $dowhat_ref, $varnumbers_ref, $carrier_ref, $blockelts_ref ) = @_;
	my %dowhat = %{ $dowhat_ref };
	my %carrier = %{ $carrier_ref };
	my @blockelts = @{ $blockelts_ref };

	my @varnumbers = @{ $varnumbers_ref };

	my (  @genextremes, @gencentres, @starpositions );
	if ( $dowhat{stardivisions} == 1 )
	{
		$gencentres_ref = gencen( \@varnumbers);
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
			@genpoints = @{ $genextremes_ref };
			$i++;
		}
		push( @starpositions, @genpoints );
	}

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

	if ( $dowhat{tofile} eq "" )
	{
		$tofile = "$mypath/$file-tofile.txt";
	}
	else
	{
		$tofile = $dowhat{tofile};
	}

	if ( $dowhat{randomfraction} eq "" )
	{
		$dowhat{randomfraction} = 1;
	}

	if ( $dowhat{hypercubefraction} eq "" )
	{
		$dowhat{hypercubefraction} = 1;
	}

	$tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL

	say $tee "\nNow in Sim::OPT. \n";
	$dowhat{file} = $file;

	if ( $dowhat{justchecksensitivity} ne "" )
	{
		say $tee "RECEIVED.";
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
    say $tee "NEW RANDOMIZED DIRECTIONS: " . dump( $dowhat{direction} );
  }


  { #IT FILLS THE MISSING $dowhat{direction} UNDER REQUESTED SETTINGS.
    my @newarr;
		my $i = 0;
    foreach my $dirref ( @{ $dowhat{direction} } )
    {
      my @thesesweeps = @{ $sweeps[$i] };
      my $numcases =  scalar( @thesesweeps );

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
  }

	{ #IT FILLS THE MISSING $dowhat{starorder} UNDER APPROPRIATE SETTINGS.
    my @newarr;
		my $i = 0;
    foreach my $dirref ( @{ $dowhat{starorder} } )
    {
			my @thesesweeps = @{ $sweeps[$i] };
      my $numcases =  scalar( @thesesweeps );

      my @starorders;
      my $itemsnum = scalar( @{ $dirref } );
      my $c = 0;
      while ( ( $itemsnum + $c ) <= $numcases )
      {
        push ( @starorders, ${ $dirref }[0] );
        $c++;
      }
      push ( @newarr, [ @starorders ] );
      $i++;
    }
    $dowhat{starorder} = [ @newarr ];
  }

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
    say $tee "NEW INIT LEVELS: " . dump( @miditers );
  }

	if ( not ( $target ) ) { $target = "opt"; }

	#####################################################################################
	# INSTRUCTIONS THAT LAUNCH OPT AT EACH SWEEP (SUBSPACE SEARCH) CYCLE

	if ( not ( ( @chanceseed ) and ( @caseseed ) and ( @chancedata ) ) )
	{
		if ( ( @sweepseed ) and ( @chancedata ) ) # IF THIS VALUE IS DEFINED. TO BE FIXED.
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
		my @obt = Sim::OPT::Takechance::takechance( \@caseseed, \@chanceseed, \@chancedata, $dimchance );
		@sweeps_ = @{ $obt[0] };
		@caseseed_ = @{ $obt[1] };
		@chanceseed_ = @{ $obt[2] };
		open( MESSAGE, ">./search_structure_that_may_be_adopted.txt" );
		say MESSAGE "\@sweeps_ " . Dumper(@sweeps_);
		say MESSAGE "\THESE VALUES OF \@sweeps IS EQUIVALENT TO THE FOLLOWING VALUES OF \@caseseed AND \@chanceseed: ";
		say MESSAGE "\n\@caseseed " . Dumper(@caseseed_);
		say MESSAGE "\n\@chanceseed_ " . Dumper(@chanceseed_);
		close MESSAGE;

		if ( not (@sweeps) ) # CONSERVATIVE CONDITION. IT MAY BE CHANCED.
		{
			@sweeps = @sweeps_ ;
		}
	}
	elsif ( $target eq "opt" )
	{

		if ( scalar( @miditers ) == 0 ) { calcmiditers( @varnumbers ); }

		@rootnames = definerootcases( \@sweeps, \@miditers );

		my $countcase = 0;
		my $countblock = 0;
		my %datastruc;

		my @winneritems = populatewinners( \@rootnames, $countcase, $countblock );

		my $count = 0;
		my @arr;
		foreach ( @varnumbers )
		{
			my $elt = getitem( \@winneritems, $count, 0 );
			push ( @arr, $elt );
			$count++;
		}
		$datastruc{pinwinneritem} = [ @arr ];

		my ( @gencentres, @genextremes, @genpoints, $genextremes_ref, $gencentres_ref );

		if ( $dowhat{outstarmode} eq "yes" )
		{
			if ( ( $dowhat{stardivisions} ne "" ) and ( $dowhat{starpositions} eq "" ) )
			{
				$dowhat{starpositions} = genstar( \%dowhat, \@varnumbers, $miditers[$countcase] );
			}

			$dowhat{starnumber} = scalar( @{ $dowhat{starpositions} } );

			if ( not( scalar( @{ $dowhat{starpositions} } ) == 0 ) )
			{
				$dowhat{direction} => [ [ "star" ] ];
				$dowhat{randomsweeps} => "no"; # to randomize the order specified in @sweeps.
				$dowhat{randominit} => "no"; # to randomize the init levels specified in @miditers.
				$dowhat{randomdirs} => "no"; # to randomize the directions of descent.

				my @sweeps = @{ starsweep( \@varnumbers, \@sweeps ) };

				my $number = scalar( @varnumbers );

				my ( @addition, @addition2, @addition3, @sweepaddition );
				my $cn = 0;
				while ( $cn < $dowhat{starnumber} )
				{
					push( @addition, $varnumbers[0] );
					push( @addition2, $dowhat{direction}[0] );
					push( @addition3, $dowhat{starorder}[0] );
					push( @sweepaddition, $sweeps[0] );
					$cn++;
				}

				@varnumbers = @addition;
				$dowhat{direction} = \@addition2;
				$dowhat{starorder} = \@addition3;
				my @sweeps = @sweepaddition;

				my @bag;
				my @miditers = @miditers[1 ... $#miditers];
				push( @bag, @{ $dowhat{starpositions} }, @miditers );
				my @miditers = @bag;

				$countstring = 1;

				my ( $sweepz_ref, $sourcesweeps_ref ) = readsweeps( @sweeps );
				my @sweepz = @$sweepz_ref;
				my @sourcesweeps = @$sourcesweeps_ref;
				if ( @sweepz )
				{
					@sweeps = @sweepz;
				}

				@calcoverlaps = calcoverlaps( @sweeps );

				$dirfiles{countstring} = $countstring;
				$dirfiles{nestclock} = 0;

				$dirfiles{tottot} = "$mypath/$file-$countcase" . "-tottot.csv";
				$dirfiles{ordtot} = "$mypath/$file-$countcase" . "-ordtot.csv";


				callblock( { countcase => $countcase, countblock => $countblock,
					miditers => \@miditers, varnumbers => \@varnumbers, winneritems => \@winneritems, sweeps => \@sweeps,
					sourcesweeps => \@sourcesweeps, datastruc => \%datastruc, dirfiles => \%dirfiles,
					dowhat => \%dowhat, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
					$countstring++;
					$dirfiles{countstring} = $countstring;
			}
		}
		else
		{
			my ( $sweepz_ref, $sourcesweeps_ref ) = cleansweeps( \@sweeps );
			my @sweepz = @{ $sweepz_ref };
			my @sourcesweeps = @{ $sourcesweeps_ref };
			if ( @sweepz )
			{
				@sweeps = @sweepz;
			}

			#@calcoverlaps = calcoverlaps( @sweeps );
			$dirfiles{tottot} = "$mypath/$file-$countcase" . "-tottot.csv";
			$dirfiles{ordtot} = "$mypath/$file-$countcase" . "-ordtot.csv";
			#@miditers = @pinmiditers;
			say $tee "miditers: " . dump ( @miditers );

			if ( scalar( @miditers ) == 0 ) { calcmiditers( @varnumbers ); }

			@rootnames = definerootcases( \@sweeps, \@miditers );

			my $countcase = 0;
			my $countblock = 0;
			my %datastruc;

			my @winneritems = populatewinners( \@rootnames, $countcase, $countblock );

			my $count = 0;
			my @arr;
			foreach ( @varnumbers )
			{
				my $elt = getitem(\@winneritems, $count, 0);
				push ( @arr, $elt );
				$count++;
			}
			$datastruc = [ @arr ];

			$dirfiles{nestclock} = 0;
			callblock
			(	{ countcase => $countcase, countblock => $countblock,
					miditers => \@miditers, varnumbers => \@varnumbers, winneritems => \@winneritems,
					sweeps => \@sweeps, sourcesweeps => \@sourcesweeps,
					datastruc => \%datastruc, dowhat => \%dowhat,
					dirfiles => \%dirfiles, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
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

OPT is an optimization and parametric exploration program favouring problem decomposition. It can be used with simulation programs receiving text files as input and emitting text files as output. Sim::OPT's optimization modules (Sim::OPT, Sim::OPT::Descent) pursue optimization through block search, allowing blocks (subspaces) to overlap, and allowing a free intermix of sequential searches (inexact Gauss-Seidel method) and parallell ones (inexact Jacobi method). The Sim::OPT::Takechange module can seek for the least explored search paths when exploring new search spaces sequentially (following rules presented in: http://dx.doi.org/10.1016/j.autcon.2016.08.014). Sim::OPT::Morph, the morphing module, can manipulate parameters of simulation models.
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

By default the behaviour of the program is sequential.

OPT can perform star searches (Jacoby method of course, but also Gauss-Seidel) within blocks in place of multilevel full-factorial searches. To ask for that in a configuration file, the first number in a block has to be preceded by a ">" sign, which in its turn has to be preceded by a number specifying how many star points there have to be in the block. A block, in that case, should be declared with something like this: ( "2>1", 2, 3). When operating with pre-simulated dataseries or metamodels, OPT can also perform: factorial searches (to ask for that, the first number in that block has to be preceded by a "<" sign); face-centered composite design searches of the DOE type (in that case, the first number in the block has to be preceded by a "£"); random searches (the first number has to be preceded by a "|" or by a "°"); latin hypercube searches (the first number has to be preceded by a "§"). The simbols "ç" and "é" preceding the first number make possible to cumulate the search results, possibly in a nested manner. "ç" opens the first block and "é" opens the last block. Following that instruction, at the end of the execution of the last block, the results of the previous blocks are cumulated in the evaluation. The number preceding the "é", when present, tells how many top-performing metamodel results have to be refreshed with real samples (simulations).

For specifying in a Sim::OPT configuration file that a certain block has to be searched by the means of a metamodel derived from star searches or other "positions" instead of a multilevel full-factorial search, it is necessary to assign the value "yes" to the variable $dowhat{metamodel}.

OPT can perform variance-based preliminary sensitivity analyses on the basis of metamodels.

OPT works under Linux.

=head2 EXPORT

"opt".

=head1 SEE ALSO

Annotated examples (which include "esp.pl" for ESP-r, "ep.pl" for EnergyPlus - the two perform the same morphing operations on models describing the same building -, "des.pl" about block search, and "f.pl" about a search in a pre-simulated dataset, and other) can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution. They constitute all the available documentation besides these pages and the source code.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2022 by Gian Luca Brunetti and Politecnico di Milano. This is free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
